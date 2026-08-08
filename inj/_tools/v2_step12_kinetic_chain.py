#!/usr/bin/env python3
"""
Exercise model V2 - PHASE 2, STEP 12
Populate exercise.kinetic_chain.

Clinical definition (see the DDL comment for why this one and not the NSCA
reading): CLOSED when the distal segment is fixed against a surface or
apparatus and the body moves around it; OPEN when the distal segment travels
freely through space.

The bench press is therefore OPEN: the hands hold a bar that moves. A push-up
is CLOSED: the hands are planted and the body moves. This is the distinction
that carries information; calling the bench press closed would just restate
joint_class = multi_joint.

Stretching, yoga and mobility drills are left NULL on purpose - the
classification says nothing useful about them, and a guess would be worse than
an honest gap.

Usage:
    python inj/_tools/v2_step12_kinetic_chain.py [--apply]
"""
import argparse
import os
import pathlib
import sys

import psycopg

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from dsn import get_dsn  # noqa: E402

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

CLOSED = {
    # squat / hinge patterns: feet planted
    "squat_back", "squat_front", "squat_hack", "squat_bodyweight", "leg_press",
    "split_squat", "lunge", "step_up", "pistol_squat", "sissy_squat", "wall_sit",
    "deadlift_conventional", "deadlift_sumo", "rdl", "good_morning", "hip_thrust",
    "glute_bridge", "back_extension", "reverse_hyper", "kb_swing", "pull_through",
    "nordic_curl", "slider_leg_curl", "copenhagen", "band_walk",
    # calves: the foot is on the floor or a platform
    "calf_raise_standing", "calf_raise_seated", "calf_raise_leg_press",
    "calf_machine_lever", "calf_raise_band", "tibialis_raise",
    # hands planted, body moves
    "pushup", "pushup_deficit", "tri_dip", "dip_machine", "tri_bodyweight_ext",
    "hspu", "pike_pushup", "planche", "handstand_hold", "crawl",
    # hanging: the hands are the fixed point
    "pullup", "chinup", "muscle_up", "row_inverted", "hang_passive",
    "scapular_pull", "scapula_dip", "rope_climb", "front_lever_row",
    "lever_hold", "skin_the_cat",
    # trunk braced against a fixed contact
    "plank", "ab_wheel", "hollow_hold", "l_sit", "dragon_flag",
    # loaded locomotion and power: ground contact drives the movement
    "plyometric", "sled", "carry", "carry_overhead", "olympic_lift", "push_jerk",
    "cardio_cyclic", "get_up",
}

OPEN = {
    # elbow flexion / extension: the hand travels
    "curl_standing", "curl_preacher", "curl_incline", "curl_bayesian", "curl_spider",
    "curl_concentration", "curl_cable", "curl_overhead_cable", "curl_machine",
    "curl_band", "curl_drag", "curl_reverse", "curl_sprinter", "curl_wrist",
    "wrist_roller", "tri_pushdown", "tri_overhead", "tri_overhead_cable",
    "tri_skullcrusher", "tri_kickback", "tri_band_pushdown", "tri_extension_lever",
    # pressing a moving implement
    "bench_flat", "bench_incline", "bench_decline", "bench_floor", "bench_machine",
    "bench_smith", "tri_close_press", "press_cable_chest", "svend_press",
    "fly_dumbbell", "fly_cable", "fly_machine", "fly_band",
    "ohp_standing", "ohp_seated", "ohp_machine", "ohp_landmine",
    # shoulder isolation
    "lateral_raise_db", "lateral_raise_cable", "lateral_raise_machine", "front_raise",
    "rear_delt_fly_db", "rear_delt_cable", "rear_delt_machine", "face_pull",
    "band_pull_apart", "upright_row", "shrug", "cuff_rotation", "cuff_rotation_band",
    # pulling a moving implement
    "lat_pulldown", "pullover_db", "pullover_machine", "straight_arm_pulldown",
    "row_barbell", "row_dumbbell", "row_cable", "row_machine", "row_chest_supported",
    "row_landmine",
    # the foot travels
    "leg_extension", "leg_curl_lying", "leg_curl_seated", "leg_curl_band",
    "hip_abduction", "hip_adduction", "hip_flexion", "kickback_glute",
    # trunk and neck isolation
    "crunch", "cable_crunch", "leg_raise_hanging", "side_bend", "russian_twist",
    "woodchop", "rotation_twist", "pallof_press", "superman",
    "neck_machine", "neck_band",
    "grip_hold", "throw",
}

# deliberately unclassified: the distinction carries no information here
UNCLASSIFIED = {"stretch", "yoga_pose", "mobility_drill", "balance_drill"}

# The validation agents promoted three `stretch`-archetype exercises to
# resistance, and a resistance exercise must carry a decision. All three are
# closed: the roller drills fix the hands and feet, the lunge plants the foot.
EXPLICIT_CLOSED = ["roller_body_saw", "roller_reverse_crunch", "weighted_stretch_lunge"]

ARCH = "split_part(split_part(b.method_note,'archetype=',2),';',1)"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dsn", default=None,
                    help="optional; resolved from $COACHLY_BIOMECH_DSN or auto-injestion/.env")
    ap.add_argument("--apply", action="store_true")
    args = ap.parse_args()
    dsn = args.dsn or get_dsn()

    overlap = CLOSED & OPEN
    if overlap:
        sys.exit(f"archetype in both sets: {sorted(overlap)}")

    with psycopg.connect(dsn, connect_timeout=30) as conn:
        conn.autocommit = False
        cur = conn.cursor()

        # every archetype in the catalogue must be accounted for
        cur.execute(f"""SELECT DISTINCT {ARCH}
                          FROM exercises.exercise e
                          JOIN exercises.exercise_biomechanics b ON b.exercise_id = e.id
                         WHERE e.deleted_at IS NULL""")
        live = {r[0] for r in cur.fetchall() if r[0]}
        unaccounted = sorted(live - CLOSED - OPEN - UNCLASSIFIED)
        if unaccounted:
            sys.exit(f"archetypes with no kinetic chain decision: {unaccounted}")
        print(f"archetypes covered: {len(live)}")

        for value, archetypes in (("closed", CLOSED), ("open", OPEN)):
            cur.execute(f"""UPDATE exercises.exercise e
                               SET kinetic_chain = %s, updated_at = NOW()
                              FROM exercises.exercise_biomechanics b
                             WHERE b.exercise_id = e.id AND {ARCH} = ANY(%s)""",
                        (value, sorted(archetypes)))
            print(f"   {value:7s} -> {cur.rowcount} exercises")

        cur.execute("""UPDATE exercises.exercise SET kinetic_chain = 'closed', updated_at = NOW()
                        WHERE code = ANY(%s)""", (EXPLICIT_CLOSED,))
        print(f"   explicit  -> {cur.rowcount} reclassified exercises")

        cur.execute("""SELECT coalesce(kinetic_chain::text, '<unclassified>'), count(*)
                         FROM exercises.exercise WHERE deleted_at IS NULL
                        GROUP BY 1 ORDER BY 2 DESC""")
        print("distribution:", dict(cur.fetchall()))

        # a resistance exercise should always have a decision
        cur.execute("""SELECT count(*) FROM exercises.exercise
                        WHERE deleted_at IS NULL AND exercise_kind = 'resistance'
                          AND kinetic_chain IS NULL""")
        missing = cur.fetchone()[0]
        print(f"resistance exercises without kinetic_chain: {missing}")
        if missing:
            cur.execute(f"""SELECT DISTINCT {ARCH} FROM exercises.exercise e
                              JOIN exercises.exercise_biomechanics b ON b.exercise_id = e.id
                             WHERE e.deleted_at IS NULL AND e.exercise_kind = 'resistance'
                               AND e.kinetic_chain IS NULL""")
            print("   archetypes:", [r[0] for r in cur.fetchall()])
            conn.rollback()
            sys.exit("incomplete - rolled back")

        if args.apply:
            conn.commit()
            print("COMMITTED")
        else:
            conn.rollback()
            print("DRY RUN - rolled back")


if __name__ == "__main__":
    main()
