"""Database access is deterministic and never accepts SQL from the model."""
import json
from pathlib import Path

def metadata(database_url, schema="exercises"):
    if not database_url: return {"available": False, "reason": "DATABASE_URL is not configured", "tables": [], "columns": [], "foreign_keys": []}
    import psycopg
    with psycopg.connect(database_url) as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT table_name FROM information_schema.tables WHERE table_schema=%s ORDER BY table_name", (schema,)); tables=[r[0] for r in cur.fetchall()]
            cur.execute("SELECT table_name,column_name,data_type,is_nullable FROM information_schema.columns WHERE table_schema=%s ORDER BY table_name,ordinal_position", (schema,)); columns=[dict(zip(("table","column","type","nullable"),r)) for r in cur.fetchall()]
            cur.execute("SELECT table_name,column_name,foreign_table_name,foreign_column_name FROM (SELECT tc.table_name,kcu.column_name,ccu.table_name AS foreign_table_name,ccu.column_name AS foreign_column_name FROM information_schema.table_constraints tc JOIN information_schema.key_column_usage kcu ON tc.constraint_name=kcu.constraint_name AND tc.table_schema=kcu.table_schema JOIN information_schema.constraint_column_usage ccu ON ccu.constraint_name=tc.constraint_name AND ccu.table_schema=tc.table_schema WHERE tc.constraint_type='FOREIGN KEY' AND tc.table_schema=%s) x", (schema,)); fks=[dict(zip(("table","column","foreign_table","foreign_column"),r)) for r in cur.fetchall()]
    return {"available":True,"schema":schema,"tables":tables,"columns":columns,"foreign_keys":fks}

def schema_diff(manifest, db):
    java={e.get("table") for e in manifest.get("entities",[])}; tables=set(db.get("tables",[]))
    return {"missing_in_database":sorted(java-tables),"unmapped_database_tables":sorted(tables-java),"compatible":not (java-tables)}

def extract_rows(database_url, table="exercise", schema="exercises"):
    if not database_url: return []
    import psycopg
    with psycopg.connect(database_url) as conn, conn.cursor() as cur:
        cur.execute(f'SELECT * FROM "{schema}"."{table}"')
        names=[d.name for d in cur.description]; return [dict(zip(names,row)) for row in cur.fetchall()]

def catalogs(database_url, schema="exercises"):
    if not database_url: return {}
    import psycopg
    with psycopg.connect(database_url) as conn, conn.cursor() as cur:
        result={}
        for table, key in (("muscle", "muscles"), ("category", "categories"), ("equipment", "equipment"), ("tag", "tags")):
            cur.execute(f'SELECT code, translations FROM "{schema}"."{table}" WHERE deleted_at IS NULL ORDER BY code')
            entries=[]
            for code, translations in cur.fetchall():
                if isinstance(translations, str):
                    translations=json.loads(translations)
                entries.append({"code":code,"name_it":translations.get("it",{}).get("name",code),"name_en":translations.get("en",{}).get("name",code)})
            result[key]=entries
        cur.execute(f'SELECT id,name FROM "{schema}"."exercise" WHERE deleted_at IS NULL ORDER BY name')
        result["exercises"]=[{"id":str(r[0]),"name":r[1]} for r in cur.fetchall()]
        return result
