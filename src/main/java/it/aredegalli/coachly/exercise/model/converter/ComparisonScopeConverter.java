package it.aredegalli.coachly.exercise.model.converter;

import it.aredegalli.coachly.exercise.enums.ComparisonScope;
import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;
import java.util.Locale;

@Converter
public class ComparisonScopeConverter implements AttributeConverter<ComparisonScope, String> {

    @Override
    public String convertToDatabaseColumn(ComparisonScope attribute) {
        return attribute == null ? null : attribute.name().toLowerCase(Locale.ROOT);
    }

    @Override
    public ComparisonScope convertToEntityAttribute(String dbData) {
        return dbData == null ? null : ComparisonScope.valueOf(dbData.toUpperCase(Locale.ROOT));
    }
}
