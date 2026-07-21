def create_staging(database_url, source_schema, staging_schema):
    if not database_url: return {"available":False,"reason":"DATABASE_URL is not configured"}
    import psycopg
    with psycopg.connect(database_url) as conn, conn.cursor() as cur:
        cur.execute("SELECT pg_advisory_xact_lock(hashtext(%s))", (staging_schema,)); cur.execute(f'CREATE SCHEMA IF NOT EXISTS "{staging_schema}"')
        cur.execute("SELECT table_name FROM information_schema.tables WHERE table_schema=%s", (source_schema,))
        for (table,) in cur.fetchall():
            cur.execute(f'CREATE TABLE IF NOT EXISTS "{staging_schema}"."{table}" (LIKE "{source_schema}"."{table}" INCLUDING ALL)')
            cur.execute(f'INSERT INTO "{staging_schema}"."{table}" SELECT * FROM "{source_schema}"."{table}" ON CONFLICT DO NOTHING')
    return {"available":True,"schema":staging_schema,"copied":True}

def import_proposals(database_url, source_schema, staging_schema, proposals_dir):
    """Copy source first, then apply only explicitly present scalar proposal fields."""
    if not database_url: return {"imported":False,"reason":"DATABASE_URL is not configured"}
import json
    from pathlib import Path
    import psycopg
    allowed={"name","difficulty","mechanics","force","unilateral","bodyweight","overall_risk","spotter_required","visibility","translations"}; applied=0
    with psycopg.connect(database_url) as conn, conn.cursor() as cur:
        create_staging(database_url,source_schema,staging_schema)
        for path in Path(proposals_dir).glob("*.json"):
            item=json.loads(path.read_text(encoding="utf-8"));
            if item.get("validation",{}).get("status")!="ACCEPTED": continue
            proposal=item.get("proposal",{}); values={k:v for k,v in proposal.get("proposed",{}).items() if k in allowed and v not in (None,{},[])}
            if not values: continue
            if "translations" in values and isinstance(values["translations"],dict): values["translations"]=json.dumps(values["translations"],ensure_ascii=False)
            sets=", ".join(f'"{k}"=%s' for k in values); cur.execute(f'UPDATE "{staging_schema}"."exercise" SET {sets}, updated_at=now() WHERE id=%s',list(values.values())+[proposal.get("exercise_id")]); applied+=cur.rowcount
            exercise_id=proposal.get("exercise_id")
            for candidate in proposal.get("proposed",{}).get("new_tag_candidates",[]):
                code="".join(ch.lower() if ch.isalnum() else "_" for ch in str(candidate)).strip("_")[:150]
                if code:
                    cur.execute(f'''INSERT INTO "{staging_schema}"."tag"(id,code,tag_type,status,translations,created_at,updated_at) VALUES(gen_random_uuid(),%s,'llm_candidate','active','{{}}'::jsonb,now(),now()) ON CONFLICT (code) DO NOTHING''',(code,))
            for code in proposal.get("proposed",{}).get("tags",[]):
                cur.execute(f'''INSERT INTO "{staging_schema}"."exercise_tag"(exercise_id,tag_id,created_at) SELECT %s,id,now() FROM "{staging_schema}"."tag" WHERE code=%s ON CONFLICT DO NOTHING''',(exercise_id,code))
            for code in proposal.get("proposed",{}).get("categories",[]):
                cur.execute(f'''INSERT INTO "{staging_schema}"."exercise_category"(exercise_id,category_id,is_primary,created_at) SELECT %s,id,false,now() FROM "{staging_schema}"."category" WHERE code=%s ON CONFLICT DO NOTHING''',(exercise_id,code))
            for code in proposal.get("proposed",{}).get("equipment",[]):
                cur.execute(f'''INSERT INTO "{staging_schema}"."exercise_equipment"(exercise_id,equipment_id,required,is_primary,quantity_needed,created_at) SELECT %s,id,true,false,1,now() FROM "{staging_schema}"."equipment" WHERE code=%s ON CONFLICT DO NOTHING''',(exercise_id,code))
            for target in proposal.get("proposed",{}).get("variations",[]):
                cur.execute(f'''INSERT INTO "{staging_schema}"."exercise_variation"(base_exercise_id,variant_exercise_id,variation_type,difficulty_delta,created_at) SELECT %s,id,'related',NULL,now() FROM "{staging_schema}"."exercise" WHERE id::text=%s AND id<>%s ON CONFLICT DO NOTHING''',(exercise_id,str(target),exercise_id))
    return {"imported":True,"applied_rows":applied}

def promote(database_url, staging_schema, source_schema):
    if not database_url: return {"promoted":False,"reason":"DATABASE_URL is not configured"}
    # Promotion is intentionally explicit and only copies tables that exist in both schemas.
    import psycopg
    with psycopg.connect(database_url) as conn, conn.cursor() as cur:
        cur.execute("SELECT pg_advisory_xact_lock(hashtext(%s))", (source_schema,)); cur.execute("SELECT table_name FROM information_schema.tables WHERE table_schema=%s", (staging_schema,)); tables=[r[0] for r in cur.fetchall()]
        if "exercise" in tables:
            cur.execute(f'''UPDATE "{source_schema}"."exercise" target SET name=staging.name,difficulty=staging.difficulty,mechanics=staging.mechanics,force=staging.force,unilateral=staging.unilateral,bodyweight=staging.bodyweight,overall_risk=staging.overall_risk,spotter_required=staging.spotter_required,visibility=staging.visibility,translations=staging.translations,updated_at=staging.updated_at FROM "{staging_schema}"."exercise" staging WHERE target.id=staging.id''')
        return {"promoted":True,"tables":tables}
