package it.aredegalli.coachly.exercise.model.converter;

import it.aredegalli.coachly.exercise.enums.SideMode;
import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;
import java.util.Locale;

@Converter
public class SideModeConverter implements AttributeConverter<SideMode, String> {

    @Override
    public String convertToDatabaseColumn(SideMode attribute) {
        return attribute == null ? null : attribute.name().toLowerCase(Locale.ROOT);
    }

    @Override
    public SideMode convertToEntityAttribute(String dbData) {
        return dbData == null ? null : SideMode.valueOf(dbData.toUpperCase(Locale.ROOT));
    }
}
