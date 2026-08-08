package it.aredegalli.coachly.exercise.model.converter;

import it.aredegalli.coachly.exercise.enums.ExternalResistanceProfile;
import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;
import java.util.Locale;

@Converter
public class ExternalResistanceProfileConverter implements AttributeConverter<ExternalResistanceProfile, String> {

    @Override
    public String convertToDatabaseColumn(ExternalResistanceProfile attribute) {
        return attribute == null ? null : attribute.name().toLowerCase(Locale.ROOT);
    }

    @Override
    public ExternalResistanceProfile convertToEntityAttribute(String dbData) {
        return dbData == null ? null : ExternalResistanceProfile.valueOf(dbData.toUpperCase(Locale.ROOT));
    }
}
