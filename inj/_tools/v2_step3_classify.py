#!/usr/bin/env python3
"""
Exercise model V2 - PHASE 2, STEP 3
Apply the V2 classification to the whole catalogue.

Writes: exercise.{exercise_kind, technical_demand, joint_class, spotter_policy,
family_id}, exercise_movement_pattern, exercise_joint_action,
exercise_tracking_profile, exercise_muscle tension profile + provenance,
exercise_biomechanics.{spinal_loading, evidence_basis, confidence, method_note},
equipment.equipment_class.

Provenance is deliberately conservative. Nothing here is MEASURED or
LITERATURE: the archetype catalogue is expert judgement applied through a
biomechanical model, so rows are marked EXPERT_CURATED / BIOMECHANICAL_MODEL /
HEURISTIC with LOW-to-MODERATE confidence. Literature-backed rows are promoted
separately in step 5, where a real DOI can be attached.

Usage:
    python inj/_tools/v2_step3_classify.py --dsn "..." [--apply]
"""
import argparse
import importlib.util
import pathlib
import sys
from collections import Counter

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
MAP = _load("v2_archetype_map", "v2_archetype_map.py")

# archetype data_confidence -> (evidence_basis, confidence)
# implements held one per hand: their load is recorded per implement
PER_IMPLEMENT_EQUIPMENT = {"dumbbell", "kettlebell"}

PROVENANCE = {
    "curated":   ("expert_curated", "moderate"),
    "modeled":   ("biomechanical_model", "low"),
    "estimated": ("heuristic", "low"),
}

# equipment.code -> equipment_class, falling back to equipment.category
EQUIPMENT_CLASS_BY_CATEGORY = {
    "free_weights": "free_weight",
    "machines": "selectorized_machine",
    "cables": "cable",
    "bodyweight": "bodyweight",
    "cardio": "fixed_implement",
    "benches_racks": "fixed_implement",
    "accessories": "other",
}
EQUIPMENT_CLASS_BY_CODE = {
    "resistance_band": "elastic", "mini_band": "elastic",
    "pull_up_assist_band": "elastic", "yoga_strap": "elastic",
    "trx_straps": "bodyweight", "gymnastic_rings": "bodyweight",
    "parallettes": "bodyweight", "dip_bars": "bodyweight",
    "pull_up_bar": "bodyweight", "none_bodyweight": "bodyweight",
    "leg_press_machine": "plate_loaded_machine",
    "hack_squat_machine": "plate_loaded_machine",
    "smith_machine": "plate_loaded_machine",
    "t_bar_attachment": "plate_loaded_machine",
    "landmine": "plate_loaded_machine",
    "atlas_stone": "fixed_implement", "sandbag": "fixed_implement",
    "tire": "fixed_implement", "yoke": "fixed_implement",
    "medicine_ball": "fixed_implement", "wall_ball": "fixed_implement",
    "kettlebell": "free_weight", "dumbbell": "free_weight",
    "barbell": "free_weight", "ez_bar": "free_weight",
    "axle_bar": "free_weight", "trap_bar": "free_weight",
    "cambered_bar": "free_weight", "safety_squat_bar": "free_weight",
    "log_bar": "free_weight", "weight_vest": "free_weight",
    "ankle_weights": "free_weight", "dip_belt": "free_weight",
}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dsn", default=None,
                    help="optional; resolved from $COACHLY_BIOMECH_DSN or auto-injestion/.env")
    ap.add_argument("--apply", action="store_true")
    args = ap.parse_args()

    with psycopg.connect(dsn, connect_timeout=30) as conn:
        conn.autocommit = False
        cur = conn.cursor()

        cur.execute("SELECT code, id FROM exercises.exercise_family")
        family_ids = dict(cur.fetchall())
        cur.execute("SELECT code, id FROM exercises.movement_pattern")
        pattern_ids = dict(cur.fetchall())
        cur.execute("SELECT joint_code, action_code, id FROM exercises.joint_action")
        action_ids = {(j, a): i for j, a, i in cur.fetchall()}

        cur.execute("""SELECT id, name, unilateral, bodyweight
                         FROM exercises.exercise WHERE deleted_at IS NULL""")
        exercises = cur.fetchall()

        # An archetype knows the movement, not the implement: "Dumbbell Curl"
        # and "Barbell Curl" share curl_standing but are logged differently.
        # Equipment is the only place that fact lives.
        cur.execute("""SELECT eq.exercise_id, e.code
                         FROM exercises.exercise_equipment eq
                         JOIN exercises.equipment e ON e.id = eq.equipment_id""")
        equipment_by_exercise = {}
        for exercise_id, equipment_code in cur.fetchall():
            equipment_by_exercise.setdefault(exercise_id, set()).add(equipment_code)

        stats = Counter()
        unmapped_family = Counter()

        # Compute everything in Python first, then push it in a handful of
        # batched statements. Row-at-a-time over a remote DB meant ~25k
        # round trips and minutes of wall clock; batching makes it seconds.
        exercise_rows, pattern_rows, action_rows, tracking_rows = [], [], [], []
        muscle_rows, bias_rows, biomech_rows = [], [], []

        for exercise_id, name, unilateral, bodyweight in exercises:
            archetype = GEN.classify(name)
            if archetype is None:
                stats["unclassified"] += 1
                continue
            spec = GEN.A[archetype]
            v2 = MAP.V2[archetype]
            stats[f"kind:{v2['kind']}"] += 1

            family_id = family_ids.get(v2["family"])
            if family_id is None:
                unmapped_family[v2["family"]] += 1

            exercise_rows.append((v2["kind"], v2["td"], v2["jc"], v2["sp"],
                                  family_id, exercise_id))

            for pattern_code, role in v2["mp"]:
                pattern_id = pattern_ids.get(pattern_code)
                if pattern_id is None:
                    stats["missing_pattern"] += 1
                    continue
                pattern_rows.append((exercise_id, pattern_id, role))

            for joint, action, role in v2["ja"]:
                action_id = action_ids.get((joint, action))
                if action_id is None:
                    stats["missing_joint_action"] += 1
                    continue
                action_rows.append((exercise_id, action_id, role))

            tracking_type, load_mode, side_mode, scope = v2["tr"]
            # the catalogue's own unilateral/bodyweight flags win over the
            # archetype default: they are per-exercise facts
            if unilateral and side_mode == "none":
                side_mode = "separate"
            if bodyweight and tracking_type == "weight_reps":
                tracking_type, load_mode, scope = "bodyweight_reps", "none", "bodyweight_aware"
            # Coachly convention: a hand-held implement is logged per implement
            # (a 32 kg dumbbell curl is 32, not 64).
            if load_mode == "total_load" and                     equipment_by_exercise.get(exercise_id, set()) & PER_IMPLEMENT_EQUIPMENT:
                load_mode = "per_implement"
                if side_mode == "none":
                    side_mode = "optional"
            evidence, confidence = PROVENANCE[spec["conf"]]
            tracking_rows.append((exercise_id, tracking_type, load_mode, side_mode,
                                  scope, "expert_curated", confidence))

            lengthened, midrange, shortened = MAP.tension_levels(spec, GEN.curve_points)
            muscle_rows.append((lengthened, midrange, shortened, evidence,
                                confidence, exercise_id))

            for bias, muscle_codes in spec["mb"].items():
                if not muscle_codes or bias == "mid_range":
                    continue
                if bias == "lengthened":
                    new_l, new_s = MAP.shift(lengthened, 1), MAP.shift(shortened, -1)
                else:
                    new_l, new_s = MAP.shift(lengthened, -1), MAP.shift(shortened, 1)
                bias_rows.append((new_l, new_s, exercise_id, sorted(set(muscle_codes))))

            biomech_rows.append((spec["axial"], evidence, confidence,
                                 f"archetype={archetype}; derived by v2_step3_classify",
                                 exercise_id))

        cur.executemany("""UPDATE exercises.exercise
                              SET exercise_kind = %s, technical_demand = %s,
                                  joint_class = %s, spotter_policy = %s,
                                  family_id = %s, updated_at = NOW()
                            WHERE id = %s""", exercise_rows)
        stats["exercises_classified"] = len(exercise_rows)

        cur.executemany("""INSERT INTO exercises.exercise_movement_pattern
                               (exercise_id, movement_pattern_id, role)
                           VALUES (%s, %s, %s)
                           ON CONFLICT (exercise_id, movement_pattern_id)
                           DO UPDATE SET role = EXCLUDED.role""", pattern_rows)
        stats["movement_pattern_links"] = len(pattern_rows)

        cur.executemany("""INSERT INTO exercises.exercise_joint_action
                               (exercise_id, joint_action_id, role)
                           VALUES (%s, %s, %s)
                           ON CONFLICT (exercise_id, joint_action_id)
                           DO UPDATE SET role = EXCLUDED.role""", action_rows)
        stats["joint_action_links"] = len(action_rows)

        cur.executemany("""INSERT INTO exercises.exercise_tracking_profile
                               (exercise_id, tracking_type, load_input_mode, side_mode,
                                comparison_scope, evidence_basis, confidence)
                           VALUES (%s, %s, %s, %s, %s, %s, %s)
                           ON CONFLICT (exercise_id) DO UPDATE SET
                               tracking_type = EXCLUDED.tracking_type,
                               load_input_mode = EXCLUDED.load_input_mode,
                               side_mode = EXCLUDED.side_mode,
                               comparison_scope = EXCLUDED.comparison_scope,
                               evidence_basis = EXCLUDED.evidence_basis,
                               confidence = EXCLUDED.confidence,
                               updated_at = NOW()""", tracking_rows)
        stats["tracking_profiles"] = len(tracking_rows)

        cur.executemany("""UPDATE exercises.exercise_muscle
                              SET tension_lengthened = %s, tension_midrange = %s,
                                  tension_shortened = %s, evidence_basis = %s,
                                  confidence = %s, updated_at = NOW()
                            WHERE exercise_id = %s""", muscle_rows)

        # bias overrides must land AFTER the defaults above
        cur.executemany("""UPDATE exercises.exercise_muscle em
                              SET tension_lengthened = %s, tension_shortened = %s
                             FROM exercises.muscle m
                            WHERE em.muscle_id = m.id AND em.exercise_id = %s
                              AND m.code = ANY(%s)""", bias_rows)
        stats["muscle_bias_overrides"] = len(bias_rows)

        cur.executemany("""UPDATE exercises.exercise_biomechanics
                              SET spinal_loading = %s, evidence_basis = %s,
                                  confidence = %s, method_note = %s, updated_at = NOW()
                            WHERE exercise_id = %s""", biomech_rows)

        # ---- equipment classes ----
        cur.execute("SELECT id, code, category FROM exercises.equipment")
        for equipment_id, code, category in cur.fetchall():
            klass = EQUIPMENT_CLASS_BY_CODE.get(code) \
                or EQUIPMENT_CLASS_BY_CATEGORY.get(category, "other")
            cur.execute("""UPDATE exercises.equipment
                              SET equipment_class = %s, updated_at = NOW() WHERE id = %s""",
                        (klass, equipment_id))
            stats[f"equipment:{klass}"] += 1

        print("--- classification")
        for key in sorted(stats):
            print(f"   {key:28s} {stats[key]}")
        if unmapped_family:
            print("   !! family codes missing from exercise_family:", dict(unmapped_family))

        # ---- verification ----
        print("\n--- verification")
        checks = [
            ("exercises without kind",
             "SELECT count(*) FROM exercises.exercise WHERE deleted_at IS NULL AND exercise_kind IS NULL"),
            ("exercises without family",
             "SELECT count(*) FROM exercises.exercise WHERE deleted_at IS NULL AND family_id IS NULL"),
            ("exercises without tracking profile",
             """SELECT count(*) FROM exercises.exercise e
                 LEFT JOIN exercises.exercise_tracking_profile t ON t.exercise_id = e.id
                WHERE e.deleted_at IS NULL AND t.exercise_id IS NULL"""),
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
            ("PRIMARY muscles without tension profile",
             """SELECT count(*) FROM exercises.exercise_muscle
                 WHERE involvement = 'primary' AND tension_lengthened IS NULL"""),
            ("biomechanics without spinal_loading",
             "SELECT count(*) FROM exercises.exercise_biomechanics WHERE spinal_loading IS NULL"),
            ("equipment without class",
             "SELECT count(*) FROM exercises.equipment WHERE equipment_class IS NULL"),
        ]
        for label, query in checks:
            cur.execute(query)
            print(f"   {label:42s} {cur.fetchone()[0]}")

        if args.apply:
            conn.commit()
            print("\nCOMMITTED")
        else:
            conn.rollback()
            print("\nDRY RUN - rolled back")


if __name__ == "__main__":
    main()
