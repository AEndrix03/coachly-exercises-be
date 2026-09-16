package it.aredegalli.coachly.exercise.model.converter;

import it.aredegalli.coachly.exercise.enums.RankingTier;
import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;
import java.util.Locale;

@Converter
public class RankingTierConverter implements AttributeConverter<RankingTier, String> {

    @Override
    public String convertToDatabaseColumn(RankingTier attribute) {
        return attribute == null ? null : attribute.name().toLowerCase(Locale.ROOT);
    }

    @Override
    public RankingTier convertToEntityAttribute(String dbData) {
        return dbData == null ? null : RankingTier.valueOf(dbData.toUpperCase(Locale.ROOT));
    }
}
