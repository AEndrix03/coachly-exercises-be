#!/usr/bin/env python3
"""
Exercise model V2 - PHASE 2, STEP 1
Deduplicate exercise names, then assign every exercise a stable `code`.

The 8 duplicated names are the same movement ingested twice from different
sources. Rather than dropping a row (which would lose its relations), the
richer record survives, the poorer one donates its relations and is then
ARCHIVED, never hard-deleted.

`code` becomes the identity key that seeds and imports rely on, so `name` is
free to change later.

Usage:
    python inj/_tools/v2_step1_dedup_and_codes.py --dsn "..." [--apply]

Without --apply the whole thing runs inside a transaction and rolls back,
printing exactly what it would do.
"""
import argparse
import re
import sys
import unicodedata
from collections import Counter, defaultdict

import psycopg

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

RELATION_TABLES = [
    ("exercise_muscle", "muscle_id"),
    ("exercise_equipment", "equipment_id"),
    ("exercise_tag", "tag_id"),
    ("exercise_category", "category_id"),
    ("exercise_media", None),
    ("exercise_biomechanics", None),
]


def slugify(name):
    text = unicodedata.normalize("NFKD", name)
    text = "".join(ch for ch in text if not unicodedata.combining(ch))
    text = text.lower()
    text = text.replace("&", " and ")
    text = text.replace("+", " plus ")
    text = re.sub(r"[^a-z0-9]+", "_", text)
    return re.sub(r"_+", "_", text).strip("_")


def richness(cur, exercise_id):
    """Relations are what make a record worth keeping."""
    total = 0
    for table, _ in [("exercise_muscle", None), ("exercise_equipment", None),
                     ("exercise_tag", None), ("exercise_category", None),
                     ("exercise_media", None)]:
        cur.execute(f"SELECT count(*) FROM exercises.{table} WHERE exercise_id = %s",
                    (exercise_id,))
        total += cur.fetchone()[0]
    return total


def merge_duplicate(cur, survivor, victim, report):
    """Move every relation of `victim` onto `survivor`, then archive `victim`."""
    for table, second_key in RELATION_TABLES:
        if table == "exercise_biomechanics":
            # survivor already has its own row; the victim's adds nothing
            cur.execute("DELETE FROM exercises.exercise_biomechanics WHERE exercise_id = %s",
                        (victim,))
            continue
        if second_key:
            # skip pairs the survivor already has, then move the rest
            cur.execute(
                f"""DELETE FROM exercises.{table} v
                     WHERE v.exercise_id = %s
                       AND EXISTS (SELECT 1 FROM exercises.{table} s
                                    WHERE s.exercise_id = %s AND s.{second_key} = v.{second_key})""",
                (victim, survivor))
        cur.execute(f"UPDATE exercises.{table} SET exercise_id = %s WHERE exercise_id = %s",
                    (survivor, victim))
        report[table] += cur.rowcount

    # variation edges. A chk_variation_not_self constraint rejects self-loops,
    # so edges that would collapse onto the survivor must go BEFORE re-pointing.
    cur.execute(
        """DELETE FROM exercises.exercise_variation
            WHERE (base_exercise_id = %(victim)s AND variant_exercise_id = %(survivor)s)
               OR (variant_exercise_id = %(victim)s AND base_exercise_id = %(survivor)s)""",
        {"victim": victim, "survivor": survivor})

    for col, other in (("base_exercise_id", "variant_exercise_id"),
                       ("variant_exercise_id", "base_exercise_id")):
        # drop edges the survivor already has, so the re-point cannot collide
        cur.execute(
            f"""DELETE FROM exercises.exercise_variation v
                 WHERE v.{col} = %s
                   AND EXISTS (SELECT 1 FROM exercises.exercise_variation s
                                WHERE s.{col} = %s AND s.{other} = v.{other})""",
            (victim, survivor))
        cur.execute(f"UPDATE exercises.exercise_variation SET {col} = %s WHERE {col} = %s",
                    (survivor, victim))
        report["exercise_variation"] += cur.rowcount

    cur.execute(
        """UPDATE exercises.exercise
              SET status = 'archived', deleted_at = NOW(), updated_at = NOW(),
                  name = name || ' [merged into ' || %s || ']'
            WHERE id = %s""",
        (str(survivor), victim))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dsn", required=True)
    ap.add_argument("--apply", action="store_true")
    args = ap.parse_args()

    with psycopg.connect(args.dsn, connect_timeout=20) as conn:
        conn.autocommit = False
        cur = conn.cursor()

        # ---------- 1. deduplicate ----------
        # Group on the SLUG, not the raw name: "Behind-the-Back Wrist Curl" and
        # "Behind the Back Wrist Curl" are the same movement, and so is the
        # mojibake "Sled 45в° Leg Press" vs "Sled 45° Leg Press". Grouping on
        # exact names would leave those pairs behind and then break the unique
        # code constraint anyway.
        cur.execute("""SELECT id, name FROM exercises.exercise
                        WHERE deleted_at IS NULL ORDER BY created_at, id""")
        by_slug = defaultdict(list)
        for exercise_id, name in cur.fetchall():
            by_slug[slugify(name)].append((exercise_id, name))
        duplicate_groups = {k: v for k, v in by_slug.items() if len(v) > 1}

        report = Counter()
        merges = []
        for slug, members in sorted(duplicate_groups.items()):
            ranked = sorted(members, key=lambda m: (richness(cur, m[0]), str(m[0])), reverse=True)
            survivor_id, survivor_name = ranked[0]
            for victim_id, victim_name in ranked[1:]:
                merge_duplicate(cur, survivor_id, victim_id, report)
                merges.append((slug, survivor_id, survivor_name, victim_id, victim_name))

        print(f"merged {len(merges)} duplicate rows across {len(duplicate_groups)} slugs")
        for slug, survivor_id, survivor_name, victim_id, victim_name in merges:
            print(f"   {slug:34s} keep {str(survivor_id)[:8]} {survivor_name!r}"
                  f"  <- archive {str(victim_id)[:8]} {victim_name!r}")
        print("   relations moved:", dict(report))

        # ---------- 2. assign codes ----------
        cur.execute("""SELECT id, name FROM exercises.exercise
                        WHERE deleted_at IS NULL ORDER BY name, id""")
        rows = cur.fetchall()
        used = set()
        collisions = defaultdict(list)
        assignments = []
        for exercise_id, name in rows:
            base = slugify(name) or "exercise"
            code = base
            suffix = 2
            while code in used:
                collisions[base].append(name)
                code = f"{base}_v{suffix}"
                suffix += 1
            used.add(code)
            assignments.append((code, exercise_id))

        cur.executemany("UPDATE exercises.exercise SET code = %s, updated_at = NOW() WHERE id = %s",
                        assignments)
        print(f"\nassigned {len(assignments)} codes")
        if collisions:
            print(f"   {len(collisions)} slug collisions disambiguated with _vN:")
            for base, names in list(collisions.items())[:15]:
                print(f"     {base}: {names}")

        # archived rows still need a code for the future NOT NULL constraint
        cur.execute("""UPDATE exercises.exercise
                          SET code = 'archived_' || replace(id::text, '-', '')
                        WHERE code IS NULL""")
        print(f"   archived rows given placeholder codes: {cur.rowcount}")

        # ---------- 3. verify ----------
        cur.execute("SELECT count(*) FROM exercises.exercise WHERE code IS NULL")
        missing = cur.fetchone()[0]
        cur.execute("""SELECT count(*) FROM (SELECT code FROM exercises.exercise
                        GROUP BY code HAVING count(*) > 1) d""")
        dup_codes = cur.fetchone()[0]
        cur.execute("""SELECT count(*) FROM (SELECT name FROM exercises.exercise
                        WHERE deleted_at IS NULL GROUP BY name HAVING count(*) > 1) d""")
        dup_names = cur.fetchone()[0]
        cur.execute("SELECT count(*) FROM exercises.exercise WHERE deleted_at IS NULL")
        active = cur.fetchone()[0]
        print(f"\nverify: active={active} missing_code={missing} "
              f"duplicate_codes={dup_codes} duplicate_names={dup_names}")

        if missing or dup_codes or dup_names:
            conn.rollback()
            sys.exit("verification failed - rolled back")

        if args.apply:
            conn.commit()
            print("COMMITTED")
        else:
            conn.rollback()
            print("DRY RUN - rolled back")


if __name__ == "__main__":
    main()
