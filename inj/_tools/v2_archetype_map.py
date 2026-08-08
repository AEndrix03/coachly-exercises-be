#!/usr/bin/env python3
"""
Exercise model V2 - archetype -> V2 attributes.

The 152 movement archetypes already classify the whole catalogue (see
gen_biomechanics_sql.py). This module says, for each archetype, what the V2
model needs that cannot be derived from the old numbers:

    kind      exercise_kind
    family    exercise_family.code
    jc        joint_class
    td        technical_demand
    sp        spotter_policy
    mp        [(movement_pattern_code, role)]
    ja        [(joint_code, action_code, role)]
    tr        (tracking_type, load_input_mode, side_mode, comparison_scope)

Everything else IS derived, so it cannot drift:
    spinal_loading      <- archetype axial
    stability_demand    <- archetype stab
    tension_*           <- archetype ts / peak / tc  (see tension_levels)

Coachly convention: PER_IMPLEMENT means the logged number is the load of a
single implement (a 32 kg dumbbell curl is logged as 32, not 64).
"""

# tracking shorthands ------------------------------------------------------
T_BB = ("weight_reps", "total_load", "none", "exercise")             # barbell / fixed bar
T_DB = ("weight_reps", "per_implement", "optional", "exercise")      # dumbbells, both sides
T_DB1 = ("weight_reps", "per_implement", "separate", "exercise")     # single-arm dumbbell
T_CBL = ("weight_reps", "total_load", "optional", "equipment_instance")
T_CBL1 = ("weight_reps", "total_load", "separate", "equipment_instance")
T_MCH = ("weight_reps", "total_load", "optional", "equipment_instance")
T_MCH1 = ("weight_reps", "total_load", "separate", "equipment_instance")
T_BW = ("bodyweight_reps", "none", "none", "bodyweight_aware")
T_BW1 = ("bodyweight_reps", "none", "separate", "bodyweight_aware")
T_BWW = ("bodyweight_plus_weight", "added_weight", "none", "bodyweight_aware")
T_ASST = ("assisted_bodyweight", "assistance", "none", "bodyweight_aware")
T_BAND = ("reps", "none", "optional", "non_comparable")
T_HOLD = ("time", "none", "none", "bodyweight_aware")
T_HOLDW = ("weight_time", "total_load", "none", "exercise")
T_CARRY = ("weight_distance", "total_load", "none", "exercise")
T_CARRY1 = ("weight_distance", "per_implement", "separate", "exercise")
T_CARDIO = ("time", "none", "none", "non_comparable")
T_DIST = ("distance", "none", "none", "non_comparable")
T_REPS = ("reps", "none", "optional", "non_comparable")

# joint action shorthands --------------------------------------------------
JA_ELBOW_FLEX = [("elbow", "flexion", "primary")]
JA_ELBOW_EXT = [("elbow", "extension", "primary")]
JA_HORIZ_PRESS = [("shoulder", "horizontal_adduction", "primary"),
                  ("elbow", "extension", "primary"),
                  ("scapula", "protraction", "secondary")]
JA_VERT_PRESS = [("shoulder", "flexion", "primary"),
                 ("elbow", "extension", "primary"),
                 ("scapula", "elevation", "secondary")]
JA_VERT_PULL = [("shoulder", "adduction", "primary"),
                ("elbow", "flexion", "primary"),
                ("scapula", "depression", "secondary")]
JA_HORIZ_PULL = [("shoulder", "extension", "primary"),
                 ("elbow", "flexion", "primary"),
                 ("scapula", "retraction", "primary")]
JA_SQUAT = [("knee", "extension", "primary"), ("hip", "extension", "primary"),
            ("ankle", "dorsiflexion", "secondary")]
JA_HINGE = [("hip", "extension", "primary"), ("spine", "anti_flexion", "secondary")]
JA_KNEE_EXT = [("knee", "extension", "primary")]
JA_KNEE_FLEX = [("knee", "flexion", "primary")]
JA_HIP_EXT = [("hip", "extension", "primary")]
JA_CALF = [("ankle", "plantar_flexion", "primary")]
JA_SH_ABD = [("shoulder", "abduction", "primary")]
JA_SH_FLEX = [("shoulder", "flexion", "primary")]
JA_SH_HABD = [("shoulder", "horizontal_abduction", "primary"),
              ("scapula", "retraction", "secondary")]
JA_SPINE_FLEX = [("spine", "flexion", "primary")]
JA_SPINE_EXT = [("spine", "extension", "primary")]

# ---------------------------------------------------------------------------
# archetype -> V2. `kind` defaults to resistance; only exceptions state it.
# ---------------------------------------------------------------------------
V2 = {}


def a(key, family, jc="multi_joint", td="moderate", sp="none",
      mp=(), ja=(), tr=T_BB, kind="resistance"):
    V2[key] = {"kind": kind, "family": family, "jc": jc, "td": td, "sp": sp,
               "mp": list(mp), "ja": list(ja), "tr": tr}


SJ = "single_joint"
MJ = "multi_joint"

# ----- elbow flexion -------------------------------------------------------
for k, tr, fam in [
    ("curl_standing", T_BB, "biceps_curl"), ("curl_preacher", T_BB, "preacher_curl"),
    ("curl_incline", T_DB, "biceps_curl"), ("curl_bayesian", T_CBL1, "biceps_curl"),
    ("curl_spider", T_DB, "biceps_curl"), ("curl_concentration", T_DB1, "biceps_curl"),
    ("curl_cable", T_CBL, "biceps_curl"), ("curl_overhead_cable", T_CBL1, "biceps_curl"),
    ("curl_machine", T_MCH, "biceps_curl"), ("curl_band", T_BAND, "biceps_curl"),
    ("curl_drag", T_BB, "biceps_curl"), ("curl_reverse", T_BB, "biceps_curl"),
    ("curl_sprinter", T_CBL1, "biceps_curl"),
]:
    a(k, fam, SJ, "low", mp=[("elbow_flexion", "primary")], ja=JA_ELBOW_FLEX, tr=tr)
a("curl_wrist", "wrist_curl", SJ, "low",
  mp=[("wrist_flexion", "primary")], ja=[("wrist", "flexion", "primary")], tr=T_BB)

# ----- elbow extension -----------------------------------------------------
a("tri_pushdown", "triceps_pushdown", SJ, "low",
  mp=[("elbow_extension", "primary")], ja=JA_ELBOW_EXT, tr=T_CBL)
a("tri_overhead", "triceps_overhead_extension", SJ, "low",
  mp=[("elbow_extension", "primary")], ja=JA_ELBOW_EXT, tr=T_DB)
a("tri_overhead_cable", "triceps_overhead_extension", SJ, "low",
  mp=[("elbow_extension", "primary")], ja=JA_ELBOW_EXT, tr=T_CBL)
a("tri_skullcrusher", "skull_crusher", SJ, "moderate",
  mp=[("elbow_extension", "primary")], ja=JA_ELBOW_EXT, tr=T_BB)
a("tri_kickback", "triceps_kickback", SJ, "low",
  mp=[("elbow_extension", "primary")], ja=JA_ELBOW_EXT, tr=T_DB1)
a("tri_band_pushdown", "triceps_pushdown", SJ, "low",
  mp=[("elbow_extension", "primary")], ja=JA_ELBOW_EXT, tr=T_BAND)
a("tri_extension_lever", "triceps_pushdown", SJ, "low",
  mp=[("elbow_extension", "primary")], ja=JA_ELBOW_EXT, tr=T_MCH)
a("tri_dip", "dip", MJ, "moderate",
  mp=[("horizontal_press", "primary"), ("vertical_press", "secondary")],
  ja=JA_HORIZ_PRESS, tr=T_BWW)
a("dip_machine", "dip", MJ, "low",
  mp=[("horizontal_press", "primary")], ja=JA_HORIZ_PRESS, tr=T_MCH)
a("tri_close_press", "bench_press", MJ, "moderate", sp="recommended_high_effort",
  mp=[("horizontal_press", "primary")], ja=JA_HORIZ_PRESS, tr=T_BB)
a("tri_bodyweight_ext", "triceps_overhead_extension", SJ, "moderate",
  mp=[("elbow_extension", "primary")], ja=JA_ELBOW_EXT, tr=T_BW)

# ----- horizontal push -----------------------------------------------------
a("bench_flat", "bench_press", MJ, "moderate", sp="recommended_high_effort",
  mp=[("horizontal_press", "primary")], ja=JA_HORIZ_PRESS, tr=T_BB)
a("bench_incline", "incline_press", MJ, "moderate", sp="recommended_high_effort",
  mp=[("horizontal_press", "primary"), ("vertical_press", "secondary")],
  ja=JA_HORIZ_PRESS, tr=T_BB)
a("bench_decline", "decline_press", MJ, "moderate", sp="recommended_high_effort",
  mp=[("horizontal_press", "primary")], ja=JA_HORIZ_PRESS, tr=T_BB)
a("bench_floor", "bench_press", MJ, "moderate", sp="recommended_high_effort",
  mp=[("horizontal_press", "primary")], ja=JA_HORIZ_PRESS, tr=T_BB)
a("bench_machine", "chest_press_machine", MJ, "low",
  mp=[("horizontal_press", "primary")], ja=JA_HORIZ_PRESS, tr=T_MCH)
a("bench_smith", "bench_press", MJ, "low",
  mp=[("horizontal_press", "primary")], ja=JA_HORIZ_PRESS, tr=T_BB)
a("press_cable_chest", "chest_press_machine", MJ, "moderate",
  mp=[("horizontal_press", "primary")], ja=JA_HORIZ_PRESS, tr=T_CBL)
a("pushup", "push_up", MJ, "low",
  mp=[("horizontal_press", "primary")], ja=JA_HORIZ_PRESS, tr=T_BW)
a("pushup_deficit", "push_up", MJ, "moderate",
  mp=[("horizontal_press", "primary")], ja=JA_HORIZ_PRESS, tr=T_BW)
for k, tr in [("fly_dumbbell", T_DB), ("fly_cable", T_CBL),
              ("fly_machine", T_MCH), ("fly_band", T_BAND)]:
    a(k, "chest_fly", SJ, "low", mp=[("horizontal_press", "primary")],
      ja=[("shoulder", "horizontal_adduction", "primary")], tr=tr)
a("svend_press", "chest_fly", SJ, "low", mp=[("horizontal_press", "primary")],
  ja=[("shoulder", "horizontal_adduction", "primary")], tr=T_HOLDW)

# ----- vertical push -------------------------------------------------------
a("ohp_standing", "overhead_press", MJ, "high",
  mp=[("vertical_press", "primary")], ja=JA_VERT_PRESS, tr=T_BB)
a("ohp_seated", "overhead_press", MJ, "moderate",
  mp=[("vertical_press", "primary")], ja=JA_VERT_PRESS, tr=T_DB)
a("ohp_machine", "overhead_press", MJ, "low",
  mp=[("vertical_press", "primary")], ja=JA_VERT_PRESS, tr=T_MCH)
a("ohp_landmine", "overhead_press", MJ, "moderate",
  mp=[("vertical_press", "primary")], ja=JA_VERT_PRESS, tr=T_BB)
a("hspu", "handstand", MJ, "high",
  mp=[("vertical_press", "primary")], ja=JA_VERT_PRESS, tr=T_BW)
a("pike_pushup", "push_up", MJ, "moderate",
  mp=[("vertical_press", "primary")], ja=JA_VERT_PRESS, tr=T_BW)
a("push_jerk", "olympic_lift", MJ, "high",
  mp=[("vertical_press", "primary"), ("squat", "secondary")], ja=JA_VERT_PRESS, tr=T_BB)

# ----- shoulder isolation --------------------------------------------------
for k, tr in [("lateral_raise_db", T_DB), ("lateral_raise_cable", T_CBL1),
              ("lateral_raise_machine", T_MCH)]:
    a(k, "lateral_raise", SJ, "low", mp=[("shoulder_abduction", "primary")],
      ja=JA_SH_ABD, tr=tr)
a("front_raise", "front_raise", SJ, "low", mp=[("shoulder_flexion", "primary")],
  ja=JA_SH_FLEX, tr=T_DB)
for k, tr in [("rear_delt_fly_db", T_DB), ("rear_delt_cable", T_CBL),
              ("rear_delt_machine", T_MCH)]:
    a(k, "rear_delt_fly", SJ, "low",
      mp=[("shoulder_horizontal_abduction", "primary")], ja=JA_SH_HABD, tr=tr)
a("face_pull", "face_pull", SJ, "low",
  mp=[("shoulder_horizontal_abduction", "primary"), ("scapular", "secondary")],
  ja=JA_SH_HABD, tr=T_CBL)
a("band_pull_apart", "rear_delt_fly", SJ, "low",
  mp=[("shoulder_horizontal_abduction", "primary")], ja=JA_SH_HABD, tr=T_BAND)
a("upright_row", "upright_row", MJ, "moderate",
  mp=[("shoulder_abduction", "primary"), ("elbow_flexion", "secondary")],
  ja=JA_SH_ABD + [("elbow", "flexion", "secondary")], tr=T_BB)
a("shrug", "shrug", SJ, "low", mp=[("scapular", "primary")],
  ja=[("scapula", "elevation", "primary")], tr=T_BB)
a("cuff_rotation", "rotator_cuff_work", SJ, "low", mp=[("rotation", "primary")],
  ja=[("shoulder", "external_rotation", "primary")], tr=T_CBL1)
a("cuff_rotation_band", "rotator_cuff_work", SJ, "low", mp=[("rotation", "primary")],
  ja=[("shoulder", "external_rotation", "primary")], tr=T_BAND)

# ----- vertical pull -------------------------------------------------------
a("pullup", "pull_up", MJ, "moderate", mp=[("vertical_pull", "primary")],
  ja=JA_VERT_PULL, tr=T_BWW)
a("chinup", "chin_up", MJ, "moderate", mp=[("vertical_pull", "primary")],
  ja=JA_VERT_PULL, tr=T_BWW)
a("lat_pulldown", "lat_pulldown", MJ, "low", mp=[("vertical_pull", "primary")],
  ja=JA_VERT_PULL, tr=T_MCH)
a("muscle_up", "muscle_up", MJ, "high",
  mp=[("vertical_pull", "primary"), ("vertical_press", "secondary")],
  ja=JA_VERT_PULL, tr=T_BWW)
a("straight_arm_pulldown", "straight_arm_pulldown", SJ, "low",
  mp=[("shoulder_extension", "primary")],
  ja=[("shoulder", "extension", "primary")], tr=T_CBL)
a("pullover_db", "pullover", SJ, "moderate", mp=[("shoulder_extension", "primary")],
  ja=[("shoulder", "extension", "primary")], tr=T_DB)
a("pullover_machine", "pullover", SJ, "low", mp=[("shoulder_extension", "primary")],
  ja=[("shoulder", "extension", "primary")], tr=T_MCH)
a("hang_passive", "hang", SJ, "low", mp=[("grip", "primary")],
  ja=[("hand", "grip", "primary")], tr=T_HOLD)
a("scapular_pull", "scapular_control", SJ, "low", mp=[("scapular", "primary")],
  ja=[("scapula", "depression", "primary")], tr=T_BW)
a("scapula_dip", "scapular_control", SJ, "low", mp=[("scapular", "primary")],
  ja=[("scapula", "depression", "primary")], tr=T_BW)

# ----- horizontal pull -----------------------------------------------------
a("row_barbell", "barbell_row", MJ, "moderate", mp=[("horizontal_pull", "primary")],
  ja=JA_HORIZ_PULL, tr=T_BB)
a("row_dumbbell", "dumbbell_row", MJ, "low", mp=[("horizontal_pull", "primary")],
  ja=JA_HORIZ_PULL, tr=T_DB1)
a("row_chest_supported", "machine_row", MJ, "low", mp=[("horizontal_pull", "primary")],
  ja=JA_HORIZ_PULL, tr=T_BB)
a("row_cable", "cable_row", MJ, "low", mp=[("horizontal_pull", "primary")],
  ja=JA_HORIZ_PULL, tr=T_CBL)
a("row_machine", "machine_row", MJ, "low", mp=[("horizontal_pull", "primary")],
  ja=JA_HORIZ_PULL, tr=T_MCH)
a("row_inverted", "inverted_row", MJ, "low", mp=[("horizontal_pull", "primary")],
  ja=JA_HORIZ_PULL, tr=T_BW)
a("row_landmine", "barbell_row", MJ, "moderate", mp=[("horizontal_pull", "primary")],
  ja=JA_HORIZ_PULL, tr=T_BB)

# ----- squat ---------------------------------------------------------------
a("squat_back", "back_squat", MJ, "high", sp="recommended_high_effort",
  mp=[("squat", "primary")], ja=JA_SQUAT, tr=T_BB)
a("squat_front", "front_squat", MJ, "high", sp="recommended_high_effort",
  mp=[("squat", "primary")], ja=JA_SQUAT, tr=T_BB)
a("squat_hack", "hack_squat", MJ, "low", mp=[("squat", "primary")], ja=JA_SQUAT, tr=T_MCH)
a("leg_press", "leg_press", MJ, "low", mp=[("squat", "primary")], ja=JA_SQUAT, tr=T_MCH)
a("squat_bodyweight", "bodyweight_squat", MJ, "low",
  mp=[("squat", "primary")], ja=JA_SQUAT, tr=T_BW)
a("split_squat", "split_squat", MJ, "moderate",
  mp=[("squat", "primary")], ja=JA_SQUAT, tr=T_DB1)
a("lunge", "lunge", MJ, "moderate", mp=[("squat", "primary")], ja=JA_SQUAT, tr=T_DB)
a("step_up", "step_up", MJ, "moderate", mp=[("squat", "primary")], ja=JA_SQUAT, tr=T_DB1)
a("pistol_squat", "single_leg_squat", MJ, "high",
  mp=[("squat", "primary")], ja=JA_SQUAT, tr=T_BW1)
a("sissy_squat", "sissy_squat", SJ, "moderate",
  mp=[("knee_extension", "primary")], ja=JA_KNEE_EXT, tr=T_BW)
a("leg_extension", "leg_extension", SJ, "low",
  mp=[("knee_extension", "primary")], ja=JA_KNEE_EXT, tr=T_MCH)
a("wall_sit", "wall_sit", MJ, "low", mp=[("squat", "primary")], ja=JA_SQUAT, tr=T_HOLD)

# ----- hinge ---------------------------------------------------------------
a("deadlift_conventional", "deadlift", MJ, "high",
  mp=[("hip_hinge", "primary"), ("squat", "secondary")], ja=JA_HINGE, tr=T_BB)
a("deadlift_sumo", "deadlift", MJ, "high",
  mp=[("hip_hinge", "primary"), ("squat", "secondary")], ja=JA_HINGE, tr=T_BB)
a("rdl", "romanian_deadlift", MJ, "moderate", mp=[("hip_hinge", "primary")],
  ja=JA_HINGE, tr=T_BB)
a("good_morning", "good_morning", MJ, "high", mp=[("hip_hinge", "primary")],
  ja=JA_HINGE, tr=T_BB)
a("back_extension", "back_extension", MJ, "low",
  mp=[("hip_extension", "primary"), ("spinal_extension", "secondary")],
  ja=JA_HIP_EXT + [("spine", "extension", "secondary")], tr=T_BWW)
a("reverse_hyper", "reverse_hyper", MJ, "low", mp=[("hip_extension", "primary")],
  ja=JA_HIP_EXT, tr=T_MCH)
a("hip_thrust", "hip_thrust", MJ, "low", mp=[("hip_extension", "primary")],
  ja=JA_HIP_EXT, tr=T_BB)
a("glute_bridge", "glute_bridge", MJ, "low", mp=[("hip_extension", "primary")],
  ja=JA_HIP_EXT, tr=T_BW)
a("kb_swing", "kettlebell_swing", MJ, "high", mp=[("hip_hinge", "primary")],
  ja=JA_HINGE, tr=T_DB)
a("pull_through", "pull_through", MJ, "low", mp=[("hip_hinge", "primary")],
  ja=JA_HINGE, tr=T_CBL)
a("kickback_glute", "glute_kickback", SJ, "low", mp=[("hip_extension", "primary")],
  ja=JA_HIP_EXT, tr=T_CBL1)

# ----- knee flexion --------------------------------------------------------
a("leg_curl_lying", "leg_curl", SJ, "low", mp=[("knee_flexion", "primary")],
  ja=JA_KNEE_FLEX, tr=T_MCH)
a("leg_curl_seated", "leg_curl", SJ, "low", mp=[("knee_flexion", "primary")],
  ja=JA_KNEE_FLEX, tr=T_MCH)
a("leg_curl_band", "leg_curl", SJ, "low", mp=[("knee_flexion", "primary")],
  ja=JA_KNEE_FLEX, tr=T_BAND)
a("nordic_curl", "nordic_curl", SJ, "high", mp=[("knee_flexion", "primary")],
  ja=JA_KNEE_FLEX, tr=T_BW)
a("slider_leg_curl", "leg_curl", SJ, "moderate", mp=[("knee_flexion", "primary")],
  ja=JA_KNEE_FLEX, tr=T_BW)

# ----- calves --------------------------------------------------------------
for k, tr in [("calf_raise_standing", T_BB), ("calf_raise_seated", T_MCH),
              ("calf_raise_leg_press", T_MCH), ("calf_machine_lever", T_MCH),
              ("calf_raise_band", T_BAND)]:
    a(k, "calf_raise", SJ, "low", mp=[("plantar_flexion", "primary")], ja=JA_CALF, tr=tr)
a("tibialis_raise", "tibialis_raise", SJ, "low", mp=[("dorsiflexion", "primary")],
  ja=[("ankle", "dorsiflexion", "primary")], tr=T_BW)

# ----- hip abd / add -------------------------------------------------------
a("hip_abduction", "hip_abduction", SJ, "low", mp=[("hip_abduction", "primary")],
  ja=[("hip", "abduction", "primary")], tr=T_MCH)
a("hip_adduction", "hip_adduction", SJ, "low", mp=[("hip_adduction", "primary")],
  ja=[("hip", "adduction", "primary")], tr=T_MCH)
a("band_walk", "hip_abduction", SJ, "low", mp=[("hip_abduction", "primary")],
  ja=[("hip", "abduction", "primary")], tr=T_BAND)
a("copenhagen", "hip_adduction", SJ, "moderate", mp=[("hip_adduction", "primary")],
  ja=[("hip", "adduction", "primary")], tr=T_HOLD)
a("hip_flexion", "mobility_drill", SJ, "low", mp=[("hip_flexion", "primary")],
  ja=[("hip", "flexion", "primary")], tr=T_BAND)

# ----- core ----------------------------------------------------------------
a("crunch", "crunch", SJ, "low", mp=[("spinal_flexion", "primary")],
  ja=JA_SPINE_FLEX, tr=T_BW)
a("cable_crunch", "crunch", SJ, "low", mp=[("spinal_flexion", "primary")],
  ja=JA_SPINE_FLEX, tr=T_CBL)
a("leg_raise_hanging", "leg_raise", MJ, "moderate",
  mp=[("hip_flexion", "primary"), ("spinal_flexion", "secondary")],
  ja=[("hip", "flexion", "primary"), ("spine", "flexion", "secondary")], tr=T_BW)
a("ab_wheel", "ab_wheel", MJ, "high", mp=[("anti_extension", "primary")],
  ja=[("spine", "anti_extension", "primary")], tr=T_BW)
a("plank", "plank", MJ, "low", mp=[("anti_extension", "primary")],
  ja=[("spine", "anti_extension", "primary")], tr=T_HOLD)
a("pallof_press", "pallof_press", MJ, "low", mp=[("anti_rotation", "primary")],
  ja=[("spine", "anti_rotation", "primary")], tr=T_CBL1)
a("russian_twist", "woodchop", MJ, "low", mp=[("rotation", "primary")],
  ja=[("spine", "rotation", "primary")], tr=T_HOLDW)
a("woodchop", "woodchop", MJ, "moderate", mp=[("rotation", "primary")],
  ja=[("spine", "rotation", "primary")], tr=T_CBL1)
a("rotation_twist", "woodchop", MJ, "low", mp=[("rotation", "primary")],
  ja=[("spine", "rotation", "primary")], tr=T_HOLDW)
a("side_bend", "side_bend", SJ, "low", mp=[("lateral_flexion", "primary")],
  ja=[("spine", "lateral_flexion", "primary")], tr=T_DB1)
a("hollow_hold", "hollow_hold", MJ, "moderate", mp=[("anti_extension", "primary")],
  ja=[("spine", "anti_extension", "primary")], tr=T_HOLD)
a("superman", "back_extension", SJ, "low", mp=[("spinal_extension", "primary")],
  ja=JA_SPINE_EXT, tr=T_BW)
a("dragon_flag", "dragon_flag", MJ, "high", mp=[("anti_extension", "primary")],
  ja=[("spine", "anti_extension", "primary")], tr=T_BW)
a("l_sit", "l_sit", MJ, "high", mp=[("hip_flexion", "primary")],
  ja=[("hip", "flexion", "primary")], tr=T_HOLD)

# ----- neck / grip / forearm ----------------------------------------------
a("neck_machine", "neck_work", SJ, "low", mp=[("neck", "primary")],
  ja=[("neck", "flexion", "primary")], tr=T_MCH)
a("neck_band", "neck_work", SJ, "low", mp=[("neck", "primary")],
  ja=[("neck", "flexion", "primary")], tr=T_BAND)
a("grip_hold", "grip_hold", SJ, "low", mp=[("grip", "primary")],
  ja=[("hand", "grip", "primary")], tr=T_HOLDW)
a("wrist_roller", "wrist_curl", SJ, "low", mp=[("wrist_flexion", "primary")],
  ja=[("wrist", "flexion", "primary")], tr=T_HOLDW)
a("carry", "carry", MJ, "low", mp=[("carry", "primary"), ("grip", "secondary")],
  ja=[("hand", "grip", "primary"), ("spine", "anti_flexion", "secondary")], tr=T_CARRY)
a("carry_overhead", "carry", MJ, "moderate",
  mp=[("carry", "primary"), ("vertical_press", "secondary")],
  ja=[("shoulder", "flexion", "primary"), ("spine", "anti_extension", "secondary")],
  tr=T_CARRY1)

# ----- gymnastics ----------------------------------------------------------
a("lever_hold", "gymnastic_lever", MJ, "high", mp=[("anti_extension", "primary")],
  ja=[("shoulder", "extension", "primary")], tr=T_HOLD)
a("planche", "planche", MJ, "high", mp=[("anti_extension", "primary")],
  ja=[("shoulder", "flexion", "primary")], tr=T_HOLD)
a("front_lever_row", "gymnastic_lever", MJ, "high", mp=[("horizontal_pull", "primary")],
  ja=JA_HORIZ_PULL, tr=T_BW)
a("handstand_hold", "handstand", MJ, "high", mp=[("vertical_press", "primary")],
  ja=[("shoulder", "flexion", "primary")], tr=T_HOLD)
a("skin_the_cat", "gymnastic_lever", MJ, "high", mp=[("shoulder_extension", "primary")],
  ja=[("shoulder", "extension", "primary")], tr=T_REPS)
a("rope_climb", "pull_up", MJ, "high", mp=[("vertical_pull", "primary")],
  ja=JA_VERT_PULL, tr=T_REPS)

# ----- power / conditioning / mobility -------------------------------------
a("olympic_lift", "olympic_lift", MJ, "high",
  mp=[("hip_hinge", "primary"), ("vertical_press", "secondary")], ja=JA_HINGE, tr=T_BB)
a("plyometric", "plyometric_jump", MJ, "moderate", kind="conditioning",
  mp=[("jump", "primary")], ja=JA_SQUAT, tr=T_REPS)
a("throw", "throw", MJ, "moderate", kind="conditioning",
  mp=[("rotation", "primary")], ja=[("spine", "rotation", "primary")], tr=T_REPS)
a("sled", "sled", MJ, "low", kind="conditioning",
  mp=[("locomotion", "primary")], ja=JA_SQUAT, tr=T_CARRY)
a("cardio_cyclic", "cardio_machine", MJ, "low", kind="conditioning",
  mp=[("locomotion", "primary")], ja=[], tr=T_CARDIO)
a("crawl", "crawl", MJ, "moderate", kind="conditioning",
  mp=[("locomotion", "primary")], ja=[("spine", "anti_rotation", "primary")], tr=T_HOLD)
a("get_up", "get_up", MJ, "high", mp=[("carry", "primary")],
  ja=[("shoulder", "flexion", "primary")], tr=T_DB1)
a("mobility_drill", "mobility_drill", MJ, "low", kind="mobility",
  mp=[("locomotion", "primary")], ja=[], tr=T_REPS)
a("balance_drill", "balance_drill", MJ, "low", kind="mobility",
  mp=[("locomotion", "primary")], ja=[], tr=T_HOLD)
a("stretch", "stretch", MJ, "low", kind="mobility", mp=[], ja=[], tr=T_HOLD)
a("yoga_pose", "stretch", MJ, "low", kind="mobility", mp=[], ja=[], tr=T_HOLD)


# ---------------------------------------------------------------------------
# derived values
# ---------------------------------------------------------------------------
def tension_level(load):
    """Map a 0-100 relative external load onto the qualitative scale."""
    if load >= 78:
        return "high"
    if load >= 52:
        return "moderate"
    if load >= 22:
        return "low"
    return "none"


def tension_levels(spec, curve_points_fn):
    """Derive the three tension levels from the archetype's own numbers, so the
    qualitative profile cannot drift from the curve it came from."""
    points = curve_points_fn(spec)
    midrange = next(p["relative_load"] for p in points if abs(p["rom_pct"] - 50.0) < 0.01)
    return (tension_level(spec["ts"]), tension_level(midrange), tension_level(spec["tc"]))


def shift(level, steps):
    """Nudge a tension level by the archetype's per-muscle bias.

    Floored at "low" rather than "none": a muscle the exercise actually trains
    still receives some tension at every position it passes through, so a bias
    should skew the profile, never zero out an end of it.
    """
    order = ["none", "low", "moderate", "high"]
    shifted = order[max(0, min(len(order) - 1, order.index(level) + steps))]
    if shifted == "none" and level != "none":
        return "low"
    return shifted
