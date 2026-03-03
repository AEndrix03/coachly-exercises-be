package it.aredegalli.coachly.exercise.model.converter;

import it.aredegalli.coachly.exercise.enums.DifficultyLevel;
import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;
import java.util.Locale;

@Converter
public class DifficultyLevelConverter implements AttributeConverter<DifficultyLevel, String> {

    @Override
    public String convertToDatabaseColumn(DifficultyLevel attribute) {
        return attribute == null ? null : attribute.name().toLowerCase(Locale.ROOT);
    }

    @Override
    public DifficultyLevel convertToEntityAttribute(String dbData) {
        return dbData == null ? null : DifficultyLevel.valueOf(dbData.toUpperCase(Locale.ROOT));
    }
}
