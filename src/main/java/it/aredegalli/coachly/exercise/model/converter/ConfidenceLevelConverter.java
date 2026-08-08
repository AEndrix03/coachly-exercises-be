package it.aredegalli.coachly.exercise.model.converter;

import it.aredegalli.coachly.exercise.enums.ConfidenceLevel;
import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;
import java.util.Locale;

@Converter
public class ConfidenceLevelConverter implements AttributeConverter<ConfidenceLevel, String> {

    @Override
    public String convertToDatabaseColumn(ConfidenceLevel attribute) {
        return attribute == null ? null : attribute.name().toLowerCase(Locale.ROOT);
    }

    @Override
    public ConfidenceLevel convertToEntityAttribute(String dbData) {
        return dbData == null ? null : ConfidenceLevel.valueOf(dbData.toUpperCase(Locale.ROOT));
    }
}
