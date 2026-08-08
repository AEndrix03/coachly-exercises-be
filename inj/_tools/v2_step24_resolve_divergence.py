#!/usr/bin/env python3
"""
Exercise model V2 - PHASE 2, STEP 24
Resolve tension-profile divergence where one side of the disagreement is
literature-backed and the other is a guess.

Within a (family, muscle, primary joint actions) group, exercises should carry
the same tension profile unless something distinguishes them. 1569 exercises sit
in a group where the profiles disagree.

Most of that divergence is LEGITIMATE and must be preserved: a preacher curl and
an incline curl share family, muscle and joint action, yet genuinely differ
because the shoulder is placed differently - and shoulder position is not part
of the signature. Forcing those to converge would delete exactly the distinction
this catalogue exists to record, and it is the mistake step 17 already made once.

So only the subset where the disagreement is decidable is touched: a group that
contains a LITERATURE-backed profile and also HEURISTIC rows carrying a
different one. There, the heuristic row is a guess contradicting a measurement,
and the measurement wins. Everything else is reported, not forced.

Usage:
    python inj/_tools/v2_step24_resolve_divergence.py [--apply]
"""
import argparse
import pathlib
import sys
from collections import defaultdict

import psycopg

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from dsn import get_dsn  # noqa: E402

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

SIGNATURE_SQL = """
SELECT e.id, e.code, f.code AS family, m.code AS muscle,
       em.tension_lengthened::text || '/' || em.tension_midrange::text || '/' ||
       em.tension_shortened::text AS profile,
       em.evidence_basis::text AS basis,
       (SELECT string_agg(ja.joint_code || '.' || ja.action_code, ','
                          ORDER BY ja.joint_code, ja.action_code)
          FROM exercises.exercise_joint_action j
          JOIN exercises.joint_action ja ON ja.id = j.joint_action_id
         WHERE j.exercise_id = e.id AND j.role = 'primary') AS actions
  FROM exercises.exercise e
  JOIN exercises.exercise_family f ON f.id = e.family_id
  JOIN exercises.exercise_muscle em ON em.exercise_id = e.id
                                   AND em.involvement = 'primary'
  JOIN exercises.muscle m ON m.id = em.muscle_id
 WHERE e.deleted_at IS NULL
"""


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dsn", default=None)
    ap.add_argument("--apply", action="store_true")
    args = ap.parse_args()
    dsn = args.dsn or get_dsn()

    with psycopg.connect(dsn, connect_timeout=60) as conn:
        conn.autocommit = False
        cur = conn.cursor()

        cur.execute(SIGNATURE_SQL)
        groups = defaultdict(list)
        for exercise_id, code, family, muscle, profile, basis, actions in cur.fetchall():
            if actions is None:
                continue
            groups[(family, muscle, actions)].append(
                {"id": exercise_id, "code": code, "profile": profile, "basis": basis})

        divergent = {k: v for k, v in groups.items()
                     if len({r["profile"] for r in v}) > 1}
        print(f"groups whose profiles disagree: {len(divergent)}")
        print(f"exercises inside them: {len({r['code'] for v in divergent.values() for r in v})}")

        decidable, undecidable = [], []
        for key, rows in divergent.items():
            literature = {r["profile"] for r in rows if r["basis"] == "literature"}
            if len(literature) != 1:
                undecidable.append((key, len(rows)))
                continue
            target = literature.pop()
            losers = [r for r in rows
                      if r["basis"] == "heuristic" and r["profile"] != target]
            if losers:
                decidable.append((key, target, losers))
            else:
                undecidable.append((key, len(rows)))

        print(f"\ndecidable (a measurement contradicts a guess): {len(decidable)} groups")
        print(f"left untouched (a real distinction, or nothing to decide with): "
              f"{len(undecidable)} groups")

        aligned = 0
        for (family, muscle, _actions), target, losers in decidable:
            lengthened, midrange, shortened = target.split("/")
            for row in losers:
                cur.execute("""UPDATE exercises.exercise_muscle em
                                  SET tension_lengthened = %s, tension_midrange = %s,
                                      tension_shortened = %s,
                                      evidence_basis = 'biomechanical_model',
                                      confidence = 'moderate', updated_at = NOW()
                                 FROM exercises.muscle mu
                                WHERE em.muscle_id = mu.id AND em.exercise_id = %s
                                  AND mu.code = %s AND em.involvement = 'primary'""",
                            (lengthened, midrange, shortened, row["id"], muscle))
                aligned += cur.rowcount
            print(f"   {family:24s} {muscle:24s} -> {target:22s} ({len(losers)} rows)")

        print(f"\nrows aligned to the measured profile: {aligned}")

        # what remains divergent, for the record
        cur.execute(SIGNATURE_SQL)
        after = defaultdict(set)
        for _i, _c, family, muscle, profile, _b, actions in cur.fetchall():
            if actions is not None:
                after[(family, muscle, actions)].add(profile)
        still = sum(1 for v in after.values() if len(v) > 1)
        print(f"groups still divergent (legitimate or undecidable): {still}")

        print("\n--- invariants")
        failed = False
        for label, query in [
            ("primary muscles without tension profile",
             """SELECT count(*) FROM exercises.exercise_muscle
                 WHERE involvement = 'primary' AND tension_lengthened IS NULL"""),
            ("exercises without a primary muscle",
             """SELECT count(*) FROM exercises.exercise e WHERE e.deleted_at IS NULL
                  AND NOT EXISTS (SELECT 1 FROM exercises.exercise_muscle m
                                   WHERE m.exercise_id = e.id AND m.involvement = 'primary')"""),
            ("muscle rows without provenance",
             """SELECT count(*) FROM exercises.exercise_muscle
                 WHERE evidence_basis IS NULL OR confidence IS NULL"""),
        ]:
            cur.execute(query)
            value = cur.fetchone()[0]
            print(f"   [{'OK  ' if value == 0 else 'FAIL'}] {label:44s} {value}")
            if value:
                failed = True
        if failed:
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
