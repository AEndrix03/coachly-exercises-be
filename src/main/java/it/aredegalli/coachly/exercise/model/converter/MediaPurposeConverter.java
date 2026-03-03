package it.aredegalli.coachly.exercise.model.converter;

import it.aredegalli.coachly.exercise.enums.MediaPurpose;
import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;
import java.util.Locale;

@Converter
public class MediaPurposeConverter implements AttributeConverter<MediaPurpose, String> {

    @Override
    public String convertToDatabaseColumn(MediaPurpose attribute) {
        return attribute == null ? null : attribute.name().toLowerCase(Locale.ROOT);
    }

    @Override
    public MediaPurpose convertToEntityAttribute(String dbData) {
        return dbData == null ? null : MediaPurpose.valueOf(dbData.toUpperCase(Locale.ROOT));
    }
}
