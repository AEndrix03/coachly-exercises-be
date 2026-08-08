package it.aredegalli.coachly.exercise.model.converter;

import it.aredegalli.coachly.exercise.enums.SpotterPolicy;
import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;
import java.util.Locale;

@Converter
public class SpotterPolicyConverter implements AttributeConverter<SpotterPolicy, String> {

    @Override
    public String convertToDatabaseColumn(SpotterPolicy attribute) {
        return attribute == null ? null : attribute.name().toLowerCase(Locale.ROOT);
    }

    @Override
    public SpotterPolicy convertToEntityAttribute(String dbData) {
        return dbData == null ? null : SpotterPolicy.valueOf(dbData.toUpperCase(Locale.ROOT));
    }
}
