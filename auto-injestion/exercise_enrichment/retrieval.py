import re, json
from pathlib import Path
def canonical(r):
    return " ".join(str(r.get(k,"")) for k in ("name","description","category","muscles","equipment","tags","mechanics","force")).lower()
def similar(records, limit=10):
    token_sets=[set(re.findall(r"[a-z0-9]+",canonical(r))) for r in records]; result=[]
    for i, tokens in enumerate(token_sets):
        scores=[]
        for j, other in enumerate(token_sets):
            if i==j: continue
            union=tokens|other; scores.append((len(tokens&other)/len(union) if union else 0,j))
        result.append([{"exercise_id":str(records[j].get("id")),"score":round(score,6)} for score,j in sorted(scores,reverse=True)[:limit]])
    return result
