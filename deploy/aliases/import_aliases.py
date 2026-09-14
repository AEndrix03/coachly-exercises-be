#!/usr/bin/env python3
"""Validate an exercise-alias CSV and emit idempotent PostgreSQL upserts."""

from __future__ import annotations

import argparse
import csv
import pathlib
import re
import sys

ALLOWED_LOCALES = {"it", "en"}
ALLOWED_TYPES = {"common_name", "abbreviation", "slang", "legacy_name"}
REQUIRED_COLUMNS = {"exercise_code", "locale", "alias", "type", "weight"}


def normalize(value: str) -> str:
    value = value.casefold().strip()
    replacements = str.maketrans("àáâãäåèéêëìíîïòóôõöùúûü", "aaaaaaeeeeiiiiooooouuuu")
    return re.sub(r"[^a-z0-9]+", " ", value.translate(replacements)).strip()


def validate(rows: list[dict[str, str]]) -> tuple[list[str], list[str]]:
    errors: list[str] = []
    warnings: list[str] = []
    by_exercise: set[tuple[str, str, str]] = set()
    by_alias: dict[tuple[str, str], set[str]] = {}
    for line, row in enumerate(rows, start=2):
        code, locale, label = (row[key].strip() for key in ("exercise_code", "locale", "alias"))
        alias_type = row["type"].strip()
        normalized = normalize(label)
        if not code or not normalized:
            errors.append(f"line {line}: exercise_code and alias are required")
        if locale not in ALLOWED_LOCALES:
            errors.append(f"line {line}: unsupported locale {locale!r}")
        if alias_type not in ALLOWED_TYPES:
            errors.append(f"line {line}: unsupported type {alias_type!r}")
        try:
            weight = int(row["weight"])
            if not 0 <= weight <= 100:
                raise ValueError
        except ValueError:
            errors.append(f"line {line}: weight must be between 0 and 100")
        key = (code, locale, normalized)
        if key in by_exercise:
            errors.append(f"line {line}: duplicate normalized alias for {code}")
        by_exercise.add(key)
        by_alias.setdefault((locale, normalized), set()).add(code)
    for (locale, alias), codes in sorted(by_alias.items()):
        if len(codes) > 1:
            warnings.append(f"ambiguous {locale} alias {alias!r}: {', '.join(sorted(codes))}")
    return errors, warnings


def quote(value: str) -> str:
    return "'" + value.replace("'", "''") + "'"


def render_sql(rows: list[dict[str, str]]) -> str:
    statements = ["BEGIN;"]
    for row in rows:
        code = quote(row["exercise_code"].strip())
        locale = quote(row["locale"].strip())
        label = quote(row["alias"].strip())
        statements.append(
            "DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM exercises.exercise "
            f"WHERE code = {code}) THEN RAISE EXCEPTION 'Unknown exercise code: %', {code}; "
            "END IF; END $$;"
        )
        statements.append(
            "DO $$ DECLARE item exercises.exercise%ROWTYPE; BEGIN "
            f"SELECT * INTO item FROM exercises.exercise WHERE code = {code}; "
            "IF item.catalog_status <> 'active' THEN "
            f"RAISE WARNING 'Alias targets non-active exercise: %', {code}; END IF; "
            f"IF exercises.normalize_alias(item.translations -> {locale} ->> 'name') = "
            f"exercises.normalize_alias({label}) THEN "
            f"RAISE WARNING 'Alias equals canonical localized name: %', {label}; "
            "END IF; END $$;"
        )
        values = ", ".join(quote(row[key].strip()) for key in ("locale", "alias", "type"))
        statements.append(
            "INSERT INTO exercises.exercise_alias "
            "(exercise_id, locale, label, alias_type, weight) "
            f"SELECT e.id, {values}, {int(row['weight'])} FROM exercises.exercise e "
            f"WHERE e.code = {code} "
            "ON CONFLICT (exercise_id, locale, normalized_label) DO UPDATE SET "
            "label = EXCLUDED.label, alias_type = EXCLUDED.alias_type, "
            "weight = EXCLUDED.weight, status = 'active', updated_at = now();"
        )
    statements.extend([
        "DO $$ BEGIN IF EXISTS (SELECT 1 FROM exercises.exercise_alias a "
        "JOIN exercises.exercise e ON e.id = a.exercise_id "
        "GROUP BY a.locale, a.normalized_label HAVING count(DISTINCT e.id) > 1) "
        "THEN RAISE NOTICE 'Ambiguous aliases detected; inspect before publishing'; END IF; END $$;",
        "COMMIT;",
    ])
    return "\n".join(statements) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("csv_file", type=pathlib.Path)
    parser.add_argument("--output", type=pathlib.Path)
    args = parser.parse_args()
    with args.csv_file.open(encoding="utf-8-sig", newline="") as source:
        reader = csv.DictReader(source)
        missing = REQUIRED_COLUMNS - set(reader.fieldnames or [])
        if missing:
            print(f"missing columns: {', '.join(sorted(missing))}", file=sys.stderr)
            return 2
        rows = list(reader)
    errors, warnings = validate(rows)
    for warning in warnings:
        print(f"WARNING: {warning}", file=sys.stderr)
    for error in errors:
        print(f"ERROR: {error}", file=sys.stderr)
    if errors:
        return 1
    sql = render_sql(rows)
    if args.output:
        args.output.write_text(sql, encoding="utf-8")
    else:
        print(sql, end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
