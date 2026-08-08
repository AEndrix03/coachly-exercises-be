#!/usr/bin/env python3
"""
Exercise model V2 - PHASE 2, STEP 16
Rebuild prime movers from the joint actions.

Two blind audits (80 exercises each, independent seeds) measured a 47.5%
residual error rate, and both named the same dominant cause: the MUSCLE layer.
245 exercises carry rectus_abdominis as their only primary muscle while their
own joint actions describe knee extension, plantar flexion, elbow flexion and
so on. The exercise contradicts itself inside a single row.

This survived every earlier correction round for a structural reason worth
recording: the correction schema I gave the validating agents allowed them to
change enums and tension levels, but NOT muscle involvement. They could see the
error and had no way to express the fix. The harness, not the data, was the
limiting factor.

The repair is deterministic. A joint action names the muscles that produce it,
so where the stored primaries cannot produce the stored primary joint actions,
the primaries are rebuilt from the actions. Nothing is invented: the mapping
below is anatomy, and the exercise's own joint actions decide which rows apply.

Usage:
    python inj/_tools/v2_step16_prime_movers.py [--apply]
"""
import argparse
import pathlib
import sys
from collections import Counter

import psycopg

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from dsn import get_dsn  # noqa: E402

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

# (joint, action) -> (primary muscles, secondary muscles)
ACTION_MUSCLES = {
    ("knee", "extension"): (["vastus_lateralis", "vastus_medialis", "vastus_intermedius",
                             "rectus_femoris"], []),
    ("knee", "flexion"): (["biceps_femoris_long", "semitendinosus", "semimembranosus"],
                          ["biceps_femoris_short", "gastrocnemius_medial"]),
    ("hip", "extension"): (["gluteus_maximus", "biceps_femoris_long"],
                           ["semitendinosus", "semimembranosus", "adductor_magnus"]),
    ("hip", "flexion"): (["iliopsoas"], ["rectus_femoris", "sartorius"]),
    ("hip", "abduction"): (["gluteus_medius"], ["gluteus_minimus", "tensor_fasciae_latae"]),
    ("hip", "adduction"): (["adductor_longus", "adductor_magnus"],
                           ["adductor_brevis", "gracilis"]),
    ("hip", "external_rotation"): (["gluteus_maximus"], ["gluteus_medius"]),
    ("ankle", "plantar_flexion"): (["gastrocnemius_medial", "gastrocnemius_lateral"],
                                   ["soleus"]),
    ("ankle", "dorsiflexion"): (["tibialis_anterior"], []),
    ("elbow", "flexion"): (["biceps_brachii_long", "biceps_brachii_short"],
                           ["brachialis", "brachioradialis"]),
    ("elbow", "extension"): (["triceps_brachii_long", "triceps_brachii_lateral"],
                             ["triceps_brachii_medial"]),
    ("shoulder", "flexion"): (["deltoid_anterior"], ["pectoralis_major_clavicular"]),
    ("shoulder", "extension"): (["latissimus_dorsi", "teres_major"], ["deltoid_posterior"]),
    ("shoulder", "abduction"): (["deltoid_lateral"], ["supraspinatus", "deltoid_anterior"]),
    ("shoulder", "adduction"): (["latissimus_dorsi", "teres_major"],
                                ["pectoralis_major_sternal"]),
    ("shoulder", "horizontal_adduction"): (["pectoralis_major_sternal",
                                            "pectoralis_major_clavicular"],
                                           ["deltoid_anterior"]),
    ("shoulder", "horizontal_abduction"): (["deltoid_posterior"],
                                           ["rhomboids", "trapezius_middle"]),
    ("shoulder", "external_rotation"): (["infraspinatus", "teres_minor"], []),
    ("shoulder", "internal_rotation"): (["subscapularis"], ["latissimus_dorsi"]),
    ("scapula", "retraction"): (["rhomboids", "trapezius_middle"], []),
    ("scapula", "protraction"): (["serratus_anterior"], []),
    ("scapula", "elevation"): (["trapezius_upper"], ["levator_scapulae"]),
    ("scapula", "depression"): (["trapezius_lower"], ["latissimus_dorsi"]),
    ("wrist", "flexion"): (["forearm_flexors"], []),
    ("wrist", "extension"): (["forearm_extensors"], []),
    ("forearm", "supination"): (["biceps_brachii_long"], ["forearm_extensors"]),
    ("forearm", "pronation"): (["forearm_flexors"], []),
    ("spine", "flexion"): (["rectus_abdominis"], ["obliquus_externus", "obliquus_internus"]),
    ("spine", "extension"): (["erector_spinae"], ["multifidus"]),
    ("spine", "rotation"): (["obliquus_externus", "obliquus_internus"], ["rectus_abdominis"]),
    ("spine", "lateral_flexion"): (["obliquus_externus"], ["erector_spinae"]),
    ("spine", "anti_flexion"): (["erector_spinae"], ["multifidus"]),
    ("spine", "anti_extension"): (["rectus_abdominis"], ["transversus_abdominis"]),
    ("spine", "anti_rotation"): (["obliquus_externus", "obliquus_internus"],
                                 ["transversus_abdominis"]),
    ("neck", "flexion"): (["sternocleidomastoid"], ["scalenes"]),
    ("neck", "extension"): (["splenius_capitis", "splenius_cervicis"], ["levator_scapulae"]),
    ("neck", "lateral_flexion"): (["sternocleidomastoid"], ["scalenes"]),
    ("hand", "grip"): (["forearm_flexors"], []),
}


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
        unknown = sorted({m for pair in ACTION_MUSCLES.values() for group in pair
                          for m in group} - set(muscle_ids))
        if unknown:
            sys.exit(f"mapping references muscles that do not exist: {unknown}")

        # exercises whose only primary is rectus_abdominis while their primary
        # joint actions are not spinal flexion: the row contradicts itself
        cur.execute("""
            SELECT e.id, e.code
              FROM exercises.exercise e
             WHERE e.deleted_at IS NULL
               AND (SELECT count(*) FROM exercises.exercise_muscle m
                     WHERE m.exercise_id = e.id AND m.involvement = 'primary') = 1
               AND EXISTS (SELECT 1 FROM exercises.exercise_muscle m
                             JOIN exercises.muscle mu ON mu.id = m.muscle_id
                            WHERE m.exercise_id = e.id AND m.involvement = 'primary'
                              AND mu.code = 'rectus_abdominis')
               AND EXISTS (SELECT 1 FROM exercises.exercise_joint_action j
                             JOIN exercises.joint_action ja ON ja.id = j.joint_action_id
                            WHERE j.exercise_id = e.id AND j.role = 'primary'
                              AND NOT (ja.joint_code = 'spine'
                                       AND ja.action_code IN ('flexion','anti_extension',
                                                              'rotation','anti_rotation')))
             ORDER BY e.code""")
        targets = cur.fetchall()
        print(f"exercises contradicting their own joint actions: {len(targets)}")

        stats = Counter()
        no_mapping = []
        for exercise_id, code in targets:
            cur.execute("""SELECT ja.joint_code, ja.action_code, j.role::text
                             FROM exercises.exercise_joint_action j
                             JOIN exercises.joint_action ja ON ja.id = j.joint_action_id
                            WHERE j.exercise_id = %s""", (exercise_id,))
            actions = cur.fetchall()
            primaries, secondaries = [], []
            for joint, action, role in actions:
                mapped = ACTION_MUSCLES.get((joint, action))
                if not mapped:
                    continue
                if role == "primary":
                    primaries.extend(mapped[0])
                    secondaries.extend(mapped[1])
                else:
                    secondaries.extend(mapped[0])
            primaries = list(dict.fromkeys(primaries))
            secondaries = [m for m in dict.fromkeys(secondaries) if m not in primaries]
            if not primaries:
                no_mapping.append(code)
                continue

            # keep the tension profile the exercise already uses, rather than
            # inventing one for the muscles being introduced
            cur.execute("""SELECT tension_lengthened::text, tension_midrange::text,
                                  tension_shortened::text
                             FROM exercises.exercise_muscle
                            WHERE exercise_id = %s AND tension_lengthened IS NOT NULL
                            LIMIT 1""", (exercise_id,))
            profile = cur.fetchone() or ("moderate", "high", "moderate")

            # the placeholder primary becomes a stabilizer where it belongs
            cur.execute("""UPDATE exercises.exercise_muscle em
                              SET involvement = 'stabilizer', updated_at = NOW()
                             FROM exercises.muscle mu
                            WHERE em.muscle_id = mu.id AND em.exercise_id = %s
                              AND em.involvement = 'primary'
                              AND mu.code = 'rectus_abdominis'""", (exercise_id,))

            for involvement, codes in (("primary", primaries), ("secondary", secondaries)):
                for muscle_code in codes:
                    cur.execute("""INSERT INTO exercises.exercise_muscle
                                       (exercise_id, muscle_id, involvement, created_at,
                                        updated_at, tension_lengthened, tension_midrange,
                                        tension_shortened, evidence_basis, confidence)
                                   VALUES (%s, %s, %s, NOW(), NOW(), %s, %s, %s,
                                           'biomechanical_model', 'moderate')
                                   ON CONFLICT DO NOTHING""",
                                (exercise_id, muscle_ids[muscle_code], involvement,
                                 profile[0], profile[1], profile[2]))
                    stats[involvement] += cur.rowcount
            stats["exercises"] += 1

        # inserting by (exercise, muscle, involvement) can leave the same
        # muscle present twice with different involvement; the strongest wins
        cur.execute("""DELETE FROM exercises.exercise_muscle weak
                        USING exercises.exercise_muscle strong
                        WHERE weak.exercise_id = strong.exercise_id
                          AND weak.muscle_id = strong.muscle_id
                          AND CASE weak.involvement WHEN 'primary' THEN 3
                                                    WHEN 'secondary' THEN 2 ELSE 1 END
                            < CASE strong.involvement WHEN 'primary' THEN 3
                                                      WHEN 'secondary' THEN 2 ELSE 1 END""")
        print(f"duplicate involvement rows collapsed: {cur.rowcount}")

        print(f"exercises rebuilt: {stats['exercises']}")
        print(f"   primary rows added   : {stats['primary']}")
        print(f"   secondary rows added : {stats['secondary']}")
        if no_mapping:
            print(f"   no mappable joint action, left alone: {len(no_mapping)}")
            print("     ", ", ".join(no_mapping[:8]))

        # ---- verification ----
        print("\n--- verification")
        checks = [
            ("still contradicting their own joint actions",
             """SELECT count(*) FROM exercises.exercise e
                 WHERE e.deleted_at IS NULL
                   AND (SELECT count(*) FROM exercises.exercise_muscle m
                         WHERE m.exercise_id = e.id AND m.involvement = 'primary') = 1
                   AND EXISTS (SELECT 1 FROM exercises.exercise_muscle m
                                 JOIN exercises.muscle mu ON mu.id = m.muscle_id
                                WHERE m.exercise_id = e.id AND m.involvement = 'primary'
                                  AND mu.code = 'rectus_abdominis')
                   AND EXISTS (SELECT 1 FROM exercises.exercise_joint_action j
                                 JOIN exercises.joint_action ja ON ja.id = j.joint_action_id
                                WHERE j.exercise_id = e.id AND j.role = 'primary'
                                  AND NOT (ja.joint_code = 'spine'
                                           AND ja.action_code IN ('flexion','anti_extension',
                                                                  'rotation','anti_rotation')))"""),
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
        ]
        failed = False
        for label, query in checks:
            cur.execute(query)
            value = cur.fetchone()[0]
            print(f"   [{'OK  ' if value == 0 else 'FAIL'}] {label:48s} {value}")
            if value:
                failed = True
        if failed:
            conn.rollback()
            sys.exit("verification failed - rolled back")

        if args.apply:
            conn.commit()
            print("COMMITTED")
        else:
            conn.rollback()
            print("DRY RUN - rolled back")


if __name__ == "__main__":
    main()
