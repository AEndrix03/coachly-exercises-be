#!/usr/bin/env python3
"""
Exercise model V2 - PHASE 2, STEP 17
Close the gap between what an exercise DOES and which muscles it lists.

Step 16 fixed one shape of the defect (rectus abdominis as the sole primary).
The general form is bigger: 707 of 2352 exercises perform a primary joint
action that NONE of their listed muscles can produce. An exercise that says it
does shoulder horizontal abduction while listing no posterior deltoid is
internally incoherent no matter which of the two fields is wrong.

Two causes hide behind that number and they need different treatment:

  * the muscle list is incomplete - the action is right, the muscles are
    missing. Adding them is safe.
  * the joint action came from a wrong archetype - a curl filed as a bench
    press inherited "elbow extension". Here adding triceps would make the row
    WORSE, because it would corroborate the wrong action.

This step only performs the safe half. A muscle is added as SECONDARY, never
promoted over a curated primary: the claim being recorded is "this muscle
participates", which the joint action already asserts. Where the exercise's own
primary muscles coherently describe a different movement than its stored
actions, the case is reported for review instead - guessing which field is
wrong would be an assumption dressed up as a repair.

Usage:
    python inj/_tools/v2_step17_action_muscle_closure.py [--apply]
"""
import argparse
import importlib.util
import pathlib
import sys
from collections import Counter

import psycopg

TOOLS = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(TOOLS))
from dsn import get_dsn  # noqa: E402

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

_spec = importlib.util.spec_from_file_location("s16", TOOLS / "v2_step16_prime_movers.py")
_s16 = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_s16)
ACTION_MUSCLES = _s16.ACTION_MUSCLES

# an action is only "suspect" when the exercise's own primary muscles drive the
# OPPOSITE action at the SAME joint. A bench press whose primary is the pec but
# which also lists elbow extension is not suspect - it is simply missing its
# triceps.
ANTAGONISTS = {
    ("elbow", "flexion"): ("elbow", "extension"),
    ("elbow", "extension"): ("elbow", "flexion"),
    ("knee", "flexion"): ("knee", "extension"),
    ("knee", "extension"): ("knee", "flexion"),
    ("hip", "flexion"): ("hip", "extension"),
    ("hip", "extension"): ("hip", "flexion"),
    ("hip", "abduction"): ("hip", "adduction"),
    ("hip", "adduction"): ("hip", "abduction"),
    ("shoulder", "flexion"): ("shoulder", "extension"),
    ("shoulder", "extension"): ("shoulder", "flexion"),
    ("shoulder", "abduction"): ("shoulder", "adduction"),
    ("shoulder", "adduction"): ("shoulder", "abduction"),
    ("shoulder", "horizontal_adduction"): ("shoulder", "horizontal_abduction"),
    ("shoulder", "horizontal_abduction"): ("shoulder", "horizontal_adduction"),
    ("shoulder", "internal_rotation"): ("shoulder", "external_rotation"),
    ("shoulder", "external_rotation"): ("shoulder", "internal_rotation"),
    ("ankle", "plantar_flexion"): ("ankle", "dorsiflexion"),
    ("ankle", "dorsiflexion"): ("ankle", "plantar_flexion"),
    ("scapula", "retraction"): ("scapula", "protraction"),
    ("scapula", "protraction"): ("scapula", "retraction"),
    ("spine", "flexion"): ("spine", "extension"),
    ("spine", "extension"): ("spine", "flexion"),
    ("wrist", "flexion"): ("wrist", "extension"),
    ("wrist", "extension"): ("wrist", "flexion"),
}

# reverse map: which actions a muscle can drive
MUSCLE_ACTIONS = {}
for (joint, action), (primaries, _secondaries) in ACTION_MUSCLES.items():
    for muscle in primaries:
        MUSCLE_ACTIONS.setdefault(muscle, set()).add((joint, action))


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

        cur.execute("SELECT code, id FROM exercises.muscle")
        muscle_ids = dict(cur.fetchall())

        cur.execute("""SELECT j.exercise_id, ja.joint_code, ja.action_code, j.role::text
                         FROM exercises.exercise_joint_action j
                         JOIN exercises.joint_action ja ON ja.id = j.joint_action_id""")
        actions = {}
        for exercise_id, joint, action, role in cur.fetchall():
            actions.setdefault(exercise_id, []).append((joint, action, role))

        cur.execute("""SELECT em.exercise_id, mu.code, em.involvement::text
                         FROM exercises.exercise_muscle em
                         JOIN exercises.muscle mu ON mu.id = em.muscle_id""")
        muscles = {}
        for exercise_id, code, involvement in cur.fetchall():
            muscles.setdefault(exercise_id, {})[code] = involvement

        cur.execute("""SELECT id, code FROM exercises.exercise WHERE deleted_at IS NULL""")
        catalogue = cur.fetchall()

        to_add, ambiguous = [], []
        for exercise_id, code in catalogue:
            stored_actions = actions.get(exercise_id, [])
            present = muscles.get(exercise_id, {})
            if not stored_actions or not present:
                continue

            primary_muscles = [m for m, inv in present.items() if inv == "primary"]
            # what movement do the exercise's own primary muscles describe?
            muscle_driven = set()
            for muscle in primary_muscles:
                muscle_driven |= MUSCLE_ACTIONS.get(muscle, set())

            for joint, action, role in stored_actions:
                if role != "primary":
                    continue
                expected = ACTION_MUSCLES.get((joint, action), ([], []))[0]
                if not expected or any(m in present for m in expected):
                    continue

                # If the primary muscles describe a coherent movement of their
                # own that does not include this action, the ACTION is the
                # suspect, not the muscles. Do not corroborate it.
                antagonist = ANTAGONISTS.get((joint, action))
                if antagonist and antagonist in muscle_driven:
                    ambiguous.append((code, f"{joint}.{action}", sorted(primary_muscles)[:3]))
                    continue

                for muscle in expected:
                    if muscle in present or muscle not in muscle_ids:
                        continue
                    to_add.append((exercise_id, muscle_ids[muscle], code, muscle,
                                   f"{joint}.{action}"))

        print(f"muscles missing for an action the exercise performs : {len(to_add)}")
        print(f"cases where the ACTION is the suspect, left for review: {len(ambiguous)}")
        if ambiguous:
            print("   most common:",
                  Counter(a[1] for a in ambiguous).most_common(6))
            for code, action, prim in ambiguous[:6]:
                print(f"     {code[:36]:38s} {action:26s} primaries={prim}")

        added = 0
        for exercise_id, muscle_id, code, muscle, action in to_add:
            cur.execute("""SELECT tension_lengthened::text, tension_midrange::text,
                                  tension_shortened::text
                             FROM exercises.exercise_muscle
                            WHERE exercise_id = %s AND tension_lengthened IS NOT NULL
                            LIMIT 1""", (exercise_id,))
            profile = cur.fetchone() or ("moderate", "high", "moderate")
            cur.execute("""INSERT INTO exercises.exercise_muscle
                               (exercise_id, muscle_id, involvement, created_at, updated_at,
                                tension_lengthened, tension_midrange, tension_shortened,
                                evidence_basis, confidence)
                           VALUES (%s, %s, 'secondary', NOW(), NOW(), %s, %s, %s,
                                   'biomechanical_model', 'moderate')
                           ON CONFLICT DO NOTHING""",
                        (exercise_id, muscle_id, profile[0], profile[1], profile[2]))
            added += cur.rowcount
        print(f"\nsecondary muscle rows added: {added}")

        # a muscle must still appear once per exercise
        cur.execute("""DELETE FROM exercises.exercise_muscle weak
                        USING exercises.exercise_muscle strong
                        WHERE weak.exercise_id = strong.exercise_id
                          AND weak.muscle_id = strong.muscle_id
                          AND CASE weak.involvement WHEN 'primary' THEN 3
                                                    WHEN 'secondary' THEN 2 ELSE 1 END
                            < CASE strong.involvement WHEN 'primary' THEN 3
                                                      WHEN 'secondary' THEN 2 ELSE 1 END""")
        print(f"duplicate involvement rows collapsed: {cur.rowcount}")

        print("\n--- verification")
        for label, query in [
            ("exercises without a PRIMARY muscle",
             """SELECT count(*) FROM exercises.exercise e WHERE e.deleted_at IS NULL
                  AND NOT EXISTS (SELECT 1 FROM exercises.exercise_muscle m
                                   WHERE m.exercise_id = e.id AND m.involvement = 'primary')"""),
            ("PRIMARY muscles without tension profile",
             """SELECT count(*) FROM exercises.exercise_muscle
                 WHERE involvement = 'primary' AND tension_lengthened IS NULL"""),
            ("a muscle listed twice with different involvement",
             """SELECT count(*) FROM (SELECT exercise_id, muscle_id
                                        FROM exercises.exercise_muscle
                                       GROUP BY 1,2 HAVING count(*) > 1) d"""),
            ("muscle rows without provenance",
             """SELECT count(*) FROM exercises.exercise_muscle
                 WHERE evidence_basis IS NULL OR confidence IS NULL"""),
        ]:
            cur.execute(query)
            value = cur.fetchone()[0]
            print(f"   [{'OK  ' if value == 0 else 'FAIL'}] {label:48s} {value}")
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
