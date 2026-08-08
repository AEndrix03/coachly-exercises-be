#!/usr/bin/env python3
"""
Exercise model V2 - PHASE 2, STEP 2
Seed the reference taxonomies: movement patterns, joint actions, muscle
groups (normalised out of the existing muscle.group_code) and exercise
families.

Idempotent: re-running upserts by code and never orphans existing links.

Usage:
    python inj/_tools/v2_step2_taxonomies.py --dsn "..." [--apply]
"""
import argparse
import json
import sys

import psycopg

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")


def i18n(en, it):
    return json.dumps({"en": {"name": en}, "it": {"name": it}}, ensure_ascii=False)


# ---------------------------------------------------------------------------
# Movement patterns. Deliberately coarse: each entry must represent a
# difference that actually changes how a program is built. Children are
# nested under a parent so the engine can compare at either resolution.
# ---------------------------------------------------------------------------
MOVEMENT_PATTERNS = [
    # (code, parent_code, en, it)
    ("press",               None,    "Press",                   "Spinta"),
    ("horizontal_press",    "press", "Horizontal press",         "Spinta orizzontale"),
    ("vertical_press",      "press", "Vertical press",           "Spinta verticale"),
    ("pull",                None,    "Pull",                     "Trazione"),
    ("horizontal_pull",     "pull",  "Horizontal pull",          "Trazione orizzontale"),
    ("vertical_pull",       "pull",  "Vertical pull",            "Trazione verticale"),
    ("squat",               None,    "Squat",                    "Squat"),
    ("hip_hinge",           None,    "Hip hinge",                "Hip hinge"),
    ("hip_extension",       None,    "Hip extension",            "Estensione d'anca"),
    ("hip_flexion",         None,    "Hip flexion",              "Flessione d'anca"),
    ("knee_extension",      None,    "Knee extension",           "Estensione di ginocchio"),
    ("knee_flexion",        None,    "Knee flexion",             "Flessione di ginocchio"),
    ("hip_abduction",       None,    "Hip abduction",            "Abduzione d'anca"),
    ("hip_adduction",       None,    "Hip adduction",            "Adduzione d'anca"),
    ("shoulder_abduction",  None,    "Shoulder abduction",       "Abduzione di spalla"),
    ("shoulder_flexion",    None,    "Shoulder flexion",         "Flessione di spalla"),
    ("shoulder_extension",  None,    "Shoulder extension",       "Estensione di spalla"),
    ("shoulder_horizontal_abduction", None, "Shoulder horizontal abduction",
     "Abduzione orizzontale di spalla"),
    ("elbow_flexion",       None,    "Elbow flexion",            "Flessione di gomito"),
    ("elbow_extension",     None,    "Elbow extension",          "Estensione di gomito"),
    ("plantar_flexion",     None,    "Plantar flexion",          "Flessione plantare"),
    ("dorsiflexion",        None,    "Dorsiflexion",             "Dorsiflessione"),
    ("spinal_flexion",      None,    "Spinal flexion",           "Flessione del rachide"),
    ("spinal_extension",    None,    "Spinal extension",         "Estensione del rachide"),
    ("rotation",            None,    "Rotation",                 "Rotazione"),
    ("anti_rotation",       None,    "Anti-rotation",            "Anti-rotazione"),
    ("anti_extension",      None,    "Anti-extension",           "Anti-estensione"),
    ("lateral_flexion",     None,    "Lateral flexion",          "Flessione laterale"),
    ("carry",               None,    "Carry",                    "Trasporto"),
    ("scapular",            None,    "Scapular control",         "Controllo scapolare"),
    ("locomotion",          None,    "Locomotion",               "Locomozione"),
    ("jump",                None,    "Jump / landing",           "Salto / atterraggio"),
    ("wrist_flexion",       None,    "Wrist flexion",            "Flessione del polso"),
    ("wrist_extension",     None,    "Wrist extension",          "Estensione del polso"),
    ("neck",                None,    "Neck action",              "Azione del collo"),
    ("grip",                None,    "Grip",                     "Presa"),
]

# ---------------------------------------------------------------------------
# Joint actions. This is what replaces exercise.force: instead of "push",
# a bench press is shoulder horizontal adduction + elbow extension.
# ---------------------------------------------------------------------------
JOINT_ACTIONS = [
    # (joint, action, en, it)
    ("shoulder", "flexion",              "Shoulder flexion",              "Flessione di spalla"),
    ("shoulder", "extension",            "Shoulder extension",            "Estensione di spalla"),
    ("shoulder", "abduction",            "Shoulder abduction",            "Abduzione di spalla"),
    ("shoulder", "adduction",            "Shoulder adduction",            "Adduzione di spalla"),
    ("shoulder", "horizontal_adduction", "Shoulder horizontal adduction", "Adduzione orizzontale di spalla"),
    ("shoulder", "horizontal_abduction", "Shoulder horizontal abduction", "Abduzione orizzontale di spalla"),
    ("shoulder", "external_rotation",    "Shoulder external rotation",    "Rotazione esterna di spalla"),
    ("shoulder", "internal_rotation",    "Shoulder internal rotation",    "Rotazione interna di spalla"),
    ("scapula",  "retraction",           "Scapular retraction",           "Retrazione scapolare"),
    ("scapula",  "protraction",          "Scapular protraction",          "Protrazione scapolare"),
    ("scapula",  "elevation",            "Scapular elevation",            "Elevazione scapolare"),
    ("scapula",  "depression",           "Scapular depression",           "Depressione scapolare"),
    ("elbow",    "flexion",              "Elbow flexion",                 "Flessione di gomito"),
    ("elbow",    "extension",            "Elbow extension",               "Estensione di gomito"),
    ("forearm",  "supination",           "Forearm supination",            "Supinazione avambraccio"),
    ("forearm",  "pronation",            "Forearm pronation",             "Pronazione avambraccio"),
    ("wrist",    "flexion",              "Wrist flexion",                 "Flessione del polso"),
    ("wrist",    "extension",            "Wrist extension",               "Estensione del polso"),
    ("hip",      "extension",            "Hip extension",                 "Estensione d'anca"),
    ("hip",      "flexion",              "Hip flexion",                   "Flessione d'anca"),
    ("hip",      "abduction",            "Hip abduction",                 "Abduzione d'anca"),
    ("hip",      "adduction",            "Hip adduction",                 "Adduzione d'anca"),
    ("hip",      "external_rotation",    "Hip external rotation",         "Rotazione esterna d'anca"),
    ("knee",     "extension",            "Knee extension",                "Estensione di ginocchio"),
    ("knee",     "flexion",              "Knee flexion",                  "Flessione di ginocchio"),
    ("ankle",    "plantar_flexion",      "Ankle plantar flexion",         "Flessione plantare"),
    ("ankle",    "dorsiflexion",         "Ankle dorsiflexion",            "Dorsiflessione"),
    ("spine",    "flexion",              "Spinal flexion",                "Flessione del rachide"),
    ("spine",    "extension",            "Spinal extension",              "Estensione del rachide"),
    ("spine",    "rotation",             "Spinal rotation",               "Rotazione del rachide"),
    ("spine",    "lateral_flexion",      "Spinal lateral flexion",        "Flessione laterale del rachide"),
    ("spine",    "anti_flexion",         "Resisting spinal flexion",      "Resistenza alla flessione"),
    ("spine",    "anti_extension",       "Resisting spinal extension",    "Resistenza all'estensione"),
    ("spine",    "anti_rotation",        "Resisting spinal rotation",     "Resistenza alla rotazione"),
    ("neck",     "flexion",              "Neck flexion",                  "Flessione del collo"),
    ("neck",     "extension",            "Neck extension",                "Estensione del collo"),
    ("neck",     "lateral_flexion",      "Neck lateral flexion",          "Flessione laterale del collo"),
    ("hand",     "grip",                 "Gripping",                      "Presa"),
]

# ---------------------------------------------------------------------------
# Muscle groups. The anatomical set mirrors muscle.group_code, which already
# exists as a denormalised varchar; membership is derived from it below so
# the two cannot drift. The functional groups are additions.
# ---------------------------------------------------------------------------
ANATOMICAL_GROUPS = {
    "chest":       ("Chest", "Petto"),
    "back":        ("Back", "Schiena"),
    "shoulders":   ("Shoulders", "Spalle"),
    "arms":        ("Arms", "Braccia"),
    "core":        ("Core", "Core"),
    "quadriceps":  ("Quadriceps", "Quadricipiti"),
    "hamstrings":  ("Hamstrings", "Femorali"),
    "glutes":      ("Glutes", "Glutei"),
    "adductors":   ("Adductors", "Adduttori"),
    "hip_flexors": ("Hip flexors", "Flessori dell'anca"),
    "calves":      ("Calves", "Polpacci"),
}

# finer anatomical groups that the coarse group_code cannot express
DERIVED_GROUPS = {
    "biceps":       (("Biceps", "Bicipiti"),
                     ["biceps_brachii_long", "biceps_brachii_short", "brachialis", "brachioradialis"]),
    "triceps":      (("Triceps", "Tricipiti"),
                     ["triceps_brachii_long", "triceps_brachii_lateral", "triceps_brachii_medial"]),
    "lats":         (("Lats", "Dorsali"),
                     ["latissimus_dorsi", "teres_major"]),
    "upper_back":   (("Upper back", "Alta schiena"),
                     ["rhomboids", "trapezius_middle", "trapezius_lower", "trapezius_upper"]),
    "spinal_erectors": (("Spinal erectors", "Erettori spinali"),
                     ["erector_spinae", "multifidus"]),
    "forearms":     (("Forearms", "Avambracci"),
                     ["forearm_flexors", "forearm_extensors"]),
    "abductors":    (("Hip abductors", "Abduttori dell'anca"),
                     ["gluteus_medius", "gluteus_minimus", "tensor_fasciae_latae"]),
    "obliques":     (("Obliques", "Obliqui"),
                     ["obliquus_externus", "obliquus_internus"]),
    "rotator_cuff": (("Rotator cuff", "Cuffia dei rotatori"),
                     ["infraspinatus", "teres_minor", "supraspinatus", "subscapularis"]),
    "posterior_chain": (("Posterior chain", "Catena posteriore"),
                     ["gluteus_maximus", "biceps_femoris_long", "biceps_femoris_short",
                      "semimembranosus", "semitendinosus", "erector_spinae", "multifidus"]),
}
FUNCTIONAL_GROUP_CODES = {"posterior_chain", "rotator_cuff"}

# ---------------------------------------------------------------------------
# Exercise families: "the same lift done differently".
# Barbell / dumbbell / Smith bench share one; bench and cable fly do not.
# ---------------------------------------------------------------------------
FAMILIES = [
    ("bench_press",            "Bench press",             "Panca piana"),
    ("incline_press",          "Incline press",           "Panca inclinata"),
    ("decline_press",          "Decline press",           "Panca declinata"),
    ("chest_press_machine",    "Machine chest press",     "Chest press a macchina"),
    ("chest_fly",              "Chest fly",               "Croci"),
    ("push_up",                "Push-up",                 "Piegamenti"),
    ("dip",                    "Dip",                     "Dip"),
    ("overhead_press",         "Overhead press",          "Lento avanti"),
    ("lateral_raise",          "Lateral raise",           "Alzate laterali"),
    ("front_raise",            "Front raise",             "Alzate frontali"),
    ("rear_delt_fly",          "Rear delt fly",           "Alzate posteriori"),
    ("upright_row",            "Upright row",             "Tirate al mento"),
    ("shrug",                  "Shrug",                   "Scrollate"),
    ("rotator_cuff_work",      "Rotator cuff work",       "Lavoro per la cuffia"),
    ("face_pull",              "Face pull",               "Face pull"),
    ("pull_up",                "Pull-up",                 "Trazioni"),
    ("chin_up",                "Chin-up",                 "Trazioni supine"),
    ("lat_pulldown",           "Lat pulldown",            "Lat machine"),
    ("pullover",               "Pullover",                "Pullover"),
    ("straight_arm_pulldown",  "Straight-arm pulldown",   "Pulldown a braccia tese"),
    ("barbell_row",            "Barbell row",             "Rematore con bilanciere"),
    ("dumbbell_row",           "Dumbbell row",            "Rematore con manubrio"),
    ("cable_row",              "Cable row",               "Pulley"),
    ("machine_row",            "Machine row",             "Rematore a macchina"),
    ("inverted_row",           "Inverted row",            "Rematore inverso"),
    ("muscle_up",              "Muscle-up",               "Muscle-up"),
    ("hang",                   "Hang",                    "Sospensione"),
    ("back_squat",             "Back squat",              "Squat con bilanciere"),
    ("front_squat",            "Front squat",             "Front squat"),
    ("hack_squat",             "Hack squat",              "Hack squat"),
    ("leg_press",              "Leg press",               "Pressa"),
    ("bodyweight_squat",       "Bodyweight squat",        "Squat a corpo libero"),
    ("split_squat",            "Split squat",             "Affondo bulgaro"),
    ("lunge",                  "Lunge",                   "Affondi"),
    ("step_up",                "Step-up",                 "Step-up"),
    ("single_leg_squat",       "Single-leg squat",        "Squat monopodalico"),
    ("sissy_squat",            "Sissy squat",             "Sissy squat"),
    ("leg_extension",          "Leg extension",           "Leg extension"),
    ("wall_sit",               "Wall sit",                "Wall sit"),
    ("deadlift",               "Deadlift",                "Stacco"),
    ("romanian_deadlift",      "Romanian deadlift",       "Stacco rumeno"),
    ("good_morning",           "Good morning",            "Good morning"),
    ("hip_thrust",             "Hip thrust",              "Hip thrust"),
    ("glute_bridge",           "Glute bridge",            "Ponte glutei"),
    ("back_extension",         "Back extension",          "Iperestensioni"),
    ("reverse_hyper",          "Reverse hyperextension",  "Reverse hyper"),
    ("kettlebell_swing",       "Kettlebell swing",        "Swing con kettlebell"),
    ("pull_through",           "Pull-through",            "Pull-through"),
    ("glute_kickback",         "Glute kickback",          "Slanci per i glutei"),
    ("leg_curl",               "Leg curl",                "Leg curl"),
    ("nordic_curl",            "Nordic curl",             "Nordic curl"),
    ("hip_abduction",          "Hip abduction",           "Abduzione d'anca"),
    ("hip_adduction",          "Hip adduction",           "Adduzione d'anca"),
    ("calf_raise",             "Calf raise",              "Calf raise"),
    ("tibialis_raise",         "Tibialis raise",          "Tibialis raise"),
    ("biceps_curl",            "Biceps curl",             "Curl per bicipiti"),
    ("preacher_curl",          "Preacher curl",           "Panca Scott"),
    ("triceps_pushdown",       "Triceps pushdown",        "Pushdown"),
    ("triceps_overhead_extension", "Overhead triceps extension", "Estensioni sopra la testa"),
    ("skull_crusher",          "Skull crusher",           "French press"),
    ("triceps_kickback",       "Triceps kickback",        "Kickback per tricipiti"),
    ("wrist_curl",             "Wrist curl",              "Curl per i polsi"),
    ("grip_hold",              "Grip hold",               "Tenute di presa"),
    ("crunch",                 "Crunch",                  "Crunch"),
    ("leg_raise",              "Leg raise",               "Sollevamento gambe"),
    ("ab_wheel",               "Ab wheel rollout",        "Ruota per addominali"),
    ("plank",                  "Plank",                   "Plank"),
    ("pallof_press",           "Pallof press",            "Pallof press"),
    ("woodchop",               "Woodchop",                "Woodchop"),
    ("side_bend",              "Side bend",               "Flessioni laterali"),
    ("hollow_hold",            "Hollow hold",             "Hollow hold"),
    ("dragon_flag",            "Dragon flag",             "Dragon flag"),
    ("l_sit",                  "L-sit",                   "L-sit"),
    ("neck_work",              "Neck work",               "Lavoro per il collo"),
    ("carry",                  "Loaded carry",            "Trasporti"),
    ("olympic_lift",           "Olympic lift",            "Alzata olimpica"),
    ("plyometric_jump",        "Plyometric jump",         "Salto pliometrico"),
    ("sled",                   "Sled work",               "Slitta"),
    ("throw",                  "Throw / slam",            "Lanci"),
    ("cardio_machine",         "Cardio machine",          "Macchina cardio"),
    ("running",                "Running",                 "Corsa"),
    ("jump_rope",              "Jump rope",               "Corda"),
    ("crawl",                  "Crawl",                   "Crawl"),
    ("get_up",                 "Turkish get-up",          "Turkish get-up"),
    ("gymnastic_lever",        "Gymnastic lever",         "Leve ginniche"),
    ("planche",                "Planche",                 "Planche"),
    ("handstand",              "Handstand",               "Verticale"),
    ("scapular_control",       "Scapular control",        "Controllo scapolare"),
    ("stretch",                "Stretch",                 "Allungamento"),
    ("mobility_drill",         "Mobility drill",          "Drill di mobilità"),
    ("balance_drill",          "Balance drill",           "Drill di equilibrio"),
]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dsn", required=True)
    ap.add_argument("--apply", action="store_true")
    args = ap.parse_args()

    with psycopg.connect(args.dsn, connect_timeout=20) as conn:
        conn.autocommit = False
        cur = conn.cursor()

        # ---- movement patterns (two passes so parents exist first) ----
        for code, _parent, en, it in MOVEMENT_PATTERNS:
            cur.execute("""INSERT INTO exercises.movement_pattern (code, translations)
                           VALUES (%s, %s::jsonb)
                           ON CONFLICT (code) DO UPDATE
                              SET translations = EXCLUDED.translations, updated_at = NOW()""",
                        (code, i18n(en, it)))
        for code, parent, _en, _it in MOVEMENT_PATTERNS:
            if parent:
                cur.execute("""UPDATE exercises.movement_pattern
                                  SET parent_id = (SELECT id FROM exercises.movement_pattern WHERE code = %s)
                                WHERE code = %s""", (parent, code))
        cur.execute("SELECT count(*) FROM exercises.movement_pattern")
        print("movement_pattern:", cur.fetchone()[0])

        # ---- joint actions ----
        for joint, action, en, it in JOINT_ACTIONS:
            cur.execute("""INSERT INTO exercises.joint_action (joint_code, action_code, translations)
                           VALUES (%s, %s, %s::jsonb)
                           ON CONFLICT (joint_code, action_code) DO UPDATE
                              SET translations = EXCLUDED.translations, updated_at = NOW()""",
                        (joint, action, i18n(en, it)))
        cur.execute("SELECT count(*) FROM exercises.joint_action")
        print("joint_action:", cur.fetchone()[0])

        # ---- muscle groups ----
        for code, (en, it) in ANATOMICAL_GROUPS.items():
            cur.execute("""INSERT INTO exercises.muscle_group (code, group_type, translations)
                           VALUES (%s, 'anatomical', %s::jsonb)
                           ON CONFLICT (code) DO UPDATE
                              SET translations = EXCLUDED.translations, updated_at = NOW()""",
                        (code, i18n(en, it)))
        for code, ((en, it), _members) in DERIVED_GROUPS.items():
            gtype = "functional" if code in FUNCTIONAL_GROUP_CODES else "anatomical"
            cur.execute("""INSERT INTO exercises.muscle_group (code, group_type, translations)
                           VALUES (%s, %s, %s::jsonb)
                           ON CONFLICT (code) DO UPDATE
                              SET translations = EXCLUDED.translations,
                                  group_type = EXCLUDED.group_type, updated_at = NOW()""",
                        (code, gtype, i18n(en, it)))

        # membership for the coarse groups comes straight from muscle.group_code,
        # so the normalised tables cannot drift from the legacy column
        cur.execute("""INSERT INTO exercises.muscle_group_member (group_id, muscle_id)
                       SELECT g.id, m.id
                         FROM exercises.muscle m
                         JOIN exercises.muscle_group g ON g.code = m.group_code
                       ON CONFLICT DO NOTHING""")
        print("  members from muscle.group_code:", cur.rowcount)

        for code, (_labels, members) in DERIVED_GROUPS.items():
            cur.execute("""INSERT INTO exercises.muscle_group_member (group_id, muscle_id)
                           SELECT g.id, m.id
                             FROM exercises.muscle_group g, exercises.muscle m
                            WHERE g.code = %s AND m.code = ANY(%s)
                           ON CONFLICT DO NOTHING""", (code, members))
        cur.execute("SELECT count(*) FROM exercises.muscle_group")
        groups = cur.fetchone()[0]
        cur.execute("SELECT count(*) FROM exercises.muscle_group_member")
        print(f"muscle_group: {groups}  members: {cur.fetchone()[0]}")

        # any muscle left out of every group is a taxonomy hole worth knowing about
        cur.execute("""SELECT m.code FROM exercises.muscle m
                        WHERE NOT EXISTS (SELECT 1 FROM exercises.muscle_group_member mm
                                           WHERE mm.muscle_id = m.id) ORDER BY m.code""")
        orphans = [r[0] for r in cur.fetchall()]
        print("  muscles in no group:", orphans or "none")

        # ---- families ----
        for code, en, it in FAMILIES:
            cur.execute("""INSERT INTO exercises.exercise_family (code, translations)
                           VALUES (%s, %s::jsonb)
                           ON CONFLICT (code) DO UPDATE
                              SET translations = EXCLUDED.translations, updated_at = NOW()""",
                        (code, i18n(en, it)))
        cur.execute("SELECT count(*) FROM exercises.exercise_family")
        print("exercise_family:", cur.fetchone()[0])

        if args.apply:
            conn.commit()
            print("COMMITTED")
        else:
            conn.rollback()
            print("DRY RUN - rolled back")


if __name__ == "__main__":
    main()
