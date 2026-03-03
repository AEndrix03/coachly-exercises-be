package it.aredegalli.coachly.exercise.model.converter;

import it.aredegalli.coachly.exercise.enums.InvolvementLevel;
import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;
import java.util.Locale;

@Converter
public class InvolvementLevelConverter implements AttributeConverter<InvolvementLevel, String> {

    @Override
    public String convertToDatabaseColumn(InvolvementLevel attribute) {
        return attribute == null ? null : attribute.name().toLowerCase(Locale.ROOT);
    }

    @Override
    public InvolvementLevel convertToEntityAttribute(String dbData) {
        return dbData == null ? null : InvolvementLevel.valueOf(dbData.toUpperCase(Locale.ROOT));
    }
}
