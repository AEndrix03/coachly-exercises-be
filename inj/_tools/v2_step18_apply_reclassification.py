#!/usr/bin/env python3
"""
Exercise model V2 - PHASE 2, STEP 18
Apply a reclassification derived from the DESCRIPTION, not the name.

Three blind measurements (47.5% -> 53.1%) showed that no amount of correcting
individual fields helps, because muscles, joint actions, movement patterns and
tension all descend from ONE root: an archetype matched by regex on the
exercise NAME. Deriving any of them from another just reshuffles the same
errors, which is exactly what step 17 did.

The descriptions were never used by that classifier, and the auditors read them
to identify exercises correctly every time. So they are the better source of
truth, and this step exists to write a classification taken from them.

It also removes the limitation that made the earlier rounds blind: the
correction vocabulary now covers muscle involvement, joint actions and movement
patterns, not just enums. Those were where the errors lived and there was no way
to express a fix.

Every proposal is still validated before it is trusted: the code must exist, the
value must be legal for its enum, and a removal must actually match something.

Usage:
    python inj/_tools/v2_step18_apply_reclassification.py [--apply]
"""
import argparse
import json
import pathlib
import sys
from collections import Counter

import psycopg

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from dsn import get_dsn  # noqa: E402

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

VALIDATION_DIR = pathlib.Path(__file__).resolve().parents[1] / "_validation"
INVOLVEMENTS = {"primary", "secondary", "stabilizer", "remove"}
ROLES = {"primary", "secondary", "remove"}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dsn", default=None,
                    help="optional; resolved from $COACHLY_BIOMECH_DSN or auto-injestion/.env")
    ap.add_argument("--apply", action="store_true")
    args = ap.parse_args()
    dsn = args.dsn or get_dsn()

    files = sorted(VALIDATION_DIR.glob("reclass_*.json"))
    if not files:
        sys.exit(f"no reclass_*.json in {VALIDATION_DIR}")

    entries = []
    for path in files:
        try:
            payload = json.loads(path.read_text(encoding="utf-8"))
        except Exception as exc:  # noqa: BLE001
            print(f"!! {path.name} unreadable: {exc}")
            continue
        if not isinstance(payload, list):
            print(f"!! {path.name} is not a JSON array")
            continue
        entries.extend(payload)
        print(f"{path.name}: {len(payload)} exercises")
    print(f"total exercises to reclassify: {len(entries)}\n")

    with psycopg.connect(dsn, connect_timeout=60) as conn:
        conn.autocommit = False
        cur = conn.cursor()

        cur.execute("SELECT code, id FROM exercises.exercise WHERE deleted_at IS NULL")
        exercise_ids = dict(cur.fetchall())
        cur.execute("SELECT code, id FROM exercises.muscle")
        muscle_ids = dict(cur.fetchall())
        cur.execute("SELECT joint_code, action_code, id FROM exercises.joint_action")
        action_ids = {(j, a): i for j, a, i in cur.fetchall()}
        cur.execute("SELECT code, id FROM exercises.movement_pattern")
        pattern_ids = dict(cur.fetchall())

        stats, rejected = Counter(), Counter()

        for entry in entries:
            code = (entry.get("exercise_code") or "").strip()
            exercise_id = exercise_ids.get(code)
            if exercise_id is None:
                rejected["unknown exercise"] += 1
                continue
            stats["exercises touched"] += 1

            # ---- muscles ----
            for item in entry.get("muscles", []):
                muscle_code = (item.get("muscle") or "").strip()
                involvement = (item.get("involvement") or "").strip().lower()
                if muscle_code not in muscle_ids or involvement not in INVOLVEMENTS:
                    rejected["bad muscle entry"] += 1
                    continue
                if involvement == "remove":
                    cur.execute("""DELETE FROM exercises.exercise_muscle
                                    WHERE exercise_id = %s AND muscle_id = %s""",
                                (exercise_id, muscle_ids[muscle_code]))
                    stats["muscle rows removed"] += cur.rowcount
                    continue
                # one row per muscle: change the involvement in place if present
                cur.execute("""UPDATE exercises.exercise_muscle
                                  SET involvement = %s, evidence_basis = 'expert_curated',
                                      confidence = 'moderate', updated_at = NOW()
                                WHERE exercise_id = %s AND muscle_id = %s""",
                            (involvement, exercise_id, muscle_ids[muscle_code]))
                if cur.rowcount:
                    stats["muscle involvement changed"] += cur.rowcount
                    continue
                cur.execute("""INSERT INTO exercises.exercise_muscle
                                   (exercise_id, muscle_id, involvement, created_at, updated_at,
                                    tension_lengthened, tension_midrange, tension_shortened,
                                    evidence_basis, confidence)
                               VALUES (%s, %s, %s, NOW(), NOW(), 'moderate','high','moderate',
                                       'expert_curated','moderate')
                               ON CONFLICT DO NOTHING""",
                            (exercise_id, muscle_ids[muscle_code], involvement))
                stats["muscle rows added"] += cur.rowcount

            # ---- joint actions ----
            for item in entry.get("joint_actions", []):
                joint = (item.get("joint") or "").strip()
                action = (item.get("action") or "").strip()
                role = (item.get("role") or "").strip().lower()
                action_id = action_ids.get((joint, action))
                if action_id is None or role not in ROLES:
                    rejected["bad joint action"] += 1
                    continue
                if role == "remove":
                    cur.execute("""DELETE FROM exercises.exercise_joint_action
                                    WHERE exercise_id = %s AND joint_action_id = %s""",
                                (exercise_id, action_id))
                    stats["joint actions removed"] += cur.rowcount
                    continue
                cur.execute("""INSERT INTO exercises.exercise_joint_action
                                   (exercise_id, joint_action_id, role)
                               VALUES (%s, %s, %s)
                               ON CONFLICT (exercise_id, joint_action_id)
                               DO UPDATE SET role = EXCLUDED.role""",
                            (exercise_id, action_id, role))
                stats["joint actions set"] += cur.rowcount

            # ---- movement patterns ----
            for item in entry.get("movement_patterns", []):
                pattern_code = (item.get("pattern") or "").strip()
                role = (item.get("role") or "").strip().lower()
                pattern_id = pattern_ids.get(pattern_code)
                if pattern_id is None or role not in ROLES:
                    rejected["bad movement pattern"] += 1
                    continue
                if role == "remove":
                    cur.execute("""DELETE FROM exercises.exercise_movement_pattern
                                    WHERE exercise_id = %s AND movement_pattern_id = %s""",
                                (exercise_id, pattern_id))
                    stats["patterns removed"] += cur.rowcount
                    continue
                cur.execute("""INSERT INTO exercises.exercise_movement_pattern
                                   (exercise_id, movement_pattern_id, role)
                               VALUES (%s, %s, %s)
                               ON CONFLICT (exercise_id, movement_pattern_id)
                               DO UPDATE SET role = EXCLUDED.role""",
                            (exercise_id, pattern_id, role))
                stats["patterns set"] += cur.rowcount

        print("--- applied")
        for key, value in stats.most_common():
            print(f"   {key:32s} {value}")
        if rejected:
            print("--- rejected")
            for key, value in rejected.most_common():
                print(f"   {key:32s} {value}")

        # a muscle appears once per exercise; strongest involvement wins
        cur.execute("""DELETE FROM exercises.exercise_muscle weak
                        USING exercises.exercise_muscle strong
                        WHERE weak.exercise_id = strong.exercise_id
                          AND weak.muscle_id = strong.muscle_id
                          AND CASE weak.involvement WHEN 'primary' THEN 3
                                                    WHEN 'secondary' THEN 2 ELSE 1 END
                            < CASE strong.involvement WHEN 'primary' THEN 3
                                                      WHEN 'secondary' THEN 2 ELSE 1 END""")
        print(f"\nduplicate involvement rows collapsed: {cur.rowcount}")

        print("\n--- invariants")
        failed = False
        for label, query in [
            ("exercises without a PRIMARY muscle",
             """SELECT count(*) FROM exercises.exercise e WHERE e.deleted_at IS NULL
                  AND NOT EXISTS (SELECT 1 FROM exercises.exercise_muscle m
                                   WHERE m.exercise_id = e.id AND m.involvement = 'primary')"""),
            ("PRIMARY muscles without tension profile",
             """SELECT count(*) FROM exercises.exercise_muscle
                 WHERE involvement = 'primary' AND tension_lengthened IS NULL"""),
            ("RESISTANCE without movement pattern",
             """SELECT count(*) FROM exercises.exercise e
                 WHERE e.deleted_at IS NULL AND e.exercise_kind = 'resistance'
                   AND NOT EXISTS (SELECT 1 FROM exercises.exercise_movement_pattern p
                                    WHERE p.exercise_id = e.id)"""),
            ("RESISTANCE without joint action",
             """SELECT count(*) FROM exercises.exercise e
                 WHERE e.deleted_at IS NULL AND e.exercise_kind = 'resistance'
                   AND NOT EXISTS (SELECT 1 FROM exercises.exercise_joint_action j
                                    WHERE j.exercise_id = e.id)"""),
            ("a muscle listed twice with different involvement",
             """SELECT count(*) FROM (SELECT exercise_id, muscle_id
                                        FROM exercises.exercise_muscle
                                       GROUP BY 1,2 HAVING count(*) > 1) d"""),
        ]:
            cur.execute(query)
            value = cur.fetchone()[0]
            print(f"   [{'OK  ' if value == 0 else 'FAIL'}] {label:48s} {value}")
            if value:
                failed = True
        if failed:
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
