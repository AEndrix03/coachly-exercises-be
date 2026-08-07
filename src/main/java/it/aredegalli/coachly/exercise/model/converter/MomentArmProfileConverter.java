package it.aredegalli.coachly.exercise.model.converter;

import it.aredegalli.coachly.exercise.enums.MomentArmProfile;
import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;
import java.util.Locale;

@Converter
public class MomentArmProfileConverter implements AttributeConverter<MomentArmProfile, String> {

    @Override
    public String convertToDatabaseColumn(MomentArmProfile attribute) {
        return attribute == null ? null : attribute.name().toLowerCase(Locale.ROOT);
    }

    @Override
    public MomentArmProfile convertToEntityAttribute(String dbData) {
        return dbData == null ? null : MomentArmProfile.valueOf(dbData.toUpperCase(Locale.ROOT));
    }
}
