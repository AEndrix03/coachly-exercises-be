package it.aredegalli.coachly.exercise.model.converter;

import it.aredegalli.coachly.exercise.enums.EquipmentClass;
import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;
import java.util.Locale;

@Converter
public class EquipmentClassConverter implements AttributeConverter<EquipmentClass, String> {

    @Override
    public String convertToDatabaseColumn(EquipmentClass attribute) {
        return attribute == null ? null : attribute.name().toLowerCase(Locale.ROOT);
    }

    @Override
    public EquipmentClass convertToEntityAttribute(String dbData) {
        return dbData == null ? null : EquipmentClass.valueOf(dbData.toUpperCase(Locale.ROOT));
    }
}
