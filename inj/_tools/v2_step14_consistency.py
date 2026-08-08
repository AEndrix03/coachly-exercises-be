#!/usr/bin/env python3
"""
Exercise model V2 - PHASE 2, STEP 14
Cross-field consistency audit over the WHOLE catalogue.

Sampling can only estimate; this finds the contradictions exactly. Every check
below is a pair of stored facts that cannot both be true. That is the point:
a contradiction needs no judgement call and no source, so it can be enforced
mechanically and forever.

Where the fix is unambiguous the row is repaired. Where two fields disagree and
there is no way to tell which one is wrong, the case is REPORTED, not guessed -
picking a side would be an assumption dressed up as data.

Usage:
    python inj/_tools/v2_step14_consistency.py [--apply]
"""
import argparse
import pathlib
import sys

import psycopg

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from dsn import get_dsn  # noqa: E402

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

# (label, detect SQL, repair SQL or None when the fix is not deducible)
CHECKS = [
    (
        "bodyweight=true but the load is tracked as an external weight",
        """SELECT e.code FROM exercises.exercise e
             JOIN exercises.exercise_tracking_profile t ON t.exercise_id = e.id
            WHERE e.deleted_at IS NULL AND e.bodyweight = true
              AND t.tracking_type = 'weight_reps'""",
        # bodyweight work that also carries load is bodyweight_plus_weight
        """UPDATE exercises.exercise_tracking_profile t
              SET tracking_type = 'bodyweight_plus_weight', load_input_mode = 'added_weight',
                  comparison_scope = 'bodyweight_aware', updated_at = NOW()
             FROM exercises.exercise e
            WHERE t.exercise_id = e.id AND e.deleted_at IS NULL AND e.bodyweight = true
              AND t.tracking_type = 'weight_reps'""",
    ),
    (
        "unilateral=true but sides are not tracked separately",
        """SELECT e.code FROM exercises.exercise e
             JOIN exercises.exercise_tracking_profile t ON t.exercise_id = e.id
            WHERE e.deleted_at IS NULL AND e.unilateral = true AND t.side_mode = 'none'""",
        """UPDATE exercises.exercise_tracking_profile t
              SET side_mode = 'separate', updated_at = NOW()
             FROM exercises.exercise e
            WHERE t.exercise_id = e.id AND e.deleted_at IS NULL
              AND e.unilateral = true AND t.side_mode = 'none'""",
    ),
    (
        "elastic resistance recorded as a comparable numeric load",
        """SELECT DISTINCT e.code FROM exercises.exercise e
             JOIN exercises.exercise_biomechanics b ON b.exercise_id = e.id
             JOIN exercises.exercise_tracking_profile t ON t.exercise_id = e.id
            WHERE e.deleted_at IS NULL AND b.resistance_source = 'band'
              AND t.comparison_scope <> 'non_comparable'""",
        # a band's "load" is not a number anyone can compare between gyms
        """UPDATE exercises.exercise_tracking_profile t
              SET comparison_scope = 'non_comparable', tracking_type = 'reps',
                  load_input_mode = 'none', updated_at = NOW()
             FROM exercises.exercise e
             JOIN exercises.exercise_biomechanics b ON b.exercise_id = e.id
            WHERE t.exercise_id = e.id AND e.deleted_at IS NULL
              AND b.resistance_source = 'band' AND t.comparison_scope <> 'non_comparable'""",
    ),
    (
        "machine or cable load treated as comparable across gyms",
        """SELECT DISTINCT e.code FROM exercises.exercise e
             JOIN exercises.exercise_biomechanics b ON b.exercise_id = e.id
             JOIN exercises.exercise_tracking_profile t ON t.exercise_id = e.id
            WHERE e.deleted_at IS NULL AND b.resistance_source IN ('cable','cam_machine')
              AND t.comparison_scope = 'exercise'""",
        """UPDATE exercises.exercise_tracking_profile t
              SET comparison_scope = 'equipment_instance', updated_at = NOW()
             FROM exercises.exercise e
             JOIN exercises.exercise_biomechanics b ON b.exercise_id = e.id
            WHERE t.exercise_id = e.id AND e.deleted_at IS NULL
              AND b.resistance_source IN ('cable','cam_machine')
              AND t.comparison_scope = 'exercise'""",
    ),
    (
        "a spotter is suggested for something that is not resistance training",
        """SELECT e.code FROM exercises.exercise e
            WHERE e.deleted_at IS NULL AND e.exercise_kind <> 'resistance'
              AND e.spotter_policy <> 'none'""",
        """UPDATE exercises.exercise SET spotter_policy = 'none', updated_at = NOW()
            WHERE deleted_at IS NULL AND exercise_kind <> 'resistance'
              AND spotter_policy <> 'none'""",
    ),
    (
        "a primary muscle receives no tension anywhere in the range",
        """SELECT DISTINCT e.code FROM exercises.exercise e
             JOIN exercises.exercise_muscle em ON em.exercise_id = e.id
            WHERE e.deleted_at IS NULL AND em.involvement = 'primary'
              AND em.tension_lengthened = 'none' AND em.tension_midrange = 'none'
              AND em.tension_shortened = 'none'""",
        # if it is the prime mover it is loaded somewhere; mid-range is the
        # least presumptuous place to put it
        """UPDATE exercises.exercise_muscle em
              SET tension_midrange = 'moderate', updated_at = NOW()
             FROM exercises.exercise e
            WHERE em.exercise_id = e.id AND e.deleted_at IS NULL
              AND em.involvement = 'primary' AND em.tension_lengthened = 'none'
              AND em.tension_midrange = 'none' AND em.tension_shortened = 'none'""",
    ),
    (
        "single_joint but more than one PRIMARY joint action",
        """SELECT e.code FROM exercises.exercise e
             JOIN exercises.exercise_joint_action j ON j.exercise_id = e.id
            WHERE e.deleted_at IS NULL AND e.joint_class = 'single_joint'
              AND j.role = 'primary'
            GROUP BY e.code HAVING count(*) > 1""",
        # two joints driving the movement IS multi-joint, by definition
        """UPDATE exercises.exercise e SET joint_class = 'multi_joint', updated_at = NOW()
            WHERE e.deleted_at IS NULL AND e.joint_class = 'single_joint'
              AND (SELECT count(*) FROM exercises.exercise_joint_action j
                    WHERE j.exercise_id = e.id AND j.role = 'primary') > 1""",
    ),
    (
        "closed chain but the resistance is a free-moving implement",
        """SELECT DISTINCT e.code FROM exercises.exercise e
             JOIN exercises.exercise_biomechanics b ON b.exercise_id = e.id
            WHERE e.deleted_at IS NULL AND e.kinetic_chain = 'closed'
              AND b.resistance_source = 'gravity' AND e.bodyweight = false
              AND NOT EXISTS (SELECT 1 FROM exercises.exercise_movement_pattern p
                               JOIN exercises.movement_pattern mp ON mp.id = p.movement_pattern_id
                              WHERE p.exercise_id = e.id
                                AND mp.code IN ('squat','hip_hinge','lunge','carry','jump',
                                                'locomotion','hip_extension','plantar_flexion',
                                                'knee_extension','knee_flexion','spinal_extension',
                                                'spinal_flexion','anti_extension','rotation',
                                                'grip','scapular','vertical_pull','horizontal_pull'))""",
        None,  # a loaded squat or barbell calf raise is legitimately closed + gravity
    ),
    (
        "bodyweight=false but no equipment and a bodyweight tracking type",
        """SELECT e.code FROM exercises.exercise e
             JOIN exercises.exercise_tracking_profile t ON t.exercise_id = e.id
            WHERE e.deleted_at IS NULL AND e.bodyweight = false
              AND t.tracking_type IN ('bodyweight_reps','bodyweight_plus_weight')
              AND NOT EXISTS (SELECT 1 FROM exercises.exercise_equipment q
                               WHERE q.exercise_id = e.id)""",
        """UPDATE exercises.exercise e SET bodyweight = true, updated_at = NOW()
             FROM exercises.exercise_tracking_profile t
            WHERE t.exercise_id = e.id AND e.deleted_at IS NULL AND e.bodyweight = false
              AND t.tracking_type IN ('bodyweight_reps','bodyweight_plus_weight')
              AND NOT EXISTS (SELECT 1 FROM exercises.exercise_equipment q
                               WHERE q.exercise_id = e.id)""",
    ),
    (
        "mobility or conditioning work carrying a spinal_loading of high",
        """SELECT e.code FROM exercises.exercise e
             JOIN exercises.exercise_biomechanics b ON b.exercise_id = e.id
            WHERE e.deleted_at IS NULL AND e.exercise_kind = 'mobility'
              AND b.spinal_loading = 'high'""",
        """UPDATE exercises.exercise_biomechanics b
              SET spinal_loading = 'low', updated_at = NOW()
             FROM exercises.exercise e
            WHERE b.exercise_id = e.id AND e.deleted_at IS NULL
              AND e.exercise_kind = 'mobility' AND b.spinal_loading = 'high'""",
    ),
    (
        "a muscle listed twice for the same exercise with different involvement",
        """SELECT e.code FROM exercises.exercise e
             JOIN exercises.exercise_muscle em ON em.exercise_id = e.id
            WHERE e.deleted_at IS NULL
            GROUP BY e.code, em.muscle_id HAVING count(*) > 1""",
        """DELETE FROM exercises.exercise_muscle weak
             USING exercises.exercise_muscle strong
            WHERE weak.exercise_id = strong.exercise_id
              AND weak.muscle_id = strong.muscle_id
              AND CASE weak.involvement WHEN 'primary' THEN 3 WHEN 'secondary' THEN 2 ELSE 1 END
                < CASE strong.involvement WHEN 'primary' THEN 3 WHEN 'secondary' THEN 2 ELSE 1 END""",
    ),
]


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

        print("--- contradictions found")
        pending = []
        for label, detect, repair in CHECKS:
            cur.execute(detect)
            rows = [r[0] for r in cur.fetchall()]
            marker = "auto" if repair else "REPORT"
            print(f"   [{marker:6s}] {label:62s} {len(rows)}")
            if rows and not repair:
                print("             " + ", ".join(rows[:6]) + ("..." if len(rows) > 6 else ""))
            pending.append((label, detect, repair, len(rows)))

        print("\n--- repairs")
        repaired_total = 0
        for label, detect, repair, found in pending:
            if not repair or not found:
                continue
            cur.execute(repair)
            print(f"   {label:62s} {cur.rowcount} rows")
            repaired_total += cur.rowcount
        print(f"total rows repaired: {repaired_total}")

        print("\n--- re-check")
        remaining = 0
        for label, detect, repair, _found in pending:
            cur.execute(detect)
            left = len(cur.fetchall())
            if repair:
                status = "OK  " if left == 0 else "FAIL"
                if left:
                    remaining += 1
                print(f"   [{status}] {label:62s} {left}")
        if remaining:
            conn.rollback()
            sys.exit("a repair did not resolve its own check - rolled back")

        # the standing invariants must still hold
        for label, query in [
            ("primary muscles without tension profile",
             """SELECT count(*) FROM exercises.exercise_muscle
                 WHERE involvement = 'primary' AND tension_lengthened IS NULL"""),
            ("exercises without tracking profile",
             """SELECT count(*) FROM exercises.exercise e
                 LEFT JOIN exercises.exercise_tracking_profile t ON t.exercise_id = e.id
                WHERE e.deleted_at IS NULL AND t.exercise_id IS NULL"""),
            ("RESISTANCE without movement pattern",
             """SELECT count(*) FROM exercises.exercise e
                 WHERE e.deleted_at IS NULL AND e.exercise_kind = 'resistance'
                   AND NOT EXISTS (SELECT 1 FROM exercises.exercise_movement_pattern p
                                    WHERE p.exercise_id = e.id)"""),
        ]:
            cur.execute(query)
            value = cur.fetchone()[0]
            print(f"   [{'OK  ' if value == 0 else 'FAIL'}] {label:62s} {value}")
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
