#!/usr/bin/env python3
"""
Generate the biomechanics enrichment seed for exercises.exercise_biomechanics
and the new exercises.exercise_muscle columns.

Every exercise in inj/sql/exercises/*.sql is classified into a movement
archetype (curated biomechanics), then emitted as idempotent UPSERT/UPDATE
statements keyed by exercise name.

Run:  python inj/_tools/gen_biomechanics_sql.py
Out:  inj/sql/05_biomechanics/biomechanics_seed.sql
      inj/_tools/biomechanics_coverage.md
"""
import json
import os
import pathlib
import re
import sys
from collections import Counter, OrderedDict

ROOT = pathlib.Path(__file__).resolve().parents[2]
SRC = ROOT / "inj" / "sql" / "exercises"
OUT_SQL = ROOT / "inj" / "sql" / "05_biomechanics" / "biomechanics_seed.sql"
OUT_REPORT = ROOT / "inj" / "_tools" / "biomechanics_coverage.md"

# --------------------------------------------------------------------------
# muscle groups -> muscle codes (must match inj/sql/00_reference/01_muscles.sql)
# --------------------------------------------------------------------------
GROUPS = {
    "biceps": ["biceps_brachii_long", "biceps_brachii_short"],
    "biceps_long": ["biceps_brachii_long"],
    "biceps_short": ["biceps_brachii_short"],
    "elbow_flex_other": ["brachialis", "brachioradialis"],
    "triceps_long": ["triceps_brachii_long"],
    "triceps_short": ["triceps_brachii_lateral", "triceps_brachii_medial"],
    "pecs": ["pectoralis_major_clavicular", "pectoralis_major_sternal", "pectoralis_minor"],
    "pec_upper": ["pectoralis_major_clavicular"],
    "pec_lower": ["pectoralis_major_sternal"],
    "delt_ant": ["deltoid_anterior"],
    "delt_lat": ["deltoid_lateral"],
    "delt_post": ["deltoid_posterior"],
    "lats": ["latissimus_dorsi", "teres_major"],
    "scapular": ["rhomboids", "trapezius_middle", "trapezius_lower"],
    "traps_upper": ["trapezius_upper"],
    "serratus": ["serratus_anterior"],
    "cuff": ["infraspinatus", "teres_minor", "supraspinatus", "subscapularis"],
    "quads": ["vastus_lateralis", "vastus_medialis", "vastus_intermedius"],
    "rectus_femoris": ["rectus_femoris"],
    "hams": ["biceps_femoris_long", "semimembranosus", "semitendinosus"],
    "hams_short": ["biceps_femoris_short"],
    "glutes": ["gluteus_maximus"],
    "abductors": ["gluteus_medius", "gluteus_minimus", "tensor_fasciae_latae"],
    "adductors": ["adductor_brevis", "adductor_longus", "adductor_magnus", "gracilis"],
    "hip_flexors": ["iliopsoas", "sartorius"],
    "gastroc": ["gastrocnemius_lateral", "gastrocnemius_medial"],
    "soleus": ["soleus"],
    "tibialis": ["tibialis_anterior"],
    "abs": ["rectus_abdominis", "transversus_abdominis"],
    "obliques": ["obliquus_externus", "obliquus_internus"],
    "spinal": ["erector_spinae", "multifidus"],
    "forearm_flex": ["forearm_flexors"],
    "forearm_ext": ["forearm_extensors"],
    # no dedicated codes in the live catalogue
    "forearm_rot": [],
    "neck": [],
    "ribcage": [],
}


def codes(*group_names):
    out = []
    for g in group_names:
        out.extend(GROUPS[g])
    return out


# --------------------------------------------------------------------------
# archetype catalogue
#   curve  : ascending | descending | bell | flat
#   peak   : rom_pct of peak external torque (0 = muscle fully lengthened)
#   ma     : moment arm profile + peak
#   src    : resistance source
#   stab   : stability demand      axial: spinal compression
#   sfr    : stimulus-to-fatigue 1..5 (5 = best)
#   bias   : default length_bias for the exercise
#   ts/tc  : residual load (0-100) at full stretch / full contraction
#   rs/rc  : % of the muscle's available ROM reached at the stretched /
#            contracted end
#   mb     : per-group length_bias overrides
#   joints : joint_position_bias
#   conf   : curated | modeled | estimated
# --------------------------------------------------------------------------
A = OrderedDict()


def arch(key, **kw):
    kw.setdefault("ma", ("bell", kw.get("peak", 50)))
    kw.setdefault("stab", "moderate")
    kw.setdefault("axial", "low")
    kw.setdefault("sfr", 3)
    kw.setdefault("mb", {})
    kw.setdefault("joints", None)
    kw.setdefault("conf", "modeled")
    kw.setdefault("rs", 90)
    kw.setdefault("rc", 90)
    A[key] = kw


# ----- ELBOW FLEXION (curls) --------------------------------------------
arch("curl_standing", curve="bell", peak=50, ma=("bell", 50), src="gravity",
     bias="mid_range", ts=30, tc=25, sfr=3, conf="curated",
     joints={"shoulder": "neutral"},
     mb={"lengthened": [], "shortened": []})
arch("curl_preacher", curve="ascending", peak=15, ma=("decreasing", 10), src="gravity",
     bias="lengthened", ts=95, tc=15, rs=95, rc=70, sfr=4, conf="curated",
     joints={"shoulder": "slight_flexion", "elbow": "supported"})
arch("curl_incline", curve="ascending", peak=20, ma=("decreasing", 15), src="gravity",
     bias="lengthened", ts=70, tc=20, rs=100, rc=75, sfr=4, conf="curated",
     joints={"shoulder": "extension"},
     mb={"lengthened": codes("biceps_long")})
arch("curl_bayesian", curve="flat", peak=35, ma=("constant", 35), src="cable",
     bias="lengthened", ts=88, tc=60, rs=100, rc=85, sfr=5, conf="curated",
     joints={"shoulder": "extension"},
     mb={"lengthened": codes("biceps_long")})
arch("curl_spider", curve="descending", peak=85, ma=("increasing", 85), src="gravity",
     bias="shortened", ts=15, tc=95, rs=65, rc=100, sfr=3, conf="curated",
     joints={"shoulder": "flexion"},
     mb={"shortened": codes("biceps_short")})
arch("curl_concentration", curve="bell", peak=45, ma=("bell", 45), src="gravity",
     bias="mid_range", ts=40, tc=40, sfr=3, conf="curated",
     joints={"shoulder": "slight_flexion"})
arch("curl_cable", curve="flat", peak=45, ma=("constant", 45), src="cable",
     bias="mid_range", ts=55, tc=55, sfr=4, conf="curated")
arch("curl_overhead_cable", curve="descending", peak=75, ma=("increasing", 75), src="cable",
     bias="shortened", ts=25, tc=90, rs=60, rc=100, sfr=3, conf="curated",
     joints={"shoulder": "abduction_flexion"})
arch("curl_machine", curve="flat", peak=50, ma=("constant", 50), src="cam_machine",
     bias="mid_range", ts=60, tc=60, stab="low", sfr=4)
arch("curl_band", curve="descending", peak=80, ma=("increasing", 80), src="band",
     bias="shortened", ts=20, tc=95, sfr=2)
arch("curl_drag", curve="bell", peak=40, ma=("bell", 40), src="gravity",
     bias="mid_range", ts=35, tc=45, rc=70, sfr=3,
     joints={"shoulder": "extension"})
arch("curl_reverse", curve="bell", peak=50, ma=("bell", 50), src="gravity",
     bias="mid_range", ts=30, tc=25, sfr=3,
     mb={"mid_range": codes("elbow_flex_other")})
arch("curl_wrist", curve="bell", peak=45, ma=("bell", 45), src="gravity",
     bias="mid_range", ts=45, tc=40, stab="low", sfr=3)
arch("curl_sprinter", curve="ascending", peak=25, ma=("decreasing", 20), src="gravity",
     bias="lengthened", ts=65, tc=25, sfr=4, joints={"shoulder": "extension"})

# ----- ELBOW EXTENSION (triceps) ----------------------------------------
arch("tri_pushdown", curve="descending", peak=80, ma=("increasing", 80), src="cable",
     bias="shortened", ts=35, tc=90, rs=55, rc=100, sfr=3, conf="curated",
     joints={"shoulder": "neutral"},
     mb={"shortened": codes("triceps_short")})
arch("tri_overhead", curve="ascending", peak=20, ma=("decreasing", 15), src="gravity",
     bias="lengthened", ts=90, tc=25, rs=100, rc=80, sfr=5, conf="curated",
     joints={"shoulder": "flexion"},
     mb={"lengthened": codes("triceps_long")})
arch("tri_overhead_cable", curve="flat", peak=30, ma=("constant", 30), src="cable",
     bias="lengthened", ts=85, tc=55, rs=100, rc=85, sfr=5, conf="curated",
     joints={"shoulder": "flexion"},
     mb={"lengthened": codes("triceps_long")})
arch("tri_skullcrusher", curve="ascending", peak=25, ma=("decreasing", 20), src="gravity",
     bias="lengthened", ts=85, tc=20, rs=95, rc=75, sfr=4, conf="curated",
     joints={"shoulder": "flexion"},
     mb={"lengthened": codes("triceps_long")})
arch("tri_kickback", curve="descending", peak=90, ma=("increasing", 90), src="gravity",
     bias="shortened", ts=10, tc=100, rs=45, rc=100, sfr=2, conf="curated",
     joints={"shoulder": "extension"})
arch("tri_dip", curve="ascending", peak=15, ma=("decreasing", 15), src="bodyweight_leverage",
     bias="lengthened", ts=90, tc=45, rs=95, rc=90, stab="high", sfr=4, conf="curated")
arch("tri_close_press", curve="ascending", peak=20, ma=("decreasing", 20), src="gravity",
     bias="lengthened", ts=90, tc=35, axial="low", sfr=4)
arch("tri_band_pushdown", curve="descending", peak=85, ma=("increasing", 85), src="band",
     bias="shortened", ts=20, tc=95, sfr=2)
arch("tri_bodyweight_ext", curve="ascending", peak=25, ma=("decreasing", 20),
     src="bodyweight_leverage", bias="lengthened", ts=85, tc=30, stab="high", sfr=3)

# ----- HORIZONTAL PUSH ---------------------------------------------------
arch("bench_flat", curve="ascending", peak=15, ma=("decreasing", 15), src="gravity",
     bias="lengthened", ts=90, tc=35, rs=85, rc=85, stab="moderate", axial="low",
     sfr=4, conf="curated",
     mb={"lengthened": codes("pecs"), "mid_range": codes("delt_ant")})
arch("bench_incline", curve="ascending", peak=18, ma=("decreasing", 18), src="gravity",
     bias="lengthened", ts=88, tc=35, sfr=4, conf="curated",
     mb={"lengthened": codes("pec_upper")})
arch("bench_decline", curve="ascending", peak=20, ma=("decreasing", 20), src="gravity",
     bias="lengthened", ts=85, tc=35, sfr=3,
     mb={"lengthened": codes("pec_lower")})
arch("bench_floor", curve="ascending", peak=30, ma=("decreasing", 30), src="gravity",
     bias="mid_range", ts=70, tc=35, rs=60, rc=85, sfr=3,
     mb={"mid_range": codes("pecs")})
arch("bench_machine", curve="flat", peak=35, ma=("constant", 35), src="cam_machine",
     bias="mid_range", ts=70, tc=60, stab="low", sfr=4)
arch("bench_smith", curve="ascending", peak=18, ma=("decreasing", 18), src="gravity",
     bias="lengthened", ts=88, tc=35, stab="low", sfr=4)
arch("press_cable_chest", curve="flat", peak=40, ma=("constant", 40), src="cable",
     bias="mid_range", ts=70, tc=70, sfr=4)
arch("pushup", curve="ascending", peak=15, ma=("decreasing", 15),
     src="bodyweight_leverage", bias="lengthened", ts=88, tc=30, stab="moderate",
     sfr=3, conf="curated")
arch("pushup_deficit", curve="ascending", peak=10, ma=("decreasing", 10),
     src="bodyweight_leverage", bias="lengthened", ts=95, tc=30, rs=100, sfr=4)
arch("fly_dumbbell", curve="ascending", peak=10, ma=("decreasing", 5), src="gravity",
     bias="lengthened", ts=100, tc=5, rs=100, rc=55, sfr=3, conf="curated",
     mb={"lengthened": codes("pecs")})
arch("fly_cable", curve="flat", peak=25, ma=("constant", 25), src="cable",
     bias="lengthened", ts=90, tc=75, rs=100, rc=95, sfr=5, conf="curated",
     mb={"lengthened": codes("pecs")})
arch("fly_machine", curve="flat", peak=40, ma=("constant", 40), src="cam_machine",
     bias="mid_range", ts=75, tc=70, stab="low", sfr=4)
arch("fly_band", curve="descending", peak=80, ma=("increasing", 80), src="band",
     bias="shortened", ts=20, tc=95, sfr=2)
arch("svend_press", curve="descending", peak=85, ma=("increasing", 85), src="isometric_external",
     bias="shortened", ts=15, tc=95, rs=30, rc=100, sfr=2)

# ----- VERTICAL PUSH -----------------------------------------------------
arch("ohp_standing", curve="ascending", peak=20, ma=("decreasing", 20), src="gravity",
     bias="lengthened", ts=90, tc=35, stab="high", axial="high", sfr=3, conf="curated")
arch("ohp_seated", curve="ascending", peak=20, ma=("decreasing", 20), src="gravity",
     bias="lengthened", ts=90, tc=35, stab="moderate", axial="moderate", sfr=4)
arch("ohp_machine", curve="flat", peak=35, ma=("constant", 35), src="cam_machine",
     bias="mid_range", ts=70, tc=60, stab="low", axial="low", sfr=4)
arch("ohp_landmine", curve="ascending", peak=25, ma=("decreasing", 25), src="gravity",
     bias="lengthened", ts=80, tc=45, stab="high", axial="moderate", sfr=3)
arch("hspu", curve="ascending", peak=15, ma=("decreasing", 15), src="bodyweight_leverage",
     bias="lengthened", ts=90, tc=35, stab="high", axial="moderate", sfr=3)
arch("pike_pushup", curve="ascending", peak=18, ma=("decreasing", 18),
     src="bodyweight_leverage", bias="lengthened", ts=88, tc=35, stab="high", sfr=3)
arch("push_jerk", curve="ascending", peak=15, ma=("decreasing", 15), src="gravity",
     bias="mid_range", ts=85, tc=30, stab="high", axial="high", sfr=2)

# ----- SHOULDER ISOLATION -----------------------------------------------
arch("lateral_raise_db", curve="descending", peak=85, ma=("increasing", 85), src="gravity",
     bias="shortened", ts=10, tc=100, rs=45, rc=100, sfr=3, conf="curated",
     mb={"shortened": codes("delt_lat")})
arch("lateral_raise_cable", curve="flat", peak=55, ma=("constant", 55), src="cable",
     bias="mid_range", ts=70, tc=85, rs=90, rc=100, sfr=5, conf="curated",
     mb={"lengthened": codes("delt_lat")})
arch("lateral_raise_machine", curve="flat", peak=50, ma=("constant", 50), src="cam_machine",
     bias="mid_range", ts=70, tc=75, stab="low", sfr=4)
arch("front_raise", curve="descending", peak=80, ma=("increasing", 80), src="gravity",
     bias="shortened", ts=15, tc=95, sfr=2)
arch("rear_delt_fly_db", curve="descending", peak=85, ma=("increasing", 85), src="gravity",
     bias="shortened", ts=10, tc=100, rs=45, rc=100, sfr=3,
     mb={"shortened": codes("delt_post")})
arch("rear_delt_cable", curve="flat", peak=55, ma=("constant", 55), src="cable",
     bias="mid_range", ts=70, tc=85, sfr=4)
arch("rear_delt_machine", curve="flat", peak=50, ma=("constant", 50), src="cam_machine",
     bias="mid_range", ts=70, tc=75, stab="low", sfr=4)
arch("face_pull", curve="descending", peak=75, ma=("constant", 60), src="cable",
     bias="shortened", ts=45, tc=90, sfr=4)
arch("band_pull_apart", curve="descending", peak=85, ma=("increasing", 85), src="band",
     bias="shortened", ts=20, tc=95, sfr=3)
arch("upright_row", curve="descending", peak=75, ma=("increasing", 75), src="gravity",
     bias="shortened", ts=25, tc=90, sfr=2)
arch("shrug", curve="descending", peak=85, ma=("increasing", 80), src="gravity",
     bias="shortened", ts=40, tc=95, rs=70, rc=100, axial="moderate", sfr=3)
arch("cuff_rotation", curve="descending", peak=70, ma=("increasing", 70), src="cable",
     bias="shortened", ts=35, tc=85, stab="low", sfr=3)
arch("cuff_rotation_band", curve="descending", peak=85, ma=("increasing", 85), src="band",
     bias="shortened", ts=20, tc=95, stab="low", sfr=2)

# ----- VERTICAL PULL -----------------------------------------------------
arch("pullup", curve="ascending", peak=20, ma=("decreasing", 20), src="bodyweight_leverage",
     bias="lengthened", ts=85, tc=45, rs=95, rc=85, stab="moderate", sfr=4, conf="curated",
     mb={"lengthened": codes("lats")})
arch("chinup", curve="ascending", peak=22, ma=("decreasing", 22), src="bodyweight_leverage",
     bias="lengthened", ts=85, tc=50, stab="moderate", sfr=4, conf="curated",
     mb={"lengthened": codes("lats"), "mid_range": codes("biceps")})
arch("lat_pulldown", curve="ascending", peak=30, ma=("decreasing", 30), src="cable",
     bias="lengthened", ts=80, tc=60, rs=95, rc=85, stab="low", sfr=4, conf="curated",
     mb={"lengthened": codes("lats")})
arch("straight_arm_pulldown", curve="bell", peak=45, ma=("bell", 45), src="cable",
     bias="lengthened", ts=75, tc=65, rs=95, rc=90, sfr=4,
     mb={"lengthened": codes("lats")})
arch("pullover_db", curve="ascending", peak=15, ma=("decreasing", 12), src="gravity",
     bias="lengthened", ts=95, tc=15, rs=100, rc=60, sfr=4, conf="curated",
     mb={"lengthened": codes("lats", "pecs")})
arch("pullover_machine", curve="flat", peak=35, ma=("constant", 35), src="cam_machine",
     bias="lengthened", ts=85, tc=70, stab="low", sfr=5)
arch("hang_passive", curve="flat", peak=0, ma=("constant", 0), src="isometric_external",
     bias="lengthened", ts=100, tc=0, rs=100, rc=0, sfr=3)

# ----- HORIZONTAL PULL ---------------------------------------------------
arch("row_barbell", curve="descending", peak=70, ma=("bell", 55), src="gravity",
     bias="mid_range", ts=55, tc=85, stab="high", axial="high", sfr=3, conf="curated")
arch("row_dumbbell", curve="descending", peak=70, ma=("bell", 55), src="gravity",
     bias="mid_range", ts=55, tc=85, stab="moderate", axial="moderate", sfr=4)
arch("row_chest_supported", curve="descending", peak=70, ma=("bell", 55), src="gravity",
     bias="mid_range", ts=55, tc=85, stab="low", axial="none", sfr=5, conf="curated")
arch("row_cable", curve="flat", peak=55, ma=("constant", 50), src="cable",
     bias="mid_range", ts=70, tc=80, stab="low", sfr=5, conf="curated")
arch("row_machine", curve="flat", peak=50, ma=("constant", 50), src="cam_machine",
     bias="mid_range", ts=70, tc=75, stab="low", sfr=5)
arch("row_inverted", curve="descending", peak=75, ma=("increasing", 75),
     src="bodyweight_leverage", bias="shortened", ts=45, tc=90, stab="high", sfr=3)
arch("row_landmine", curve="descending", peak=65, ma=("bell", 55), src="gravity",
     bias="mid_range", ts=60, tc=85, stab="high", axial="moderate", sfr=4)

# ----- SQUAT PATTERN -----------------------------------------------------
arch("squat_back", curve="ascending", peak=10, ma=("decreasing", 10), src="gravity",
     bias="lengthened", ts=100, tc=20, rs=90, rc=80, stab="high", axial="high",
     sfr=3, conf="curated",
     mb={"lengthened": codes("quads", "glutes")})
arch("squat_front", curve="ascending", peak=10, ma=("decreasing", 10), src="gravity",
     bias="lengthened", ts=100, tc=20, stab="high", axial="high", sfr=3, conf="curated",
     mb={"lengthened": codes("quads")})
arch("squat_hack", curve="ascending", peak=12, ma=("decreasing", 12), src="cam_machine",
     bias="lengthened", ts=95, tc=30, stab="low", axial="moderate", sfr=5, conf="curated",
     mb={"lengthened": codes("quads")})
arch("leg_press", curve="ascending", peak=12, ma=("decreasing", 12), src="cam_machine",
     bias="lengthened", ts=95, tc=25, stab="low", axial="low", sfr=5, conf="curated",
     mb={"lengthened": codes("quads")})
arch("squat_bodyweight", curve="ascending", peak=12, ma=("decreasing", 12),
     src="bodyweight_leverage", bias="lengthened", ts=95, tc=20, stab="moderate",
     axial="low", sfr=3)
arch("split_squat", curve="ascending", peak=12, ma=("decreasing", 12), src="gravity",
     bias="lengthened", ts=98, tc=20, stab="high", axial="moderate", sfr=4, conf="curated",
     mb={"lengthened": codes("quads", "glutes")})
arch("lunge", curve="ascending", peak=15, ma=("decreasing", 15), src="gravity",
     bias="lengthened", ts=95, tc=25, stab="high", axial="moderate", sfr=3)
arch("step_up", curve="ascending", peak=15, ma=("decreasing", 15), src="gravity",
     bias="lengthened", ts=90, tc=30, stab="high", axial="moderate", sfr=3)
arch("pistol_squat", curve="ascending", peak=10, ma=("decreasing", 10),
     src="bodyweight_leverage", bias="lengthened", ts=100, tc=20, stab="high", sfr=2)
arch("sissy_squat", curve="ascending", peak=15, ma=("decreasing", 15),
     src="bodyweight_leverage", bias="lengthened", ts=95, tc=30, stab="high", sfr=4,
     mb={"lengthened": codes("rectus_femoris", "quads")})
arch("leg_extension", curve="descending", peak=80, ma=("increasing", 75), src="cam_machine",
     bias="shortened", ts=40, tc=95, rs=70, rc=100, stab="low", axial="none",
     sfr=4, conf="curated",
     mb={"shortened": codes("quads"), "mid_range": codes("rectus_femoris")})
arch("wall_sit", curve="flat", peak=50, ma=("constant", 50), src="isometric_external",
     bias="mid_range", ts=60, tc=60, stab="low", sfr=3)

# ----- HIP HINGE ---------------------------------------------------------
arch("deadlift_conventional", curve="ascending", peak=10, ma=("decreasing", 10), src="gravity",
     bias="lengthened", ts=100, tc=20, rs=80, rc=85, stab="high", axial="high",
     sfr=2, conf="curated")
arch("deadlift_sumo", curve="ascending", peak=12, ma=("decreasing", 12), src="gravity",
     bias="lengthened", ts=100, tc=20, stab="high", axial="high", sfr=2)
arch("rdl", curve="ascending", peak=8, ma=("decreasing", 8), src="gravity",
     bias="lengthened", ts=100, tc=15, rs=100, rc=60, stab="high", axial="high",
     sfr=4, conf="curated",
     mb={"lengthened": codes("hams", "glutes")})
arch("good_morning", curve="ascending", peak=8, ma=("decreasing", 8), src="gravity",
     bias="lengthened", ts=100, tc=15, stab="high", axial="high", sfr=3,
     mb={"lengthened": codes("hams")})
arch("back_extension", curve="descending", peak=80, ma=("increasing", 75), src="gravity",
     bias="shortened", ts=45, tc=95, stab="moderate", axial="moderate", sfr=3)
arch("hip_thrust", curve="descending", peak=90, ma=("increasing", 85), src="gravity",
     bias="shortened", ts=20, tc=100, rs=50, rc=100, stab="moderate", axial="low",
     sfr=4, conf="curated",
     mb={"shortened": codes("glutes")})
arch("glute_bridge", curve="descending", peak=90, ma=("increasing", 85), src="gravity",
     bias="shortened", ts=25, tc=100, rs=45, rc=100, stab="low", sfr=3,
     mb={"shortened": codes("glutes")})
arch("kb_swing", curve="ascending", peak=20, ma=("decreasing", 20), src="gravity",
     bias="lengthened", ts=90, tc=40, stab="high", axial="moderate", sfr=2)
arch("pull_through", curve="flat", peak=45, ma=("constant", 45), src="cable",
     bias="lengthened", ts=85, tc=70, stab="moderate", axial="low", sfr=4)
arch("kickback_glute", curve="descending", peak=85, ma=("increasing", 85), src="cable",
     bias="shortened", ts=25, tc=95, stab="moderate", sfr=3)
arch("reverse_hyper", curve="descending", peak=80, ma=("increasing", 80), src="gravity",
     bias="shortened", ts=35, tc=95, stab="low", axial="none", sfr=4)

# ----- KNEE FLEXION ------------------------------------------------------
arch("leg_curl_lying", curve="descending", peak=70, ma=("increasing", 65), src="cam_machine",
     bias="mid_range", ts=50, tc=90, stab="low", axial="none", sfr=4, conf="curated",
     joints={"hip": "extension"},
     mb={"shortened": codes("hams")})
arch("leg_curl_seated", curve="descending", peak=65, ma=("increasing", 60), src="cam_machine",
     bias="lengthened", ts=75, tc=85, rs=100, rc=90, stab="low", axial="none",
     sfr=5, conf="curated",
     joints={"hip": "flexion"},
     mb={"lengthened": codes("hams")})
arch("nordic_curl", curve="ascending", peak=15, ma=("decreasing", 15),
     src="bodyweight_leverage", bias="lengthened", ts=100, tc=25, rs=100, rc=60,
     stab="high", sfr=4, conf="curated",
     mb={"lengthened": codes("hams")})
arch("slider_leg_curl", curve="ascending", peak=25, ma=("decreasing", 25),
     src="bodyweight_leverage", bias="lengthened", ts=85, tc=45, stab="high", sfr=3)
arch("leg_curl_band", curve="descending", peak=85, ma=("increasing", 85), src="band",
     bias="shortened", ts=20, tc=95, stab="low", sfr=2)

# ----- CALVES ------------------------------------------------------------
arch("calf_raise_standing", curve="ascending", peak=15, ma=("decreasing", 15), src="gravity",
     bias="lengthened", ts=95, tc=35, rs=100, rc=95, stab="moderate", axial="moderate",
     sfr=4, conf="curated",
     joints={"knee": "extension"},
     mb={"lengthened": codes("gastroc")})
arch("calf_raise_seated", curve="ascending", peak=18, ma=("decreasing", 18), src="cam_machine",
     bias="lengthened", ts=92, tc=35, stab="low", axial="low", sfr=4, conf="curated",
     joints={"knee": "flexion"},
     mb={"lengthened": codes("soleus"), "mid_range": codes("gastroc")})
arch("calf_raise_leg_press", curve="ascending", peak=15, ma=("decreasing", 15),
     src="cam_machine", bias="lengthened", ts=95, tc=35, stab="low", axial="none", sfr=5)
arch("calf_raise_band", curve="descending", peak=85, ma=("increasing", 85), src="band",
     bias="shortened", ts=20, tc=95, sfr=2)
arch("tibialis_raise", curve="descending", peak=80, ma=("increasing", 80), src="gravity",
     bias="shortened", ts=30, tc=95, stab="low", sfr=3)

# ----- HIP ABD / ADD -----------------------------------------------------
arch("hip_abduction", curve="descending", peak=80, ma=("increasing", 80), src="cam_machine",
     bias="shortened", ts=35, tc=95, stab="low", sfr=4)
arch("hip_adduction", curve="ascending", peak=20, ma=("decreasing", 20), src="cam_machine",
     bias="lengthened", ts=90, tc=35, stab="low", sfr=4,
     mb={"lengthened": codes("adductors")})
arch("band_walk", curve="flat", peak=60, ma=("increasing", 70), src="band",
     bias="shortened", ts=40, tc=90, stab="moderate", sfr=3)
arch("copenhagen", curve="ascending", peak=20, ma=("decreasing", 20),
     src="bodyweight_leverage", bias="lengthened", ts=90, tc=40, stab="high", sfr=4,
     mb={"lengthened": codes("adductors")})

# ----- CORE --------------------------------------------------------------
arch("crunch", curve="descending", peak=70, ma=("increasing", 65), src="bodyweight_leverage",
     bias="shortened", ts=45, tc=90, rs=50, rc=100, stab="low", sfr=3)
arch("cable_crunch", curve="flat", peak=55, ma=("constant", 55), src="cable",
     bias="mid_range", ts=70, tc=85, stab="low", sfr=5, conf="curated")
arch("leg_raise_hanging", curve="descending", peak=70, ma=("bell", 55),
     src="bodyweight_leverage", bias="lengthened", ts=70, tc=85, rs=95, rc=90,
     stab="high", sfr=4, conf="curated")
arch("ab_wheel", curve="ascending", peak=10, ma=("decreasing", 10),
     src="bodyweight_leverage", bias="lengthened", ts=100, tc=20, rs=100, rc=50,
     stab="high", sfr=4, conf="curated",
     mb={"lengthened": codes("abs")})
arch("plank", curve="flat", peak=50, ma=("constant", 50), src="isometric_external",
     bias="mid_range", ts=60, tc=60, stab="high", sfr=2)
arch("pallof_press", curve="descending", peak=85, ma=("increasing", 85), src="cable",
     bias="mid_range", ts=40, tc=95, stab="high", sfr=3)
arch("russian_twist", curve="bell", peak=50, ma=("bell", 50), src="gravity",
     bias="mid_range", ts=55, tc=55, stab="moderate", sfr=2)
arch("woodchop", curve="flat", peak=55, ma=("constant", 55), src="cable",
     bias="mid_range", ts=65, tc=80, stab="high", sfr=3)
arch("hollow_hold", curve="flat", peak=50, ma=("constant", 50), src="isometric_external",
     bias="mid_range", ts=60, tc=60, stab="high", sfr=3)
arch("superman", curve="descending", peak=85, ma=("increasing", 85),
     src="bodyweight_leverage", bias="shortened", ts=25, tc=95, stab="low", sfr=2)
arch("dragon_flag", curve="ascending", peak=20, ma=("decreasing", 20),
     src="bodyweight_leverage", bias="lengthened", ts=95, tc=40, stab="high", sfr=3)
arch("l_sit", curve="flat", peak=60, ma=("constant", 60), src="isometric_external",
     bias="shortened", ts=45, tc=85, stab="high", sfr=3)

# ----- NECK --------------------------------------------------------------
arch("neck_machine", curve="flat", peak=50, ma=("constant", 50), src="cam_machine",
     bias="mid_range", ts=65, tc=70, stab="low", sfr=4)
arch("neck_band", curve="descending", peak=80, ma=("increasing", 80), src="band",
     bias="shortened", ts=25, tc=95, stab="low", sfr=2)

# ----- GRIP / FOREARM ----------------------------------------------------
arch("grip_hold", curve="flat", peak=50, ma=("constant", 50), src="isometric_external",
     bias="mid_range", ts=70, tc=70, stab="moderate", axial="moderate", sfr=3)
arch("carry", curve="flat", peak=50, ma=("constant", 50), src="isometric_external",
     bias="mid_range", ts=70, tc=70, stab="high", axial="moderate", sfr=3)
arch("wrist_roller", curve="flat", peak=50, ma=("constant", 50), src="gravity",
     bias="mid_range", ts=60, tc=60, stab="low", sfr=3)

# ----- GYMNASTIC STATIC HOLDS / LEVERS -----------------------------------
arch("lever_hold", curve="flat", peak=50, ma=("constant", 50), src="bodyweight_leverage",
     bias="mid_range", ts=65, tc=65, stab="high", sfr=3)
arch("planche", curve="flat", peak=55, ma=("constant", 55), src="bodyweight_leverage",
     bias="mid_range", ts=60, tc=70, stab="high", sfr=3)
arch("front_lever_row", curve="descending", peak=70, ma=("increasing", 70),
     src="bodyweight_leverage", bias="mid_range", ts=55, tc=90, stab="high", sfr=3)
arch("muscle_up", curve="ascending", peak=25, ma=("decreasing", 25),
     src="bodyweight_leverage", bias="lengthened", ts=85, tc=50, stab="high", sfr=2)
arch("handstand_hold", curve="flat", peak=50, ma=("constant", 50), src="isometric_external",
     bias="mid_range", ts=60, tc=60, stab="high", axial="moderate", sfr=2)
arch("scapular_pull", curve="descending", peak=80, ma=("increasing", 80),
     src="bodyweight_leverage", bias="shortened", ts=40, tc=95, stab="moderate", sfr=3)
arch("skin_the_cat", curve="ascending", peak=15, ma=("decreasing", 15),
     src="bodyweight_leverage", bias="lengthened", ts=95, tc=30, stab="high", sfr=2)
arch("rope_climb", curve="ascending", peak=30, ma=("decreasing", 30),
     src="bodyweight_leverage", bias="mid_range", ts=75, tc=55, stab="high", sfr=2)

# ----- OLYMPIC / POWER / CONDITIONING ------------------------------------
arch("olympic_lift", curve="ascending", peak=15, ma=("decreasing", 15), src="gravity",
     bias="lengthened", ts=95, tc=30, stab="high", axial="high", sfr=1, conf="estimated")
arch("plyometric", curve="ascending", peak=20, ma=("decreasing", 20),
     src="bodyweight_leverage", bias="lengthened", ts=90, tc=25, stab="high",
     axial="moderate", sfr=2, conf="estimated")
arch("cardio_cyclic", curve="flat", peak=50, ma=("constant", 50), src="hydraulic",
     bias="mid_range", ts=60, tc=60, stab="moderate", axial="low", sfr=2,
     conf="estimated")
arch("sled", curve="flat", peak=50, ma=("constant", 50), src="isometric_external",
     bias="mid_range", ts=65, tc=65, stab="high", axial="low", sfr=3)
arch("carry_overhead", curve="flat", peak=50, ma=("constant", 50), src="isometric_external",
     bias="shortened", ts=55, tc=80, stab="high", axial="high", sfr=3)
arch("crawl", curve="flat", peak=50, ma=("constant", 50), src="isometric_external",
     bias="mid_range", ts=60, tc=60, stab="high", sfr=2, conf="estimated")
arch("mobility_drill", curve="flat", peak=50, ma=("constant", 50), src="bodyweight_leverage",
     bias="mid_range", ts=55, tc=55, stab="moderate", sfr=2, conf="estimated")
arch("get_up", curve="flat", peak=50, ma=("constant", 50), src="isometric_external",
     bias="mid_range", ts=60, tc=70, stab="high", axial="moderate", sfr=2,
     conf="estimated")
arch("throw", curve="descending", peak=75, ma=("increasing", 70), src="gravity",
     bias="mid_range", ts=50, tc=85, stab="high", sfr=2, conf="estimated")

# ----- STRETCHING / MOBILITY --------------------------------------------
# a static stretch loads the muscle exclusively at maximum length: the
# "resistance curve" degenerates to a single point at rom_pct = 0.
arch("stretch", curve="ascending", peak=0, ma=("decreasing", 0),
     src="isometric_external", bias="lengthened", ts=100, tc=0, rs=100, rc=0,
     stab="low", axial="none", sfr=2, conf="estimated")
arch("yoga_pose", curve="flat", peak=25, ma=("constant", 25),
     src="isometric_external", bias="lengthened", ts=90, tc=30, rs=100, rc=30,
     stab="moderate", axial="none", sfr=2, conf="estimated")

# ----- MISSING PATTERNS FROM THE IMPORTED CATALOGUE ---------------------
arch("hip_flexion", curve="descending", peak=75, ma=("increasing", 75), src="band",
     bias="shortened", ts=30, tc=92, stab="moderate", sfr=3,
     mb={"shortened": codes("hip_flexors")})
arch("side_bend", curve="descending", peak=70, ma=("increasing", 65), src="gravity",
     bias="shortened", ts=45, tc=90, stab="moderate", axial="moderate", sfr=3,
     mb={"shortened": codes("obliques")})
arch("rotation_twist", curve="bell", peak=50, ma=("bell", 50), src="gravity",
     bias="mid_range", ts=55, tc=60, stab="moderate", axial="moderate", sfr=2,
     mb={"mid_range": codes("obliques")})
arch("tri_extension_lever", curve="flat", peak=45, ma=("constant", 45), src="cam_machine",
     bias="mid_range", ts=70, tc=70, stab="low", sfr=4)
arch("calf_machine_lever", curve="ascending", peak=15, ma=("decreasing", 15),
     src="cam_machine", bias="lengthened", ts=95, tc=35, stab="low", axial="none", sfr=5)
arch("dip_machine", curve="descending", peak=75, ma=("increasing", 70), src="cam_machine",
     bias="shortened", ts=40, tc=90, stab="low", sfr=4)
arch("scapula_dip", curve="descending", peak=80, ma=("increasing", 80),
     src="bodyweight_leverage", bias="shortened", ts=40, tc=95, stab="moderate", sfr=3)
arch("balance_drill", curve="flat", peak=50, ma=("constant", 50),
     src="isometric_external", bias="mid_range", ts=55, tc=55, stab="high", sfr=1,
     conf="estimated")

# --------------------------------------------------------------------------
# classification rules — ORDER MATTERS, first match wins
# --------------------------------------------------------------------------
RULES = [
    # ---- stretching & yoga must win over the movement patterns they name
    (r"\bstretch\b|\bstretches\b", "stretch"),
    (r"(yoga pose|upward facing dog|butterfly yoga|wide angle pose|"
     r"reclining big toe pose|pelvic tilt|spine twist|spine stretch|"
     r"iron cross stretch|world greatest)", "yoga_pose"),
    (r"^(roller|foam roller)\b|\broller (back|hip|side|seated)", "stretch"),
    (r"(ankle circles|wrist circles|standing calves$|hamstring stretch|"
     r"circles knee|hug keens|behind head chest)", "stretch"),

    # ---- ergometers / conditioning must win over the "row" pattern
    (r"(pacing row|steady state row|sprint row|rowing|row \(ergometer\)|ski erg|rowing machine|kayak)", "cardio_cyclic"),
    (r"(cable seated rear|seated rear lateral|rear lateral raise)", "rear_delt_cable"),
    (r"front chest squat", "squat_front"),
    # ---- a landmine chest press is a horizontal push, not an overhead one
    (r"landmine.*chest press", "bench_incline"),
    (r"rear delt row", "rear_delt_cable"),
    (r"(barbell|dumbbell|kettlebell|loaded).*sumo squat", "squat_back"),
    (r"^dumbbell .*\brow\b", "row_dumbbell"),
    # ---- imported catalogue: machines ("Lever ..."), explicit variants
    (r"^lever (chest press|standing chest press)", "bench_machine"),
    (r"^lever seated fly", "fly_machine"),
    (r"^lever seated reverse fly", "rear_delt_machine"),
    (r"^lever (calf press|rotary calf)", "calf_machine_lever"),
    (r"^lever triceps extension", "tri_extension_lever"),
    (r"^lever seated dip", "dip_machine"),
    (r"^lever hip extension", "back_extension"),
    (r"^lever gripper|weighted standing hand squeeze|finger curls", "grip_hold"),
    (r"^lever kneeling twist", "rotation_twist"),

    # ---- imported catalogue: triceps extension family
    (r"(lying|decline|on floor|across face|bench).*(triceps? extension|tricep extension)",
     "tri_skullcrusher"),
    (r"(french press|anti gravity press|lying close-?grip triceps|"
     r"back of the head tricep|barbell lying extension|"
     r"concentration extension)", "tri_skullcrusher"),
    (r"(seated|standing|kneeling|incline|supine|overhead).*(triceps? extension|"
     r"tricep extension)", "tri_overhead"),
    (r"triceps? extension|triceps press|elbow press", "tri_overhead"),
    (r"(reverse dip|one arm dip|elbow dips|impossible dips|exercise ball dip|"
     r"scapula dips|bench dip)", "tri_dip"),
    (r"scapula (push|dip)|scapular", "scapula_dip"),

    # ---- imported catalogue: shoulders
    (r"(rear delt(oid)? raise|reverse fly|deltoide posteriore|rear drive|"
     r"lying one arm deltoid rear|lateral bent-?over)", "rear_delt_fly_db"),
    (r"(y-?raise|t-?raise|incline shoulder raise|shoulder raises|iron cross|"
     r"around world|round arm|w-?press|scott press|dumbbell raise|"
     r"side lying one hand raise|standing alternate raise|alternating arm ups)",
     "lateral_raise_db"),
    (r"(forward raise|front shoulder raise|incline raise)", "front_raise"),
    (r"(alzate).*(deltoide|laterali)", "lateral_raise_db"),
    (r"(lying external shoulder rotation|external shoulder rotation)", "cuff_rotation"),
    (r"(z ?press|seesaw press|alternating press|bent press|windmill|"
     r"extended range one arm press|alternate side press|w-?press)", "ohp_seated"),
    (r"pin press overhead", "ohp_standing"),
    (r"pin press|smith reverse-?grip press", "bench_floor"),

    # ---- imported catalogue: chest / pressing
    (r"(dumbbell|ez bar)(?!.*fly).*(on exercise ball|hammer press|palms? in press|"
     r"one arm press|reverse grip press)", "bench_flat"),
    (r"(floor fly|isometric chest squeeze|push and pull bodyweight)", "fly_dumbbell"),
    (r"(distensioni|panca)", "bench_flat"),

    # ---- imported catalogue: core
    (r"(rollerout|roller ?out|abdominal fallout|wheel roll)", "ab_wheel"),
    (r"(side bend|side bent|lateral stretch|side bridge|londra|"
     r"side hip \(on parallel)", "side_bend"),
    (r"(twist|judo flip|landmine 180|spell caster|swing 360|"
     r"barbell skier|standing lift|cable standing lift)", "rotation_twist"),
    (r"(toe touch|cocoons|otis up|butt-?ups|elbow-?to-?knee|body-?up|"
     r"bottoms-?up|kick out sit|flexion leg sit|elbow to knee|"
     r"swimmer kicks|isometric wipers|pull-?in)", "crunch"),
    (r"(hip raise|leg-?hip raise|hanging pike|arm slingers|leg pull in)",
     "leg_raise_hanging"),
    (r"(front bridge|rear decline bridge|sphinx$|london bridge|^flag$|"
     r"suspended)", "plank"),
    (r"(bridge with outstretched|smith hip raise|hip lift|band hip lift|"
     r"bench hip extension|standing hip extension|bent-?over hip extension)",
     "glute_bridge"),
    (r"(band hip flexion|hip flexion|high knee against wall)", "hip_flexion"),

    # ---- imported catalogue: legs / misc
    (r"(sollevamento polpaccio|toe raise|standing calves)", "calf_raise_standing"),
    (r"(stacco rumeno)", "rdl"),
    (r"(stacco)", "deadlift_conventional"),
    (r"(pronazione|supinazione)", "curl_wrist"),
    (r"(lying femoral|platform slide|single leg platform)", "leg_curl_lying"),
    (r"(half knee bends|all fours squad)", "squat_bodyweight"),
    (r"(gironda sternum chin|gorilla chin|side-?to-?side chin|standing archer|"
     r"one hand pull up)", "chinup"),
    (r"(tire flip|kettlebell pirate|weighted kneeling step)", "get_up"),
    (r"(balance board|quick feet|ski step|back and forth step|elevator|"
     r"posterior step to overhead)", "balance_drill"),
    (r"(jump|jumps|inchworm|skater hops|high knee)", "plyometric"),
    (r"(cross trainer|elliptical|stepmill|treadmill|stationary bike|hands bike|"
     r"battling ropes|left hook|boxing)", "cardio_cyclic"),

    # ---- KNEE-flexion "curls" must be resolved BEFORE the elbow-flexion
    #      block: the qualifier ("Leg", "Nordic", "Swiss Ball") precedes the
    #      word "curl", so a lookahead on the curl rule cannot exclude them.
    (r"nordic", "nordic_curl"),
    (r"(slider|sliding|swiss ball|hamstring walkout|bridge curl|heel curl|"
     r"femoral|platform slide)", "slider_leg_curl"),
    (r"seated leg curl|single leg seated curl", "leg_curl_seated"),
    (r"(band|banded).*(leg curl|lying curl|standing leg curl)", "leg_curl_band"),
    (r"(leg curl|lying curl|glute-ham raise|hamstring curl|standing leg curl)",
     "leg_curl_lying"),

    # ---- curls (elbow flexion) — specific variants before the generic curl
    (r"\bbayesian curl", "curl_bayesian"),
    (r"\bpreacher curl", "curl_preacher"),
    (r"\bspider curl", "curl_spider"),
    (r"\bincline (dumbbell |sprinter )?curl", "curl_incline"),
    (r"\bsprinter curl", "curl_sprinter"),
    (r"\bconcentration curl", "curl_concentration"),
    (r"\bdrag curl", "curl_drag"),
    (r"\boverhead cable curl|\bhigh cable curl", "curl_overhead_cable"),
    (r"\b(reverse|zottman).*curl|\breverse (barbell|cable|dumbbell|ez bar) curl", "curl_reverse"),
    (r"(wrist curl|wrist roller|finger extension|pronation|towel curl|plate neck curl)", "curl_wrist"),
    (r"\bmachine curl", "curl_machine"),
    (r"\bband.*curl|\bdoorframe curl", "curl_band"),
    (r"\bcable.*curl", "curl_cable"),
    (r"\bhammer curl|\bcurl\b.*rope", "curl_standing"),
    (r"\b(21s|barbell|dumbbell|ez bar|kettlebell|simultaneous|supinating|alternating|"
     r"single arm|single-arm|wide grip ez|close grip ez|kb) .*curl\b", "curl_standing"),
    (r"\bbicep curl|\bcurl\b(?!.*(leg|ham|nordic|heel|slider|sliding|bridge|lever))", "curl_standing"),

    # ---- triceps
    (r"skull ?crusher|\bjm press|\btate press", "tri_skullcrusher"),
    (r"(cable|rope).*overhead.*(extension|tricep)", "tri_overhead_cable"),
    (r"overhead.*(tricep|extension)|triceps overhead", "tri_overhead"),
    (r"band.*(pushdown|push-down|tricep)", "tri_band_pushdown"),
    (r"(push-?down|pushdown)", "tri_pushdown"),
    (r"kickback", "tri_kickback"),
    (r"(bodyweight|wall) triceps extension", "tri_bodyweight_ext"),
    (r"(triceps dip machine|machine dip)", "tri_pushdown"),
    (r"(tricep|triceps|legs-extended|bench) dip|dip \(triceps", "tri_dip"),
    (r"close.?grip.*(bench|press|floor|decline|incline)", "tri_close_press"),

    # ---- chest
    (r"(dumbbell|decline dumbbell|incline dumbbell).*fly|\bflat fly", "fly_dumbbell"),
    (r"(pec deck|chest fly machine)", "fly_machine"),
    (r"(band|resistance band).*(fly|chest fly)", "fly_band"),
    (r"(cable).*(fly|crossover)|crossover", "fly_cable"),
    (r"ring fly", "fly_dumbbell"),
    (r"svend press", "svend_press"),
    (r"landmine.*(chest press|press)", "ohp_landmine"),
    (r"(machine|converging).*chest press|chest press machine", "bench_machine"),
    (r"smith machine.*(bench|incline|decline|close grip)", "bench_smith"),
    (r"floor press|larsen press|spoto press|board press|pin press \(chest", "bench_floor"),
    (r"incline.*(bench press|barbell press|dumbbell press|hex press|press)", "bench_incline"),
    (r"decline.*(bench|press)", "bench_decline"),
    (r"(cable|band).*(chest press|press)", "press_cable_chest"),
    (r"(bench press|competition bench|medium grip bench|wide grip bench|touch and go bench|"
     r"dead stop bench|slingshot bench|reverse grip bench|hex press|dumbbell press$|"
     r"neutral grip.*press)", "bench_flat"),
    (r"push[- ]?ups?\b", "pushup"),
    (r"(pull through|pull-through)", "pull_through"),
    (r"(lying|seated|standing|incline).*(extension|supination|rotate|alternate shoulder)", "tri_overhead"),
    (r"(seated curls|barbell lying lifting)", "curl_standing"),
    (r"(cross-?over)", "fly_cable"),
    (r"(heel touchers|exercise ball hug|lower body rotation|figure 8|march sit|one arm against wall|elbow lift)", "plank"),
    (r"(prone hamstring)", "stretch"),
    (r"chest squeeze press|ball squeeze|lying ball squeeze|seated ball squeeze", "svend_press"),
    (r"chest dip|straight bar dip|parallel bar dip|ring dip|korean dip|^dips?$|"
     r"assisted dip|weighted dip|band-assisted dip|dip \(parallel", "tri_dip"),

    # ---- shoulders
    (r"(cable).*lateral raise", "lateral_raise_cable"),
    (r"machine lateral raise", "lateral_raise_machine"),
    (r"lateral raise|plate raise", "lateral_raise_db"),
    (r"front raise", "front_raise"),
    (r"(cable|reverse pec deck).*(rear delt|fly)|reverse pec deck", "rear_delt_machine"),
    (r"rear delt fly|bent-over lateral raise|reverse snow angel|prone y raise", "rear_delt_fly_db"),
    (r"face pull", "face_pull"),
    (r"pull-?apart", "band_pull_apart"),
    (r"upright row|sdhp|sumo deadlift high pull|high pull", "upright_row"),
    (r"shrug", "shrug"),
    (r"(external|internal) rotation|cuban press", "cuff_rotation"),
    (r"(behind[- ]?(the[- ]?)?neck press|bradford press|arnold press|z-?press|"
     r"seated.*(press|strict press)|smith machine seated press)", "ohp_seated"),
    (r"(machine|plate loaded).*shoulder press|shoulder press machine", "ohp_machine"),
    (r"landmine.*press", "ohp_landmine"),
    (r"handstand push[- ]?up|hspu", "hspu"),
    (r"pike push[- ]?up", "pike_pushup"),
    (r"(push jerk|split jerk|push press|thruster|jerk)", "push_jerk"),
    (r"(overhead press|strict press|shoulder press|military press|"
     r"barbell overhead press|dumbbell overhead press|cable overhead press|"
     r"two-hand landmine press|tall-kneeling band press|bottom-up kettlebell press|"
     r"kettlebell press|rotating dumbbell press|single arm machine press)", "ohp_standing"),

    # ---- back
    (r"straight arm pulldown", "straight_arm_pulldown"),
    (r"machine pullover", "pullover_machine"),
    (r"(cable) pullover", "pullover_machine"),
    (r"pullover", "pullover_db"),
    (r"lat pulldown|pulldown", "lat_pulldown"),
    (r"muscle[- ]?up", "muscle_up"),
    (r"chin[- ]?up", "chinup"),
    (r"(pull[- ]?up|typewriter pull|archer pull|commando pull|one-arm pull)", "pullup"),
    (r"scapular (pull|retraction)|handstand shrug", "scapular_pull"),
    (r"skin the cat", "skin_the_cat"),
    (r"rope climb", "rope_climb"),
    (r"(dead hang|passive bar hang|active hang|active bar hang|fingertip hang|"
     r"false grip hang|towel hang|bar hang|support hold|hang$)", "hang_passive"),
    (r"front lever (row|curl)", "front_lever_row"),
    (r"(front lever|back lever|maltese)", "lever_hold"),
    (r"planche", "planche"),
    (r"(inverted row|australian pull[- ]?up|ring row|table row|doorframe row|"
     r"suspension row|explosive ring row|archer ring row|feet-elevated.*row)", "row_inverted"),
    (r"(chest.?supported|seal|pendlay chest)", "row_chest_supported"),
    (r"(machine row|hammer strength row)", "row_machine"),
    (r"(cable|low cable|high cable|wide grip cable).*row", "row_cable"),
    (r"landmine row", "row_landmine"),
    (r"(dumbbell row|kroc row|renegade row|single-arm.*row|pronated dumbbell row|"
     r"incline dumbbell row|bent-over dumbbell row)", "row_dumbbell"),
    (r"(row|pendlay|underhand barbell row)", "row_barbell"),

    # ---- legs: hinge
    (r"(romanian deadlift|rdl|stiff leg deadlift)", "rdl"),
    (r"good morning", "good_morning"),
    (r"reverse hyper", "reverse_hyper"),
    (r"(back extension|hyperextension|ghd (back|hip) extension)", "back_extension"),
    (r"hip thrust|frog pump", "hip_thrust"),
    (r"(glute bridge|hip bridge|bridge walkout|back bridge|wrestler bridge)", "glute_bridge"),
    (r"(kettlebell swing|kb swing)", "kb_swing"),
    (r"pull-?through", "pull_through"),
    (r"(glute kickback|cable kickback|donkey kick|fire hydrant|quadruped hip extension|"
     r"banded donkey|band kickback|kneeling cable kickback|standing cable kickback|"
     r"bent over cable kickback)", "kickback_glute"),
    (r"(deadlift|rack pull|block pull|clean pull|snatch pull)", "deadlift_conventional"),

    # ---- legs: knee flexion
    (r"nordic", "nordic_curl"),
    (r"(slider|sliding|swiss ball|hamstring walkout|bridge curl|heel curl|"
     r"single-leg.*curl)", "slider_leg_curl"),
    (r"seated leg curl|single leg seated curl", "leg_curl_seated"),
    (r"(band|banded).*(leg curl|lying curl|standing leg curl)", "leg_curl_band"),
    (r"(leg curl|lying curl|glute-ham raise|hamstring curl|standing leg curl)", "leg_curl_lying"),

    # ---- legs: knee extension / squat
    (r"leg extension|terminal knee extension|reverse leg extension", "leg_extension"),
    (r"sissy squat", "sissy_squat"),
    (r"leg press", "leg_press"),
    (r"hack squat", "squat_hack"),
    (r"(pistol|shrimp squat|skater squat|single-leg squat)", "pistol_squat"),
    (r"(bulgarian|split squat|front-foot elevated)", "split_squat"),
    (r"(lunge|curtsy)", "lunge"),
    (r"step-?up", "step_up"),
    (r"wall sit", "wall_sit"),
    (r"front squat|zombie front squat|box front squat", "squat_front"),
    (r"(air squat|bodyweight squat|hindu squat|pulse squat|goblet squat|"
     r"sumo squat|cossack squat|jump squat|squat jump|tempo squat)", "squat_bodyweight"),
    (r"(overhead squat|snatch balance)", "squat_front"),
    (r"squat", "squat_back"),

    # ---- calves / tibialis
    (r"tibialis", "tibialis_raise"),
    (r"(band|banded|resistance band).*calf raise", "calf_raise_band"),
    (r"seated calf raise|bent-knee calf raise", "calf_raise_seated"),
    (r"leg press calf raise", "calf_raise_leg_press"),
    (r"(calf raise|calf pulse|heel drop|toe walk|donkey calf|stair calf|"
     r"ankle plantarflexion|farmer walk on toes|sled toe push)", "calf_raise_standing"),

    # ---- hip abd/add
    (r"copenhagen", "copenhagen"),
    (r"(adduction|adductor)", "hip_adduction"),
    (r"(abduction|abductor|clamshell)", "hip_abduction"),
    (r"(lateral band walk|monster walk|band walk)", "band_walk"),

    # ---- core
    (r"ab wheel|rollout", "ab_wheel"),
    (r"(cable crunch|standing cable crunch|kneeling cable crunch|oblique cable crunch)",
     "cable_crunch"),
    (r"(hanging.*(leg|knee) raise|toes-?to-?bar|t2b|parallel bar leg raise|"
     r"l-sit.*leg raise|pike compression|seated pike lift|seated leg lift)",
     "leg_raise_hanging"),
    (r"dragon flag", "dragon_flag"),
    (r"(l-sit|v-sit|tuck l-sit|tuck v-sit)", "l_sit"),
    (r"(hollow|arch body|superman)", "hollow_hold"),
    (r"pallof", "pallof_press"),
    (r"woodchop", "woodchop"),
    (r"russian twist", "russian_twist"),
    (r"(plank|bird dog|dead bug|body saw|bear plank|shoulder tap|side plank)", "plank"),
    (r"(crunch|sit-?up|v-up|tuck-?up|flutter kick|scissor kick|leg raise|"
     r"reverse crunch|bicycle|butterfly sit)", "crunch"),
    (r"(mountain climber|wall slide|hip airplane|wall walk|wall march|"
     r"high-?knee march|ankling|high knees|boxer skip|foot skip)", "mobility_drill"),

    # ---- neck
    (r"neck (machine|harness)|4-way neck", "neck_machine"),
    (r"neck", "neck_band"),

    # ---- grip / carries
    (r"(plate pinch|fat bar hold|thick bar hold|axle deadlift hold|barbell hold|"
     r"grip trainer|deadlift hold|double overhand|hook grip|mixed grip|overhand grip)",
     "grip_hold"),
    (r"wrist roller", "wrist_roller"),
    (r"overhead (carry|farmer|hold)", "carry_overhead"),
    (r"(farmer|carry|suitcase|yoke)", "carry"),

    # ---- gymnastics / handstand
    (r"(handstand|press to handstand|pike hold)", "handstand_hold"),
    (r"ring support|turnout ring", "lever_hold"),

    # ---- power / olympic
    (r"(clean|snatch|jerk)", "olympic_lift"),
    (r"(box jump|broad jump|depth jump|tuck jump|pogo|bound|line hop|"
     r"jump lunge|split squat jump|single-leg hop|lateral jump)", "plyometric"),
    (r"(medicine ball|wall ball|slam|chest pass|plate halo|battle rope)", "throw"),
    (r"sled", "sled"),
    (r"(bear crawl|crawl)", "crawl"),
    (r"(turkish get-?up|get-?up)", "get_up"),
    (r"(run|sprint|jog|row \(ergometer\)|rowing|ski erg|assault bike|air bike|"
     r"jump rope|skipping|double.?under|single under|triple under|shuttle|"
     r"burpee|penguin jump|steady state|pacing row)", "cardio_cyclic"),
]

COMPILED = [(re.compile(p, re.I), a) for p, a in RULES]

# prefixes that do NOT change the biomechanics — stripped before matching
NEUTRAL_PREFIX = re.compile(
    r"^(tempo|paused|pause|weighted|slow|slow-eccentric|eccentric|negative|isometric|"
    r"alternating|simultaneous|assisted|band-assisted|counterbalance|box assisted|"
    r"timed|explosive|kipping|strict|advanced|full|partial|deep|long|short|"
    r"single|double|heavy|light|wall|rock)\s+", re.I)


def canonical(name):
    n = name.strip()
    for _ in range(4):
        n2 = NEUTRAL_PREFIX.sub("", n)
        if n2 == n:
            break
        n = n2
    return n


def classify(name):
    for probe in (name, canonical(name)):
        for rx, a in COMPILED:
            if rx.search(probe):
                return a
    return None


# --------------------------------------------------------------------------
# strength curve point synthesis
# --------------------------------------------------------------------------
def smoothstep(t):
    t = max(0.0, min(1.0, t))
    return t * t * (3 - 2 * t)


def curve_points(spec):
    peak = spec["peak"]
    ts, tc = spec["ts"], spec["tc"]
    pts = []
    for i in range(9):
        rom = i * 12.5
        if peak <= 0:
            load = tc + (100 - tc) * (1 - smoothstep(rom / 100.0))
        elif peak >= 100:
            load = ts + (100 - ts) * smoothstep(rom / 100.0)
        elif rom <= peak:
            load = ts + (100 - ts) * smoothstep(rom / peak)
        else:
            load = tc + (100 - tc) * (1 - smoothstep((rom - peak) / (100.0 - peak)))
        pts.append({"rom_pct": round(rom, 1), "relative_load": int(round(load))})
    return pts


# --------------------------------------------------------------------------
# collect exercise names
# --------------------------------------------------------------------------
INSERT_RX = re.compile(
    r"INSERT INTO exercises\.exercise\s*\(.*?\)\s*VALUES\s*\(\s*\w+\s*,\s*'((?:[^']|'')*)'",
    re.S)


def collect_names_from_files():
    names = []
    for f in sorted(SRC.rglob("*.sql")):
        txt = f.read_text(encoding="utf-8", errors="replace")
        for m in INSERT_RX.finditer(txt):
            names.append(m.group(1).replace("''", "'"))
    # preserve order, dedupe
    return list(OrderedDict.fromkeys(names))


def collect_names_from_db(dsn):
    """The live catalogue is larger than the seed files (imported exercises),
    so prefer the DB as the source of truth when a DSN is available."""
    import psycopg
    with psycopg.connect(dsn, connect_timeout=15) as conn:
        cur = conn.cursor()
        cur.execute("SELECT DISTINCT name FROM exercises.exercise "
                    "WHERE deleted_at IS NULL ORDER BY name")
        return [r[0] for r in cur.fetchall()]


def validate_muscle_codes(dsn):
    """The live catalogue has its own muscle vocabulary, which does NOT match
    inj/sql/00_reference/01_muscles.sql. A stale code here silently produces a
    no-op UPDATE, so fail loudly instead."""
    import psycopg
    with psycopg.connect(dsn, connect_timeout=15) as conn:
        cur = conn.cursor()
        cur.execute("SELECT code FROM exercises.muscle")
        known = {r[0] for r in cur.fetchall()}
    referenced = {c for group in GROUPS.values() for c in group}
    unknown = sorted(referenced - known)
    if unknown:
        raise SystemExit("unknown muscle codes in GROUPS: " + ", ".join(unknown))
    print(f"muscle codes validated ({len(referenced)} referenced, {len(known)} in DB)")


def collect_names():
    dsn = os.environ.get("COACHLY_BIOMECH_DSN")
    if "--dsn" in sys.argv:
        dsn = sys.argv[sys.argv.index("--dsn") + 1]
    if dsn:
        try:
            validate_muscle_codes(dsn)
            names = collect_names_from_db(dsn)
            print(f"source: database ({len(names)} names)")
            return names
        except Exception as exc:  # noqa: BLE001
            print(f"! DB unavailable ({exc}); falling back to seed files")
    names = collect_names_from_files()
    print(f"source: seed files ({len(names)} names)")
    return names


def q(s):
    return "'" + s.replace("'", "''") + "'"


def emit(names):
    lines = [
        "-- =============================================================",
        "-- Biomechanics seed  (GENERATED by inj/_tools/gen_biomechanics_sql.py)",
        "-- Do not edit by hand: edit the archetype catalogue and regenerate.",
        "-- Requires sql/2026-08-08_add_biomechanics.sql to have been applied.",
        "-- Idempotent: safe to re-run.",
        "-- =============================================================",
        "",
    ]
    stats = Counter()
    unmatched = []

    for name in names:
        key = classify(name)
        if key is None:
            unmatched.append(name)
            stats["<unmatched>"] += 1
            continue
        stats[key] += 1
        s = A[key]
        ma_profile, ma_peak = s["ma"]
        joints = "NULL" if not s["joints"] else q(json.dumps(s["joints"], separators=(",", ":")))
        pts = q(json.dumps(curve_points(s), separators=(",", ":")))
        note = f"archetype={key}"

        lines.append(f"-- {name}  [{key}]")
        lines.append(
            "INSERT INTO exercises.exercise_biomechanics (exercise_id, resistance_source,"
            " resistance_curve, peak_torque_rom_pct, moment_arm_profile,"
            " moment_arm_peak_rom_pct, stability_demand, axial_load, sfr_rating,"
            " joint_position_bias, strength_curve_points, data_confidence, source_note)\n"
            f"SELECT e.id, '{s['src']}', '{s['curve']}', {s['peak']}, '{ma_profile}',"
            f" {ma_peak}, '{s['stab']}', '{s['axial']}', {s['sfr']}, {joints}::jsonb,"
            f" {pts}::jsonb, '{s['conf']}', {q(note)}\n"
            f"FROM exercises.exercise e WHERE e.name = {q(name)}\n"
            "ON CONFLICT (exercise_id) DO UPDATE SET"
            " resistance_source = EXCLUDED.resistance_source,"
            " resistance_curve = EXCLUDED.resistance_curve,"
            " peak_torque_rom_pct = EXCLUDED.peak_torque_rom_pct,"
            " moment_arm_profile = EXCLUDED.moment_arm_profile,"
            " moment_arm_peak_rom_pct = EXCLUDED.moment_arm_peak_rom_pct,"
            " stability_demand = EXCLUDED.stability_demand,"
            " axial_load = EXCLUDED.axial_load,"
            " sfr_rating = EXCLUDED.sfr_rating,"
            " joint_position_bias = EXCLUDED.joint_position_bias,"
            " strength_curve_points = EXCLUDED.strength_curve_points,"
            " data_confidence = EXCLUDED.data_confidence,"
            " source_note = EXCLUDED.source_note,"
            " updated_at = NOW();")

        # default per-muscle bias for every muscle of this exercise
        lines.append(
            "UPDATE exercises.exercise_muscle em SET"
            f" length_bias = '{s['bias']}',"
            f" rom_stretch_pct = {s['rs']}, rom_contract_pct = {s['rc']},"
            f" tension_at_stretch = {s['ts']}, tension_at_contraction = {s['tc']}"
            f" FROM exercises.exercise e"
            f" WHERE em.exercise_id = e.id AND e.name = {q(name)};")

        # per-muscle-group overrides
        for bias, muscle_codes in s["mb"].items():
            if not muscle_codes:
                continue
            code_list = ",".join(q(c) for c in sorted(set(muscle_codes)))
            lines.append(
                f"UPDATE exercises.exercise_muscle em SET length_bias = '{bias}'"
                " FROM exercises.exercise e, exercises.muscle m"
                " WHERE em.exercise_id = e.id AND em.muscle_id = m.id"
                f" AND e.name = {q(name)} AND m.code IN ({code_list});")
        lines.append("")

    OUT_SQL.parent.mkdir(parents=True, exist_ok=True)
    OUT_SQL.write_text("\n".join(lines), encoding="utf-8")

    # ---- coverage report
    total = len(names)
    matched = total - len(unmatched)
    rep = [
        "# Biomechanics coverage",
        "",
        f"- exercises processed: **{total}**",
        f"- classified: **{matched}** ({matched * 100 // total}%)",
        f"- unmatched: **{len(unmatched)}**",
        f"- archetypes used: **{len([k for k in stats if k != '<unmatched>'])}** / {len(A)}",
        "",
        "## Archetype distribution",
        "",
        "| archetype | curve | peak_rom | bias | n |",
        "|---|---|---|---|---|",
    ]
    for k, n in stats.most_common():
        if k == "<unmatched>":
            continue
        s = A[k]
        rep.append(f"| `{k}` | {s['curve']} | {s['peak']} | {s['bias']} | {n} |")
    rep += ["", "## Unmatched exercises", ""]
    rep += [f"- {u}" for u in unmatched] or ["_none_"]
    OUT_REPORT.write_text("\n".join(rep) + "\n", encoding="utf-8")

    return total, matched, unmatched, stats


if __name__ == "__main__":
    names = collect_names()
    if not names:
        sys.exit("no exercises found under " + str(SRC))
    total, matched, unmatched, stats = emit(names)
    print(f"exercises: {total}  classified: {matched}  unmatched: {len(unmatched)}")
    print(f"archetypes used: {len([k for k in stats if k != '<unmatched>'])}/{len(A)}")
    print("wrote", OUT_SQL)
    print("wrote", OUT_REPORT)
    if unmatched:
        print("\nunmatched sample:")
        for u in unmatched[:40]:
            print("  -", u)
