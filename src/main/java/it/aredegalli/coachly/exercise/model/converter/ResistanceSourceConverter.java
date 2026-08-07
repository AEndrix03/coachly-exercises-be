package it.aredegalli.coachly.exercise.model.converter;

import it.aredegalli.coachly.exercise.enums.ResistanceSource;
import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;
import java.util.Locale;

@Converter
public class ResistanceSourceConverter implements AttributeConverter<ResistanceSource, String> {

    @Override
    public String convertToDatabaseColumn(ResistanceSource attribute) {
        return attribute == null ? null : attribute.name().toLowerCase(Locale.ROOT);
    }

    @Override
    public ResistanceSource convertToEntityAttribute(String dbData) {
        return dbData == null ? null : ResistanceSource.valueOf(dbData.toUpperCase(Locale.ROOT));
    }
}
