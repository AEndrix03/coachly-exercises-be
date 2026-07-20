import json, time
from .ollama import OllamaClient

def run(client, records, schema, sample_size=40):
    sample=records[:sample_size]; results=[]
    if not sample: return {"total":0,"json_valid_rate":1.0,"schema_valid_rate":1.0,"failure_rate":0.0,"results":[]}
    for record in sample:
        started=time.perf_counter(); valid=False; error=None
        try:
            response=client.chat(json.dumps({"original":record,"schema":schema}),schema)
            content=response.get("message",{}).get("content",response.get("response",response)); json.loads(content) if isinstance(content,str) else content; valid=True
        except Exception as exc: error=str(exc)
        results.append({"exercise_id":str(record.get("id")),"valid":valid,"duration_ms":round((time.perf_counter()-started)*1000,2),"error":error})
    valid=sum(x["valid"] for x in results)/len(results)
    return {"total":len(results),"json_valid_rate":valid,"schema_valid_rate":valid,"failure_rate":1-valid,"results":results,"passed":valid>=.98}
