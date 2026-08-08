#!/usr/bin/env python3
"""
Exercise model V2 - THE AUDIT PROTOCOL

Six blind audits produced 47.5% -> 53.1% -> 40.0% -> 36.9% -> 30.6%, but the
last pair of auditors disagreed by 21 points on the same catalogue (41.25% vs
20.0%). Not because either was careless: one counted several catalogue-wide
conventions as errors and the other did not. Once reviewer variance exceeds the
per-round improvement, an LLM audit can no longer tell progress from noise.

So the definition of "error" has to stop being a judgement and become a rule.
Every check below is a CONTRADICTION between two stored facts: it needs no
opinion, no source, and no reviewer, so it returns the same number every time
and can gate a pipeline.

What this deliberately does NOT measure: whether a curated value is the best
one. It cannot tell you that a tension profile is subtly wrong. It tells you,
exactly and reproducibly, how much of the catalogue contradicts itself - and
that is the part that was drifting round to round.

    python inj/_tools/v2_audit_protocol.py            # report
    python inj/_tools/v2_audit_protocol.py --json     # machine readable
    python inj/_tools/v2_audit_protocol.py --max-rate 5   # exit 1 above 5%
"""
import argparse
import json
import pathlib
import sys

import psycopg

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from dsn import get_dsn  # noqa: E402

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

ARCH = "split_part(split_part(b.method_note,'archetype=',2),';',1)"

# Each rule returns the exercise CODES it finds. A code appearing in any rule
# counts once toward the rate, so the number is "share of the catalogue that
# contradicts itself", not "number of complaints".
RULES = [
    ("identity", "exercise without a stable code",
     "SELECT code FROM exercises.exercise WHERE deleted_at IS NULL AND code IS NULL"),

    ("completeness", "resistance exercise with no movement pattern",
     """SELECT e.code FROM exercises.exercise e
         WHERE e.deleted_at IS NULL AND e.exercise_kind = 'resistance'
           AND NOT EXISTS (SELECT 1 FROM exercises.exercise_movement_pattern p
                            WHERE p.exercise_id = e.id)"""),

    ("completeness", "resistance exercise with no joint action",
     """SELECT e.code FROM exercises.exercise e
         WHERE e.deleted_at IS NULL AND e.exercise_kind = 'resistance'
           AND NOT EXISTS (SELECT 1 FROM exercises.exercise_joint_action j
                            WHERE j.exercise_id = e.id)"""),

    ("completeness", "exercise with no primary muscle",
     """SELECT e.code FROM exercises.exercise e WHERE e.deleted_at IS NULL
          AND NOT EXISTS (SELECT 1 FROM exercises.exercise_muscle m
                           WHERE m.exercise_id = e.id AND m.involvement = 'primary')"""),

    ("completeness", "loaded resistance exercise with no equipment",
     """SELECT e.code FROM exercises.exercise e
         WHERE e.deleted_at IS NULL AND e.exercise_kind = 'resistance'
           AND e.bodyweight = false
           AND NOT EXISTS (SELECT 1 FROM exercises.exercise_equipment q
                            WHERE q.exercise_id = e.id)"""),

    ("completeness", "resistance exercise with no kinetic chain",
     """SELECT code FROM exercises.exercise WHERE deleted_at IS NULL
          AND exercise_kind = 'resistance' AND kinetic_chain IS NULL"""),

    ("coherence", "primary muscles cannot produce a primary joint action",
     """SELECT DISTINCT e.code FROM exercises.exercise e
         WHERE e.deleted_at IS NULL
           AND EXISTS (
               SELECT 1 FROM exercises.exercise_joint_action j
                 JOIN exercises.joint_action ja ON ja.id = j.joint_action_id
                WHERE j.exercise_id = e.id AND j.role = 'primary'
                  AND ja.joint_code = 'elbow' AND ja.action_code = 'flexion'
                  AND NOT EXISTS (SELECT 1 FROM exercises.exercise_muscle m
                                    JOIN exercises.muscle mu ON mu.id = m.muscle_id
                                   WHERE m.exercise_id = e.id
                                     AND mu.code IN ('biceps_brachii_long','biceps_brachii_short',
                                                     'brachialis','brachioradialis')))"""),

    ("coherence", "unilateral flag disagrees with side_mode",
     """SELECT e.code FROM exercises.exercise e
          JOIN exercises.exercise_tracking_profile t ON t.exercise_id = e.id
         WHERE e.deleted_at IS NULL AND e.unilateral = true AND t.side_mode = 'none'"""),

    ("coherence", "bodyweight flag disagrees with the resistance source",
     """SELECT e.code FROM exercises.exercise e
          JOIN exercises.exercise_biomechanics b ON b.exercise_id = e.id
         WHERE e.deleted_at IS NULL AND e.bodyweight = false
           AND b.resistance_source = 'bodyweight_leverage'
           AND NOT EXISTS (SELECT 1 FROM exercises.exercise_equipment q
                             JOIN exercises.equipment eq ON eq.id = q.equipment_id
                            WHERE q.exercise_id = e.id
                              AND eq.equipment_class IN ('free_weight','selectorized_machine',
                                                         'plate_loaded_machine','cable'))"""),

    ("coherence", "loaded lift whose tracking cannot record its load",
     """SELECT e.code FROM exercises.exercise e
          JOIN exercises.exercise_tracking_profile t ON t.exercise_id = e.id
         WHERE e.deleted_at IS NULL AND e.bodyweight = false
           AND t.tracking_type = 'bodyweight_reps'
           AND EXISTS (SELECT 1 FROM exercises.exercise_equipment q
                         JOIN exercises.equipment eq ON eq.id = q.equipment_id
                        WHERE q.exercise_id = e.id
                          AND eq.equipment_class IN ('free_weight','plate_loaded_machine'))"""),

    ("coherence", "elastic resistance logged as a comparable weight",
     """SELECT DISTINCT e.code FROM exercises.exercise e
          JOIN exercises.exercise_biomechanics b ON b.exercise_id = e.id
          JOIN exercises.exercise_tracking_profile t ON t.exercise_id = e.id
         WHERE e.deleted_at IS NULL AND b.resistance_source = 'band'
           AND t.comparison_scope <> 'non_comparable'"""),

    ("coherence", "machine or cable load treated as comparable across gyms",
     """SELECT DISTINCT e.code FROM exercises.exercise e
          JOIN exercises.exercise_biomechanics b ON b.exercise_id = e.id
          JOIN exercises.exercise_tracking_profile t ON t.exercise_id = e.id
         WHERE e.deleted_at IS NULL AND b.resistance_source IN ('cable','cam_machine')
           AND t.comparison_scope = 'exercise'"""),

    ("coherence", "single_joint with more than one primary joint action",
     """SELECT e.code FROM exercises.exercise e
          JOIN exercises.exercise_joint_action j ON j.exercise_id = e.id
         WHERE e.deleted_at IS NULL AND e.joint_class = 'single_joint' AND j.role = 'primary'
         GROUP BY e.code HAVING count(*) > 1"""),

    ("coherence", "spotter suggested for non-resistance work",
     """SELECT code FROM exercises.exercise WHERE deleted_at IS NULL
          AND exercise_kind <> 'resistance' AND spotter_policy <> 'none'"""),

    ("coherence", "added-weight tracking with nothing to add",
     """SELECT e.code FROM exercises.exercise e
          JOIN exercises.exercise_tracking_profile t ON t.exercise_id = e.id
         WHERE e.deleted_at IS NULL AND t.tracking_type = 'bodyweight_plus_weight'
           AND e.bodyweight = false"""),

    # Two exercises in the same family, training the same muscle, through the same
    # primary joint actions, may legitimately carry different tension profiles - a
    # preacher and an incline curl differ because of the shoulder, which is not in
    # that signature. So divergence alone is NOT an error and is not flagged here.
    # What is flagged is the decidable case: a heuristic guess contradicting a
    # literature-backed measurement inside that same group.
    ("coherence", "a guessed tension profile contradicts a measured one",
     """WITH sig AS (
            SELECT e.code, f.id AS family_id, em.muscle_id, em.evidence_basis,
                   em.tension_lengthened::text || em.tension_midrange::text
                     || em.tension_shortened::text AS profile,
                   (SELECT string_agg(j.joint_action_id::text, ',' ORDER BY j.joint_action_id)
                      FROM exercises.exercise_joint_action j
                     WHERE j.exercise_id = e.id AND j.role = 'primary') AS actions
              FROM exercises.exercise e
              JOIN exercises.exercise_family f ON f.id = e.family_id
              JOIN exercises.exercise_muscle em ON em.exercise_id = e.id
                                               AND em.involvement = 'primary'
             WHERE e.deleted_at IS NULL)
        SELECT DISTINCT g.code FROM sig g JOIN sig l
          ON l.family_id = g.family_id AND l.muscle_id = g.muscle_id
         AND l.actions IS NOT DISTINCT FROM g.actions
       WHERE g.actions IS NOT NULL AND g.evidence_basis = 'heuristic'
         AND l.evidence_basis = 'literature' AND l.profile <> g.profile"""),

    ("integrity", "the same muscle listed twice with different involvement",
     """SELECT DISTINCT e.code FROM exercises.exercise e
          JOIN exercises.exercise_muscle m ON m.exercise_id = e.id
         WHERE e.deleted_at IS NULL
         GROUP BY e.code, m.muscle_id HAVING count(*) > 1"""),

    ("integrity", "primary muscle with no tension profile",
     """SELECT DISTINCT e.code FROM exercises.exercise e
          JOIN exercises.exercise_muscle m ON m.exercise_id = e.id
         WHERE e.deleted_at IS NULL AND m.involvement = 'primary'
           AND (m.tension_lengthened IS NULL OR m.tension_midrange IS NULL
                OR m.tension_shortened IS NULL)"""),

    ("integrity", "muscle row with no provenance",
     """SELECT DISTINCT e.code FROM exercises.exercise e
          JOIN exercises.exercise_muscle m ON m.exercise_id = e.id
         WHERE e.deleted_at IS NULL
           AND (m.evidence_basis IS NULL OR m.confidence IS NULL)"""),

    ("integrity", "derived data claiming to be measured",
     """SELECT DISTINCT e.code FROM exercises.exercise e
          JOIN exercises.exercise_muscle m ON m.exercise_id = e.id
         WHERE e.deleted_at IS NULL AND m.evidence_basis = 'measured'"""),

    ("integrity", "placeholder text reaching the user",
     """SELECT code FROM exercises.exercise WHERE deleted_at IS NULL
          AND (translations::text LIKE '%"//"%' OR translations::text LIKE '%safety_tips_%'
               OR translations::text LIKE '%execution_tips_%')"""),

    ("integrity", "variation edge with no axis",
     """SELECT DISTINCT e.code FROM exercises.exercise e
          JOIN exercises.exercise_variation v
            ON v.base_exercise_id = e.id OR v.variant_exercise_id = e.id
         WHERE e.deleted_at IS NULL AND v.variation_axis IS NULL"""),

    ("content", "missing common mistakes in either locale",
     """SELECT code FROM exercises.exercise WHERE deleted_at IS NULL
          AND NOT (translations -> 'it' ? 'commonMistakes'
                   AND translations -> 'en' ? 'commonMistakes')"""),

    ("content", "missing description in either locale",
     """SELECT code FROM exercises.exercise WHERE deleted_at IS NULL
          AND (coalesce(translations->'it'->>'description','') = ''
               OR coalesce(translations->'en'->>'description','') = '')"""),
]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dsn", default=None)
    ap.add_argument("--json", action="store_true", help="emit machine-readable output")
    ap.add_argument("--max-rate", type=float, default=None,
                    help="exit 1 if the self-contradiction rate exceeds this percentage")
    args = ap.parse_args()
    dsn = args.dsn or get_dsn()

    with psycopg.connect(dsn, connect_timeout=60) as conn:
        cur = conn.cursor()
        cur.execute("SELECT count(*) FROM exercises.exercise WHERE deleted_at IS NULL")
        total = cur.fetchone()[0]

        results, offenders = [], set()
        for category, label, query in RULES:
            cur.execute(query)
            codes = [r[0] for r in cur.fetchall()]
            offenders.update(codes)
            results.append({"category": category, "rule": label,
                            "count": len(codes), "sample": codes[:5]})

        rate = 100.0 * len(offenders) / total if total else 0.0

    if args.json:
        print(json.dumps({"exercises": total, "self_contradicting": len(offenders),
                          "rate_pct": round(rate, 2), "rules": results},
                         indent=1, ensure_ascii=False))
    else:
        print(f"catalogue: {total} active exercises\n")
        current = None
        for row in results:
            if row["category"] != current:
                current = row["category"]
                print(f"[{current}]")
            mark = "OK  " if row["count"] == 0 else "FAIL"
            print(f"   [{mark}] {row['rule']:56s} {row['count']}")
            if row["count"]:
                print(f"            {', '.join(row['sample'])}"
                      f"{'...' if row['count'] > 5 else ''}")
        print(f"\nexercises contradicting themselves: {len(offenders)}/{total} "
              f"= {rate:.2f}%")
        print("(deterministic: same catalogue, same number, no reviewer involved)")

    if args.max_rate is not None and rate > args.max_rate:
        sys.exit(f"self-contradiction rate {rate:.2f}% exceeds --max-rate {args.max_rate}")


if __name__ == "__main__":
    main()
