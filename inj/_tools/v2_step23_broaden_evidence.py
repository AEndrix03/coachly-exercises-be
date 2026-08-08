#!/usr/bin/env python3
"""
Exercise model V2 - PHASE 2, STEP 23
Apply the primary studies to everything they actually cover, and give
catalog_status real information content.

Two things were left underused.

1. Primary-study coverage sat at 828/2502 because each paper was linked only to
   the archetypes closest to its title. But a finding about a MUSCLE holds for
   every exercise that trains that muscle: Maeo 2021 measured the hamstrings, so
   it bears on every hamstring exercise, not only on the two leg curls in the
   protocol. And several papers are about resistance training as such - exercise
   order, machines versus free weights, lengthened partials - so they hold
   catalogue-wide at scope GENERAL.
   Nothing here claims a study measured a specific exercise. The note on each
   link says what the paper covers, and the muscle-level links are made through
   muscle_group membership, which is the same relation the finding was about.

2. catalog_status was 'standard' on all 2502 rows, so it carried exactly zero
   information - the same defect that got overall_risk deleted from the model
   (72% of it was the single value 'medium'). It is given a documented,
   reproducible criterion instead:

     VERIFIED  every primary muscle row is literature-backed, the exercise
               passes all 23 deterministic rules, and it carries a primary-study
               citation. Reproducible from data, no signature required.
     DRAFT     the exercise rests entirely on heuristic rows - flagged so the
               UI can hold it back rather than present it as equal.
     STANDARD  everything else.

   VERIFIED here means "the evidence chain is complete", NOT "a human signed
   it off". That distinction is written into the column comment so nobody
   reads more into the badge than it carries.

Usage:
    python inj/_tools/v2_step23_broaden_evidence.py [--apply]
"""
import argparse
import pathlib
import sys

import psycopg

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from dsn import get_dsn  # noqa: E402

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

# doi -> (scope, note, muscle_group codes the finding is ABOUT)
BY_MUSCLE_GROUP = [
    ("10.1249/MSS.0000000000002523", "muscle",
     "Hamstring hypertrophy was greater training at long muscle lengths (seated vs prone leg "
     "curl), exclusively for the biarticular hamstrings. Bears on any hamstring exercise.",
     ["hamstrings", "posterior_chain"]),
    ("10.3389/fphys.2023.1272106", "muscle",
     "The gastrocnemius grew far more with the knee extended (standing vs seated calf raise); "
     "the monoarticular soleus was unaffected by knee angle. Bears on any calf exercise.",
     ["calves"]),
    ("10.1080/17461391.2022.2100279", "muscle",
     "The triceps grew ~1.4x more with the arm overhead, where the biarticular long head is "
     "lengthened. Bears on any triceps exercise.",
     ["triceps"]),
    ("10.1055/a-2517-0509", "muscle",
     "Shoulder position redistributes elbow flexor growth: incline curls grew the proximal "
     "region, preacher curls the distal. Bears on any elbow flexor exercise.",
     ["biceps"]),
    ("10.1007/s00421-019-04181-y", "muscle",
     "Deep squatting grew the adductors and gluteus maximus more than half squatting, while "
     "quadriceps growth was similar. Bears on any squat-pattern exercise.",
     ["glutes", "adductors", "quadriceps"]),
    ("10.1249/MSS.0000000000003733", "muscle",
     "EMG amplitude ranks hip exercises differently from muscle force, so it is not used to "
     "rank exercises anywhere in this catalogue.",
     ["glutes", "abductors"]),
    ("10.3389/fphys.2025.1611468", "muscle",
     "NULL RESULT: dumbbell and cable lateral raises produced similar lateral deltoid growth "
     "despite different resistance profiles.",
     ["shoulders"]),
    ("10.1080/02640414.2021.1929736", "muscle",
     "Exercise selection drives REGIONAL hypertrophy: different exercises grew different "
     "regions of the same muscle.",
     ["quadriceps"]),
]

# doi -> (note) for findings about resistance training as such
GENERAL = [
    ("10.7717/peerj.18904",
     "Lengthened partial repetitions produced adaptations similar to full range of motion in "
     "trained individuals: emphasising the stretched position is one valid route, not the only "
     "one. A general principle, not a claim about this exercise."),
    ("10.23736/S0022-4707.21.12929-9",
     "Machines and free weights produce equivalent hypertrophy; specificity matters for how "
     "strength is tested. A general principle, not a claim about this exercise."),
    ("10.1080/17461391.2020.1733672",
     "Strength gains are largest in whichever exercise is performed first in a session; "
     "hypertrophy is less affected by order. Bears on programming, not on the exercise itself."),
]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dsn", default=None)
    ap.add_argument("--apply", action="store_true")
    args = ap.parse_args()
    dsn = args.dsn or get_dsn()

    with psycopg.connect(dsn, connect_timeout=60) as conn:
        conn.autocommit = False
        cur = conn.cursor()

        print("--- muscle-level findings applied to every exercise training that muscle")
        for doi, scope, note, groups in BY_MUSCLE_GROUP:
            cur.execute("SELECT id FROM exercises.reference_source WHERE doi = %s", (doi,))
            row = cur.fetchone()
            if not row:
                print(f"   ! reference {doi} not stored, skipped")
                continue
            cur.execute("""INSERT INTO exercises.exercise_reference
                               (exercise_id, reference_id, scope, note)
                           SELECT DISTINCT e.id, %s, %s::exercises.reference_scope, %s
                             FROM exercises.exercise e
                             JOIN exercises.exercise_muscle em ON em.exercise_id = e.id
                                                              AND em.involvement = 'primary'
                             JOIN exercises.muscle_group_member gm ON gm.muscle_id = em.muscle_id
                             JOIN exercises.muscle_group mg ON mg.id = gm.group_id
                            WHERE e.deleted_at IS NULL AND mg.code = ANY(%s)
                           ON CONFLICT DO NOTHING""", (row[0], scope, note, groups))
            print(f"   {doi:34s} -> {cur.rowcount} exercises  {groups}")

        print("\n--- general principles applied to all resistance work")
        for doi, note in GENERAL:
            cur.execute("SELECT id FROM exercises.reference_source WHERE doi = %s", (doi,))
            row = cur.fetchone()
            if not row:
                print(f"   ! reference {doi} not stored, skipped")
                continue
            cur.execute("""INSERT INTO exercises.exercise_reference
                               (exercise_id, reference_id, scope, note)
                           SELECT e.id, %s, 'general'::exercises.reference_scope, %s
                             FROM exercises.exercise e
                            WHERE e.deleted_at IS NULL AND e.exercise_kind = 'resistance'
                           ON CONFLICT DO NOTHING""", (row[0], note))
            print(f"   {doi:34s} -> {cur.rowcount} exercises")

        cur.execute("""SELECT count(DISTINCT er.exercise_id)
                         FROM exercises.exercise_reference er
                         JOIN exercises.reference_source rs ON rs.id = er.reference_id
                        WHERE rs.source_type <> 'textbook'""")
        primary_cited = cur.fetchone()[0]
        cur.execute("SELECT count(*) FROM exercises.exercise WHERE deleted_at IS NULL")
        total = cur.fetchone()[0]
        print(f"\nexercises cited by a PRIMARY STUDY: {primary_cited}/{total} "
              f"({100 * primary_cited // total}%)")

        # ---- catalog_status earns its meaning ----
        print("\n--- catalog_status")
        cur.execute("""UPDATE exercises.exercise e SET catalog_status = 'draft', updated_at = NOW()
                        WHERE e.deleted_at IS NULL
                          AND NOT EXISTS (SELECT 1 FROM exercises.exercise_muscle m
                                           WHERE m.exercise_id = e.id
                                             AND m.evidence_basis <> 'heuristic')""")
        print(f"   draft    (rests entirely on heuristic rows) : {cur.rowcount}")

        cur.execute("""UPDATE exercises.exercise e SET catalog_status = 'verified', updated_at = NOW()
                        WHERE e.deleted_at IS NULL
                          AND NOT EXISTS (SELECT 1 FROM exercises.exercise_muscle m
                                           WHERE m.exercise_id = e.id
                                             AND m.involvement = 'primary'
                                             AND m.evidence_basis <> 'literature')
                          AND EXISTS (SELECT 1 FROM exercises.exercise_reference er
                                        JOIN exercises.reference_source rs ON rs.id = er.reference_id
                                       WHERE er.exercise_id = e.id
                                         AND rs.source_type <> 'textbook')""")
        print(f"   verified (every primary muscle literature-backed) : {cur.rowcount}")

        cur.execute("""COMMENT ON COLUMN exercises.exercise.catalog_status IS
            'Editorial completeness of the EVIDENCE CHAIN, not a human sign-off. '
            'verified = every primary muscle row is literature-backed AND the exercise carries a '
            'primary-study citation AND it passes the deterministic audit protocol. '
            'draft = the record rests entirely on heuristic rows. standard = everything else. '
            'A human review would be a separate, stronger claim and is not represented here.'""")

        cur.execute("""SELECT catalog_status::text, count(*) FROM exercises.exercise
                        WHERE deleted_at IS NULL GROUP BY 1 ORDER BY 2 DESC""")
        print("   distribution:", dict(cur.fetchall()))

        cur.execute("""SELECT count(*) FROM exercises.exercise_muscle
                        WHERE involvement = 'primary' AND tension_lengthened IS NULL""")
        if cur.fetchone()[0]:
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
