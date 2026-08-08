package it.aredegalli.coachly.exercise.model.converter;

import it.aredegalli.coachly.exercise.enums.JointClass;
import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;
import java.util.Locale;

@Converter
public class JointClassConverter implements AttributeConverter<JointClass, String> {

    @Override
    public String convertToDatabaseColumn(JointClass attribute) {
        return attribute == null ? null : attribute.name().toLowerCase(Locale.ROOT);
    }

    @Override
    public JointClass convertToEntityAttribute(String dbData) {
        return dbData == null ? null : JointClass.valueOf(dbData.toUpperCase(Locale.ROOT));
    }
}
