from pathlib import Path
import hashlib
import json
import sqlite3
import shutil

from .database import catalogs, extract_rows
from .ollama import OllamaClient
from .provider_pool import GeminiPool
from .spring_scan import scan_project
from .validation import validate_proposal


def write_json(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, indent=2, ensure_ascii=False), encoding="utf-8")


def extract(settings):
    root, out = Path(settings.spring_project), settings.data_dir
    manifest = scan_project(root)
    write_json(out / "metadata/project_manifest.json", manifest)
    dump = root / "exercises_dump.json"
    if dump.exists():
        raw = json.loads(dump.read_text(encoding="utf-8"))
        records = raw if isinstance(raw, list) else raw.get("exercises", raw.get("data", []))
    elif settings.database_url:
        records = extract_rows(settings.database_url, "exercise", settings.db_schema)
    else:
        records = []
    if settings.max_records is not None:
        records = records[:settings.max_records]
    (out / "raw").mkdir(parents=True, exist_ok=True)
    with (out / "raw/exercises.jsonl").open("w", encoding="utf-8") as output:
        for record in records:
            output.write(json.dumps(record, ensure_ascii=False, default=str) + "\n")
    write_json(out / "metadata/domain_schema.json", {"generated_from": manifest, "record_count": len(records)})
    return manifest, records


def audit(records):
    issues = []
    for record in records:
        exercise_id, name = str(record.get("id", "")), record.get("name")
        if not exercise_id:
            issues.append({"exercise_id": exercise_id, "code": "MISSING_ID"})
        if not name:
            issues.append({"exercise_id": exercise_id, "code": "MISSING_NAME"})
        if isinstance(record.get("translations"), str):
            try:
                json.loads(record["translations"])
            except json.JSONDecodeError:
                issues.append({"exercise_id": exercise_id, "code": "INVALID_TRANSLATIONS_JSON"})
    return {"total": len(records), "issue_count": len(issues), "issues": issues, "valid": not issues}


def init_jobs(path, records, model):
    path.parent.mkdir(parents=True, exist_ok=True)
    db = sqlite3.connect(path)
    db.execute("CREATE TABLE IF NOT EXISTS enrichment_job (exercise_id TEXT PRIMARY KEY, source_hash TEXT NOT NULL, model_name TEXT NOT NULL, prompt_version TEXT NOT NULL, schema_version TEXT NOT NULL, status TEXT NOT NULL, attempts INTEGER NOT NULL DEFAULT 0, input_path TEXT, output_path TEXT, error_message TEXT, started_at TEXT, completed_at TEXT)")
    for record in records:
        exercise_id = str(record.get("id"))
        source_hash = hashlib.sha256(json.dumps(record, sort_keys=True, default=str).encode()).hexdigest()
        db.execute("INSERT OR IGNORE INTO enrichment_job(exercise_id,source_hash,model_name,prompt_version,schema_version,status) VALUES(?,?,?,?,?,?)", (exercise_id, source_hash, model, "v2", "v2", "PENDING"))
    db.commit()
    db.close()


def report(settings, audit_result):
    write_json(settings.data_dir / "reports/initial_audit.json", audit_result)
    html = "<html><body><h1>Exercise enrichment audit</h1><p>Total: %s</p><p>Issues: %s</p></body></html>" % (audit_result["total"], audit_result["issue_count"])
    target = settings.data_dir / "reports/initial_audit.html"
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(html, encoding="utf-8")


def _gemini_schema():
    strings = ("exercise_id", "name", "description_it", "description_en", "difficulty", "mechanics", "force")
    arrays = ("execution_tips_it", "execution_tips_en", "safety_tips_it", "safety_tips_en", "muscles", "categories", "equipment", "tags", "new_tag_candidates", "new_exercise_candidates", "variations")
    properties = {field: {"type": "string"} for field in strings}
    properties.update({field: {"type": "array", "items": {"type": "string"}} for field in arrays})
    properties["confidence"] = {"type": "number"}
    return {"type": "object", "properties": properties, "required": [*strings, *arrays, "confidence"]}


def enrich(settings, records):
    """Process resumably; the model can only produce persisted proposals."""
    proposals_dir = settings.data_dir / "proposals"
    proposals_dir.mkdir(parents=True, exist_ok=True)
    init_jobs(settings.data_dir / "pipeline.sqlite", records, settings.model)
    db = sqlite3.connect(settings.data_dir / "pipeline.sqlite")
    schema = _gemini_schema()

    if settings.gemini_api_key:
        available = catalogs(settings.database_url, settings.db_schema)
        pending = []
        prompt_version = "v4"
        archive_dir = settings.data_dir / "proposals_previous"
        for record in records:
            target = proposals_dir / f"{record.get('id')}.json"
            if target.exists():
                try:
                    existing = json.loads(target.read_text(encoding="utf-8"))
                except json.JSONDecodeError:
                    existing = {}
                if existing.get("prompt_version") == prompt_version:
                    continue
                archive_dir.mkdir(parents=True, exist_ok=True)
                shutil.move(str(target), str(archive_dir / f"{record.get('id')}.pre-{prompt_version}.json"))
            candidate = dict(record)
            candidate["_allowed_catalogs"] = {
                key: [f"{item['code']} | {item['name_it']} | {item['name_en']}" for item in values]
                for key, values in available.items() if key != "exercises"
            }
            candidate["_candidate_variations"] = [f"{item['id']} | {item['name']}" for item in available.get("exercises", [])[:30]]
            pending.append(candidate)

        def handle(response, record):
            exercise_id = str(record.get("id"))
            raw = response.get("response", response)
            flat = json.loads(raw.replace("```json", "").replace("```", "")) if isinstance(raw, str) else raw
            proposed = {
                "name": flat.get("name"),
                "difficulty": flat.get("difficulty"),
                "mechanics": flat.get("mechanics"),
                "force": flat.get("force"),
                "translations": {
                    "it": {"name": flat.get("name"), "description": flat.get("description_it"), "executionTips": flat.get("execution_tips_it", []), "safetyTips": flat.get("safety_tips_it", [])},
                    "en": {"name": flat.get("name"), "description": flat.get("description_en"), "executionTips": flat.get("execution_tips_en", []), "safetyTips": flat.get("safety_tips_en", [])},
                },
                "muscles": flat.get("muscles", []),
                "categories": flat.get("categories", []),
                "equipment": flat.get("equipment", []),
                "tags": flat.get("tags", []),
                "new_tag_candidates": flat.get("new_tag_candidates", []),
                "new_exercise_candidates": flat.get("new_exercise_candidates", []),
                "variations": flat.get("variations", []),
            }
            proposal = {"exercise_id": exercise_id, "proposed": proposed, "overall_confidence": flat.get("confidence", 0), "changes": ["translations", "catalog_relations"]}
            validation = validate_proposal(proposal, record, available)
            target = proposals_dir / f"{exercise_id}.json"
            target.write_text(json.dumps({"exercise_id": exercise_id, "prompt_version": prompt_version, "proposal": proposal, "validation": validation}, ensure_ascii=False, indent=2), encoding="utf-8")
            print(f"[enrich] {exercise_id} {validation['status']}", flush=True)
            return exercise_id, validation

        results = GeminiPool(settings.gemini_api_key, settings.gemini_models).process(pending, schema, handle)
        for index, result in results:
            if isinstance(result, tuple):
                exercise_id, validation = result
                status = validation["status"]
                error = None
            else:
                exercise_id, status, error = str(pending[index].get("id")), "REJECTED", str(result)
            if exercise_id:
                db.execute("UPDATE enrichment_job SET status=?,attempts=attempts+1,error_message=?,completed_at=datetime('now') WHERE exercise_id=?", (status, error, exercise_id))
        db.commit()
        db.close()
        return len(results)

    client = OllamaClient(settings.ollama_url, settings.model)
    done = 0
    for record in records:
        exercise_id = str(record.get("id"))
        target = proposals_dir / f"{exercise_id}.json"
        if target.exists():
            continue
        prompt = json.dumps({"original": record, "rules": "Use only supplied original/catalog values. Never invent codes, UUIDs or percentages.", "schema": schema}, ensure_ascii=False)
        try:
            response = client.chat(prompt, schema)
            raw = response.get("message", {}).get("content", response.get("response", response))
            proposal = json.loads(raw) if isinstance(raw, str) else raw
            validation = validate_proposal(proposal, record)
            target.write_text(json.dumps({"exercise_id": exercise_id, "proposal": proposal, "validation": validation}, ensure_ascii=False, indent=2), encoding="utf-8")
            db.execute("UPDATE enrichment_job SET status=?,attempts=attempts+1,output_path=?,completed_at=datetime('now') WHERE exercise_id=?", (validation["status"], str(target), exercise_id))
            done += 1
        except Exception as exc:
            db.execute("UPDATE enrichment_job SET status='REJECTED',attempts=attempts+1,error_message=? WHERE exercise_id=?", (str(exc), exercise_id))
    db.commit()
    db.close()
    return done
