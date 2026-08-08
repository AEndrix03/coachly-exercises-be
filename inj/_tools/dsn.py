"""Single place the migration tooling gets its database DSN from.

Order of preference:
  1. $COACHLY_BIOMECH_DSN, if the caller already set it
  2. auto-injestion/.env, which already holds COACHLY_DB_* and is gitignored

The point is that no script, prompt or command line ever has to spell the
password out. Import this instead:

    from dsn import get_dsn
    with psycopg.connect(get_dsn()) as conn:
        ...
"""
import os
import pathlib

ENV_FILE = pathlib.Path(__file__).resolve().parents[2] / "auto-injestion" / ".env"


def _read_env_file(path=ENV_FILE):
    values = {}
    if not path.exists():
        return values
    for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        values[key.strip()] = value.strip().strip('"').strip("'")
    return values


def get_dsn(connect_timeout=30):
    """Return a libpq DSN, without the caller ever handling the password."""
    existing = os.environ.get("COACHLY_BIOMECH_DSN")
    if existing:
        return existing

    env = _read_env_file()
    missing = [k for k in ("COACHLY_DB_HOST", "COACHLY_DB_PORT", "COACHLY_DB_NAME",
                           "COACHLY_DB_USERNAME", "COACHLY_DB_PASSWORD") if k not in env]
    if missing:
        raise SystemExit(
            "cannot build a DSN: set $COACHLY_BIOMECH_DSN, or provide "
            f"{ENV_FILE} with {', '.join(missing)}")

    return (f"host={env['COACHLY_DB_HOST']} port={env['COACHLY_DB_PORT']} "
            f"dbname={env['COACHLY_DB_NAME']} user={env['COACHLY_DB_USERNAME']} "
            f"password={env['COACHLY_DB_PASSWORD']} connect_timeout={connect_timeout}")
