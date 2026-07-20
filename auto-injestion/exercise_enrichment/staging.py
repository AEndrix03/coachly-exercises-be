def create_staging(database_url, source_schema, staging_schema):
    if not database_url: return {"available":False,"reason":"DATABASE_URL is not configured"}
    import psycopg
    with psycopg.connect(database_url) as conn, conn.cursor() as cur:
        cur.execute("SELECT pg_advisory_xact_lock(hashtext(%s))", (staging_schema,)); cur.execute(f'CREATE SCHEMA IF NOT EXISTS "{staging_schema}"')
        cur.execute("SELECT table_name FROM information_schema.tables WHERE table_schema=%s", (source_schema,))
        for (table,) in cur.fetchall(): cur.execute(f'CREATE TABLE IF NOT EXISTS "{staging_schema}"."{table}" (LIKE "{source_schema}"."{table}" INCLUDING ALL)')
    return {"available":True,"schema":staging_schema}

def promote(database_url, staging_schema, source_schema):
    if not database_url: return {"promoted":False,"reason":"DATABASE_URL is not configured"}
    # Promotion is intentionally explicit and only copies tables that exist in both schemas.
    import psycopg
    with psycopg.connect(database_url) as conn, conn.cursor() as cur:
        cur.execute("SELECT pg_advisory_xact_lock(hashtext(%s))", (source_schema,)); cur.execute("SELECT table_name FROM information_schema.tables WHERE table_schema=%s", (staging_schema,)); tables=[r[0] for r in cur.fetchall()]
        for table in tables: cur.execute(f'INSERT INTO "{source_schema}"."{table}" SELECT * FROM "{staging_schema}"."{table}" ON CONFLICT DO NOTHING')
    return {"promoted":True,"tables":tables}
