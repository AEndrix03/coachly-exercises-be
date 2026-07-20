from pathlib import Path
import json, typer
from .config import Settings
from .pipeline import extract,audit,init_jobs,report
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
def run(spring_project:Path=Path("."),ollama_url:str="http://localhost:11434",model:str="qwen3:4b-instruct",max_records:int|None=None,auto_promote:bool=False):
    s=Settings.load(spring_project=spring_project,ollama_url=ollama_url,model=model,max_records=max_records,auto_promote=auto_promote)
    manifest,records=extract(s); result=audit(records); report(s,result); init_jobs(s.data_dir/"pipeline.sqlite",records,s.model)
    if not result["valid"]: raise typer.Exit(code=2)
    typer.echo("STAGING VALIDATED\nRun `python -m exercise_enrichment promote` to apply the validated dataset.")
for name in ("enrich","validate","import-staging","verify-staging","promote","report","resume","benchmark"):
    app.command(name)(lambda name=name: typer.echo(name+" is available after prerequisite pipeline stages."))
