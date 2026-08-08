#!/usr/bin/env python3
"""
Exercise model V2 - PHASE 2, STEP 8
Repair the neck archetype, and the damage it caused.

Root cause: the name regex `neck` matched "Standing Behind Neck Press" and
"Smith Behind Neck Press". Those are overhead presses, not neck work, and the
ohp rule required the literal "behind THE neck", so they fell through to
neck_band.

Because they were the only neck_band members that already had muscles, step 4's
modal vote copied THEIR muscles - anterior deltoid, triceps, lats - onto the 8
genuine neck exercises, which ended up with no cervical muscle at all.

This is the failure mode worth remembering: one misclassified exercise becomes
the donor for its whole archetype, so a single naming quirk propagates.

Fixes:
  1. the two presses are reclassified as seated overhead presses
  2. the 8 neck exercises get the cervical muscle set, replacing the junk
  3. the generator regex is corrected separately so a re-run cannot repeat it

Usage:
    python inj/_tools/v2_step8_neck_repair.py [--apply]     (DSN from $COACHLY_BIOMECH_DSN)
"""
import argparse
import os
import sys

import psycopg

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

# overhead presses wrongly filed under the neck archetype
PRESSES = ["smith_behind_neck_press", "standing_behind_neck_press"]

# genuine neck work whose muscles were poisoned by the modal vote
NECK_EXERCISES = [
    "band_neck_extension", "band_neck_flexion", "band_neck_lateral_flexion",
    "band_neck_resistance", "manual_neck_resistance_extension",
    "manual_neck_resistance_flexion", "manual_neck_resistance_lateral_flexion",
    "neck_rotation_manual_resistance",
]

CERVICAL = [
    ("sternocleidomastoid", "primary"),
    ("splenius_capitis", "primary"),
    ("splenius_cervicis", "primary"),
    ("scalenes", "secondary"),
    ("levator_scapulae", "secondary"),
]
# a neck flexion/extension holds tension across the range without a strong end bias
NECK_TENSION = ("moderate", "high", "moderate")


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

        # ---- 1. the two presses become overhead presses ----
        cur.execute("""UPDATE exercises.exercise
                          SET exercise_kind = 'resistance', joint_class = 'multi_joint',
                              technical_demand = 'high',
                              spotter_policy = 'recommended_high_effort',
                              family_id = (SELECT id FROM exercises.exercise_family
                                            WHERE code = 'overhead_press'),
                              updated_at = NOW()
                        WHERE code = ANY(%s)""", (PRESSES,))
        print(f"presses reclassified: {cur.rowcount}")

        cur.execute("""UPDATE exercises.exercise_biomechanics b
                          SET spinal_loading = 'high', stability_demand = 'high',
                              resistance_source = 'gravity',
                              method_note = 'archetype=ohp_seated; reclassified by v2_step8',
                              evidence_basis = 'expert_curated', confidence = 'moderate',
                              updated_at = NOW()
                         FROM exercises.exercise e
                        WHERE e.id = b.exercise_id AND e.code = ANY(%s)""", (PRESSES,))

        # movement pattern / joint actions must follow the reclassification
        cur.execute("""DELETE FROM exercises.exercise_movement_pattern p
                        USING exercises.exercise e
                        WHERE p.exercise_id = e.id AND e.code = ANY(%s)""", (PRESSES,))
        cur.execute("""INSERT INTO exercises.exercise_movement_pattern
                           (exercise_id, movement_pattern_id, role)
                       SELECT e.id, mp.id, 'primary'
                         FROM exercises.exercise e, exercises.movement_pattern mp
                        WHERE e.code = ANY(%s) AND mp.code = 'vertical_press'
                       ON CONFLICT DO NOTHING""", (PRESSES,))
        cur.execute("""DELETE FROM exercises.exercise_joint_action j
                        USING exercises.exercise e
                        WHERE j.exercise_id = e.id AND e.code = ANY(%s)""", (PRESSES,))
        cur.execute("""INSERT INTO exercises.exercise_joint_action
                           (exercise_id, joint_action_id, role)
                       SELECT e.id, ja.id,
                              CASE WHEN ja.joint_code = 'scapula' THEN 'secondary'::exercises.contribution_role
                                   ELSE 'primary'::exercises.contribution_role END
                         FROM exercises.exercise e, exercises.joint_action ja
                        WHERE e.code = ANY(%s)
                          AND ((ja.joint_code = 'shoulder' AND ja.action_code = 'flexion')
                            OR (ja.joint_code = 'elbow' AND ja.action_code = 'extension')
                            OR (ja.joint_code = 'scapula' AND ja.action_code = 'elevation'))
                       ON CONFLICT DO NOTHING""", (PRESSES,))

        # ---- 2. neck exercises get their real muscles ----
        cur.execute("""DELETE FROM exercises.exercise_muscle em
                        USING exercises.exercise e
                        WHERE em.exercise_id = e.id AND e.code = ANY(%s)""", (NECK_EXERCISES,))
        print(f"junk muscle rows removed: {cur.rowcount}")

        lengthened, midrange, shortened = NECK_TENSION
        inserted = 0
        for muscle_code, involvement in CERVICAL:
            cur.execute("""INSERT INTO exercises.exercise_muscle
                               (exercise_id, muscle_id, involvement, created_at, updated_at,
                                tension_lengthened, tension_midrange, tension_shortened,
                                evidence_basis, confidence)
                           SELECT e.id, m.id, %s, NOW(), NOW(), %s, %s, %s,
                                  'expert_curated', 'moderate'
                             FROM exercises.exercise e, exercises.muscle m
                            WHERE e.code = ANY(%s) AND m.code = %s
                           ON CONFLICT DO NOTHING""",
                        (involvement, lengthened, midrange, shortened,
                         NECK_EXERCISES, muscle_code))
            inserted += cur.rowcount
        print(f"cervical muscle rows inserted: {inserted}")

        # ---- 3. verify ----
        cur.execute("""SELECT e.code, count(*) FILTER (WHERE mg.code = 'neck')
                         FROM exercises.exercise e
                         JOIN exercises.exercise_muscle em ON em.exercise_id = e.id
                         JOIN exercises.muscle m ON m.id = em.muscle_id
                         LEFT JOIN exercises.muscle_group_member gm ON gm.muscle_id = m.id
                         LEFT JOIN exercises.muscle_group mg ON mg.id = gm.group_id
                        WHERE e.code = ANY(%s) GROUP BY e.code ORDER BY e.code""",
                    (NECK_EXERCISES,))
        print("\nneck exercises, cervical muscles now:")
        for code, count in cur.fetchall():
            print(f"   {'OK  ' if count else 'FAIL'} {code:44s} {count}")

        cur.execute("""SELECT count(*) FROM exercises.exercise e
                        WHERE e.deleted_at IS NULL
                          AND NOT EXISTS (SELECT 1 FROM exercises.exercise_muscle m
                                           WHERE m.exercise_id = e.id AND m.involvement = 'primary')""")
        orphans = cur.fetchone()[0]
        print(f"\nexercises without a PRIMARY muscle: {orphans}")
        if orphans:
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
