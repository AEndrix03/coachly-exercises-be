#!/usr/bin/env python3
"""Deploy only the Coachly exercises backend from the Coachly checkout root.

Ricalca lo script di `coachly-workouts-be`: prima le migrazioni, poi build e
riavvio del solo servizio, infine l'attesa dell'health.
"""

from __future__ import annotations

import json
import os
import pathlib
import subprocess
import sys
import time
import urllib.request


SERVICE = "coachly-exercises-be"


def run(*args: str, cwd: pathlib.Path, env: dict[str, str] | None = None) -> None:
    subprocess.run(args, cwd=cwd, env=env, check=True)


def container_environment(root: pathlib.Path) -> dict[str, str]:
    output = subprocess.check_output(
        ["docker", "inspect", SERVICE, "--format", "{{json .Config.Env}}"],
        cwd=root,
        text=True,
    )
    values = json.loads(output)
    return dict(item.split("=", 1) for item in values if "=" in item)


def apply_migration(root: pathlib.Path) -> None:
    """Applica in ordine tutte le migrazioni presenti.

    Prima il file V2 era nominato a mano e aggiungerne uno nuovo significava
    ricordarsi di toccare anche questo script — cioe' dimenticarsene. Le
    migrazioni sono additive e idempotenti, quindi rieseguirle tutte a ogni
    deploy e' sicuro e toglie di mezzo il passo che si salta.
    """
    values = container_environment(root)
    jdbc_url = values["COACHLY_DB_URL"]
    postgres_url = jdbc_url.removeprefix("jdbc:")
    environment = os.environ.copy()
    environment["PGPASSWORD"] = values["COACHLY_DB_PASSWORD"]

    migrations_dir = root / "services/coachly-exercises-be/deploy/migrations"
    migrations = sorted(migrations_dir.glob("V*__*.sql"))
    if not migrations:
        raise RuntimeError(f"No migration found in {migrations_dir}")

    for migration in migrations:
        print(f"==> {migration.name}")
        run(
            "psql",
            postgres_url,
            "--username",
            values["COACHLY_DB_USERNAME"],
            "--set",
            "ON_ERROR_STOP=1",
            "--file",
            str(migration),
            cwd=root,
            env=environment,
        )


def wait_for_health() -> None:
    deadline = time.monotonic() + 90
    url = "http://127.0.0.1:9102/actuator/health"
    while time.monotonic() < deadline:
        try:
            with urllib.request.urlopen(url, timeout=3) as response:
                payload = json.load(response)
                if response.status == 200 and payload.get("status") == "UP":
                    return
        except Exception:
            pass
        time.sleep(2)
    raise RuntimeError(f"{SERVICE} did not become healthy within 90 seconds")


def main() -> int:
    root = pathlib.Path.cwd().resolve()
    expected = root / "services/coachly-exercises-be"
    if not expected.is_dir():
        print("Run deploy.py from the Coachly checkout root.", file=sys.stderr)
        return 2

    apply_migration(root)
    # Build e riavvio passano da compose e non da `docker build`: il Dockerfile
    # di questo servizio si aspetta come contesto la cartella del servizio, che
    # e' esattamente quello che compose gli passa. Un `docker build` dalla root
    # userebbe il contesto sbagliato.
    run(
        "docker",
        "compose",
        "up",
        "--detach",
        "--build",
        "--no-deps",
        "--force-recreate",
        SERVICE,
        cwd=root,
    )
    wait_for_health()
    print(f"{SERVICE} deployed and healthy")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
