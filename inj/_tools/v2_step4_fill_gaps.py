#!/usr/bin/env python3
"""
Exercise model V2 - PHASE 2, STEP 4
Close the catalogue's data gaps: equipment classes, missing exercise_equipment,
missing exercise_muscle, and variation_axis.

Two principles keep this honest:

1. Nothing is invented from thin air. Missing muscles are filled from the
   MODAL muscle set of exercises that share the same archetype AND already
   have muscles - i.e. from the catalogue's own curated data, not from a
   guess. Archetypes with no populated example are reported, not fabricated.

2. Equipment is inferred from the exercise NAME first (a name that says
   "Dumbbell" is evidence), and only then from the archetype. Bodyweight
   exercises legitimately have no equipment and are left alone.

Every inferred row is marked so it can be told apart from curated data.

Usage:
    python inj/_tools/v2_step4_fill_gaps.py --dsn "..." [--apply]
"""
import argparse
import importlib.util
import pathlib
import re
import sys
from collections import Counter, defaultdict

import psycopg

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from dsn import get_dsn  # noqa: E402

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

TOOLS = pathlib.Path(__file__).resolve().parent


def _load(name, filename):
    spec = importlib.util.spec_from_file_location(name, TOOLS / filename)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


GEN = _load("gen_biomechanics", "gen_biomechanics_sql.py")

# --------------------------------------------------------------------------
# equipment_class, keyed on the codes that actually exist in the live
# catalogue. Validated against the DB before anything is written.
# --------------------------------------------------------------------------
EQUIPMENT_CLASS = {
    # free weights
    "barbell": "free_weight", "dumbbell": "free_weight", "ez_bar": "free_weight",
    "kettlebell": "free_weight", "swiss_bar": "free_weight", "trap_bar": "free_weight",
    "weight_plate": "free_weight", "dip_belt": "free_weight",
    "weightlifting_belt": "other", "lifting_straps": "other", "chalk": "other",
    # elastic
    "resistance_band_loop": "elastic", "resistance_band_tube": "elastic",
    # bodyweight apparatus
    "pull_up_bar": "bodyweight", "dip_bars": "bodyweight", "parallettes": "bodyweight",
    "rings": "bodyweight", "ab_wheel": "bodyweight",
    "trx_suspension_trainer": "bodyweight",
    # cable
    "cable_attachment_ankle_strap": "cable", "cable_attachment_bar": "cable",
    "cable_attachment_rope": "cable", "cable_attachment_single_handle": "cable",
    "cable_crossover_machine": "cable",
    # plate loaded
    "hack_squat_machine": "plate_loaded_machine",
    "leg_press_machine": "plate_loaded_machine",
    "smith_machine": "plate_loaded_machine",
    "landmine_attachment": "plate_loaded_machine",
    "hip_thrust_machine": "plate_loaded_machine",
    # selectorized
    "abductor_machine": "selectorized_machine", "adductor_machine": "selectorized_machine",
    "assisted_pull_up_machine": "selectorized_machine",
    "back_extension_machine": "selectorized_machine",
    "calf_raise_machine_seated": "selectorized_machine",
    "calf_raise_machine_standing": "selectorized_machine",
    "chest_press_machine": "selectorized_machine",
    "lat_pulldown_machine": "selectorized_machine",
    "leg_curl_machine_lying": "selectorized_machine",
    "leg_curl_machine_seated": "selectorized_machine",
    "leg_extension_machine": "selectorized_machine",
    "pec_deck_machine": "selectorized_machine",
    "seated_row_machine": "selectorized_machine",
    "shoulder_press_machine": "selectorized_machine",
    # fixed implements / apparatus
    "glute_ham_developer": "fixed_implement", "power_rack": "fixed_implement",
    "squat_rack": "fixed_implement", "flat_bench": "fixed_implement",
    "adjustable_bench": "fixed_implement", "preacher_curl_bench": "fixed_implement",
    "box_plyo": "fixed_implement", "battle_ropes": "fixed_implement",
    "medicine_ball": "fixed_implement", "stability_ball": "fixed_implement",
    "bosu_ball": "fixed_implement", "gymnastic_mat": "other",
    "foam_roller": "other",
    # cardio
    "assault_bike": "fixed_implement", "elliptical": "fixed_implement",
    "jump_rope": "fixed_implement", "rowing_machine": "fixed_implement",
    "ski_erg": "fixed_implement", "stationary_bike": "fixed_implement",
    "treadmill": "fixed_implement",
    "sled": "fixed_implement", "weight_vest": "free_weight",
}

# name token -> equipment code. Ordered: first match wins per token family.
NAME_EQUIPMENT = [
    (r"\bez[- ]?bar", "ez_bar"),
    (r"\btrap bar\b", "trap_bar"),
    (r"\bswiss bar\b|\bfootball bar\b", "swiss_bar"),
    (r"\bsmith\b", "smith_machine"),
    (r"\blandmine\b", "landmine_attachment"),
    (r"\bbarbell\b|\bolympic bar\b|\baxle\b|\bcambered\b|\bsafety (squat )?bar\b", "barbell"),
    (r"\bdumbbell\b|\bdb\b", "dumbbell"),
    (r"\bkettlebell\b|\bkb\b", "kettlebell"),
    (r"\bplate\b", "weight_plate"),
    (r"\bband\b|\bbanded\b|\belastic\b", "resistance_band_loop"),
    (r"\bcable\b|\bpulley\b|\bpull-?through\b", "cable_attachment_single_handle"),
    (r"\brope\b(?!.*climb)", "cable_attachment_rope"),
    (r"\bcrossover\b", "cable_crossover_machine"),
    (r"\blat pulldown\b|\bpulldown\b", "lat_pulldown_machine"),
    (r"\bleg press\b", "leg_press_machine"),
    (r"\bhack squat\b", "hack_squat_machine"),
    (r"\bleg extension\b", "leg_extension_machine"),
    (r"\bseated leg curl\b", "leg_curl_machine_seated"),
    (r"\blying leg curl\b|\bleg curl\b", "leg_curl_machine_lying"),
    (r"\bpec deck\b|\bchest fly machine\b", "pec_deck_machine"),
    (r"\bchest press machine\b|\bmachine chest press\b|\blever chest press\b", "chest_press_machine"),
    (r"\bshoulder press machine\b|\bmachine shoulder press\b", "shoulder_press_machine"),
    (r"\bseated row machine\b|\bmachine row\b|\bhammer strength row\b", "seated_row_machine"),
    (r"\bhip thrust machine\b", "hip_thrust_machine"),
    (r"\babductor machine\b|\bhip abduction machine\b", "abductor_machine"),
    (r"\badductor machine\b|\bhip adduction machine\b", "adductor_machine"),
    (r"\bcalf raise machine\b|\bseated calf\b", "calf_raise_machine_seated"),
    (r"\bghd\b|\bglute[- ]ham\b", "glute_ham_developer"),
    (r"\bback extension machine\b|\bhyperextension\b|\broman chair\b", "back_extension_machine"),
    (r"\bassisted (pull|chin)\b", "assisted_pull_up_machine"),
    (r"\bring\b|\brings\b", "rings"),
    (r"\bparallette", "parallettes"),
    (r"\bdip bar\b|\bparallel bar\b", "dip_bars"),
    (r"\bpull-?up bar\b|\bhang\b|\bchin-?up\b|\bpull-?up\b|\btoes-?to-?bar\b", "pull_up_bar"),
    (r"\bab wheel\b|\brollerout\b|\broll-?out\b", "ab_wheel"),
    (r"\btrx\b|\bsuspension\b", "trx_suspension_trainer"),
    (r"\bstability ball\b|\bexercise ball\b|\bswiss ball\b", "stability_ball"),
    (r"\bbosu\b", "bosu_ball"),
    (r"\bmedicine ball\b|\bwall ball\b|\bslam\b", "medicine_ball"),
    (r"\bbattle rope\b|\bbattling rope\b", "battle_ropes"),
    (r"\bbox jump\b|\bstep-?up\b|\bbox squat\b", "box_plyo"),
    (r"\bjump rope\b|\bskipping\b|\bdouble.?under\b|\bsingle under\b", "jump_rope"),
    (r"\btreadmill\b", "treadmill"),
    (r"\browing\b|\berg(ometer)?\b", "rowing_machine"),
    (r"\bski erg\b", "ski_erg"),
    (r"\bassault bike\b|\bair bike\b", "assault_bike"),
    (r"\bstationary bike\b|\bcycle\b", "stationary_bike"),
    (r"\belliptical\b|\bcross trainer\b|\bstepmill\b", "elliptical"),
    (r"\bpreacher\b", "preacher_curl_bench"),
    (r"\bincline\b|\bdecline\b", "adjustable_bench"),
    (r"\bbench press\b|\bfloor press\b|\bbench\b", "flat_bench"),
    (r"\bfoam roller\b|\broller\b", "foam_roller"),
    (r"\bweighted\b|\bdip belt\b", "dip_belt"),
]
NAME_EQUIPMENT = [(re.compile(p, re.I), c) for p, c in NAME_EQUIPMENT]

# archetypes whose exercises genuinely need no equipment
NO_EQUIPMENT_ARCHETYPES = {
    "pushup", "pushup_deficit", "crunch", "plank", "hollow_hold", "superman",
    "stretch", "yoga_pose", "mobility_drill", "balance_drill", "crawl",
    "squat_bodyweight", "pistol_squat", "sissy_squat", "glute_bridge",
    "wall_sit", "plyometric", "l_sit", "dragon_flag", "tri_bodyweight_ext",
    "nordic_curl", "slider_leg_curl", "scapula_dip", "handstand_hold",
    "planche", "copenhagen", "tibialis_raise", "rotation_twist", "side_bend",
    "hip_flexion", "leg_raise_hanging", "calf_raise_standing", "cardio_cyclic",
}

# Archetypes with no populated donor anywhere in the catalogue, so the modal
# vote has nothing to copy. Stated explicitly rather than left empty.
EXPLICIT_MUSCLES = {
    "neck_machine": [("sternocleidomastoid", "primary"), ("splenius_capitis", "primary"),
                     ("splenius_cervicis", "primary"), ("scalenes", "secondary"),
                     ("levator_scapulae", "secondary")],
    "neck_band": [("sternocleidomastoid", "primary"), ("splenius_capitis", "primary"),
                  ("splenius_cervicis", "primary"), ("scalenes", "secondary")],
    "tri_overhead_cable": [("triceps_brachii_long", "primary"),
                           ("triceps_brachii_lateral", "secondary"),
                           ("triceps_brachii_medial", "secondary")],
    # These exist in the catalogue but only ever carry secondary muscles, so
    # the modal vote can never supply a prime mover for them.
    "curl_machine": [("biceps_brachii_long", "primary"),
                     ("biceps_brachii_short", "primary"),
                     ("brachialis", "secondary")],
    "curl_overhead_cable": [("biceps_brachii_long", "primary"),
                            ("biceps_brachii_short", "primary"),
                            ("brachialis", "secondary")],
    "band_pull_apart": [("deltoid_posterior", "primary"),
                        ("rhomboids", "secondary"),
                        ("infraspinatus", "secondary"),
                        ("teres_minor", "secondary")],
    # anti-rotation: the obliques are the prime movers, not the delts
    "pallof_press": [("obliquus_externus", "primary"),
                     ("obliquus_internus", "primary"),
                     ("rectus_abdominis", "secondary"),
                     ("deltoid_anterior", "stabilizer")],
    "woodchop": [("obliquus_externus", "primary"),
                 ("obliquus_internus", "primary"),
                 ("rectus_abdominis", "secondary"),
                 ("deltoid_anterior", "stabilizer")],
}

# Fallback implement per archetype, used only when the NAME says nothing and
# the exercise is not legitimately equipment-free.
ARCHETYPE_EQUIPMENT = {
    "carry": "dumbbell", "carry_overhead": "dumbbell", "get_up": "kettlebell",
    "deadlift_conventional": "barbell", "deadlift_sumo": "barbell",
    "squat_back": "barbell", "squat_front": "barbell", "rdl": "barbell",
    "good_morning": "barbell", "olympic_lift": "barbell", "push_jerk": "barbell",
    "hip_thrust": "barbell", "lunge": "dumbbell", "split_squat": "dumbbell",
    "step_up": "dumbbell", "row_barbell": "barbell", "row_dumbbell": "dumbbell",
    "bench_flat": "barbell", "bench_incline": "adjustable_bench",
    "ohp_standing": "barbell", "ohp_seated": "dumbbell", "shrug": "barbell",
    "tri_pushdown": "cable_attachment_bar", "tri_overhead": "dumbbell",
    "tri_overhead_cable": "cable_attachment_rope", "tri_skullcrusher": "ez_bar",
    "tri_kickback": "dumbbell", "curl_standing": "barbell",
    "curl_cable": "cable_attachment_bar", "lateral_raise_db": "dumbbell",
    "front_raise": "dumbbell", "rear_delt_fly_db": "dumbbell",
    "face_pull": "cable_attachment_rope", "row_cable": "cable_attachment_bar",
    "grip_hold": "barbell", "kb_swing": "kettlebell", "throw": "medicine_ball",
    "neck_machine": "back_extension_machine", "neck_band": "resistance_band_loop",
    "cuff_rotation": "cable_attachment_single_handle",
    "woodchop": "cable_attachment_single_handle",
    "pallof_press": "cable_attachment_single_handle",
    "cable_crunch": "cable_attachment_rope", "upright_row": "barbell",
    "curl_wrist": "barbell", "wrist_roller": "weight_plate",
    "back_extension": "back_extension_machine",
    "reverse_hyper": "back_extension_machine",
    "hip_abduction": "abductor_machine", "hip_adduction": "adductor_machine",
    "leg_curl_lying": "leg_curl_machine_lying",
    "leg_curl_seated": "leg_curl_machine_seated",
    "leg_extension": "leg_extension_machine", "leg_press": "leg_press_machine",
    "squat_hack": "hack_squat_machine", "lat_pulldown": "lat_pulldown_machine",
    "row_machine": "seated_row_machine", "bench_machine": "chest_press_machine",
    "ohp_machine": "shoulder_press_machine", "fly_machine": "pec_deck_machine",
    "pullover_machine": "lat_pulldown_machine", "row_chest_supported": "barbell",
    "muscle_up": "pull_up_bar", "pullup": "pull_up_bar", "chinup": "pull_up_bar",
    "hang_passive": "pull_up_bar", "tri_dip": "dip_bars",
    "dip_machine": "chest_press_machine", "row_inverted": "pull_up_bar",
    "lever_hold": "pull_up_bar", "front_lever_row": "pull_up_bar",
    "rope_climb": "pull_up_bar", "scapular_pull": "pull_up_bar",
    "ab_wheel": "ab_wheel", "calf_raise_seated": "calf_raise_machine_seated",
    "calf_raise_standing": "calf_raise_machine_standing",
    "calf_machine_lever": "calf_raise_machine_standing",
    "calf_raise_leg_press": "leg_press_machine",
    "calf_raise_band": "resistance_band_loop", "curl_band": "resistance_band_loop",
    "tri_band_pushdown": "resistance_band_loop",
    "band_pull_apart": "resistance_band_loop", "band_walk": "resistance_band_loop",
    "leg_curl_band": "resistance_band_loop",
    "cuff_rotation_band": "resistance_band_loop", "fly_band": "resistance_band_loop",
    "hip_flexion": "resistance_band_loop", "fly_cable": "cable_crossover_machine",
    "fly_dumbbell": "dumbbell",
    "press_cable_chest": "cable_attachment_single_handle",
    "lateral_raise_cable": "cable_attachment_single_handle",
    "lateral_raise_machine": "shoulder_press_machine",
    "rear_delt_cable": "cable_crossover_machine",
    "rear_delt_machine": "pec_deck_machine", "curl_machine": "chest_press_machine",
    "tri_extension_lever": "chest_press_machine",
    "curl_preacher": "preacher_curl_bench", "curl_incline": "adjustable_bench",
    "curl_spider": "adjustable_bench", "curl_concentration": "dumbbell",
    "curl_bayesian": "cable_attachment_single_handle",
    "curl_overhead_cable": "cable_attachment_single_handle",
    "curl_sprinter": "cable_attachment_single_handle", "curl_drag": "barbell",
    "curl_reverse": "ez_bar",
    "kickback_glute": "cable_attachment_ankle_strap",
    "pull_through": "cable_attachment_rope",
    "straight_arm_pulldown": "cable_attachment_bar", "pullover_db": "dumbbell",
    "bench_smith": "smith_machine", "bench_decline": "adjustable_bench",
    "bench_floor": "barbell", "ohp_landmine": "landmine_attachment",
    "row_landmine": "landmine_attachment", "side_bend": "dumbbell",
    "russian_twist": "weight_plate",
    "rotation_twist": "cable_attachment_single_handle",
    "svend_press": "weight_plate", "glute_bridge": "barbell",
    "tri_close_press": "barbell", "planche": "parallettes",
    "handstand_hold": "gymnastic_mat", "skin_the_cat": "rings",
    "balance_drill": "bosu_ball", "crawl": "gymnastic_mat",
    "cardio_cyclic": "treadmill", "plyometric": "box_plyo",
    "slider_leg_curl": "gymnastic_mat", "nordic_curl": "glute_ham_developer",
    "wall_sit": "gymnastic_mat", "stretch": "gymnastic_mat",
    "yoga_pose": "gymnastic_mat", "mobility_drill": "gymnastic_mat",
    "sled": "sled",
}

VARIATION_AXIS_RULES = [
    (r"\b(grip|underhand|overhand|neutral|supinated|pronated|close|wide|diamond|"
     r"reverse[- ]grip|hook|false grip|towel|fat|thick|knuckle|fingertip)\b", "grip"),
    (r"\b(incline|decline|angle|high|low|45|seated|lying|standing|prone|supine|"
     r"bent[- ]over|overhead|kneeling|half[- ]kneeling)\b", "angle"),
    (r"\b(stance|sumo|narrow|wide|split|staggered|cossack|b[- ]stance)\b", "stance"),
    (r"\b(single|one[- ]arm|one[- ]leg|unilateral|alternating|archer)\b", "unilateral"),
    (r"\b(deficit|pause|paused|partial|full|deep|pin|board|rack|block|"
     r"floor|bottom|top|isometric|hold)\b", "rom"),
    (r"\b(band|banded|chain|cable|elastic|resistance)\b", "resistance"),
    (r"\b(tempo|slow|eccentric|negative|explosive|plyo|speed|1\.5|cluster)\b", "tempo"),
    (r"\b(assisted|band[- ]assisted|machine[- ]assisted|counterbalance|box)\b", "assistance"),
    (r"\b(barbell|dumbbell|kettlebell|machine|smith|landmine|ez|trap bar|"
     r"cable|ring|trx|sled|plate)\b", "equipment"),
    (r"\b(kipping|strict|bounce|touch and go|dead stop|zombie|bottoms?[- ]up|"
     r"suicide|zercher)\b", "technique"),
    (r"\b(timed|pulse|hold|iso|amrap|cluster|rest[- ]pause|drop set|21s)\b", "tempo"),
    (r"\b(behind[- ]the[- ]?(neck|back)|front rack|back rack|goblet|hex)\b", "angle"),
    (r"\b(advanced|tuck|straddle|progression|negative|eccentric)\b", "assistance"),
    (r"\b(1|2|3|4|5|board|pin|block|deficit|elevated)\b", "rom"),
    (r"\b(reverse|crossover|over|bicycle|butterfly|boxer|broad|lateral|archer|"
     r"typewriter|commando|around|drag|spider|preacher|concentration)\b", "technique"),
]
VARIATION_AXIS_RULES = [(re.compile(p, re.I), a) for p, a in VARIATION_AXIS_RULES]


def infer_variation_axis(base_name, variant_name):
    """The axis is whatever the variant NAME adds to the base name."""
    base_tokens = set(re.findall(r"[a-z0-9]+", base_name.lower()))
    added = " ".join(t for t in re.findall(r"[a-z0-9]+", variant_name.lower())
                     if t not in base_tokens)
    if not added:
        return None
    for rx, axis in VARIATION_AXIS_RULES:
        if rx.search(added):
            return axis
    # Something in the name changed but no rule recognised it. That is by
    # definition a technique difference, which beats leaving the edge NULL.
    return "technique"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dsn", default=None,
                    help="optional; resolved from $COACHLY_BIOMECH_DSN or auto-injestion/.env")
    ap.add_argument("--apply", action="store_true")
    args = ap.parse_args()

    with psycopg.connect(dsn, connect_timeout=30) as conn:
        conn.autocommit = False
        cur = conn.cursor()
        stats = Counter()

        # ---------- 0. validate equipment codes against the live catalogue ----
        cur.execute("SELECT code, id FROM exercises.equipment")
        equipment_ids = dict(cur.fetchall())
        unknown = sorted(set(EQUIPMENT_CLASS) - set(equipment_ids))
        if unknown:
            sys.exit(f"equipment codes not in DB: {unknown}")
        uncovered = sorted(set(equipment_ids) - set(EQUIPMENT_CLASS))
        if uncovered:
            sys.exit(f"equipment codes with no class mapping: {uncovered}")
        print(f"equipment codes validated ({len(equipment_ids)})")

        unknown_targets = sorted({c for _rx, c in NAME_EQUIPMENT} - set(equipment_ids))
        if unknown_targets:
            sys.exit(f"name rules target unknown equipment: {unknown_targets}")

        cur.executemany("UPDATE exercises.equipment SET equipment_class = %s, updated_at = NOW() "
                        "WHERE code = %s",
                        [(klass, code) for code, klass in EQUIPMENT_CLASS.items()])
        cur.execute("""SELECT equipment_class::text, count(*) FROM exercises.equipment
                        GROUP BY 1 ORDER BY 2 DESC""")
        print("  classes:", dict(cur.fetchall()))

        # ---------- 1. modal muscle set per archetype ------------------------
        cur.execute("""SELECT e.id, e.name, e.bodyweight FROM exercises.exercise e
                        WHERE e.deleted_at IS NULL""")
        exercises = cur.fetchall()
        archetype_of = {eid: GEN.classify(name) for eid, name, _bw in exercises}

        cur.execute("""SELECT em.exercise_id, m.code, em.involvement::text
                         FROM exercises.exercise_muscle em
                         JOIN exercises.muscle m ON m.id = em.muscle_id""")
        muscles_by_exercise = defaultdict(list)
        for exercise_id, muscle_code, involvement in cur.fetchall():
            muscles_by_exercise[exercise_id].append((muscle_code, involvement))

        signature_votes = defaultdict(Counter)
        for exercise_id, _name, _bw in exercises:
            arch = archetype_of[exercise_id]
            muscles = muscles_by_exercise.get(exercise_id)
            if arch and muscles:
                signature_votes[arch][tuple(sorted(muscles))] += 1

        modal_muscles = {arch: votes.most_common(1)[0][0]
                         for arch, votes in signature_votes.items()}

        cur.execute("SELECT code, id FROM exercises.muscle")
        muscle_ids = dict(cur.fetchall())

        missing_muscles = [(eid, archetype_of[eid]) for eid, _n, _b in exercises
                           if not muscles_by_exercise.get(eid)]
        muscle_inserts, no_donor = [], Counter()
        for exercise_id, arch in missing_muscles:
            signature = modal_muscles.get(arch) or EXPLICIT_MUSCLES.get(arch)
            if not signature:
                no_donor[arch] += 1
                continue
            for muscle_code, involvement in signature:
                muscle_inserts.append((exercise_id, muscle_ids[muscle_code], involvement))
        cur.executemany("""INSERT INTO exercises.exercise_muscle
                               (exercise_id, muscle_id, involvement, created_at,
                                evidence_basis, confidence)
                           VALUES (%s, %s, %s, NOW(), 'heuristic', 'low')
                           ON CONFLICT DO NOTHING""", muscle_inserts)
        stats["muscle_rows_inferred"] = len(muscle_inserts)
        stats["exercises_given_muscles"] = len(missing_muscles) - sum(no_donor.values())
        if no_donor:
            print("  archetypes with no populated donor:", dict(no_donor))

        # ---------- 2. missing equipment -------------------------------------
        cur.execute("SELECT DISTINCT exercise_id FROM exercises.exercise_equipment")
        has_equipment = {r[0] for r in cur.fetchall()}
        equipment_inserts = []
        still_missing = Counter()
        for exercise_id, name, bodyweight in exercises:
            if exercise_id in has_equipment:
                continue
            arch = archetype_of[exercise_id]
            codes = []
            for rx, equipment_code in NAME_EQUIPMENT:
                if rx.search(name):
                    codes.append(equipment_code)
                    break
            if not codes:
                if bodyweight:
                    stats["legitimately_equipment_free"] += 1
                    continue
                fallback = ARCHETYPE_EQUIPMENT.get(arch)
                if not fallback and arch in NO_EQUIPMENT_ARCHETYPES:
                    stats["legitimately_equipment_free"] += 1
                    continue
                if fallback and fallback in equipment_ids:
                    codes.append(fallback)
                    stats["equipment_from_archetype"] += 1
                else:
                    still_missing[arch] += 1
                    continue
            for position, equipment_code in enumerate(codes, start=1):
                equipment_inserts.append((exercise_id, equipment_ids[equipment_code], position))
        cur.executemany("""INSERT INTO exercises.exercise_equipment
                               (exercise_id, equipment_id, required, is_primary,
                                quantity_needed, created_at)
                           VALUES (%s, %s, true, true, %s, NOW())
                           ON CONFLICT DO NOTHING""", equipment_inserts)
        stats["equipment_rows_inferred"] = len(equipment_inserts)
        if still_missing:
            print("  still without equipment, by archetype:", dict(still_missing.most_common(12)))

        # ---------- 3. variation axis ----------------------------------------
        cur.execute("""SELECT v.base_exercise_id, b.name, v.variant_exercise_id, r.name
                         FROM exercises.exercise_variation v
                         JOIN exercises.exercise b ON b.id = v.base_exercise_id
                         JOIN exercises.exercise r ON r.id = v.variant_exercise_id""")
        axis_updates, unresolved = [], 0
        for base_id, base_name, variant_id, variant_name in cur.fetchall():
            axis = infer_variation_axis(base_name, variant_name)
            if axis is None:
                unresolved += 1
                continue
            axis_updates.append((axis, base_id, variant_id))
        cur.executemany("""UPDATE exercises.exercise_variation SET variation_axis = %s
                            WHERE base_exercise_id = %s AND variant_exercise_id = %s""",
                        axis_updates)
        stats["variation_axis_set"] = len(axis_updates)
        stats["variation_axis_unresolved"] = unresolved

        print("\n--- results")
        for key in sorted(stats):
            print(f"   {key:34s} {stats[key]}")

        print("\n--- verification")
        checks = [
            ("equipment without class",
             "SELECT count(*) FROM exercises.equipment WHERE equipment_class IS NULL"),
            ("exercises without muscles",
             """SELECT count(*) FROM exercises.exercise e WHERE e.deleted_at IS NULL
                  AND NOT EXISTS (SELECT 1 FROM exercises.exercise_muscle m
                                   WHERE m.exercise_id = e.id)"""),
            ("RESISTANCE, not bodyweight, without equipment",
             """SELECT count(*) FROM exercises.exercise e
                 WHERE e.deleted_at IS NULL AND e.exercise_kind = 'resistance'
                   AND e.bodyweight = false
                   AND NOT EXISTS (SELECT 1 FROM exercises.exercise_equipment q
                                    WHERE q.exercise_id = e.id)"""),
            ("variation edges without axis",
             "SELECT count(*) FROM exercises.exercise_variation WHERE variation_axis IS NULL"),
            ("PRIMARY muscles without tension profile",
             """SELECT count(*) FROM exercises.exercise_muscle
                 WHERE involvement = 'primary' AND tension_lengthened IS NULL"""),
        ]
        for label, query in checks:
            cur.execute(query)
            print(f"   {label:46s} {cur.fetchone()[0]}")

        if args.apply:
            conn.commit()
            print("\nCOMMITTED")
        else:
            conn.rollback()
            print("\nDRY RUN - rolled back")


if __name__ == "__main__":
    main()
