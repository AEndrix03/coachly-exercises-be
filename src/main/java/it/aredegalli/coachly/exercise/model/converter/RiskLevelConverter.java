package it.aredegalli.coachly.exercise.model.converter;

import it.aredegalli.coachly.exercise.enums.RiskLevel;
import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;
import java.util.Locale;

@Converter
public class RiskLevelConverter implements AttributeConverter<RiskLevel, String> {

    @Override
    public String convertToDatabaseColumn(RiskLevel attribute) {
        return attribute == null ? null : attribute.name().toLowerCase(Locale.ROOT);
    }

    @Override
    public RiskLevel convertToEntityAttribute(String dbData) {
        return dbData == null ? null : RiskLevel.valueOf(dbData.toUpperCase(Locale.ROOT));
    }
}
