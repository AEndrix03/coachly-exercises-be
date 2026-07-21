import json
from uuid import UUID

def validate_proposal(proposal, original, catalogs=None, confidence=(.85,.65)):
    errors=[]; catalogs=catalogs or {}
    if not proposal.get("proposed"): errors.append("NO_ENRICHMENT_CHANGES")
    try: UUID(str(proposal["exercise_id"]))
    except (KeyError,ValueError,TypeError): errors.append("INVALID_EXERCISE_ID")
    for field, key in (("muscles","muscles"),("categories","categories"),("equipment","equipment"),("tags","tags")):
        allowed={item.get("code") if isinstance(item, dict) else item for item in catalogs.get(field, [])}
        for item in proposal.get("proposed",{}).get(key,[]):
            code=item.get("code") if isinstance(item,dict) else item
            if allowed and code not in allowed: errors.append("UNKNOWN_"+field.upper()+":"+str(code))
    score=float(proposal.get("overall_confidence",0))
    status="ACCEPTED" if not errors and score>=confidence[0] else "MANUAL_REVIEW" if not errors and score>=confidence[1] else "REJECTED"
    return {"status":status,"errors":errors,"schema_valid":not errors,"catalog_valid":not any(x.startswith("UNKNOWN_") for x in errors)}
