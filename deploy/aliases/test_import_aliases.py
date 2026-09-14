import import_aliases


def test_validate_rejects_duplicate_normalized_alias():
    rows = [
        {"exercise_code": "row", "locale": "it", "alias": "Pulley", "type": "slang", "weight": "100"},
        {"exercise_code": "row", "locale": "it", "alias": "PULLÉY!", "type": "slang", "weight": "90"},
    ]
    errors, _ = import_aliases.validate(rows)
    assert any("duplicate normalized alias" in error for error in errors)


def test_validate_reports_cross_exercise_ambiguity_as_warning():
    rows = [
        {"exercise_code": "row_a", "locale": "it", "alias": "Pulley", "type": "slang", "weight": "100"},
        {"exercise_code": "row_b", "locale": "it", "alias": "pulley", "type": "slang", "weight": "80"},
    ]
    errors, warnings = import_aliases.validate(rows)
    assert errors == []
    assert any("ambiguous" in warning for warning in warnings)
