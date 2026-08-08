package it.aredegalli.coachly.exercise.model.converter;

import it.aredegalli.coachly.exercise.enums.VariationAxis;
import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;
import java.util.Locale;

@Converter
public class VariationAxisConverter implements AttributeConverter<VariationAxis, String> {

    @Override
    public String convertToDatabaseColumn(VariationAxis attribute) {
        return attribute == null ? null : attribute.name().toLowerCase(Locale.ROOT);
    }

    @Override
    public VariationAxis convertToEntityAttribute(String dbData) {
        return dbData == null ? null : VariationAxis.valueOf(dbData.toUpperCase(Locale.ROOT));
    }
}
