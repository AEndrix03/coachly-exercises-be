package it.aredegalli.coachly.exercise.model.converter;

import it.aredegalli.coachly.exercise.enums.TensionLevel;
import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;
import java.util.Locale;

@Converter
public class TensionLevelConverter implements AttributeConverter<TensionLevel, String> {

    @Override
    public String convertToDatabaseColumn(TensionLevel attribute) {
        return attribute == null ? null : attribute.name().toLowerCase(Locale.ROOT);
    }

    @Override
    public TensionLevel convertToEntityAttribute(String dbData) {
        return dbData == null ? null : TensionLevel.valueOf(dbData.toUpperCase(Locale.ROOT));
    }
}
