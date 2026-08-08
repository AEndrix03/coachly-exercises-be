package it.aredegalli.coachly.exercise.model.converter;

import it.aredegalli.coachly.exercise.enums.ExerciseKind;
import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;
import java.util.Locale;

@Converter
public class ExerciseKindConverter implements AttributeConverter<ExerciseKind, String> {

    @Override
    public String convertToDatabaseColumn(ExerciseKind attribute) {
        return attribute == null ? null : attribute.name().toLowerCase(Locale.ROOT);
    }

    @Override
    public ExerciseKind convertToEntityAttribute(String dbData) {
        return dbData == null ? null : ExerciseKind.valueOf(dbData.toUpperCase(Locale.ROOT));
    }
}
