#!/usr/bin/env python3
"""
Exercise model V2 - PHASE 2, STEP 15
Fix what comparing the execution TEXT against the stored data exposed.

Two families:

1. Placeholder text shipped to users. Some records carry literal "//" entries
   in their tips, and some leak the i18n key itself ("safety_tips_en"). Those
   are swept catalogue-wide, not just on the reported exercises: if the ingest
   produced them once it produced them everywhere.

2. Muscles that contradict the exercise's own description. The archetype regex
   copied the wrong muscle set in, and the text is the witness: a rear delt fly
   whose primary is the ANTERIOR deltoid, an overhead press whose only muscle
   is rectus abdominis, a cable calf raise carrying hamstrings and glutes.
   These are corrected against what the description itself says.

Usage:
    python inj/_tools/v2_step15_text_and_muscles.py [--apply]
"""
import argparse
import json
import pathlib
import sys

import psycopg

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from dsn import get_dsn  # noqa: E402

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

# text that should never reach a user
PLACEHOLDERS = ("//", "///", "-", "n/a", "na", "tbd", "todo")
PLACEHOLDER_PREFIXES = ("safety_tips_", "execution_tips_", "description_", "name_", "tips_")

# exercise code -> (primary muscle codes, secondary, muscles to remove)
MUSCLE_FIXES = {
    # the description says overhead press; only rectus abdominis was linked
    "strict_press_overhead_press": (
        ["deltoid_anterior", "deltoid_lateral", "triceps_brachii_long"],
        ["triceps_brachii_lateral", "trapezius_upper"], ["rectus_abdominis"]),
    # torso extension on a GHD, with its antagonist stored as the prime mover
    "weighted_ghd_back_extension": (
        ["erector_spinae", "gluteus_maximus", "biceps_femoris_long"],
        ["multifidus", "semitendinosus"], ["rectus_abdominis"]),
    # a rear delt fly whose primary was the ANTERIOR deltoid
    "cable_cross_over_reverse_fly": (
        ["deltoid_posterior"], ["rhomboids", "trapezius_middle", "infraspinatus"],
        ["deltoid_anterior"]),
    "barbell_rear_delt_row": (
        ["deltoid_posterior"], ["rhomboids", "trapezius_middle", "biceps_brachii_long"],
        ["deltoid_anterior"]),
    "lever_lateral_raise": (
        ["deltoid_lateral"], ["deltoid_anterior", "trapezius_upper"], []),
    # plantar flexion carrying hamstrings and glutes from a poisoned archetype
    "cable_standing_calf_raise": (
        ["gastrocnemius_medial", "gastrocnemius_lateral"], ["soleus"],
        ["biceps_femoris_long", "gluteus_maximus"]),
}

# exercises whose stored classification the text contradicts
FIELD_FIXES = [
    ("handstand_push_up", "technical_demand", "high"),
    ("paused_handstand_push_up", "technical_demand", "high"),
    ("tempo_handstand_push_up", "technical_demand", "high"),
    ("close_grip_handstand_push_up", "technical_demand", "high"),
    ("barbell_rear_delt_row", "joint_class", "multi_joint"),
]


def strip_placeholders(value):
    """Drop placeholder entries from a tips-style value, keeping the shape."""
    if isinstance(value, list):
        kept = [v for v in value if not is_placeholder(v)]
        return kept if kept else None
    if is_placeholder(value):
        return None
    return value


def is_placeholder(item):
    if item is None:
        return True
    text = str(item).strip().lower()
    if not text or text in PLACEHOLDERS:
        return True
    return any(text.startswith(prefix) for prefix in PLACEHOLDER_PREFIXES)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dsn", default=None,
                    help="optional; resolved from $COACHLY_BIOMECH_DSN or auto-injestion/.env")
    ap.add_argument("--apply", action="store_true")
    args = ap.parse_args()
    dsn = args.dsn or get_dsn()

    with psycopg.connect(dsn, connect_timeout=30) as conn:
        conn.autocommit = False
        cur = conn.cursor()

        # ---------- 1. placeholder sweep ----------
        cur.execute("""SELECT id, code, translations FROM exercises.exercise
                        WHERE deleted_at IS NULL""")
        rows = cur.fetchall()
        cleaned, affected = 0, []
        for exercise_id, code, raw in rows:
            payload = raw if isinstance(raw, dict) else json.loads(raw)
            changed = False
            for locale, content in list(payload.items()):
                if not isinstance(content, dict):
                    continue
                for key, value in list(content.items()):
                    stripped = strip_placeholders(value)
                    if stripped != value:
                        changed = True
                        if stripped is None:
                            content.pop(key)
                        else:
                            content[key] = stripped
            if changed:
                cur.execute("""UPDATE exercises.exercise
                                  SET translations = %s::jsonb, updated_at = NOW()
                                WHERE id = %s""",
                            (json.dumps(payload, ensure_ascii=False), exercise_id))
                cleaned += 1
                if len(affected) < 10:
                    affected.append(code)
        print(f"placeholder text removed from {cleaned} exercises")
        if affected:
            print("   e.g.", ", ".join(affected))

        # nothing may have lost its name in the process
        cur.execute("""SELECT count(*) FROM exercises.exercise
                        WHERE deleted_at IS NULL
                          AND NOT (translations -> 'it' ? 'name' AND translations -> 'en' ? 'name')""")
        lost = cur.fetchone()[0]
        print(f"exercises left without a name translation: {lost}")
        if lost:
            conn.rollback()
            sys.exit("translations damaged - rolled back")

        # ---------- 2. muscles the description contradicts ----------
        cur.execute("SELECT code, id FROM exercises.muscle")
        muscle_ids = dict(cur.fetchall())
        cur.execute("""SELECT code, id FROM exercises.exercise WHERE deleted_at IS NULL""")
        exercise_ids = dict(cur.fetchall())

        print("\nmuscle sets corrected against the description:")
        for code, (primaries, secondaries, remove) in MUSCLE_FIXES.items():
            exercise_id = exercise_ids.get(code)
            if exercise_id is None:
                print(f"   ! {code}: not in the catalogue, skipped")
                continue
            if remove:
                cur.execute("""DELETE FROM exercises.exercise_muscle
                                WHERE exercise_id = %s AND muscle_id = ANY(
                                    SELECT id FROM exercises.muscle WHERE code = ANY(%s))""",
                            (exercise_id, remove))
            removed = cur.rowcount if remove else 0

            # reuse the tension profile of a muscle that is already right here,
            # rather than inventing one
            cur.execute("""SELECT tension_lengthened::text, tension_midrange::text,
                                  tension_shortened::text
                             FROM exercises.exercise_muscle
                            WHERE exercise_id = %s AND tension_lengthened IS NOT NULL
                            LIMIT 1""", (exercise_id,))
            profile = cur.fetchone() or ("moderate", "high", "moderate")

            added = 0
            for involvement, codes in (("primary", primaries), ("secondary", secondaries)):
                for muscle_code in codes:
                    if muscle_code not in muscle_ids:
                        print(f"   ! unknown muscle {muscle_code}")
                        continue
                    cur.execute("""INSERT INTO exercises.exercise_muscle
                                       (exercise_id, muscle_id, involvement, created_at,
                                        updated_at, tension_lengthened, tension_midrange,
                                        tension_shortened, evidence_basis, confidence)
                                   VALUES (%s, %s, %s, NOW(), NOW(), %s, %s, %s,
                                           'expert_curated', 'moderate')
                                   ON CONFLICT (exercise_id, muscle_id, involvement)
                                   DO UPDATE SET evidence_basis = 'expert_curated',
                                                 confidence = 'moderate', updated_at = NOW()""",
                                (exercise_id, muscle_ids[muscle_code], involvement,
                                 profile[0], profile[1], profile[2]))
                    added += cur.rowcount
            print(f"   {code:34s} -{removed} +{added}")

        # ---------- 3. classification the text contradicts ----------
        print("\nclassification corrected against the description:")
        for code, field, value in FIELD_FIXES:
            cur.execute(f"""UPDATE exercises.exercise SET {field} = %s, updated_at = NOW()
                             WHERE code = %s AND deleted_at IS NULL""", (value, code))
            print(f"   {code:34s} {field} -> {value}  ({cur.rowcount})")

        # ---------- 4. invariants ----------
        print("\n--- invariants")
        for label, query in [
            ("exercises without a PRIMARY muscle",
             """SELECT count(*) FROM exercises.exercise e WHERE e.deleted_at IS NULL
                  AND NOT EXISTS (SELECT 1 FROM exercises.exercise_muscle m
                                   WHERE m.exercise_id = e.id AND m.involvement = 'primary')"""),
            ("PRIMARY muscles without tension profile",
             """SELECT count(*) FROM exercises.exercise_muscle
                 WHERE involvement = 'primary' AND tension_lengthened IS NULL"""),
            ("placeholder text still present",
             """SELECT count(*) FROM exercises.exercise
                 WHERE deleted_at IS NULL AND translations::text LIKE '%"//"%'"""),
        ]:
            cur.execute(query)
            value = cur.fetchone()[0]
            print(f"   [{'OK  ' if value == 0 else 'FAIL'}] {label:44s} {value}")
            if value:
                conn.rollback()
                sys.exit("invariant broken - rolled back")

        if args.apply:
            conn.commit()
            print("COMMITTED")
        else:
            conn.rollback()
            print("DRY RUN - rolled back")


if __name__ == "__main__":
    main()
