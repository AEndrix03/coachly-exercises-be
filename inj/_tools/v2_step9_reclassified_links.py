#!/usr/bin/env python3
"""
Exercise model V2 - PHASE 2, STEP 9
Give movement patterns and joint actions to the exercises the validation
agents moved into `resistance`.

The agents could correct exercise_kind but not the link tables, so four
exercises promoted out of `mobility` / `conditioning` were left without the
patterns every resistance exercise must have. Their movements are unambiguous,
so they are stated explicitly here.

Usage:
    python inj/_tools/v2_step9_reclassified_links.py [--apply]
"""
import argparse
import os
import sys

import psycopg

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

# code -> (patterns [(code, role)], joint actions [(joint, action, role)])
LINKS = {
    # a cable "kayak" row is a rotational horizontal pull, not conditioning
    "cable_thibaudeau_kayak_row": (
        [("horizontal_pull", "primary"), ("rotation", "secondary")],
        [("shoulder", "extension", "primary"), ("elbow", "flexion", "primary"),
         ("scapula", "retraction", "primary"), ("spine", "rotation", "secondary")],
    ),
    # a body saw on a roller is loaded anti-extension, not a stretch
    "roller_body_saw": (
        [("anti_extension", "primary")],
        [("spine", "anti_extension", "primary"), ("shoulder", "flexion", "secondary")],
    ),
    "roller_reverse_crunch": (
        [("spinal_flexion", "primary"), ("hip_flexion", "secondary")],
        [("spine", "flexion", "primary"), ("hip", "flexion", "secondary")],
    ),
    # carrying load through a lunge is a squat pattern, not mobility work
    "weighted_stretch_lunge": (
        [("squat", "primary")],
        [("knee", "extension", "primary"), ("hip", "extension", "primary"),
         ("ankle", "dorsiflexion", "secondary")],
    ),
}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dsn", default=os.environ.get("COACHLY_BIOMECH_DSN"))
    ap.add_argument("--apply", action="store_true")
    args = ap.parse_args()
    if not args.dsn:
        sys.exit("no DSN: set COACHLY_BIOMECH_DSN")

    with psycopg.connect(args.dsn, connect_timeout=30) as conn:
        conn.autocommit = False
        cur = conn.cursor()
        patterns = actions = 0

        for code, (pattern_links, action_links) in LINKS.items():
            for pattern_code, role in pattern_links:
                cur.execute("""INSERT INTO exercises.exercise_movement_pattern
                                   (exercise_id, movement_pattern_id, role)
                               SELECT e.id, mp.id, %s
                                 FROM exercises.exercise e, exercises.movement_pattern mp
                                WHERE e.code = %s AND mp.code = %s
                               ON CONFLICT (exercise_id, movement_pattern_id)
                               DO UPDATE SET role = EXCLUDED.role""",
                            (role, code, pattern_code))
                patterns += cur.rowcount
            for joint, action, role in action_links:
                cur.execute("""INSERT INTO exercises.exercise_joint_action
                                   (exercise_id, joint_action_id, role)
                               SELECT e.id, ja.id, %s
                                 FROM exercises.exercise e, exercises.joint_action ja
                                WHERE e.code = %s AND ja.joint_code = %s AND ja.action_code = %s
                               ON CONFLICT (exercise_id, joint_action_id)
                               DO UPDATE SET role = EXCLUDED.role""",
                            (role, code, joint, action))
                actions += cur.rowcount

        print(f"pattern links: {patterns}, joint action links: {actions}")

        for label, query in [
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
        ]:
            cur.execute(query)
            value = cur.fetchone()[0]
            print(f"   [{'OK  ' if value == 0 else 'FAIL'}] {label:38s} {value}")
            if value:
                conn.rollback()
                sys.exit("still incomplete - rolled back")

        if args.apply:
            conn.commit()
            print("COMMITTED")
        else:
            conn.rollback()
            print("DRY RUN - rolled back")


if __name__ == "__main__":
    main()
