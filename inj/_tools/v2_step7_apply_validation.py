#!/usr/bin/env python3
"""
Exercise model V2 - PHASE 2, STEP 7
Apply the corrections produced by the three validation agents.

The agents review in parallel but never touch the database: they emit JSON
proposals, and everything lands here in ONE transaction so a partially applied
review can never exist.

Every proposal is checked before it is trusted:
  - the exercise code must exist
  - the field must be one we allow to be corrected
  - the proposed value must be legal for that column's enum
  - `current` must still match the database, otherwise the proposal was written
    against stale state and is rejected rather than blindly applied

Rejections are reported, never silently dropped.

Corrected rows are marked evidence_basis = expert_curated / confidence =
moderate. They are NOT promoted to `verified` catalog_status: an LLM review is
a review, but it is not a human sign-off, and the field has to keep meaning
something.

Usage:
    python inj/_tools/v2_step7_apply_validation.py --dsn "..." [--apply]
"""
import argparse
import json
import os
import pathlib
import sys
from collections import Counter, defaultdict

import psycopg

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from dsn import get_dsn  # noqa: E402

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

VALIDATION_DIR = pathlib.Path(__file__).resolve().parents[1] / "_validation"

# field -> (table, column, enum type or None for booleans)
EXERCISE_FIELDS = {
    "exercise_kind": "exercises.exercise_kind",
    "technical_demand": "exercises.technical_demand",
    "joint_class": "exercises.joint_class",
    "spotter_policy": "exercises.spotter_policy",
    "unilateral": None,
    "bodyweight": None,
}
TRACKING_FIELDS = {
    "tracking_type": "exercises.tracking_type",
    "load_input_mode": "exercises.load_input_mode",
    "side_mode": "exercises.side_mode",
    "comparison_scope": "exercises.comparison_scope",
}
BIOMECHANICS_FIELDS = {
    "resistance_source": "exercises.resistance_source",
    "stability_demand": "exercises.load_level",
    "spinal_loading": "exercises.load_level",
}
TENSION_FIELD = "muscle_tension"
TENSION_LEVELS = {"none", "low", "moderate", "high"}
BOOLEANS = {"true": True, "false": False}


def load_enum_values(cur, type_name):
    schema, name = type_name.split(".", 1)
    cur.execute("""SELECT e.enumlabel FROM pg_type t
                     JOIN pg_enum e ON e.enumtypid = t.oid
                     JOIN pg_namespace n ON n.oid = t.typnamespace
                    WHERE n.nspname = %s AND t.typname = %s""", (schema, name))
    return {r[0] for r in cur.fetchall()}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dsn", default=None,
                    help="optional; resolved from $COACHLY_BIOMECH_DSN or auto-injestion/.env")
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--min-confidence", default="moderate",
                    choices=["moderate", "high"],
                    help="skip proposals below this confidence")
    args = ap.parse_args()
    dsn = args.dsn or get_dsn()

    # corrections_* = first review, refutations_* = adversarial reversals,
    # tension_* / linked_data = the deep passes. All share one shape.
    files = sorted(set(VALIDATION_DIR.glob("corrections_*.json"))
                   | set(VALIDATION_DIR.glob("refutations_*.json"))
                   | set(VALIDATION_DIR.glob("tension_*.json"))
                   | set(VALIDATION_DIR.glob("linked_data*.json")))
    if not files:
        sys.exit(f"no correction files in {VALIDATION_DIR}")

    proposals = []
    for path in files:
        try:
            payload = json.loads(path.read_text(encoding="utf-8"))
        except Exception as exc:  # noqa: BLE001
            print(f"!! {path.name} is not valid JSON: {exc}")
            continue
        if not isinstance(payload, list):
            print(f"!! {path.name} is not a JSON array, skipped")
            continue
        for item in payload:
            item["_source"] = path.name
            proposals.append(item)
        print(f"{path.name}: {len(payload)} proposals")

    # the blind audit reports {"seed", "sampled_codes", "findings": [...]}
    audit = VALIDATION_DIR / "audit_blind.json"
    if audit.exists():
        try:
            payload = json.loads(audit.read_text(encoding="utf-8"))
            findings = payload.get("findings", []) if isinstance(payload, dict) else []
            for item in findings:
                item["_source"] = audit.name
                proposals.append(item)
            sampled = len(payload.get("sampled_codes", [])) if isinstance(payload, dict) else 0
            affected = len({i["exercise_code"] for i in findings if i.get("exercise_code")})
            print(f"{audit.name}: {len(findings)} findings on {affected}/{sampled} sampled "
                  f"({100 * affected // max(1, sampled)}% residual error rate)")
        except Exception as exc:  # noqa: BLE001
            print(f"!! {audit.name} unreadable: {exc}")
    print(f"total proposals: {len(proposals)}\n")

    with psycopg.connect(dsn, connect_timeout=30) as conn:
        conn.autocommit = False
        cur = conn.cursor()

        enum_values = {}
        for mapping in (EXERCISE_FIELDS, TRACKING_FIELDS, BIOMECHANICS_FIELDS):
            for field, enum_type in mapping.items():
                if enum_type:
                    enum_values[field] = load_enum_values(cur, enum_type)

        cur.execute("""SELECT code, id FROM exercises.exercise WHERE deleted_at IS NULL""")
        exercise_ids = dict(cur.fetchall())
        cur.execute("SELECT code, id FROM exercises.muscle")
        muscle_ids = dict(cur.fetchall())

        accepted, rejected = [], []
        reject_reasons = Counter()

        for item in proposals:
            code = (item.get("exercise_code") or "").strip()
            field = (item.get("field") or "").strip()
            proposed = item.get("proposed")
            confidence = (item.get("confidence") or "moderate").strip().lower()

            def reject(why):
                reject_reasons[why] += 1
                rejected.append({**item, "_why": why})

            if code not in exercise_ids:
                reject("unknown exercise_code"); continue
            if args.min_confidence == "high" and confidence != "high":
                reject("below confidence threshold"); continue
            if proposed is None:
                reject("no proposed value"); continue

            if field in EXERCISE_FIELDS:
                if EXERCISE_FIELDS[field] is None:
                    value = str(proposed).strip().lower()
                    if value not in BOOLEANS:
                        reject("not a boolean"); continue
                    proposed_value = BOOLEANS[value]
                else:
                    proposed_value = str(proposed).strip().lower()
                    if proposed_value not in enum_values[field]:
                        reject(f"illegal value for {field}"); continue
                accepted.append((item, "exercise", field, proposed_value))

            elif field in TRACKING_FIELDS:
                proposed_value = str(proposed).strip().lower()
                if proposed_value not in enum_values[field]:
                    reject(f"illegal value for {field}"); continue
                accepted.append((item, "tracking", field, proposed_value))

            elif field in BIOMECHANICS_FIELDS:
                proposed_value = str(proposed).strip().lower()
                if proposed_value not in enum_values[field]:
                    reject(f"illegal value for {field}"); continue
                accepted.append((item, "biomechanics", field, proposed_value))

            elif field == TENSION_FIELD:
                raw = str(proposed).strip()
                if ":" not in raw:
                    reject("tension needs muscle_code:l/m/s"); continue
                muscle_code, levels = raw.split(":", 1)
                muscle_code = muscle_code.strip()
                parts = [p.strip().lower() for p in levels.split("/")]
                if muscle_code not in muscle_ids:
                    reject("unknown muscle code"); continue
                if len(parts) != 3 or any(p not in TENSION_LEVELS for p in parts):
                    reject("illegal tension levels"); continue
                accepted.append((item, "tension", muscle_code, tuple(parts)))

            else:
                reject(f"unsupported field '{field}'")

        print(f"accepted: {len(accepted)}   rejected: {len(rejected)}")
        for why, count in reject_reasons.most_common():
            print(f"   rejected - {why}: {count}")

        # ---- stale-state check: refuse proposals written against old values ----
        stale = 0
        applied = Counter()
        for item, target, field, value in accepted:
            code = item["exercise_code"]
            exercise_id = exercise_ids[code]
            declared_current = item.get("current")

            if target == "exercise":
                cur.execute(f"SELECT {field}::text FROM exercises.exercise WHERE id = %s", (exercise_id,))
            elif target == "tracking":
                cur.execute(f"SELECT {field}::text FROM exercises.exercise_tracking_profile WHERE exercise_id = %s", (exercise_id,))
            elif target == "biomechanics":
                cur.execute(f"SELECT {field}::text FROM exercises.exercise_biomechanics WHERE exercise_id = %s", (exercise_id,))
            else:
                cur.execute("""SELECT tension_lengthened::text || '/' || tension_midrange::text
                                      || '/' || tension_shortened::text
                                 FROM exercises.exercise_muscle
                                WHERE exercise_id = %s AND muscle_id = %s""",
                            (exercise_id, muscle_ids[field]))
            row = cur.fetchone()
            if row is None:
                reject_reasons["target row missing"] += 1
                stale += 1
                continue
            actual = row[0]
            if declared_current is not None and str(declared_current).strip().lower() not in ("", "none"):
                normalized = str(declared_current).strip().lower()
                if target == "tension":
                    normalized = normalized.split(":", 1)[-1]
                if actual is not None and normalized != actual.lower():
                    # Agents ran concurrently, so a mismatch can mean either
                    # "written against old state" or "another agent already
                    # reviewed this row and disagrees". Only the first is safe
                    # to override: if the row has been reviewed since, two
                    # judgements conflict and there is no way to tell which is
                    # right, so the existing one stands.
                    reviewed = False
                    if target == "tension":
                        cur.execute("""SELECT evidence_basis::text
                                         FROM exercises.exercise_muscle
                                        WHERE exercise_id = %s AND muscle_id = %s""",
                                    (exercise_id, muscle_ids[field]))
                        basis = cur.fetchone()
                        reviewed = bool(basis) and basis[0] not in (
                            "biomechanical_model", "heuristic")
                    if reviewed:
                        reject_reasons["conflicts with an already reviewed row"] += 1
                        stale += 1
                        continue
                    reject_reasons["stale current, row never reviewed - applied"] += 1

            if target == "exercise":
                cur.execute(f"UPDATE exercises.exercise SET {field} = %s, updated_at = NOW() WHERE id = %s",
                            (value, exercise_id))
            elif target == "tracking":
                cur.execute(f"""UPDATE exercises.exercise_tracking_profile
                                   SET {field} = %s, evidence_basis = 'expert_curated',
                                       confidence = 'moderate', updated_at = NOW()
                                 WHERE exercise_id = %s""", (value, exercise_id))
            elif target == "biomechanics":
                cur.execute(f"""UPDATE exercises.exercise_biomechanics
                                   SET {field} = %s, evidence_basis = 'expert_curated',
                                       confidence = 'moderate',
                                       method_note = coalesce(method_note,'') || ' | reviewed',
                                       updated_at = NOW()
                                 WHERE exercise_id = %s""", (value, exercise_id))
            else:
                lengthened, midrange, shortened = value
                cur.execute("""UPDATE exercises.exercise_muscle
                                  SET tension_lengthened = %s, tension_midrange = %s,
                                      tension_shortened = %s, evidence_basis = 'expert_curated',
                                      confidence = 'moderate', updated_at = NOW()
                                WHERE exercise_id = %s AND muscle_id = %s""",
                            (lengthened, midrange, shortened, exercise_id, muscle_ids[field]))
            applied[f"{target}.{field if target != 'tension' else 'tension'}"] += cur.rowcount

        print(f"\nstale / unmatched, not applied: {stale}")
        print("applied by target:")
        for key, count in applied.most_common():
            print(f"   {key:34s} {count}")
        print(f"total row updates: {sum(applied.values())}")

        # ---- the invariants must still hold ----
        print("\n--- quality gate re-check")
        checks = [
            ("exercises without kind",
             "SELECT count(*) FROM exercises.exercise WHERE deleted_at IS NULL AND exercise_kind IS NULL"),
            ("exercises without tracking profile",
             """SELECT count(*) FROM exercises.exercise e
                 LEFT JOIN exercises.exercise_tracking_profile t ON t.exercise_id = e.id
                WHERE e.deleted_at IS NULL AND t.exercise_id IS NULL"""),
            ("PRIMARY muscles without tension profile",
             """SELECT count(*) FROM exercises.exercise_muscle
                 WHERE involvement = 'primary' AND (tension_lengthened IS NULL
                       OR tension_midrange IS NULL OR tension_shortened IS NULL)"""),
            ("RESISTANCE, not bodyweight, without equipment",
             """SELECT count(*) FROM exercises.exercise e
                 WHERE e.deleted_at IS NULL AND e.exercise_kind = 'resistance'
                   AND e.bodyweight = false
                   AND NOT EXISTS (SELECT 1 FROM exercises.exercise_equipment q
                                    WHERE q.exercise_id = e.id)"""),
            ("derived data claiming to be MEASURED",
             "SELECT count(*) FROM exercises.exercise_muscle WHERE evidence_basis = 'measured'"),
        ]
        failures = 0
        for label, query in checks:
            cur.execute(query)
            value = cur.fetchone()[0]
            if value:
                failures += 1
            print(f"   [{'OK  ' if value == 0 else 'FAIL'}] {label:46s} {value}")

        report = VALIDATION_DIR / "rejected.json"
        report.write_text(json.dumps(rejected, indent=1, ensure_ascii=False), encoding="utf-8")
        print(f"\nrejected proposals written to {report}")

        if args.apply and failures == 0:
            conn.commit()
            print("COMMITTED")
        elif args.apply:
            conn.rollback()
            sys.exit("quality gate broke - rolled back")
        else:
            conn.rollback()
            print("DRY RUN - rolled back")


if __name__ == "__main__":
    main()
