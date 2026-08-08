#!/usr/bin/env python3
"""
Exercise model V2 - PHASE 2, STEP 6
Tag audit.

A tag earns its place only if it carries something the structured model does
NOT already express. Everything else is archived (never deleted: the links
survive, so the decision is reversible and nothing is lost).

Three families go:

1. Duplicates of structured columns - unilateral, bilateral, no_equipment,
   gym_only, spotter_recommended, beginner_friendly...
2. Goals attached to the exercise - strength, hypertrophy, power, fat_loss.
   An exercise is not "a strength exercise"; the PROGRAM decides why it is
   there. Training intent belongs to the workout service.
3. Programming methods - supersets, drop_set, cluster_sets, circuit_training.
   Those describe how a set is run, not what the exercise is.

Usage:
    python inj/_tools/v2_step6_tag_audit.py --dsn "..." [--apply]
"""
import argparse
import sys

import psycopg

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

# tag code -> why it is being retired
RETIRE = {
    # --- 1. already expressed by a structured column ---
    "unilateral": "exercise.unilateral",
    "bilateral": "exercise.unilateral (inverse)",
    "bodyweight": "exercise.bodyweight",
    "no_equipment": "absence of exercise_equipment",
    "gym_only": "equipment.equipment_class",
    "home_gym": "equipment.equipment_class",
    "minimal_equipment": "equipment.equipment_class",
    "spotter_recommended": "exercise.spotter_policy",
    "beginner_friendly": "exercise.technical_demand",
    "high_skill": "exercise.technical_demand",
    "isometric": "tracking_profile.tracking_type = time",
    "explosive": "movement_pattern jump / exercise_kind",
    "flexibility_goal": "exercise_kind = mobility",
    "mobility_goal": "exercise_kind = mobility",
    "push_day": "movement patterns",
    "pull_day": "movement patterns",
    "leg_day": "movement patterns",
    "upper_day": "movement patterns",
    "lower_day": "movement patterns",
    "core_stability": "muscle group + stability_demand",
    # --- 2. goals: a property of the program, not of the exercise ---
    "strength": "training intent belongs to the program",
    "hypertrophy": "training intent belongs to the program",
    "power": "training intent belongs to the program",
    "endurance": "training intent belongs to the program",
    "fat_loss": "training intent belongs to the program",
    "body_recomposition": "training intent belongs to the program",
    "sport_performance": "training intent belongs to the program",
    "cardiovascular_fitness": "training intent belongs to the program",
    "posture_correction": "training intent belongs to the program",
    # --- 3. programming methods, not exercise properties ---
    "supersets": "set method, belongs to the program",
    "drop_set": "set method, belongs to the program",
    "cluster_sets": "set method, belongs to the program",
    "rest_pause": "set method, belongs to the program",
    "circuit_training": "session method, belongs to the program",
    "hiit": "session method, belongs to the program",
    "tempo_training": "set method, belongs to the program",
    "eccentric_focus": "set method, belongs to the program",
    "crossfit": "discipline, already a category",
    # --- risk verdict we deliberately removed from the model ---
    "injury_risk": "a universal risk verdict has no basis; see safety notes",
}

# what a tag is FOR: editorial or search value with no structured home
KEEP_REASON = {
    "grip_intensive": "grip demand is not modelled anywhere",
    "back_friendly": "editorial guidance for a constraint",
    "knee_friendly": "editorial guidance for a constraint",
    "shoulder_friendly": "editorial guidance for a constraint",
    "mind_muscle": "coaching cue",
    "functional": "editorial",
    "popular": "editorial / ranking",
    "underrated": "editorial / ranking",
    "coachly_pick": "editorial / curation",
    "time_efficient": "editorial",
}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dsn", required=True)
    ap.add_argument("--apply", action="store_true")
    args = ap.parse_args()

    with psycopg.connect(args.dsn, connect_timeout=20) as conn:
        conn.autocommit = False
        cur = conn.cursor()

        cur.execute("SELECT code FROM exercises.tag")
        existing = {r[0] for r in cur.fetchall()}
        unknown = sorted(set(RETIRE) - existing)
        if unknown:
            print("  (tag codes not present, ignored:", unknown, ")")

        cur.execute("""SELECT t.code, count(et.exercise_id)
                         FROM exercises.tag t
                         LEFT JOIN exercises.exercise_tag et ON et.tag_id = t.id
                        WHERE t.code = ANY(%s)
                        GROUP BY t.code ORDER BY 2 DESC""", (list(RETIRE),))
        retired = cur.fetchall()
        total_links = sum(n for _c, n in retired)
        print(f"retiring {len(retired)} tags covering {total_links} links")
        for code, count in retired:
            print(f"   {code:26s} {count:5d}  <- {RETIRE[code]}")

        cur.execute("""UPDATE exercises.tag
                          SET status = 'archived', deleted_at = NOW(), updated_at = NOW()
                        WHERE code = ANY(%s)""", (list(RETIRE),))
        print(f"\narchived: {cur.rowcount} (links preserved, decision reversible)")

        cur.execute("""SELECT t.code, t.tag_type, count(et.exercise_id)
                         FROM exercises.tag t
                         LEFT JOIN exercises.exercise_tag et ON et.tag_id = t.id
                        WHERE t.status = 'active'
                        GROUP BY t.code, t.tag_type ORDER BY 3 DESC""")
        kept = cur.fetchall()
        print(f"\nstill active: {len(kept)}")
        for code, tag_type, count in kept:
            reason = KEEP_REASON.get(code, "review")
            print(f"   {str(tag_type):18s} {code:22s} {count:5d}  {reason}")

        if args.apply:
            conn.commit()
            print("\nCOMMITTED")
        else:
            conn.rollback()
            print("\nDRY RUN - rolled back")


if __name__ == "__main__":
    main()
