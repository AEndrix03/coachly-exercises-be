package it.aredegalli.coachly.exercise.model.converter;

import it.aredegalli.coachly.exercise.enums.MuscleGroupType;
import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;
import java.util.Locale;

@Converter
public class MuscleGroupTypeConverter implements AttributeConverter<MuscleGroupType, String> {

    @Override
    public String convertToDatabaseColumn(MuscleGroupType attribute) {
        return attribute == null ? null : attribute.name().toLowerCase(Locale.ROOT);
    }

    @Override
    public MuscleGroupType convertToEntityAttribute(String dbData) {
        return dbData == null ? null : MuscleGroupType.valueOf(dbData.toUpperCase(Locale.ROOT));
    }
}
