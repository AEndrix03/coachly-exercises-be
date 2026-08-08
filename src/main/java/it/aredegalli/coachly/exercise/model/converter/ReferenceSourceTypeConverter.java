package it.aredegalli.coachly.exercise.model.converter;

import it.aredegalli.coachly.exercise.enums.ReferenceSourceType;
import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;
import java.util.Locale;

@Converter
public class ReferenceSourceTypeConverter implements AttributeConverter<ReferenceSourceType, String> {

    @Override
    public String convertToDatabaseColumn(ReferenceSourceType attribute) {
        return attribute == null ? null : attribute.name().toLowerCase(Locale.ROOT);
    }

    @Override
    public ReferenceSourceType convertToEntityAttribute(String dbData) {
        return dbData == null ? null : ReferenceSourceType.valueOf(dbData.toUpperCase(Locale.ROOT));
    }
}
