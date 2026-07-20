from exercise_enrichment.pipeline import audit

def test_audit_accepts_complete_snapshot():
    result = audit([{"id":"1", "name":"Squat", "translations":"{}"}])
    assert result["valid"]

def test_audit_rejects_missing_name():
    result = audit([{"id":"1"}])
    assert not result["valid"]
