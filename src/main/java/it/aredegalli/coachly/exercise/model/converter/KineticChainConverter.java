package it.aredegalli.coachly.exercise.model.converter;

import it.aredegalli.coachly.exercise.enums.KineticChain;
import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;
import java.util.Locale;

@Converter
public class KineticChainConverter implements AttributeConverter<KineticChain, String> {

    @Override
    public String convertToDatabaseColumn(KineticChain attribute) {
        return attribute == null ? null : attribute.name().toLowerCase(Locale.ROOT);
    }

    @Override
    public KineticChain convertToEntityAttribute(String dbData) {
        return dbData == null ? null : KineticChain.valueOf(dbData.toUpperCase(Locale.ROOT));
    }
}
