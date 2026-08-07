package it.aredegalli.coachly.exercise.model.converter;

import it.aredegalli.coachly.exercise.enums.LengthBias;
import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;
import java.util.Locale;

@Converter
public class LengthBiasConverter implements AttributeConverter<LengthBias, String> {

    @Override
    public String convertToDatabaseColumn(LengthBias attribute) {
        return attribute == null ? null : attribute.name().toLowerCase(Locale.ROOT);
    }

    @Override
    public LengthBias convertToEntityAttribute(String dbData) {
        return dbData == null ? null : LengthBias.valueOf(dbData.toUpperCase(Locale.ROOT));
    }
}
