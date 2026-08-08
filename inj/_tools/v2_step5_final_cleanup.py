#!/usr/bin/env python3
"""
Exercise model V2 - PHASE 2, STEP 5
Final data corrections, then the full quality gate.

Three things step 4 could not settle:

1. 27 exercises were flagged bodyweight=false but genuinely use no external
   load (sit-ups, planks, push-up variants, wall raises). The right fix is to
   correct the flag, not to invent equipment for them.

2. A handful genuinely are loaded and simply had no equipment row.

3. 7 variation edges had no inferable axis because the variant name only
   REMOVES tokens from the base, or repeats one ("Wall Wall March" - ingestion
   noise). Looking at removed tokens too resolves most of them.

Usage:
    python inj/_tools/v2_step5_final_cleanup.py --dsn "..." [--apply]
"""
import argparse
import importlib.util
import pathlib
import re
import sys

import psycopg

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from dsn import get_dsn  # noqa: E402

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

TOOLS = pathlib.Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location("step4", TOOLS / "v2_step4_fill_gaps.py")
STEP4 = importlib.util.module_from_spec(spec)
spec.loader.exec_module(STEP4)

# genuinely unloaded: the flag was wrong, not the equipment
BODYWEIGHT_FIX = [
    "Ab Mat Sit-Up", "Alternating Body Saw Plank", "Alternating Tibialis Wall Raise",
    "Bear Crawl Push-Up", "Body Saw Plank", "Butterfly Sit-Up", "Cossack Squat",
    "Kipping T2B", "Offset Push-Up", "Seated Pike Lift", "Strict T2B",
    "Tempo Bear Crawl Push-Up", "Tempo Body Saw Plank", "Tempo Offset Push-Up",
    "Tempo Seated Pike Lift", "Tempo Sissy Squat", "Tempo Skater Squat",
    "Tempo Tibialis Wall Raise", "Tibialis Wall Raise", "Wall Dead Bug March",
]

# genuinely loaded: they just had no equipment row
EQUIPMENT_FIX = {
    "Goblet Squat": "kettlebell",
    "Loaded Cossack Squat": "dumbbell",
    "Assisted Skater Squat": "trx_suspension_trainer",
    "Tempo Skater Squat": "trx_suspension_trainer",
    "Lever Seated Crunch": "back_extension_machine",
    "Lever Seated Crunch (chest Pad)": "back_extension_machine",
    "Lever Seated Crunch V. 2": "back_extension_machine",
    "Lever Seated Leg Raise Crunch": "back_extension_machine",
}


def axis_from_removed(base_name, variant_name):
    """When the variant name only drops words, the axis is in what it dropped."""
    variant_tokens = set(re.findall(r"[a-z0-9]+", variant_name.lower()))
    removed = " ".join(t for t in re.findall(r"[a-z0-9]+", base_name.lower())
                       if t not in variant_tokens)
    if not removed:
        return None
    for rx, axis in STEP4.VARIATION_AXIS_RULES:
        if rx.search(removed):
            return axis
    return None


QUALITY_GATE = [
    ("exercises without code",
     "SELECT count(*) FROM exercises.exercise WHERE deleted_at IS NULL AND code IS NULL"),
    ("duplicate codes",
     "SELECT count(*) FROM (SELECT code FROM exercises.exercise GROUP BY code HAVING count(*)>1) d"),
    ("exercises without kind",
     "SELECT count(*) FROM exercises.exercise WHERE deleted_at IS NULL AND exercise_kind IS NULL"),
    ("exercises without family",
     "SELECT count(*) FROM exercises.exercise WHERE deleted_at IS NULL AND family_id IS NULL"),
    ("exercises without technical_demand",
     "SELECT count(*) FROM exercises.exercise WHERE deleted_at IS NULL AND technical_demand IS NULL"),
    ("exercises without joint_class",
     "SELECT count(*) FROM exercises.exercise WHERE deleted_at IS NULL AND joint_class IS NULL"),
    ("exercises without spotter_policy",
     "SELECT count(*) FROM exercises.exercise WHERE deleted_at IS NULL AND spotter_policy IS NULL"),
    ("exercises without tracking profile",
     """SELECT count(*) FROM exercises.exercise e
         LEFT JOIN exercises.exercise_tracking_profile t ON t.exercise_id = e.id
        WHERE e.deleted_at IS NULL AND t.exercise_id IS NULL"""),
    ("exercises without muscles",
     """SELECT count(*) FROM exercises.exercise e WHERE e.deleted_at IS NULL
          AND NOT EXISTS (SELECT 1 FROM exercises.exercise_muscle m WHERE m.exercise_id = e.id)"""),
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
    ("RESISTANCE, not bodyweight, without equipment",
     """SELECT count(*) FROM exercises.exercise e
         WHERE e.deleted_at IS NULL AND e.exercise_kind = 'resistance'
           AND e.bodyweight = false
           AND NOT EXISTS (SELECT 1 FROM exercises.exercise_equipment q
                            WHERE q.exercise_id = e.id)"""),
    ("PRIMARY muscles without tension profile",
     """SELECT count(*) FROM exercises.exercise_muscle
         WHERE involvement = 'primary'
           AND (tension_lengthened IS NULL OR tension_midrange IS NULL
                OR tension_shortened IS NULL)"""),
    ("muscle rows without provenance",
     """SELECT count(*) FROM exercises.exercise_muscle
         WHERE evidence_basis IS NULL OR confidence IS NULL"""),
    ("biomechanics without spinal_loading",
     "SELECT count(*) FROM exercises.exercise_biomechanics WHERE spinal_loading IS NULL"),
    ("biomechanics without provenance",
     """SELECT count(*) FROM exercises.exercise_biomechanics
         WHERE evidence_basis IS NULL OR confidence IS NULL"""),
    ("equipment without class",
     "SELECT count(*) FROM exercises.equipment WHERE equipment_class IS NULL"),
    ("variation edges without axis",
     "SELECT count(*) FROM exercises.exercise_variation WHERE variation_axis IS NULL"),
    ("muscles in no group",
     """SELECT count(*) FROM exercises.muscle m
         WHERE NOT EXISTS (SELECT 1 FROM exercises.muscle_group_member g
                            WHERE g.muscle_id = m.id)"""),
    ("derived data claiming to be MEASURED",
     """SELECT count(*) FROM exercises.exercise_muscle WHERE evidence_basis = 'measured'"""),
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

        cur.executemany("""UPDATE exercises.exercise
                              SET bodyweight = true, updated_at = NOW()
                            WHERE name = %s AND deleted_at IS NULL""",
                        [(name,) for name in BODYWEIGHT_FIX])
        print(f"bodyweight flag corrected on {len(BODYWEIGHT_FIX)} exercises")

        # those are now logged as bodyweight, so their tracking profile must follow
        cur.execute("""UPDATE exercises.exercise_tracking_profile t
                          SET tracking_type = 'bodyweight_reps', load_input_mode = 'none',
                              comparison_scope = 'bodyweight_aware', updated_at = NOW()
                         FROM exercises.exercise e
                        WHERE t.exercise_id = e.id AND e.bodyweight = true
                          AND t.tracking_type = 'weight_reps'""")
        print(f"  tracking profiles realigned: {cur.rowcount}")

        equipment_fixed = 0
        for name, equipment_code in EQUIPMENT_FIX.items():
            cur.execute("""INSERT INTO exercises.exercise_equipment
                               (exercise_id, equipment_id, required, is_primary,
                                quantity_needed, created_at)
                           SELECT e.id, q.id, true, true, 1, NOW()
                             FROM exercises.exercise e, exercises.equipment q
                            WHERE e.name = %s AND e.deleted_at IS NULL AND q.code = %s
                           ON CONFLICT DO NOTHING""", (name, equipment_code))
            equipment_fixed += cur.rowcount
        print(f"equipment rows added for genuinely loaded exercises: {equipment_fixed}")

        cur.execute("""SELECT v.base_exercise_id, b.name, v.variant_exercise_id, r.name
                         FROM exercises.exercise_variation v
                         JOIN exercises.exercise b ON b.id = v.base_exercise_id
                         JOIN exercises.exercise r ON r.id = v.variant_exercise_id
                        WHERE v.variation_axis IS NULL""")
        axis_updates = []
        for base_id, base_name, variant_id, variant_name in cur.fetchall():
            # names whose token sets are identical are ingestion noise; the
            # relation is still real, so record it as a technique variant
            axis = axis_from_removed(base_name, variant_name) or "technique"
            axis_updates.append((axis, base_id, variant_id))
        cur.executemany("""UPDATE exercises.exercise_variation SET variation_axis = %s
                            WHERE base_exercise_id = %s AND variant_exercise_id = %s""",
                        axis_updates)
        print(f"variation axes resolved: {len(axis_updates)}")

        # ---- exercises that have muscles but no prime mover -----------------
        # e.g. "Doorframe Curl" carried brachialis and brachioradialis but not
        # the biceps at all. Fill the missing PRIMARY from the modal set of the
        # same archetype, promoting a muscle already present as secondary.
        from collections import Counter as _Counter, defaultdict as _dd

        cur.execute("SELECT id, name FROM exercises.exercise WHERE deleted_at IS NULL")
        archetype_of = {eid: STEP4.GEN.classify(name) for eid, name in cur.fetchall()}

        cur.execute("""SELECT em.exercise_id, m.code, em.involvement::text
                         FROM exercises.exercise_muscle em
                         JOIN exercises.muscle m ON m.id = em.muscle_id""")
        muscles_by_exercise = _dd(list)
        for exercise_id, muscle_code, involvement in cur.fetchall():
            muscles_by_exercise[exercise_id].append((muscle_code, involvement))

        votes = _dd(_Counter)
        for exercise_id, muscles in muscles_by_exercise.items():
            arch = archetype_of.get(exercise_id)
            if arch and any(inv == "primary" for _c, inv in muscles):
                votes[arch][tuple(sorted(muscles))] += 1
        modal = {arch: v.most_common(1)[0][0] for arch, v in votes.items()}

        cur.execute("SELECT code, id FROM exercises.muscle")
        muscle_ids = dict(cur.fetchall())

        cur.execute("""SELECT e.id FROM exercises.exercise e WHERE e.deleted_at IS NULL
                        AND EXISTS (SELECT 1 FROM exercises.exercise_muscle m
                                     WHERE m.exercise_id = e.id)
                        AND NOT EXISTS (SELECT 1 FROM exercises.exercise_muscle p
                                         WHERE p.exercise_id = e.id
                                           AND p.involvement = 'primary')""")
        promoted = inserted = unresolved = 0
        for (exercise_id,) in cur.fetchall():
            arch = archetype_of.get(exercise_id)
            signature = modal.get(arch) or STEP4.EXPLICIT_MUSCLES.get(arch)
            if not signature:
                unresolved += 1
                continue
            present = {code for code, _inv in muscles_by_exercise[exercise_id]}
            for muscle_code, involvement in signature:
                if involvement != "primary":
                    continue
                if muscle_code in present:
                    cur.execute("""UPDATE exercises.exercise_muscle
                                      SET involvement = 'primary', updated_at = NOW()
                                    WHERE exercise_id = %s AND muscle_id = %s""",
                                (exercise_id, muscle_ids[muscle_code]))
                    promoted += cur.rowcount
                else:
                    cur.execute("""INSERT INTO exercises.exercise_muscle
                                       (exercise_id, muscle_id, involvement, created_at,
                                        evidence_basis, confidence)
                                   VALUES (%s, %s, 'primary', NOW(), 'heuristic', 'low')
                                   ON CONFLICT DO NOTHING""",
                                (exercise_id, muscle_ids[muscle_code]))
                    inserted += cur.rowcount
        print(f"prime movers: {promoted} promoted, {inserted} inserted, "
              f"{unresolved} unresolved")

        # new or promoted rows must carry the same tension profile as their peers
        cur.execute("""UPDATE exercises.exercise_muscle em
                          SET tension_lengthened = src.tension_lengthened,
                              tension_midrange = src.tension_midrange,
                              tension_shortened = src.tension_shortened,
                              updated_at = NOW()
                         FROM (SELECT DISTINCT ON (exercise_id) exercise_id,
                                      tension_lengthened, tension_midrange,
                                      tension_shortened
                                 FROM exercises.exercise_muscle
                                WHERE tension_lengthened IS NOT NULL) src
                        WHERE em.exercise_id = src.exercise_id
                          AND em.tension_lengthened IS NULL""")
        print(f"  tension profiles back-filled: {cur.rowcount}")

        print("\n--- QUALITY GATE")
        failures = 0
        for label, query in QUALITY_GATE:
            cur.execute(query)
            value = cur.fetchone()[0]
            status = "OK  " if value == 0 else "FAIL"
            if value:
                failures += 1
            print(f"   [{status}] {label:46s} {value}")
        print(f"\n{len(QUALITY_GATE) - failures}/{len(QUALITY_GATE)} checks pass")

        if args.apply and failures == 0:
            conn.commit()
            print("COMMITTED")
        elif args.apply:
            conn.rollback()
            sys.exit("quality gate failed - rolled back")
        else:
            conn.rollback()
            print("DRY RUN - rolled back")


if __name__ == "__main__":
    main()
