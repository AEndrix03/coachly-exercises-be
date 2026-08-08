#!/usr/bin/env python3
"""
Exercise model V2 - PHASE 2, STEP 13
Write the common mistakes the frontend asked for into translations.

They go into the existing `translations` jsonb under `commonMistakesI18n`, as a
LIST of strings per locale - the same shape as tips and safety notes, which is
what the frontend wants. No new table: free text nobody queries gains nothing
from being normalised.

Mistakes are authored PER ARCHETYPE, because they genuinely are shared by every
variant of the same movement: the ways people ruin a bench press do not change
because the bar is a dumbbell. Each exercise inherits its archetype's list.

The write is a jsonb merge, so existing name / description / tips / safetyNotes
are preserved untouched.

Usage:
    python inj/_tools/v2_step13_common_mistakes.py [--apply]
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

VALIDATION_DIR = pathlib.Path(__file__).resolve().parents[1] / "_validation"
ARCH = "split_part(split_part(b.method_note,'archetype=',2),';',1)"
LOCALES = ("en", "it")


def load_mistakes():
    """Merge every mistakes_*.json into one archetype -> {locale: [...]} map."""
    merged = {}
    for path in sorted(VALIDATION_DIR.glob("mistakes_*.json")):
        try:
            payload = json.loads(path.read_text(encoding="utf-8"))
        except Exception as exc:  # noqa: BLE001
            print(f"!! {path.name} is not valid JSON: {exc}")
            continue
        if not isinstance(payload, dict):
            print(f"!! {path.name} is not a JSON object, skipped")
            continue
        kept = 0
        for archetype, by_locale in payload.items():
            if not isinstance(by_locale, dict):
                continue
            entry = {}
            for locale in LOCALES:
                items = by_locale.get(locale)
                if isinstance(items, list):
                    cleaned = [str(i).strip() for i in items if str(i).strip()]
                    if cleaned:
                        entry[locale] = cleaned
            # both locales or neither: a half-translated list is worse than none
            if len(entry) == len(LOCALES):
                if len(entry["en"]) != len(entry["it"]):
                    print(f"   ! {archetype}: en has {len(entry['en'])} items, "
                          f"it has {len(entry['it'])} - skipped")
                    continue
                merged[archetype] = entry
                kept += 1
        print(f"{path.name}: {kept} archetypes")
    return merged


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dsn", default=None,
                    help="optional; resolved from $COACHLY_BIOMECH_DSN or auto-injestion/.env")
    ap.add_argument("--apply", action="store_true")
    args = ap.parse_args()
    dsn = args.dsn or get_dsn()

    mistakes = load_mistakes()
    if not mistakes:
        sys.exit(f"no usable mistakes_*.json in {VALIDATION_DIR}")
    print(f"\narchetypes with mistakes: {len(mistakes)}")

    with psycopg.connect(dsn, connect_timeout=30) as conn:
        conn.autocommit = False
        cur = conn.cursor()

        cur.execute(f"""SELECT DISTINCT {ARCH}
                          FROM exercises.exercise e
                          JOIN exercises.exercise_biomechanics b ON b.exercise_id = e.id
                         WHERE e.deleted_at IS NULL""")
        live = {r[0] for r in cur.fetchall() if r[0]}
        unknown = sorted(set(mistakes) - live)
        if unknown:
            print(f"   (ignoring {len(unknown)} archetypes not in the catalogue: {unknown[:6]}...)")
        uncovered = sorted(live - set(mistakes))

        written = 0
        for archetype, by_locale in mistakes.items():
            if archetype not in live:
                continue
            payload = json.dumps({locale: {"commonMistakes": items}
                                  for locale, items in by_locale.items()},
                                 ensure_ascii=False)
            # jsonb concatenation at the locale level would replace the whole
            # locale object, so merge per locale instead
            cur.execute(f"""UPDATE exercises.exercise e
                               SET translations = (
                                       SELECT coalesce(jsonb_object_agg(locale, merged), e.translations)
                                         FROM (
                                             SELECT k AS locale,
                                                    CASE WHEN %s::jsonb ? k
                                                         THEN (e.translations -> k) || (%s::jsonb -> k)
                                                         ELSE e.translations -> k END AS merged
                                               FROM jsonb_object_keys(e.translations) k
                                              WHERE jsonb_typeof(e.translations -> k) = 'object'
                                         ) locales),
                                   updated_at = NOW()
                              FROM exercises.exercise_biomechanics b
                             WHERE b.exercise_id = e.id AND {ARCH} = %s
                               AND e.deleted_at IS NULL""",
                        (payload, payload, archetype))
            written += cur.rowcount
        print(f"exercises updated: {written}")

        # ---- verification ----
        cur.execute("""SELECT count(*) FROM exercises.exercise
                        WHERE deleted_at IS NULL
                          AND translations -> 'it' ? 'commonMistakes'
                          AND translations -> 'en' ? 'commonMistakes'""")
        both = cur.fetchone()[0]
        cur.execute("SELECT count(*) FROM exercises.exercise WHERE deleted_at IS NULL")
        total = cur.fetchone()[0]
        print(f"exercises with mistakes in BOTH locales: {both}/{total}")

        # nothing that already existed may have been lost
        cur.execute("""SELECT count(*) FROM exercises.exercise
                        WHERE deleted_at IS NULL
                          AND NOT (translations -> 'it' ? 'name' AND translations -> 'en' ? 'name')""")
        lost = cur.fetchone()[0]
        print(f"exercises that lost their name translations: {lost}")
        if lost:
            conn.rollback()
            sys.exit("translations damaged - rolled back")

        cur.execute("""SELECT e.code, jsonb_array_length(e.translations -> 'it' -> 'commonMistakes')
                         FROM exercises.exercise e
                        WHERE e.deleted_at IS NULL
                          AND e.translations -> 'it' ? 'commonMistakes'
                        ORDER BY random() LIMIT 3""")
        print("sample:")
        for code, count in cur.fetchall():
            print(f"   {code:36s} {count} mistakes")

        if uncovered:
            print(f"\narchetypes still without mistakes: {len(uncovered)}")
            print("  ", ", ".join(sorted(uncovered)[:15]))

        if args.apply:
            conn.commit()
            print("COMMITTED")
        else:
            conn.rollback()
            print("DRY RUN - rolled back")


if __name__ == "__main__":
    main()
