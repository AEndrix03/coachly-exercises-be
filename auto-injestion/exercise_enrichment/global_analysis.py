from .retrieval import similar
def analyze(records):
    near=similar(records,5); duplicate_candidates=[]
    for i, items in enumerate(near):
        for item in items:
            if item["score"]>=.85: duplicate_candidates.append({"left":str(records[i].get("id")),"right":item["exercise_id"],"classification":"SAME_EXERCISE"})
    return {"duplicate_candidates":duplicate_candidates,"variation_cycles":[],"valid":not duplicate_candidates}
