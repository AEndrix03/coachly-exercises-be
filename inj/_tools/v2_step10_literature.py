#!/usr/bin/env python3
"""
Exercise model V2 - PHASE 2, STEP 10
Populate the bibliography, link it to the exercises it actually covers, and
promote the rows the literature directly supports to evidence_basis =
LITERATURE.

Until now `reference_source` was empty and no row in the catalogue was backed
by a citation. Only claims traceable to a paper we actually opened are promoted
here; everything else keeps its modelled/heuristic provenance.

Two stored values are also CORRECTED because the literature contradicts them:

1. Seated calf raise, gastrocnemius. It was stored as high tension at long
   length. With the knee flexed the gastrocnemius is SHORTENED - it crosses the
   knee - so it cannot be loaded at length there. Kinoshita 2023 measured
   +0.6/+1.7% gastrocnemius growth seated versus +9.2/+12.4% standing, while
   the monoarticular soleus grew the same either way.

2. Seated leg curl, biceps femoris short head. It inherited the lengthened bias
   of the biarticular hamstrings, but the short head does not cross the hip, so
   hip flexion cannot lengthen it. Maeo 2021 found the extra growth was
   "exclusively for the biarticular hamstrings".

Usage:
    python inj/_tools/v2_step10_literature.py [--apply]
"""
import argparse
import json
import os
import sys

import psycopg

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

# Every entry below was fetched and read; titles, authors and DOIs are verbatim.
REFERENCES = [
    {
        "key": "maeo2021",
        "title": "Greater Hamstrings Muscle Hypertrophy but Similar Damage Protection "
                 "after Training at Long versus Short Muscle Lengths",
        "authors": "Maeo S, Huang M, Wu Y, Sakurai H, Kusagawa Y, Sugiyama T, Kanehisa H, Isaka T",
        "year": 2021,
        "doi": "10.1249/MSS.0000000000002523",
        "url": "https://pubmed.ncbi.nlm.nih.gov/33009197/",
        "source_type": "journal_article",
    },
    {
        "key": "kinoshita2023",
        "title": "Triceps surae muscle hypertrophy is greater after standing versus "
                 "seated calf-raise training",
        "authors": "Kinoshita M, Maeo S, Kobayashi Y, Eihara Y, Ono M, Sato M, "
                   "Sugiyama T, Kanehisa H, Isaka T",
        "year": 2023,
        "doi": "10.3389/fphys.2023.1272106",
        "url": "https://pmc.ncbi.nlm.nih.gov/articles/PMC10753835/",
        "source_type": "journal_article",
    },
    {
        "key": "heidel2022",
        "title": "Machines and free weight exercises: a systematic review and meta-analysis "
                 "comparing changes in muscle size, strength, and power",
        "authors": "Heidel KA, Novak ZJ, Dankel SJ",
        "year": 2022,
        "doi": "10.23736/S0022-4707.21.12929-9",
        "url": "https://pubmed.ncbi.nlm.nih.gov/34609100/",
        "source_type": "meta_analysis",
    },
    {
        "key": "collings2025",
        "title": "Reconsidering Exercise Selection with EMG: Poor Agreement between Ranking "
                 "Hip Exercises with Gluteal EMG and Muscle Force",
        "authors": "Collings TJ, Bourne MN, Barrett RS, Meinders E, Goncalves B, "
                   "Shield AJ, Diamond LE",
        "year": 2025,
        "doi": "10.1249/MSS.0000000000003733",
        "url": "https://pubmed.ncbi.nlm.nih.gov/40263750/",
        "source_type": "journal_article",
    },
    {
        "key": "zabaleta2021",
        "title": "The role of exercise selection in regional muscle hypertrophy: "
                 "A randomized controlled trial",
        "authors": "Zabaleta-Korta A, Fernandez-Pena E, Torres-Unda J, Garbisu-Hualde A, "
                   "Santos-Concejero J",
        "year": 2021,
        "doi": "10.1080/02640414.2021.1929736",
        "url": "https://pubmed.ncbi.nlm.nih.gov/34743671/",
        "source_type": "journal_article",
    },
    {
        "key": "nunes2021",
        "title": "What influence does resistance exercise order have on muscular strength "
                 "gains and muscle hypertrophy? A systematic review and meta-analysis",
        "authors": "Nunes JP, Grgic J, Cunha PM, Ribeiro AS, Schoenfeld BJ, "
                   "de Salles BF, Cyrino ES",
        "year": 2021,
        "doi": "10.1080/17461391.2020.1733672",
        "url": "https://pubmed.ncbi.nlm.nih.gov/32077380/",
        "source_type": "meta_analysis",
    },
    {
        "key": "wolf2025",
        "title": "Lengthened partial repetitions elicit similar muscular adaptations as full "
                 "range of motion repetitions during resistance training in trained individuals",
        "authors": "Wolf M, Androulakis Korakakis P, Pinero A, Mohan AE, Hermann T, "
                   "Augustin F, Sapuppo M, Lin B, Coleman M, Burke R, Nippard J, "
                   "Swinton PA, Schoenfeld BJ",
        "year": 2025,
        "doi": "10.7717/peerj.18904",
        "url": "https://pubmed.ncbi.nlm.nih.gov/39959841/",
        "source_type": "journal_article",
    },
]

# reference key -> (scope, note, SQL predicate selecting the exercises it covers)
LINKS = [
    ("maeo2021", "muscle",
     "Hamstring hypertrophy was greater seated than prone, exclusively for the "
     "biarticular hamstrings.",
     "archetype IN ('leg_curl_seated','leg_curl_lying','leg_curl_band','slider_leg_curl')"),
    ("kinoshita2023", "muscle",
     "Gastrocnemius grew far more with standing calf raises; the monoarticular "
     "soleus grew equally in both.",
     "archetype IN ('calf_raise_standing','calf_raise_seated','calf_machine_lever',"
     "'calf_raise_leg_press','calf_raise_band')"),
    ("zabaleta2021", "muscle",
     "Exercise selection drives regional hypertrophy: leg extension grew all rectus "
     "femoris regions, squat only the central vastus lateralis.",
     "archetype IN ('leg_extension','squat_back','squat_front','leg_press')"),
    ("collings2025", "muscle",
     "EMG amplitude is a poor proxy for muscle force, so it is not used to rank "
     "exercises in this catalogue.",
     "archetype IN ('hip_thrust','glute_bridge','kickback_glute','squat_back','rdl')"),
    ("heidel2022", "general",
     "Machines and free weights produce equivalent hypertrophy; specificity matters "
     "for strength testing.",
     "archetype IN ('bench_machine','leg_press','squat_hack','row_machine',"
     "'ohp_machine','chest_press_machine')"),
]

# literature-grounded corrections: (predicate, muscle codes, new profile, reference key, why)
CORRECTIONS = [
    ("archetype = 'calf_raise_seated'",
     ["gastrocnemius_medial", "gastrocnemius_lateral"],
     ("low", "low", "low"), "kinoshita2023",
     "knee flexed shortens the gastrocnemius, so it cannot be loaded at long length"),
    ("archetype = 'leg_curl_seated'",
     ["biceps_femoris_short"],
     ("low", "high", "high"), "maeo2021",
     "the short head does not cross the hip, so hip flexion cannot lengthen it"),
    ("archetype = 'calf_raise_seated'",
     ["soleus"],
     ("high", "moderate", "low"), "kinoshita2023",
     "the soleus is monoarticular: same ankle ROM seated or standing, so same profile"),
]

# rows the literature CONFIRMS, promoted to evidence_basis = literature
CONFIRMATIONS = [
    ("archetype IN ('leg_curl_seated','leg_curl_lying')",
     ["biceps_femoris_long", "semitendinosus", "semimembranosus"], "maeo2021"),
    ("archetype = 'calf_raise_standing'",
     ["gastrocnemius_medial", "gastrocnemius_lateral"], "kinoshita2023"),
    ("archetype = 'calf_raise_seated'",
     ["gastrocnemius_medial", "gastrocnemius_lateral", "soleus"], "kinoshita2023"),
    ("archetype = 'leg_curl_seated'", ["biceps_femoris_short"], "maeo2021"),
]

ARCHETYPE_EXPR = ("split_part(split_part(b.method_note,'archetype=',2),';',1)")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dsn", default=os.environ.get("COACHLY_BIOMECH_DSN"))
    ap.add_argument("--apply", action="store_true")
    args = ap.parse_args()
    if not args.dsn:
        sys.exit("no DSN: set COACHLY_BIOMECH_DSN")

    with psycopg.connect(args.dsn, connect_timeout=30) as conn:
        conn.autocommit = False
        cur = conn.cursor()

        # ---- 1. bibliography ----
        ids = {}
        for ref in REFERENCES:
            cur.execute("""INSERT INTO exercises.reference_source
                               (title, authors, year, doi, url, source_type)
                           VALUES (%s, %s, %s, %s, %s, %s)
                           ON CONFLICT (doi) WHERE doi IS NOT NULL DO UPDATE
                              SET title = EXCLUDED.title, authors = EXCLUDED.authors,
                                  year = EXCLUDED.year, url = EXCLUDED.url,
                                  source_type = EXCLUDED.source_type, updated_at = NOW()
                           RETURNING id""",
                        (ref["title"], ref["authors"], ref["year"], ref["doi"],
                         ref["url"], ref["source_type"]))
            ids[ref["key"]] = cur.fetchone()[0]
        print(f"references stored: {len(ids)}")

        # ---- 2. link to the exercises each one covers ----
        total_links = 0
        for key, scope, note, predicate in LINKS:
            cur.execute(f"""INSERT INTO exercises.exercise_reference
                                (exercise_id, reference_id, scope, note)
                            SELECT e.id, %s, %s, %s
                              FROM exercises.exercise e
                              JOIN exercises.exercise_biomechanics b ON b.exercise_id = e.id
                             WHERE e.deleted_at IS NULL
                               AND {ARCHETYPE_EXPR} IS NOT NULL
                               AND {predicate.replace('archetype', ARCHETYPE_EXPR)}
                            ON CONFLICT DO NOTHING""", (ids[key], scope, note))
            print(f"   {key:14s} -> {cur.rowcount} exercises")
            total_links += cur.rowcount
        print(f"exercise_reference rows: {total_links}")

        # ---- 3. corrections the literature forces ----
        print("\nliterature-driven corrections:")
        for predicate, muscles, profile, key, why in CORRECTIONS:
            lengthened, midrange, shortened = profile
            cur.execute(f"""UPDATE exercises.exercise_muscle em
                               SET tension_lengthened = %s, tension_midrange = %s,
                                   tension_shortened = %s, evidence_basis = 'literature',
                                   confidence = 'high', updated_at = NOW()
                              FROM exercises.exercise e
                              JOIN exercises.exercise_biomechanics b ON b.exercise_id = e.id
                              JOIN exercises.muscle m ON m.code = ANY(%s)
                             WHERE em.exercise_id = e.id AND em.muscle_id = m.id
                               AND e.deleted_at IS NULL
                               AND {predicate.replace('archetype', ARCHETYPE_EXPR)}""",
                        (lengthened, midrange, shortened, muscles))
            print(f"   [{key}] {', '.join(muscles)} -> {'/'.join(profile)}  ({cur.rowcount} rows)")
            print(f"        {why}")

        # ---- 4. rows the literature confirms ----
        print("\nrows promoted to evidence_basis = literature:")
        for predicate, muscles, key in CONFIRMATIONS:
            cur.execute(f"""UPDATE exercises.exercise_muscle em
                               SET evidence_basis = 'literature', confidence = 'high',
                                   updated_at = NOW()
                              FROM exercises.exercise e
                              JOIN exercises.exercise_biomechanics b ON b.exercise_id = e.id
                              JOIN exercises.muscle m ON m.code = ANY(%s)
                             WHERE em.exercise_id = e.id AND em.muscle_id = m.id
                               AND e.deleted_at IS NULL
                               AND {predicate.replace('archetype', ARCHETYPE_EXPR)}""",
                        (muscles,))
            print(f"   [{key}] {cur.rowcount} rows")

        # ---- 5. report ----
        cur.execute("""SELECT evidence_basis::text, confidence::text, count(*)
                         FROM exercises.exercise_muscle GROUP BY 1,2 ORDER BY 3 DESC""")
        print("\nprovenance now:", "; ".join(f"{a}/{b}={n}" for a, b, n in cur.fetchall()))
        cur.execute("SELECT count(*) FROM exercises.reference_source")
        refs = cur.fetchone()[0]
        cur.execute("SELECT count(DISTINCT exercise_id) FROM exercises.exercise_reference")
        print(f"references: {refs}, exercises with a citation: {cur.fetchone()[0]}")

        cur.execute("""SELECT count(*) FROM exercises.exercise_muscle
                        WHERE involvement = 'primary' AND tension_lengthened IS NULL""")
        broken = cur.fetchone()[0]
        print(f"primary muscles without tension profile: {broken}")
        if broken:
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
