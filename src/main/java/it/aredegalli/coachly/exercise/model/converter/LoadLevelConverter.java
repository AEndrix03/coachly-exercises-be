package it.aredegalli.coachly.exercise.model.converter;

import it.aredegalli.coachly.exercise.enums.LoadLevel;
import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;
import java.util.Locale;

@Converter
public class LoadLevelConverter implements AttributeConverter<LoadLevel, String> {

    @Override
    public String convertToDatabaseColumn(LoadLevel attribute) {
        return attribute == null ? null : attribute.name().toLowerCase(Locale.ROOT);
    }

    @Override
    public LoadLevel convertToEntityAttribute(String dbData) {
        return dbData == null ? null : LoadLevel.valueOf(dbData.toUpperCase(Locale.ROOT));
    }
}
