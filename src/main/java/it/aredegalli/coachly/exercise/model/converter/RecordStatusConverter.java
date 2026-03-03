package it.aredegalli.coachly.exercise.model.converter;

import it.aredegalli.coachly.exercise.enums.RecordStatus;
import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;
import java.util.Locale;

@Converter
public class RecordStatusConverter implements AttributeConverter<RecordStatus, String> {

    @Override
    public String convertToDatabaseColumn(RecordStatus attribute) {
        return attribute == null ? null : attribute.name().toLowerCase(Locale.ROOT);
    }

    @Override
    public RecordStatus convertToEntityAttribute(String dbData) {
        return dbData == null ? null : RecordStatus.valueOf(dbData.toUpperCase(Locale.ROOT));
    }
}
