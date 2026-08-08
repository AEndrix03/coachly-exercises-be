package it.aredegalli.coachly.exercise.model.converter;

import it.aredegalli.coachly.exercise.enums.LoadInputMode;
import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;
import java.util.Locale;

@Converter
public class LoadInputModeConverter implements AttributeConverter<LoadInputMode, String> {

    @Override
    public String convertToDatabaseColumn(LoadInputMode attribute) {
        return attribute == null ? null : attribute.name().toLowerCase(Locale.ROOT);
    }

    @Override
    public LoadInputMode convertToEntityAttribute(String dbData) {
        return dbData == null ? null : LoadInputMode.valueOf(dbData.toUpperCase(Locale.ROOT));
    }
}
