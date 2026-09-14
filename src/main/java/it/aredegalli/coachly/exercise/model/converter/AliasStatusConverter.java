package it.aredegalli.coachly.exercise.model.converter;

import it.aredegalli.coachly.exercise.enums.AliasStatus;
import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;
import java.util.Locale;

@Converter
public class AliasStatusConverter implements AttributeConverter<AliasStatus, String> {
    @Override
    public String convertToDatabaseColumn(AliasStatus attribute) {
        return attribute == null ? null : attribute.name().toLowerCase(Locale.ROOT);
    }

    @Override
    public AliasStatus convertToEntityAttribute(String dbData) {
        return dbData == null ? null : AliasStatus.valueOf(dbData.toUpperCase(Locale.ROOT));
    }
}
