package it.aredegalli.coachly.exercise.model.converter;

import it.aredegalli.coachly.exercise.enums.ResistanceCurve;
import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;
import java.util.Locale;

@Converter
public class ResistanceCurveConverter implements AttributeConverter<ResistanceCurve, String> {

    @Override
    public String convertToDatabaseColumn(ResistanceCurve attribute) {
        return attribute == null ? null : attribute.name().toLowerCase(Locale.ROOT);
    }

    @Override
    public ResistanceCurve convertToEntityAttribute(String dbData) {
        return dbData == null ? null : ResistanceCurve.valueOf(dbData.toUpperCase(Locale.ROOT));
    }
}
