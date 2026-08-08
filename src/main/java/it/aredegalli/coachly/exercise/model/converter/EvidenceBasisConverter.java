package it.aredegalli.coachly.exercise.model.converter;

import it.aredegalli.coachly.exercise.enums.EvidenceBasis;
import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;
import java.util.Locale;

@Converter
public class EvidenceBasisConverter implements AttributeConverter<EvidenceBasis, String> {

    @Override
    public String convertToDatabaseColumn(EvidenceBasis attribute) {
        return attribute == null ? null : attribute.name().toLowerCase(Locale.ROOT);
    }

    @Override
    public EvidenceBasis convertToEntityAttribute(String dbData) {
        return dbData == null ? null : EvidenceBasis.valueOf(dbData.toUpperCase(Locale.ROOT));
    }
}
