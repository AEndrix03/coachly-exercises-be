#!/usr/bin/env python3
"""
Exercise model V2 - PHASE 2, STEP 20
Close the three clusters the fourth audit isolated.

After re-deriving the classification from descriptions the rate fell from 53.1%
to 40%, and the auditors localised what is left. One of them put a number on it:
"fixing the equipment mapping and the bodyweight/unilateral flags alone would
drop the rate to roughly 10%". So those are done here, plus an artefact the
reclassification itself introduced.

1. forearm_flexors promoted to PRIMARY on 140 exercises whose primary joint
   action is elbow flexion, elbow extension or horizontal adduction. The
   forearm flexors grip there, they do not drive the movement. My own step 18
   caused this, so it is mine to undo.

2. The bodyweight flag and the load model contradicting each other. A barbell
   pause squat stored as bodyweight_reps can never record the bar; a jump rope
   drill with bodyweight_leverage stored as bodyweight=false is the same
   contradiction the other way round. Both sides are decided by evidence that
   already exists in the row - the resistance source and the linked equipment -
   never by guessing.

3. unilateral and side_mode disagreeing. side_mode=separate is a strong signal:
   nobody logs sides separately for a bilateral lift.

4. Equipment links contradicted by the exercise name: a treadmill on a 400 m
   run, a rope attachment on a jump-rope drill, a foam roller on a wrist roller.

Usage:
    python inj/_tools/v2_step20_flags_and_equipment.py [--apply]
"""
import argparse
import pathlib
import sys

import psycopg

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from dsn import get_dsn  # noqa: E402

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

# equipment code -> name fragments that make that link impossible
IMPOSSIBLE_EQUIPMENT = [
    ("treadmill", ["400m", "800m", "mile", "sprint 100", "shuttle", "hill"]),
    ("cable_attachment_rope", ["jump rope", "skipping", "double under", "single under",
                               "triple under", "rope climb", "battle rope", "stretch"]),
    ("foam_roller", ["wrist roller"]),
    ("back_extension_machine", ["neck"]),
    ("box_plyo", ["running in place", "high knees"]),
    ("rowing_machine", ["ski erg"]),
    ("pull_up_bar", ["wall pike", "compression lift"]),
    ("dip_bars", ["wall pike", "compression lift"]),
]

STATEMENTS = [
    (
        "forearm_flexors demoted where they only grip",
        """UPDATE exercises.exercise_muscle em
              SET involvement = 'secondary', evidence_basis = 'expert_curated',
                  confidence = 'moderate', updated_at = NOW()
             FROM exercises.muscle mu
            WHERE em.muscle_id = mu.id AND mu.code = 'forearm_flexors'
              AND em.involvement = 'primary'
              AND EXISTS (SELECT 1 FROM exercises.exercise_joint_action j
                            JOIN exercises.joint_action ja ON ja.id = j.joint_action_id
                           WHERE j.exercise_id = em.exercise_id AND j.role = 'primary'
                             AND (ja.joint_code, ja.action_code) IN
                                 (('elbow','flexion'),('elbow','extension'),
                                  ('shoulder','horizontal_adduction')))""",
    ),
    (
        "bodyweight=false while the row itself says bodyweight",
        """UPDATE exercises.exercise e SET bodyweight = true, updated_at = NOW()
             FROM exercises.exercise_biomechanics b
            WHERE b.exercise_id = e.id AND e.deleted_at IS NULL AND e.bodyweight = false
              AND b.resistance_source = 'bodyweight_leverage'
              AND NOT EXISTS (SELECT 1 FROM exercises.exercise_equipment q
                                JOIN exercises.equipment eq ON eq.id = q.equipment_id
                               WHERE q.exercise_id = e.id
                                 AND eq.equipment_class IN ('free_weight','selectorized_machine',
                                                            'plate_loaded_machine','cable'))""",
    ),
    (
        "bodyweight=true although a loaded implement is linked",
        """UPDATE exercises.exercise e SET bodyweight = false, updated_at = NOW()
            WHERE e.deleted_at IS NULL AND e.bodyweight = true
              AND EXISTS (SELECT 1 FROM exercises.exercise_equipment q
                            JOIN exercises.equipment eq ON eq.id = q.equipment_id
                           WHERE q.exercise_id = e.id
                             AND eq.equipment_class IN ('free_weight','selectorized_machine',
                                                        'plate_loaded_machine','cable'))
              AND EXISTS (SELECT 1 FROM exercises.exercise_tracking_profile t
                           WHERE t.exercise_id = e.id
                             AND t.tracking_type IN ('bodyweight_reps'))""",
    ),
    (
        "a loaded lift whose tracking cannot record its load",
        """UPDATE exercises.exercise_tracking_profile t
              SET tracking_type = 'weight_reps', load_input_mode = 'total_load',
                  updated_at = NOW()
             FROM exercises.exercise e
            WHERE t.exercise_id = e.id AND e.deleted_at IS NULL AND e.bodyweight = false
              AND t.tracking_type = 'bodyweight_reps'
              AND EXISTS (SELECT 1 FROM exercises.exercise_equipment q
                            JOIN exercises.equipment eq ON eq.id = q.equipment_id
                           WHERE q.exercise_id = e.id
                             AND eq.equipment_class IN ('free_weight','plate_loaded_machine'))""",
    ),
    (
        "unilateral=false although sides are tracked separately",
        """UPDATE exercises.exercise e SET unilateral = true, updated_at = NOW()
             FROM exercises.exercise_tracking_profile t
            WHERE t.exercise_id = e.id AND e.deleted_at IS NULL
              AND e.unilateral = false AND t.side_mode = 'separate'""",
    ),
    (
        "band resistance recorded as a loggable weight",
        """UPDATE exercises.exercise_tracking_profile t
              SET tracking_type = 'reps', load_input_mode = 'none',
                  comparison_scope = 'non_comparable', updated_at = NOW()
             FROM exercises.exercise_biomechanics b
            WHERE t.exercise_id = b.exercise_id AND b.resistance_source = 'band'
              AND t.load_input_mode <> 'none'""",
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

        print("--- internal contradictions repaired")
        for label, statement in STATEMENTS:
            cur.execute(statement)
            print(f"   {label:56s} {cur.rowcount}")

        print("\n--- equipment links contradicted by the name")
        removed = 0
        for equipment_code, fragments in IMPOSSIBLE_EQUIPMENT:
            for fragment in fragments:
                cur.execute("""DELETE FROM exercises.exercise_equipment q
                                USING exercises.exercise e, exercises.equipment eq
                                WHERE q.exercise_id = e.id AND q.equipment_id = eq.id
                                  AND eq.code = %s AND lower(e.name) LIKE %s
                                  AND e.deleted_at IS NULL""",
                            (equipment_code, f"%{fragment}%"))
                if cur.rowcount:
                    print(f"   {equipment_code:26s} x '{fragment}' -> {cur.rowcount}")
                    removed += cur.rowcount
        print(f"   total removed: {removed}")

        # removing equipment must not leave a loaded lift with nothing
        cur.execute("""SELECT count(*) FROM exercises.exercise e
                        WHERE e.deleted_at IS NULL AND e.exercise_kind = 'resistance'
                          AND e.bodyweight = false
                          AND NOT EXISTS (SELECT 1 FROM exercises.exercise_equipment q
                                           WHERE q.exercise_id = e.id)""")
        orphans = cur.fetchone()[0]
        print(f"\nloaded resistance exercises left with no equipment: {orphans}")
        if orphans:
            cur.execute("""UPDATE exercises.exercise e SET bodyweight = true, updated_at = NOW()
                            WHERE e.deleted_at IS NULL AND e.exercise_kind = 'resistance'
                              AND e.bodyweight = false
                              AND NOT EXISTS (SELECT 1 FROM exercises.exercise_equipment q
                                               WHERE q.exercise_id = e.id)""")
            print(f"   reclassified as bodyweight instead: {cur.rowcount}")

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
            ("RESISTANCE, not bodyweight, without equipment",
             """SELECT count(*) FROM exercises.exercise e
                 WHERE e.deleted_at IS NULL AND e.exercise_kind = 'resistance'
                   AND e.bodyweight = false
                   AND NOT EXISTS (SELECT 1 FROM exercises.exercise_equipment q
                                    WHERE q.exercise_id = e.id)"""),
            ("unilateral disagreeing with side_mode",
             """SELECT count(*) FROM exercises.exercise e
                  JOIN exercises.exercise_tracking_profile t ON t.exercise_id = e.id
                 WHERE e.deleted_at IS NULL AND e.unilateral = true AND t.side_mode = 'none'"""),
            ("bodyweight lift whose tracking cannot record its load",
             """SELECT count(*) FROM exercises.exercise e
                  JOIN exercises.exercise_tracking_profile t ON t.exercise_id = e.id
                 WHERE e.deleted_at IS NULL AND e.bodyweight = false
                   AND t.tracking_type = 'bodyweight_reps'
                   AND EXISTS (SELECT 1 FROM exercises.exercise_equipment q
                                 JOIN exercises.equipment eq ON eq.id = q.equipment_id
                                WHERE q.exercise_id = e.id
                                  AND eq.equipment_class IN ('free_weight','plate_loaded_machine'))"""),
        ]:
            cur.execute(query)
            value = cur.fetchone()[0]
            print(f"   [{'OK  ' if value == 0 else 'FAIL'}] {label:52s} {value}")
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
