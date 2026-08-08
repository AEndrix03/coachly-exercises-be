package it.aredegalli.coachly.exercise.model.converter;

import it.aredegalli.coachly.exercise.enums.TrackingType;
import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;
import java.util.Locale;

@Converter
public class TrackingTypeConverter implements AttributeConverter<TrackingType, String> {

    @Override
    public String convertToDatabaseColumn(TrackingType attribute) {
        return attribute == null ? null : attribute.name().toLowerCase(Locale.ROOT);
    }

    @Override
    public TrackingType convertToEntityAttribute(String dbData) {
        return dbData == null ? null : TrackingType.valueOf(dbData.toUpperCase(Locale.ROOT));
    }
}
