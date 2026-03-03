package it.aredegalli.coachly.exercise.model.converter;

import it.aredegalli.coachly.exercise.enums.Visibility;
import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;
import java.util.Locale;

@Converter
public class VisibilityConverter implements AttributeConverter<Visibility, String> {

    @Override
    public String convertToDatabaseColumn(Visibility attribute) {
        return attribute == null ? null : attribute.name().toLowerCase(Locale.ROOT);
    }

    @Override
    public Visibility convertToEntityAttribute(String dbData) {
        return dbData == null ? null : Visibility.valueOf(dbData.toUpperCase(Locale.ROOT));
    }
}
