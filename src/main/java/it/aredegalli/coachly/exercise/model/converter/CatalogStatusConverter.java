package it.aredegalli.coachly.exercise.model.converter;

import it.aredegalli.coachly.exercise.enums.CatalogStatus;
import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;
import java.util.Locale;

@Converter
public class CatalogStatusConverter implements AttributeConverter<CatalogStatus, String> {

    @Override
    public String convertToDatabaseColumn(CatalogStatus attribute) {
        return attribute == null ? null : attribute.name().toLowerCase(Locale.ROOT);
    }

    @Override
    public CatalogStatus convertToEntityAttribute(String dbData) {
        return dbData == null ? null : CatalogStatus.valueOf(dbData.toUpperCase(Locale.ROOT));
    }
}
