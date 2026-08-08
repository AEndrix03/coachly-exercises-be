#!/usr/bin/env python3
"""
Exercise model V2 - PHASE 2, STEP 19
Third literature batch: squat depth, incline pressing, lateral raises.

All three fetched and read, DOIs taken from the source rather than recalled.

* Kubo 2019 - squatting to 140 vs 90 degrees of knee flexion grew the
  quadriceps about the same, but the deep squat grew the ADDUCTORS and gluteus
  maximus significantly more. That makes the adductors a real contributor to a
  deep squat, which the catalogue can check.

* Chaves 2020 - an incline-only group grew the clavicular head of pectoralis
  major substantially more than flat-only or combined. Our incline archetype
  already biases the clavicular head, so those rows are promoted.

* Larsen 2025 - another INCONVENIENT null: dumbbell and cable lateral raises
  produced similar lateral deltoid hypertrophy despite genuinely different
  resistance profiles. Recorded as a note, and the rows are NOT promoted. A
  bibliography that only stores confirmations is decoration.

Usage:
    python inj/_tools/v2_step19_literature_more.py [--apply]
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
        "key": "kubo2019",
        "title": "Effects of squat training with different depths on lower limb muscle volumes",
        "authors": "Kubo K, Ikebukuro T, Yata H",
        "year": 2019,
        "doi": "10.1007/s00421-019-04181-y",
        "url": "https://pubmed.ncbi.nlm.nih.gov/31230110/",
        "source_type": "journal_article",
    },
    {
        "key": "chaves2020",
        "title": "Effects of Horizontal and Incline Bench Press on Neuromuscular Adaptations "
                 "in Untrained Young Men",
        "authors": "Chaves SFN, Rocha-Junior VA, Encarnacao IGA, Martins-Costa HC, "
                   "Freitas EDS, Coelho DB, Franco FSC, Loenneke JP, Bottaro M, Ferreira-Junior JB",
        "year": 2020,
        "doi": "10.70252/FDNB1158",
        "url": "https://pubmed.ncbi.nlm.nih.gov/32922646/",
        "source_type": "journal_article",
    },
    {
        "key": "larsen2025",
        "title": "Dumbbell versus cable lateral raises for lateral deltoid hypertrophy: "
                 "an experimental study",
        "authors": "Larsen S, Wolf M, Schoenfeld BJ, et al.",
        "year": 2025,
        "doi": "10.3389/fphys.2025.1611468",
        "url": "https://pubmed.ncbi.nlm.nih.gov/40692697/",
        "source_type": "journal_article",
    },
]

LINKS = [
    ("kubo2019", "muscle",
     "Deep squats (140 deg knee flexion) grew the adductors and gluteus maximus more than "
     "half squats; quadriceps growth was similar at either depth.",
     "('squat_back','squat_front','squat_bodyweight','squat_hack','leg_press',"
     "'split_squat','lunge','pistol_squat')"),
    ("chaves2020", "muscle",
     "An incline-only group grew the clavicular head of pectoralis major substantially more "
     "than flat-only or combined training.",
     "('bench_incline','bench_flat','bench_decline','bench_machine','bench_smith',"
     "'press_cable_chest','fly_cable','fly_dumbbell')"),
    ("larsen2025", "muscle",
     "NULL RESULT: dumbbell and cable lateral raises produced similar lateral deltoid "
     "hypertrophy. The stored resistance profiles differ as mechanics, not as an outcome claim.",
     "('lateral_raise_db','lateral_raise_cable','lateral_raise_machine','front_raise')"),
]

CONFIRMATIONS = [
    ("('bench_incline')", ["pectoralis_major_clavicular"], "chaves2020"),
    ("('squat_back','squat_front')", ["gluteus_maximus"], "kubo2019"),
]

ARCH = "split_part(split_part(b.method_note,'archetype=',2),';',1)"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dsn", default=None,
                    help="optional; resolved from $COACHLY_BIOMECH_DSN or auto-injestion/.env")
    ap.add_argument("--apply", action="store_true")
    args = ap.parse_args()
    dsn = args.dsn or get_dsn()

    with psycopg.connect(dsn, connect_timeout=30) as conn:
        conn.autocommit = False
        cur = conn.cursor()

        ids = {}
        for ref in REFERENCES:
            cur.execute("""INSERT INTO exercises.reference_source
                               (title, authors, year, doi, url, source_type)
                           VALUES (%s, %s, %s, %s, %s, %s)
                           ON CONFLICT (doi) WHERE doi IS NOT NULL DO UPDATE
                              SET title = EXCLUDED.title, authors = EXCLUDED.authors,
                                  year = EXCLUDED.year, url = EXCLUDED.url, updated_at = NOW()
                           RETURNING id""",
                        (ref["title"], ref["authors"], ref["year"], ref["doi"],
                         ref["url"], ref["source_type"]))
            ids[ref["key"]] = cur.fetchone()[0]
        print(f"references stored: {len(ids)}")

        for key, scope, note, archetypes in LINKS:
            cur.execute(f"""INSERT INTO exercises.exercise_reference
                                (exercise_id, reference_id, scope, note)
                            SELECT e.id, %s, %s, %s
                              FROM exercises.exercise e
                              JOIN exercises.exercise_biomechanics b ON b.exercise_id = e.id
                             WHERE e.deleted_at IS NULL AND {ARCH} IN {archetypes}
                            ON CONFLICT DO NOTHING""", (ids[key], scope, note))
            print(f"   {key:12s} -> {cur.rowcount} exercises")

        print("\npromoted to literature:")
        for archetypes, muscles, key in CONFIRMATIONS:
            cur.execute(f"""UPDATE exercises.exercise_muscle em
                               SET evidence_basis = 'literature', confidence = 'high',
                                   updated_at = NOW()
                              FROM exercises.exercise e
                              JOIN exercises.exercise_biomechanics b ON b.exercise_id = e.id
                              JOIN exercises.muscle m ON m.code = ANY(%s)
                             WHERE em.exercise_id = e.id AND em.muscle_id = m.id
                               AND e.deleted_at IS NULL AND {ARCH} IN {archetypes}""",
                        (muscles,))
            print(f"   [{key}] {cur.rowcount} rows")

        # Kubo: the adductors are real contributors to a deep squat, so a squat
        # that lists none is incomplete rather than merely sparse
        cur.execute(f"""SELECT count(*) FROM exercises.exercise e
                          JOIN exercises.exercise_biomechanics b ON b.exercise_id = e.id
                         WHERE e.deleted_at IS NULL
                           AND {ARCH} IN ('squat_back','squat_front')
                           AND NOT EXISTS (
                               SELECT 1 FROM exercises.exercise_muscle em
                                 JOIN exercises.muscle mu ON mu.id = em.muscle_id
                                WHERE em.exercise_id = e.id AND mu.code LIKE 'adductor%')""")
        print(f"\nsquats with no adductor listed (Kubo 2019 says they contribute): {cur.fetchone()[0]}")

        cur.execute("SELECT count(*) FROM exercises.reference_source")
        refs = cur.fetchone()[0]
        cur.execute("SELECT count(DISTINCT exercise_id) FROM exercises.exercise_reference")
        cited = cur.fetchone()[0]
        cur.execute("SELECT count(*) FROM exercises.exercise WHERE deleted_at IS NULL")
        total = cur.fetchone()[0]
        print(f"references: {refs}, exercises with a citation: {cited}/{total} "
              f"({100 * cited // total}%)")

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
