#!/usr/bin/env python3
"""
Exercise model V2 - PHASE 2, STEP 22
Source the anatomical layer, which was carrying the whole catalogue unsourced.

Literature coverage sat at 33% and I called the rest unsourceable. That was
wrong, and worth being precise about why: no trial exists comparing, say, a
Zercher squat to a front squat, so exercise-SPECIFIC hypertrophy claims really
do stop at a third of the catalogue. But the claim underneath every single row -
"these muscles produce this joint action" - is textbook anatomy, true for all
2502 exercises, and it had no citation at all.

Two standard references cover it:

* Neumann, Kinesiology of the Musculoskeletal System (Elsevier, 3rd ed.) for
  the muscle-to-joint-action mapping that every muscle row rests on.
* NSCA, Essentials of Strength Training and Conditioning (Human Kinetics, 4th
  ed.) for the training-side conventions: joint classification, kinetic chain,
  stability and spinal loading.

They are attached at scope MUSCLE and BIOMECHANICS with a note stating exactly
what they do and do not support - so nobody reads a citation on a Zercher squat
as evidence that its tension profile was measured. Provenance is left untouched:
these rows stay EXPERT_CURATED or BIOMECHANICAL_MODEL, because a textbook
sources the anatomy, not the per-exercise judgement.

Usage:
    python inj/_tools/v2_step22_anatomical_sources.py [--apply]
"""
import argparse
import pathlib
import sys

import psycopg

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from dsn import get_dsn  # noqa: E402

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

REFERENCES = [
    {
        "key": "neumann2017",
        "title": "Kinesiology of the Musculoskeletal System: Foundations for Rehabilitation, "
                 "3rd edition",
        "authors": "Neumann DA",
        "year": 2017,
        "doi": None,
        "url": "https://shop.elsevier.com/books/kinesiology-of-the-musculoskeletal-system/"
               "neumann/978-0-323-28753-1",
        "source_type": "textbook",
        "scope": "muscle",
        "note": "Sources the muscle-to-joint-action mapping every muscle row rests on "
                "(ISBN 9780323287531). It does NOT source the per-exercise tension profile, "
                "which stays expert_curated or biomechanical_model.",
    },
    {
        "key": "nsca2016",
        "title": "Essentials of Strength Training and Conditioning, 4th edition",
        "authors": "Haff GG, Triplett NT (eds), National Strength and Conditioning Association",
        "year": 2016,
        "doi": None,
        "url": "https://us.humankinetics.com/products/essentials-of-strength-training-and-"
               "conditioning-4th-edition",
        "source_type": "textbook",
        "scope": "biomechanics",
        "note": "Sources the training-side conventions: single- vs multi-joint classification, "
                "kinetic chain, stability demand and spinal loading (ISBN 9781492501626). "
                "It does NOT source exercise-specific hypertrophy claims.",
    },
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

        for ref in REFERENCES:
            # the unique index on doi is partial, so a textbook without a DOI
            # has to be matched on its title instead
            cur.execute("SELECT id FROM exercises.reference_source WHERE title = %s",
                        (ref["title"],))
            row = cur.fetchone()
            if row:
                reference_id = row[0]
                cur.execute("""UPDATE exercises.reference_source
                                  SET authors = %s, year = %s, url = %s,
                                      source_type = %s, updated_at = NOW()
                                WHERE id = %s""",
                            (ref["authors"], ref["year"], ref["url"],
                             ref["source_type"], reference_id))
            else:
                cur.execute("""INSERT INTO exercises.reference_source
                                   (title, authors, year, doi, url, source_type)
                               VALUES (%s, %s, %s, %s, %s, %s) RETURNING id""",
                            (ref["title"], ref["authors"], ref["year"], ref["doi"],
                             ref["url"], ref["source_type"]))
                reference_id = cur.fetchone()[0]

            cur.execute("""INSERT INTO exercises.exercise_reference
                               (exercise_id, reference_id, scope, note)
                           SELECT e.id, %s, %s, %s
                             FROM exercises.exercise e
                            WHERE e.deleted_at IS NULL
                           ON CONFLICT DO NOTHING""",
                        (reference_id, ref["scope"], ref["note"]))
            print(f"   {ref['key']:14s} scope={ref['scope']:12s} -> {cur.rowcount} exercises")

        cur.execute("SELECT count(*) FROM exercises.reference_source")
        refs = cur.fetchone()[0]
        cur.execute("SELECT count(DISTINCT exercise_id) FROM exercises.exercise_reference")
        cited = cur.fetchone()[0]
        cur.execute("SELECT count(*) FROM exercises.exercise WHERE deleted_at IS NULL")
        total = cur.fetchone()[0]
        print(f"\nreferences: {refs}")
        print(f"exercises with at least one citation: {cited}/{total} ({100 * cited // total}%)")

        cur.execute("""SELECT count(DISTINCT er.exercise_id)
                         FROM exercises.exercise_reference er
                         JOIN exercises.reference_source rs ON rs.id = er.reference_id
                        WHERE rs.source_type <> 'textbook'""")
        print(f"exercises cited by a PRIMARY STUDY (not a textbook): {cur.fetchone()[0]}/{total}")

        # provenance must be untouched: a textbook sources anatomy, not judgement
        cur.execute("""SELECT evidence_basis::text, count(*) FROM exercises.exercise_muscle
                        GROUP BY 1 ORDER BY 2 DESC""")
        print("provenance (unchanged):", dict(cur.fetchall()))

        if args.apply:
            conn.commit()
            print("COMMITTED")
        else:
            conn.rollback()
            print("DRY RUN - rolled back")


if __name__ == "__main__":
    main()
