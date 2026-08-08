#!/usr/bin/env python3
"""
Exercise model V2 - PHASE 2, STEP 11
Second literature batch: elbow flexors and extensors.

Three papers, all fetched and read:

* Maeo 2023 - triceps grew ~1.4x more training overhead than in the neutral
  arm position, because the biarticular long head is lengthened overhead. Our
  stored profiles already say exactly that (tri_overhead high/moderate/low,
  tri_pushdown low/high/high), so those rows are promoted to LITERATURE.

* Kassiano 2025 - preacher and incline curls grew DIFFERENT regions: incline
  (shoulder extended) the proximal elbow flexors, preacher (shoulder flexed)
  the distal ones. Our preacher rows claimed the biceps long head is maximally
  lengthened, which is wrong: elbow extension lengthens it but shoulder flexion
  shortens it, and the two partly cancel. Corrected to a mid-range peak. The
  monoarticular brachialis is untouched - it really is at long length there.

* Larsen 2026 - a deliberately INCONVENIENT result. Training the cable curl
  with a maximally extended shoulder versus neutral produced the same growth
  (~7-9% both), with evidence favouring the null. It does not refute the
  mechanics we store (shoulder extension does lengthen the long head), but it
  does refute the practical claim that a Bayesian-style curl is therefore
  superior. So the reference is attached with that note and the rows are NOT
  promoted: recording a null result is the point of having provenance at all.

Usage:
    python inj/_tools/v2_step11_literature_arms.py [--apply]
"""
import argparse
import os
import pathlib
import sys

import psycopg

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from dsn import get_dsn  # noqa: E402

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

REFERENCES = [
    {
        "key": "maeo2023",
        "title": "Triceps brachii hypertrophy is substantially greater after elbow extension "
                 "training performed in the overhead versus neutral arm position",
        "authors": "Maeo S, Wu Y, Huang M, Sakurai H, Kusagawa Y, Sugiyama T, "
                   "Kanehisa H, Isaka T",
        "year": 2023,
        "doi": "10.1080/17461391.2022.2100279",
        "url": "https://pubmed.ncbi.nlm.nih.gov/35819335/",
        "source_type": "journal_article",
    },
    {
        "key": "kassiano2025",
        "title": "Distinct muscle growth and strength adaptations after preacher and "
                 "incline biceps curls",
        "authors": "Kassiano W, Costa B, Kunevaliki G, Lisboa F, Stavinski N, Prado A, "
                   "Tricoli I, Francsuel J, Lima L, Nunes JP, Ribeiro AS, Cyrino ES",
        "year": 2025,
        "doi": "10.1055/a-2517-0509",
        "url": "https://pubmed.ncbi.nlm.nih.gov/39809454/",
        "source_type": "journal_article",
    },
    {
        "key": "larsen2026",
        "title": "The effects of shoulder extension angle on elbow flexor hypertrophy "
                 "in the cable curl exercise",
        "authors": "Larsen S, Sandvik Kristiansen B, Osteras Sandberg N, Bao Fredriksen A, "
                   "van den Tillaar R, Wolf M, Swinton PA, Nygaard Falch H",
        "year": 2026,
        "doi": "10.3389/fphys.2026.1750722",
        "url": "https://www.frontiersin.org/journals/physiology/articles/10.3389/fphys.2026.1750722/full",
        "source_type": "journal_article",
    },
]

LINKS = [
    ("maeo2023", "muscle",
     "Elbow extension trained overhead produced ~1.4x the triceps growth of the neutral "
     "arm position; the long head is lengthened overhead.",
     "('tri_overhead','tri_overhead_cable','tri_pushdown','tri_skullcrusher',"
     "'tri_band_pushdown','tri_extension_lever','tri_kickback')"),
    ("kassiano2025", "muscle",
     "Incline curls grew the proximal elbow flexors, preacher curls the distal ones: "
     "shoulder position redistributes growth rather than simply increasing it.",
     "('curl_preacher','curl_incline','curl_spider','curl_concentration')"),
    ("larsen2026", "muscle",
     "NULL RESULT: cable curls with a maximally extended shoulder produced the same "
     "growth as a neutral shoulder. The stored tension profile reflects mechanics, not "
     "a claim that this variant grows more muscle.",
     "('curl_bayesian','curl_cable','curl_sprinter','curl_overhead_cable')"),
]

# the preacher curl claim the literature and anatomy jointly contradict
CORRECTIONS = [
    ("('curl_preacher')", ["biceps_brachii_long", "biceps_brachii_short"],
     ("moderate", "high", "low"), "kassiano2025",
     "elbow extension lengthens the biceps but the flexed shoulder shortens it; "
     "the two partly cancel, so it does not peak at long length"),
]

CONFIRMATIONS = [
    ("('tri_overhead','tri_overhead_cable')", ["triceps_brachii_long"], "maeo2023"),
    ("('tri_pushdown')", ["triceps_brachii_long"], "maeo2023"),
    ("('curl_incline')", ["biceps_brachii_long"], "kassiano2025"),
    ("('curl_preacher')", ["brachialis"], "kassiano2025"),
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
                                  year = EXCLUDED.year, url = EXCLUDED.url,
                                  source_type = EXCLUDED.source_type, updated_at = NOW()
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
            print(f"   {key:14s} -> {cur.rowcount} exercises")

        print("\ncorrections:")
        for archetypes, muscles, profile, key, why in CORRECTIONS:
            lengthened, midrange, shortened = profile
            cur.execute(f"""UPDATE exercises.exercise_muscle em
                               SET tension_lengthened = %s, tension_midrange = %s,
                                   tension_shortened = %s, evidence_basis = 'literature',
                                   confidence = 'high', updated_at = NOW()
                              FROM exercises.exercise e
                              JOIN exercises.exercise_biomechanics b ON b.exercise_id = e.id
                              JOIN exercises.muscle m ON m.code = ANY(%s)
                             WHERE em.exercise_id = e.id AND em.muscle_id = m.id
                               AND e.deleted_at IS NULL AND {ARCH} IN {archetypes}""",
                        (lengthened, midrange, shortened, muscles))
            print(f"   [{key}] {', '.join(muscles)} -> {'/'.join(profile)}  ({cur.rowcount} rows)")
            print(f"        {why}")

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

        cur.execute("""SELECT evidence_basis::text, confidence::text, count(*)
                         FROM exercises.exercise_muscle GROUP BY 1,2 ORDER BY 3 DESC""")
        print("\nprovenance:", "; ".join(f"{a}/{b}={n}" for a, b, n in cur.fetchall()))
        cur.execute("SELECT count(*) FROM exercises.reference_source")
        refs = cur.fetchone()[0]
        cur.execute("SELECT count(DISTINCT exercise_id) FROM exercises.exercise_reference")
        print(f"references: {refs}, exercises with a citation: {cur.fetchone()[0]}")

        cur.execute("""SELECT count(*) FROM exercises.exercise_muscle
                        WHERE involvement = 'primary' AND tension_lengthened IS NULL""")
        broken = cur.fetchone()[0]
        if broken:
            conn.rollback()
            sys.exit(f"invariant broken ({broken}) - rolled back")

        if args.apply:
            conn.commit()
            print("COMMITTED")
        else:
            conn.rollback()
            print("DRY RUN - rolled back")


if __name__ == "__main__":
    main()
