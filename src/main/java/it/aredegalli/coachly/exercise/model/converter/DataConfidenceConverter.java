package it.aredegalli.coachly.exercise.model.converter;

import it.aredegalli.coachly.exercise.enums.DataConfidence;
import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;
import java.util.Locale;

@Converter
public class DataConfidenceConverter implements AttributeConverter<DataConfidence, String> {

    @Override
    public String convertToDatabaseColumn(DataConfidence attribute) {
        return attribute == null ? null : attribute.name().toLowerCase(Locale.ROOT);
    }

    @Override
    public DataConfidence convertToEntityAttribute(String dbData) {
        return dbData == null ? null : DataConfidence.valueOf(dbData.toUpperCase(Locale.ROOT));
    }
}
