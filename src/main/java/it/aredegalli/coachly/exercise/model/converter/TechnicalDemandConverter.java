package it.aredegalli.coachly.exercise.model.converter;

import it.aredegalli.coachly.exercise.enums.TechnicalDemand;
import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;
import java.util.Locale;

@Converter
public class TechnicalDemandConverter implements AttributeConverter<TechnicalDemand, String> {

    @Override
    public String convertToDatabaseColumn(TechnicalDemand attribute) {
        return attribute == null ? null : attribute.name().toLowerCase(Locale.ROOT);
    }

    @Override
    public TechnicalDemand convertToEntityAttribute(String dbData) {
        return dbData == null ? null : TechnicalDemand.valueOf(dbData.toUpperCase(Locale.ROOT));
    }
}
