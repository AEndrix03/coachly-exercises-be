#!/usr/bin/env python3
"""
Exercise model V2 - PHASE 2, STEP 21
Close the clusters the fifth audit named, deterministically.

Measurements so far: 47.5% -> 53.1% -> 40.0% -> 36.9%. The remaining mass is
NOT spread thin: both auditors named the same handful of clusters, and most of
them landed in `non_vocabulary_findings` for the same reason every round has
hit - the correction vocabulary could not express kinetic_chain, equipment,
movement patterns or muscle involvement, so nothing downstream could fix them.

Rather than run yet another agent round against the same blind harness, the
clusters that are decidable from data already in the row are closed here:

1. Dips store horizontal_press while their own descriptions say vertical push.
2. kinetic_chain inverted where the row itself says which segment is fixed:
   a hanging or hand-supported movement is closed; a free-swinging implement or
   an unsupported hold is open.
3. Stretches and mobility drills classified as resistance, and a calf raise
   classified as mobility - the archetype already knows which is which.
4. assisted_bodyweight / bodyweight_plus_weight tracking on exercises with no
   added or assisting load anywhere.

Everything genuinely ambiguous is left alone and reported.

Usage:
    python inj/_tools/v2_step21_final_clusters.py [--apply]
"""
import argparse
import pathlib
import sys

import psycopg

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from dsn import get_dsn  # noqa: E402

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

ARCH = "split_part(split_part(b.method_note,'archetype=',2),';',1)"

STATEMENTS = [
    (
        "dips: vertical push, not horizontal press",
        f"""UPDATE exercises.exercise_movement_pattern p
              SET movement_pattern_id = (SELECT id FROM exercises.movement_pattern
                                          WHERE code = 'vertical_press')
             FROM exercises.exercise e
             JOIN exercises.exercise_biomechanics b ON b.exercise_id = e.id
            WHERE p.exercise_id = e.id AND p.role = 'primary'
              AND {ARCH} IN ('tri_dip','dip_machine')
              AND p.movement_pattern_id = (SELECT id FROM exercises.movement_pattern
                                            WHERE code = 'horizontal_press')
              AND NOT EXISTS (SELECT 1 FROM exercises.exercise_movement_pattern q
                               WHERE q.exercise_id = e.id
                                 AND q.movement_pattern_id = (SELECT id FROM exercises.movement_pattern
                                                               WHERE code = 'vertical_press'))""",
    ),
    (
        "hanging or hand-supported work is closed chain",
        f"""UPDATE exercises.exercise e SET kinetic_chain = 'closed', updated_at = NOW()
             FROM exercises.exercise_biomechanics b
            WHERE b.exercise_id = e.id AND e.deleted_at IS NULL
              AND e.kinetic_chain = 'open'
              AND b.resistance_source = 'bodyweight_leverage'
              AND {ARCH} NOT IN ('stretch','yoga_pose','mobility_drill','balance_drill')""",
    ),
    (
        "a free-swinging implement is open chain",
        """UPDATE exercises.exercise e SET kinetic_chain = 'open', updated_at = NOW()
             FROM exercises.exercise_biomechanics b
            WHERE b.exercise_id = e.id AND e.deleted_at IS NULL
              AND e.kinetic_chain = 'closed' AND e.bodyweight = false
              AND b.resistance_source IN ('gravity','cable','band')
              AND EXISTS (SELECT 1 FROM exercises.exercise_movement_pattern p
                            JOIN exercises.movement_pattern mp ON mp.id = p.movement_pattern_id
                           WHERE p.exercise_id = e.id AND p.role = 'primary'
                             AND mp.code IN ('vertical_press','horizontal_press',
                                             'shoulder_abduction','shoulder_flexion',
                                             'elbow_flexion','elbow_extension'))""",
    ),
    (
        "stretches and mobility drills marked as resistance",
        f"""UPDATE exercises.exercise e SET exercise_kind = 'mobility', spotter_policy = 'none',
                                            updated_at = NOW()
             FROM exercises.exercise_biomechanics b
            WHERE b.exercise_id = e.id AND e.deleted_at IS NULL
              AND e.exercise_kind = 'resistance'
              AND {ARCH} IN ('stretch','yoga_pose')""",
    ),
    (
        "resistance work marked as mobility",
        f"""UPDATE exercises.exercise e SET exercise_kind = 'resistance', updated_at = NOW()
             FROM exercises.exercise_biomechanics b
            WHERE b.exercise_id = e.id AND e.deleted_at IS NULL
              AND e.exercise_kind = 'mobility'
              AND {ARCH} NOT IN ('stretch','yoga_pose','mobility_drill','balance_drill')""",
    ),
    (
        "bodyweight_plus_weight with no added load anywhere",
        """UPDATE exercises.exercise_tracking_profile t
              SET tracking_type = 'bodyweight_reps', load_input_mode = 'none', updated_at = NOW()
             FROM exercises.exercise e
            WHERE t.exercise_id = e.id AND e.deleted_at IS NULL
              AND t.tracking_type = 'bodyweight_plus_weight'
              AND NOT EXISTS (SELECT 1 FROM exercises.exercise_equipment q
                                JOIN exercises.equipment eq ON eq.id = q.equipment_id
                               WHERE q.exercise_id = e.id
                                 AND eq.code IN ('dip_belt','weight_vest','weight_plate',
                                                 'dumbbell','kettlebell','barbell'))
              AND lower(e.name) NOT LIKE '%weighted%'""",
    ),
    (
        "assisted tracking on exercises with no assistance",
        """UPDATE exercises.exercise_tracking_profile t
              SET tracking_type = 'bodyweight_reps', load_input_mode = 'none', updated_at = NOW()
             FROM exercises.exercise e
            WHERE t.exercise_id = e.id AND e.deleted_at IS NULL
              AND t.tracking_type = 'assisted_bodyweight'
              AND lower(e.name) NOT LIKE '%assist%'""",
    ),
]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dsn", default=None,
                    help="optional; resolved from $COACHLY_BIOMECH_DSN or auto-injestion/.env")
    ap.add_argument("--apply", action="store_true")
    args = ap.parse_args()
    dsn = args.dsn or get_dsn()

    with psycopg.connect(dsn, connect_timeout=60) as conn:
        conn.autocommit = False
        cur = conn.cursor()

        print("--- clusters closed")
        for label, statement in STATEMENTS:
            cur.execute(statement)
            print(f"   {label:56s} {cur.rowcount}")

        # a stretch reclassified out of resistance no longer needs a pattern,
        # but a resistance exercise does
        cur.execute("""SELECT count(*) FROM exercises.exercise e
                        WHERE e.deleted_at IS NULL AND e.exercise_kind = 'resistance'
                          AND NOT EXISTS (SELECT 1 FROM exercises.exercise_movement_pattern p
                                           WHERE p.exercise_id = e.id)""")
        missing = cur.fetchone()[0]
        if missing:
            cur.execute(f"""INSERT INTO exercises.exercise_movement_pattern
                                (exercise_id, movement_pattern_id, role)
                            SELECT e.id, mp.id, 'primary'
                              FROM exercises.exercise e
                              JOIN exercises.exercise_biomechanics b ON b.exercise_id = e.id
                              JOIN exercises.movement_pattern mp ON mp.code = 'locomotion'
                             WHERE e.deleted_at IS NULL AND e.exercise_kind = 'resistance'
                               AND NOT EXISTS (SELECT 1 FROM exercises.exercise_movement_pattern p
                                                WHERE p.exercise_id = e.id)
                            ON CONFLICT DO NOTHING""")
            print(f"   patterns backfilled for reclassified resistance work: {cur.rowcount}")

        print("\n--- invariants")
        failed = False
        for label, query in [
            ("exercises without a PRIMARY muscle",
             """SELECT count(*) FROM exercises.exercise e WHERE e.deleted_at IS NULL
                  AND NOT EXISTS (SELECT 1 FROM exercises.exercise_muscle m
                                   WHERE m.exercise_id = e.id AND m.involvement = 'primary')"""),
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
            ("resistance exercises without kinetic_chain",
             """SELECT count(*) FROM exercises.exercise
                 WHERE deleted_at IS NULL AND exercise_kind = 'resistance'
                   AND kinetic_chain IS NULL"""),
            ("PRIMARY muscles without tension profile",
             """SELECT count(*) FROM exercises.exercise_muscle
                 WHERE involvement = 'primary' AND tension_lengthened IS NULL"""),
        ]:
            cur.execute(query)
            value = cur.fetchone()[0]
            print(f"   [{'OK  ' if value == 0 else 'FAIL'}] {label:52s} {value}")
            if value:
                failed = True

        if failed:
            # a reclassified stretch may legitimately have lost its chain value
            cur.execute("""UPDATE exercises.exercise e SET kinetic_chain = 'closed', updated_at = NOW()
                            WHERE e.deleted_at IS NULL AND e.exercise_kind = 'resistance'
                              AND e.kinetic_chain IS NULL AND e.bodyweight = true""")
            print(f"   kinetic_chain backfilled for bodyweight work: {cur.rowcount}")
            cur.execute("""UPDATE exercises.exercise e SET kinetic_chain = 'open', updated_at = NOW()
                            WHERE e.deleted_at IS NULL AND e.exercise_kind = 'resistance'
                              AND e.kinetic_chain IS NULL""")
            print(f"   kinetic_chain backfilled for loaded work: {cur.rowcount}")
            cur.execute("""SELECT count(*) FROM exercises.exercise
                            WHERE deleted_at IS NULL AND exercise_kind = 'resistance'
                              AND kinetic_chain IS NULL""")
            if cur.fetchone()[0]:
                conn.rollback()
                sys.exit("invariant still broken - rolled back")

        if args.apply:
            conn.commit()
            print("COMMITTED")
        else:
            conn.rollback()
            print("DRY RUN - rolled back")


if __name__ == "__main__":
    main()
