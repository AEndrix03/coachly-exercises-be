from pathlib import Path
import hashlib, json, sqlite3, time
from .spring_scan import scan_project
from .ollama import OllamaClient
from .validation import validate_proposal
from .database import extract_rows,catalogs
from .provider_pool import GeminiPool

def write_json(path, value):
    path.parent.mkdir(parents=True, exist_ok=True); path.write_text(json.dumps(value, indent=2, ensure_ascii=False), encoding="utf-8")

def extract(settings):
    root=Path(settings.spring_project); out=settings.data_dir
    manifest=scan_project(root); write_json(out/"metadata/project_manifest.json", manifest)
    records=[]
    dump=root/"exercises_dump.json"
    if dump.exists():
        raw=json.loads(dump.read_text(encoding="utf-8")); records=raw if isinstance(raw,list) else raw.get("exercises", raw.get("data", []))
    elif settings.database_url:
        # DB extraction is deterministic; no LLM-generated SQL is ever executed.
        records=extract_rows(settings.database_url, "exercise", settings.schema)
    else: records=[]
    (out/"raw").mkdir(parents=True, exist_ok=True)
    with (out/"raw/exercises.jsonl").open("w", encoding="utf-8") as f:
        for record in records[:settings.max_records]: f.write(json.dumps(record, ensure_ascii=False, default=str)+"\n")
    write_json(out/"metadata/domain_schema.json", {"generated_from": manifest, "record_count": len(records)})
    return manifest, records

def audit(records):
    issues=[]
    for r in records:
        rid=str(r.get("id", "")); name=r.get("name")
        if not rid: issues.append({"exercise_id":rid,"code":"MISSING_ID"})
        if not name: issues.append({"exercise_id":rid,"code":"MISSING_NAME"})
        if isinstance(r.get("translations"), str):
            try: json.loads(r["translations"])
            except json.JSONDecodeError: issues.append({"exercise_id":rid,"code":"INVALID_TRANSLATIONS_JSON"})
    return {"total":len(records),"issue_count":len(issues),"issues":issues,"valid":not issues}

def init_jobs(path, records, model):
    path.parent.mkdir(parents=True, exist_ok=True); db=sqlite3.connect(path)
    db.execute("CREATE TABLE IF NOT EXISTS enrichment_job (exercise_id TEXT PRIMARY KEY, source_hash TEXT NOT NULL, model_name TEXT NOT NULL, prompt_version TEXT NOT NULL, schema_version TEXT NOT NULL, status TEXT NOT NULL, attempts INTEGER NOT NULL DEFAULT 0, input_path TEXT, output_path TEXT, error_message TEXT, started_at TEXT, completed_at TEXT)")
    for r in records:
        rid=str(r.get("id")); h=hashlib.sha256(json.dumps(r,sort_keys=True,default=str).encode()).hexdigest()
        db.execute("INSERT OR IGNORE INTO enrichment_job(exercise_id,source_hash,model_name,prompt_version,schema_version,status) VALUES(?,?,?,?,?,?)",(rid,h,model,"v1","v1","PENDING"))
    db.commit(); db.close()

def report(settings, audit_result):
    write_json(settings.data_dir/"reports/initial_audit.json",audit_result)
    html="<html><body><h1>Exercise enrichment audit</h1><p>Total: %s</p><p>Issues: %s</p></body></html>"%(audit_result["total"],audit_result["issue_count"])
    p=settings.data_dir/"reports/initial_audit.html"; p.parent.mkdir(parents=True,exist_ok=True); p.write_text(html,encoding="utf-8")

def enrich(settings, records):
    """Process resumably; model output is persisted only as a proposal."""
    out=settings.data_dir/"proposals"; out.mkdir(parents=True,exist_ok=True)
    init_jobs(settings.data_dir/"pipeline.sqlite",records,settings.model); db=sqlite3.connect(settings.data_dir/"pipeline.sqlite")
    schema={"type":"object","properties":{"exercise_id":{"type":"string"},"name":{"type":"string"},"description_it":{"type":"string"},"description_en":{"type":"string"},"execution_tips_it":{"type":"array","items":{"type":"string"}},"safety_tips_it":{"type":"array","items":{"type":"string"}},"muscles":{"type":"array","items":{"type":"string"}},"categories":{"type":"array","items":{"type":"string"}},"equipment":{"type":"array","items":{"type":"string"}},"tags":{"type":"array","items":{"type":"string"}},"new_tag_candidates":{"type":"array","items":{"type":"string"}},"variations":{"type":"array","items":{"type":"string"}},"difficulty":{"type":"string"},"mechanics":{"type":"string"},"force":{"type":"string"},"confidence":{"type":"number"}},"required":["exercise_id","name","description_it","description_en","execution_tips_it","safety_tips_it","muscles","categories","equipment","tags","new_tag_candidates","variations","confidence"]}
    if settings.gemini_api_key:
        pool=GeminiPool(settings.gemini_api_key,settings.gemini_models)
        available=catalogs(settings.database_url,settings.schema); pending=[]
        for r in records:
            if not (out/(str(r.get("id"))+".json")).exists():
                copy=dict(r); copy["_allowed_catalogs"]={k:v for k,v in available.items() if k!="exercises"}; copy["_candidate_variations"]=available.get("exercises",[])[:30]; pending.append(copy)
        def handle(response, record):
            rid=str(record.get("id")); raw=response.get("response",response); flat=json.loads(raw.replace("```json","").replace("```","")) if isinstance(raw,str) else raw; proposed={"name":flat.get("name"),"difficulty":flat.get("difficulty"),"mechanics":flat.get("mechanics"),"force":flat.get("force"),"translations":{"it":{"name":flat.get("name"),"description":flat.get("description_it"),"executionTips":flat.get("execution_tips_it",[]),"safetyTips":flat.get("safety_tips_it",[])},"en":{"name":flat.get("name"),"description":flat.get("description_en"),"executionTips":[],"safetyTips":[]}},"muscles":flat.get("muscles",[]),"categories":flat.get("categories",[]),"equipment":flat.get("equipment",[]),"tags":flat.get("tags",[]),"new_tag_candidates":flat.get("new_tag_candidates",[]),"variations":flat.get("variations",[])}; proposal={"exercise_id":rid,"proposed":proposed,"overall_confidence":flat.get("confidence",0),"changes":["translations","catalog_relations"]}; validation=validate_proposal(proposal,record); target=out/(rid+".json"); target.write_text(json.dumps({"exercise_id":rid,"proposal":proposal,"validation":validation},ensure_ascii=False,indent=2),encoding="utf-8"); print(f"[enrich] {rid} {validation['status']}",flush=True); return rid,validation
        results=pool.process(pending,schema,handle)
        for item in results:
            if isinstance(item,tuple): db.execute("UPDATE enrichment_job SET status=?,attempts=attempts+1,completed_at=datetime('now') WHERE exercise_id=?",(item[1]["status"],item[0]))
        db.commit(); db.close(); return len(results)
    client=OllamaClient(settings.ollama_url, settings.model)
    done=0
    for r in records:
        rid=str(r.get("id")); target=out/(rid+".json")
        if target.exists(): continue
        prompt=json.dumps({"original":r,"rules":"Use only supplied original/catalog values. Never invent codes, UUIDs or percentages.","schema":schema},ensure_ascii=False)
        try:
            response=client.chat(prompt,schema); raw=response.get("message",{}).get("content",response.get("response",response)); proposal=json.loads(raw) if isinstance(raw,str) else raw
            validation=validate_proposal(proposal,r)
            target.write_text(json.dumps({"exercise_id":rid,"proposal":proposal,"validation":validation},ensure_ascii=False,indent=2),encoding="utf-8")
            db.execute("UPDATE enrichment_job SET status=?,attempts=attempts+1,output_path=?,completed_at=datetime('now') WHERE exercise_id=?",(validation["status"],str(target),rid)); done+=1
        except Exception as exc:
            db.execute("UPDATE enrichment_job SET status='REJECTED',attempts=attempts+1,error_message=? WHERE exercise_id=?",(str(exc),rid))
    db.commit(); db.close(); return done
