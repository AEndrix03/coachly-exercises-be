package it.aredegalli.coachly.exercise.model.converter;

import it.aredegalli.coachly.exercise.enums.MechanicsType;
import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;
import java.util.Locale;

@Converter
public class MechanicsTypeConverter implements AttributeConverter<MechanicsType, String> {

    @Override
    public String convertToDatabaseColumn(MechanicsType attribute) {
        return attribute == null ? null : attribute.name().toLowerCase(Locale.ROOT);
    }

    @Override
    public MechanicsType convertToEntityAttribute(String dbData) {
        return dbData == null ? null : MechanicsType.valueOf(dbData.toUpperCase(Locale.ROOT));
    }
}
