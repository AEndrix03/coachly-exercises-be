#!/usr/bin/env python3
"""Run all SQL seed files in sql/exercises against a PostgreSQL database.

Each file is executed in its own transaction. Failures are collected in a log
file while execution continues with the remaining files.
"""

from __future__ import annotations

import argparse
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, Sequence


def _load_driver():
    try:
        import psycopg  # type: ignore

        return ("psycopg", psycopg)
    except ImportError:
        pass

    try:
        import psycopg2  # type: ignore

        return ("psycopg2", psycopg2)
    except ImportError as exc:  # pragma: no cover - runtime dependency error
        raise SystemExit(
            "Missing PostgreSQL driver. Install `psycopg` or `psycopg2-binary`."
        ) from exc


@dataclass(frozen=True)
class DbConfig:
    host: str
    port: int
    dbname: str
    user: str
    password: str
    schema: str


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Execute all SQL seed files in sql/exercises."
    )
    parser.add_argument("--host", required=True, help="PostgreSQL host")
    parser.add_argument("--port", type=int, default=5432, help="PostgreSQL port")
    parser.add_argument("--dbname", required=True, help="Database name")
    parser.add_argument("--user", required=True, help="Database user")
    parser.add_argument("--password", required=True, help="Database password")
    parser.add_argument("--schema", required=True, help="Target schema name")
    parser.add_argument(
        "--sql-dir",
        default=Path(__file__).resolve().parents[1] / "exercises",
        type=Path,
        help="Directory containing seed .sql files",
    )
    parser.add_argument(
        "--log-file",
        default=Path(__file__).resolve().parents[1] / "seed_errors.log",
        type=Path,
        help="Path to the error log file",
    )
    parser.add_argument(
        "--stop-on-error",
        action="store_true",
        help="Stop at the first error instead of continuing",
    )
    return parser


def iter_sql_files(sql_dir: Path) -> list[Path]:
    if not sql_dir.exists():
        raise SystemExit(f"SQL directory not found: {sql_dir}")
    if not sql_dir.is_dir():
        raise SystemExit(f"SQL path is not a directory: {sql_dir}")
    return sorted(p for p in sql_dir.glob("*.sql") if p.is_file())


def open_connection(driver_name: str, driver, config: DbConfig):
    if driver_name == "psycopg":
        return driver.connect(
            host=config.host,
            port=config.port,
            dbname=config.dbname,
            user=config.user,
            password=config.password,
        )
    return driver.connect(
        host=config.host,
        port=config.port,
        dbname=config.dbname,
        user=config.user,
        password=config.password,
    )


def set_schema(conn, schema: str) -> None:
    if not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", schema):
        raise SystemExit(
            f"Invalid schema name: {schema!r}. Use a simple PostgreSQL identifier."
        )
    with conn.cursor() as cur:
        cur.execute(f'SET search_path TO "{schema}", public')


def execute_file(conn, sql_file: Path) -> None:
    sql_text = sql_file.read_text(encoding="utf-8")
    with conn.cursor() as cur:
        cur.execute(sql_text)


def append_log(log_file: Path, lines: Iterable[str]) -> None:
    log_file.parent.mkdir(parents=True, exist_ok=True)
    with log_file.open("a", encoding="utf-8", newline="\n") as handle:
        for line in lines:
            handle.write(line.rstrip("\n") + "\n")


def main(argv: Sequence[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)

    config = DbConfig(
        host=args.host,
        port=args.port,
        dbname=args.dbname,
        user=args.user,
        password=args.password,
        schema=args.schema,
    )

    driver_name, driver = _load_driver()
    sql_files = iter_sql_files(args.sql_dir)

    if not sql_files:
        print(f"No SQL files found in {args.sql_dir}")
        return 0

    failed: list[Path] = []
    print(f"Using driver: {driver_name}")
    print(f"Found {len(sql_files)} SQL files in {args.sql_dir}")

    conn = open_connection(driver_name, driver, config)
    try:
        if hasattr(conn, "autocommit"):
            conn.autocommit = False
        set_schema(conn, config.schema)

        for sql_file in sql_files:
            print(f"Running {sql_file.name} ...", end=" ")
            try:
                execute_file(conn, sql_file)
                conn.commit()
                print("OK")
            except Exception as exc:
                conn.rollback()
                failed.append(sql_file)
                message = f"{sql_file.name} | {type(exc).__name__}: {exc}"
                append_log(args.log_file, [message])
                print("ERROR")
                print(f"  {message}")
                if args.stop_on_error:
                    break
    finally:
        conn.close()

    print()
    print(f"Completed: {len(sql_files) - len(failed)} succeeded, {len(failed)} failed")
    if failed:
        print(f"Error log: {args.log_file}")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
