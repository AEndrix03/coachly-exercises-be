from pathlib import Path
import json, typer
from .config import Settings
from .pipeline import extract,audit,init_jobs,report
from .pipeline import enrich
from .database import metadata,schema_diff
from .global_analysis import analyze
from .staging import create_staging,promote,import_proposals
from .benchmark import run as benchmark_run
from .verification import verify_staging
from .gemini import GeminiClient
app=typer.Typer(no_args_is_help=True)

def cfg(spring_project=None,ollama_url=None,model=None): return Settings.load(spring_project=spring_project,ollama_url=ollama_url,model=model)

@app.command()
def inspect(spring_project:Path=Path(".")):
    typer.echo(json.dumps(extract(cfg(spring_project))[0],indent=2))
@app.command("extract")
def extract_cmd(spring_project:Path=Path(".")):
    manifest,_=extract(cfg(spring_project)); typer.echo(json.dumps(manifest,indent=2))
@app.command("audit")
def audit_cmd(spring_project:Path=Path(".")):
    s=cfg(spring_project); _,records=extract(s); result=audit(records); report(s,result); typer.echo(json.dumps(result,indent=2))
@app.command()
def run(spring_project:Path=Path("."),ollama_url:str="http://localhost:11434",model:str="qwen3:4b",max_records:int|None=None,auto_promote:bool=False):
    s=Settings.load(spring_project=spring_project,ollama_url=ollama_url,model=model,max_records=max_records,auto_promote=auto_promote)
    manifest,records=extract(s); dbmeta=metadata(s.database_url,s.schema); diff=schema_diff(manifest,dbmeta); report(s,{**audit(records),"schema_diff":diff}); init_jobs(s.data_dir/"pipeline.sqlite",records,s.model)
    if s.database_url and not diff["compatible"]: raise typer.Exit(code=3)
    if not result["valid"]: raise typer.Exit(code=2)
    typer.echo("STAGING VALIDATED\nRun `python -m exercise_enrichment promote` to apply the validated dataset.")
@app.command("enrich")
def enrich_cmd(spring_project:Path=Path("."),ollama_url:str="http://localhost:11434",model:str="qwen3:4b"):
    s=Settings.load(spring_project=spring_project,ollama_url=ollama_url,model=model); _,records=extract(s); typer.echo(f"processed={enrich(s,records)}")
@app.command("validate")
def validate_cmd(spring_project:Path=Path(".")):
    s=Settings.load(spring_project=spring_project); _,records=extract(s); result=audit(records); result["global"]=analyze(records); report(s,result); typer.echo(json.dumps(result,indent=2))
@app.command("import-staging")
def import_staging(spring_project:Path=Path(".")):
    s=Settings.load(spring_project=spring_project); result=import_proposals(s.database_url,s.schema,s.staging_schema,s.data_dir/"proposals"); typer.echo(json.dumps(result))
@app.command("promote")
def promote_cmd(spring_project:Path=Path(".")):
    s=Settings.load(spring_project=spring_project); typer.echo(json.dumps(promote(s.database_url,s.staging_schema,s.schema)))
@app.command("report")
def report_cmd(spring_project:Path=Path(".")):
    s=Settings.load(spring_project=spring_project); _,records=extract(s); result={**audit(records),"global":analyze(records)}; report(s,result); typer.echo(str(s.data_dir/"reports"))
@app.command("verify-staging")
def verify_staging_cmd(spring_project:Path=Path(".")):
    s=Settings.load(spring_project=spring_project); _,records=extract(s); result=verify_staging(s.database_url,s.staging_schema,len(records),s.data_dir/"proposals"); (s.data_dir/"reports").mkdir(parents=True,exist_ok=True); (s.data_dir/"reports/staging_verification.json").write_text(json.dumps(result,indent=2),encoding="utf-8"); typer.echo(json.dumps(result,indent=2)); raise typer.Exit(code=0 if result["verified"] else 3)
@app.command("resume")
def resume_cmd(spring_project:Path=Path("."),ollama_url:str="http://localhost:11434",model:str="qwen3:4b"):
    s=Settings.load(spring_project=spring_project,ollama_url=ollama_url,model=model); _,records=extract(s); typer.echo(f"processed={enrich(s,records)}")
@app.command("benchmark")
def benchmark_cmd(spring_project:Path=Path("."),ollama_url:str="http://localhost:11434",model:str="qwen3:4b",sample_size:int=40):
    s=Settings.load(spring_project=spring_project,ollama_url=ollama_url,model=model); _,records=extract(s); schema={"type":"object","required":["exercise_id","proposed","overall_confidence"]}; client=GeminiClient(s.gemini_api_key,s.gemini_model) if s.gemini_api_key else __import__('exercise_enrichment.ollama',fromlist=['OllamaClient']).OllamaClient(s.ollama_url,s.model); result=benchmark_run(client,records,schema,sample_size); (s.data_dir/"reports").mkdir(parents=True,exist_ok=True); (s.data_dir/"reports/benchmark.json").write_text(json.dumps(result,indent=2),encoding="utf-8"); typer.echo(json.dumps(result,indent=2)); raise typer.Exit(code=0 if result["passed"] else 3)
