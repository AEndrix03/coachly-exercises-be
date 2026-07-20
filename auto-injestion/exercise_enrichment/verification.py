import json
from pathlib import Path
def verify_staging(database_url, schema, expected_count, proposals_dir=None):
    if not database_url: return {"verified":False,"critical_errors":["DATABASE_URL is not configured"]}
    import psycopg
    errors=[]
    with psycopg.connect(database_url) as conn, conn.cursor() as cur:
        cur.execute("SELECT COUNT(*) FROM information_schema.tables WHERE table_schema=%s",(schema,)); tables=cur.fetchone()[0]
        if not tables: errors.append("STAGING_SCHEMA_EMPTY")
        cur.execute("SELECT table_name FROM information_schema.tables WHERE table_schema=%s",(schema,)); names=[x[0] for x in cur.fetchall()]
        if "exercise" in names:
            cur.execute(f'SELECT COUNT(*) FROM "{schema}"."exercise"'); count=cur.fetchone()[0]
            if expected_count and count<expected_count: errors.append("EXERCISE_COUNT_DECREASED")
    if proposals_dir and not list(Path(proposals_dir).glob("*.json")): errors.append("NO_VALIDATED_PROPOSALS")
    return {"verified":not errors,"critical_errors":errors,"schema":schema}
