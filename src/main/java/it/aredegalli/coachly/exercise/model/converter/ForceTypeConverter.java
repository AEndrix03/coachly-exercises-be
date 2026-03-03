package it.aredegalli.coachly.exercise.model.converter;

import it.aredegalli.coachly.exercise.enums.ForceType;
import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;
import java.util.Locale;

@Converter
public class ForceTypeConverter implements AttributeConverter<ForceType, String> {

    @Override
    public String convertToDatabaseColumn(ForceType attribute) {
        return attribute == null ? null : attribute.name().toLowerCase(Locale.ROOT);
    }

    @Override
    public ForceType convertToEntityAttribute(String dbData) {
        return dbData == null ? null : ForceType.valueOf(dbData.toUpperCase(Locale.ROOT));
    }
}
