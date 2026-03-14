package it.aredegalli.coachly.exercise.service;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import it.aredegalli.coachly.exercise.dto.retrieve.ExerciseDetailDto;
import it.aredegalli.coachly.exercise.dto.retrieve.ExerciseSummaryDto;
import it.aredegalli.coachly.exercise.enums.Visibility;
import it.aredegalli.coachly.exercise.model.Category;
import it.aredegalli.coachly.exercise.model.Equipment;
import it.aredegalli.coachly.exercise.model.Exercise;
import it.aredegalli.coachly.exercise.model.ExerciseCategory;
import it.aredegalli.coachly.exercise.model.ExerciseEquipment;
import it.aredegalli.coachly.exercise.model.ExerciseMedia;
import it.aredegalli.coachly.exercise.model.ExerciseMuscle;
import it.aredegalli.coachly.exercise.model.ExerciseTag;
import it.aredegalli.coachly.exercise.model.ExerciseVariation;
import it.aredegalli.coachly.exercise.model.Muscle;
import it.aredegalli.coachly.exercise.model.Tag;
import org.springframework.stereotype.Component;

import java.util.Collection;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

@Component
public class ExerciseRetrieveMapper {

    private static final TypeReference<Map<String, Object>> MAP_TYPE = new TypeReference<>() {};

    private final ObjectMapper objectMapper = new ObjectMapper();

    public ExerciseSummaryDto toSummary(Exercise exercise) {
        TranslationEnvelope translations = parseTranslations(exercise.getTranslations());
        return ExerciseSummaryDto.builder()
            .id(exercise.getId())
            .nameI18n(translations.fieldMap("nameI18n", "name"))
            .descriptionI18n(translations.fieldMap("descriptionI18n", "description"))
            .tipsI18n(translations.fieldMap("tipsI18n", "tips"))
            .difficultyLevel(enumValue(exercise.getDifficulty()))
            .mechanicsType(enumValue(exercise.getMechanics()))
            .forceType(enumValue(exercise.getForce()))
            .isUnilateral(exercise.isUnilateral())
            .isBodyweight(exercise.isBodyweight())
            .build();
    }

    public ExerciseDetailDto toDetail(
        Exercise exercise,
        List<ExerciseVariation> variations,
        List<ExerciseMedia> media,
        List<ExerciseCategory> categories,
        List<ExerciseMuscle> muscles,
        List<ExerciseEquipment> equipments,
        List<ExerciseTag> tags
    ) {
        TranslationEnvelope translations = parseTranslations(exercise.getTranslations());
        return ExerciseDetailDto.builder()
            .id(exercise.getId())
            .nameI18n(translations.fieldMap("nameI18n", "name"))
            .descriptionI18n(translations.fieldMap("descriptionI18n", "description"))
            .tipsI18n(translations.fieldMap("tipsI18n", "tips"))
            .difficultyLevel(enumValue(exercise.getDifficulty()))
            .mechanicsType(enumValue(exercise.getMechanics()))
            .forceType(enumValue(exercise.getForce()))
            .isUnilateral(exercise.isUnilateral())
            .isBodyweight(exercise.isBodyweight())
            .variants(variations.stream().map(this::toVariant).toList())
            .media(media.stream().map(this::toMedia).toList())
            .categories(categories.stream().map(this::toCategory).toList())
            .safety(List.of(toSafety(exercise, translations)))
            .muscles(muscles.stream().map(this::toMuscle).toList())
            .equipments(equipments.stream().map(this::toEquipment).toList())
            .tags(tags.stream().map(this::toTag).toList())
            .build();
    }

    public boolean matchesText(Exercise exercise, String rawTextFilter, String rawLangFilter) {
        if (rawTextFilter == null || rawTextFilter.isBlank()) {
            return true;
        }

        TranslationEnvelope translations = parseTranslations(exercise.getTranslations());
        String textFilter = normalize(rawTextFilter);
        List<String> languageCandidates = languageCandidates(rawLangFilter);
        return matchesI18n(translations.fieldMap("nameI18n", "name"), languageCandidates, textFilter)
            || matchesI18n(translations.fieldMap("descriptionI18n", "description"), languageCandidates, textFilter)
            || matchesI18n(translations.fieldMap("tipsI18n", "tips"), languageCandidates, textFilter);
    }

    public boolean matchesMuscles(List<ExerciseMuscle> muscles, List<String> rawMuscleTokens) {
        if (rawMuscleTokens == null || rawMuscleTokens.isEmpty()) {
            return true;
        }

        List<String> tokens = rawMuscleTokens.stream().map(this::normalize).toList();
        return muscles.stream().anyMatch(exerciseMuscle -> {
            Muscle muscle = exerciseMuscle.getMuscle();
            if (muscle == null) {
                return false;
            }
            TranslationEnvelope translations = parseTranslations(muscle.getTranslations());
            Map<String, String> names = translations.fieldMap("nameI18n", "name");
            return tokens.stream().anyMatch(token ->
                containsNormalized(muscle.getId() == null ? null : muscle.getId().toString(), token)
                    || containsNormalized(muscle.getCode(), token)
                    || containsAnyNormalized(names.values(), token)
            );
        });
    }

    private ExerciseDetailDto.VariantDto toVariant(ExerciseVariation variation) {
        Exercise variantExercise = variation.getVariantExercise();
        TranslationEnvelope translations = parseTranslations(variantExercise.getTranslations());
        return ExerciseDetailDto.VariantDto.builder()
            .id(variantExercise.getId())
            .nameI18n(translations.fieldMap("nameI18n", "name"))
            .descriptionI18n(translations.fieldMap("descriptionI18n", "description"))
            .tipsI18n(translations.fieldMap("tipsI18n", "tips"))
            .difficultyLevel(enumValue(variantExercise.getDifficulty()))
            .mechanicsType(enumValue(variantExercise.getMechanics()))
            .forceType(enumValue(variantExercise.getForce()))
            .isUnilateral(variantExercise.isUnilateral())
            .isBodyweight(variantExercise.isBodyweight())
            .difficultyDelta(variation.getDifficultyDelta())
            .build();
    }

    private ExerciseDetailDto.MediaDto toMedia(ExerciseMedia media) {
        return ExerciseDetailDto.MediaDto.builder()
            .id(media.getId())
            .mediaType(enumValue(media.getType()))
            .mediaUrl(media.getUrl())
            .thumbnailUrl(media.getThumbnailUrl())
            .mediaPurpose(enumValue(media.getPurpose()))
            .viewAngle(media.getViewAngle())
            .isPrimary(media.isPrimary())
            .isPublic(media.getVisibility() == Visibility.PUBLIC)
            .build();
    }

    private ExerciseDetailDto.CategoryNodeDto toCategory(ExerciseCategory exerciseCategory) {
        Category category = exerciseCategory.getCategory();
        TranslationEnvelope translations = parseTranslations(category.getTranslations());
        return ExerciseDetailDto.CategoryNodeDto.builder()
            .id(category.getId())
            .code(category.getCode())
            .nameI18n(translations.fieldMap("nameI18n", "name"))
            .descriptionI18n(translations.fieldMap("descriptionI18n", "description"))
            .categoryLevel(1)
            .isPrimary(exerciseCategory.isPrimary())
            .children(List.of())
            .build();
    }

    private ExerciseDetailDto.SafetyDto toSafety(Exercise exercise, TranslationEnvelope translations) {
        return ExerciseDetailDto.SafetyDto.builder()
            .id(exercise.getId())
            .overallRiskLevel(enumValue(exercise.getOverallRisk()))
            .spotterRequired(exercise.isSpotterRequired())
            .safetyNotesI18n(translations.fieldMap("safetyNotesI18n", "safetyNotes"))
            .build();
    }

    private ExerciseDetailDto.MuscleAssociationDto toMuscle(ExerciseMuscle exerciseMuscle) {
        Muscle muscle = exerciseMuscle.getMuscle();
        TranslationEnvelope translations = parseTranslations(muscle.getTranslations());
        return ExerciseDetailDto.MuscleAssociationDto.builder()
            .muscle(ExerciseDetailDto.NamedResourceDto.builder()
                .id(muscle.getId())
                .code(muscle.getCode())
                .nameI18n(translations.fieldMap("nameI18n", "name"))
                .descriptionI18n(translations.fieldMap("descriptionI18n", "description"))
                .build())
            .activationPercentage(exerciseMuscle.getActivationPercentage())
            .build();
    }

    private ExerciseDetailDto.EquipmentAssociationDto toEquipment(ExerciseEquipment exerciseEquipment) {
        Equipment equipment = exerciseEquipment.getEquipment();
        TranslationEnvelope translations = parseTranslations(equipment.getTranslations());
        return ExerciseDetailDto.EquipmentAssociationDto.builder()
            .equipment(ExerciseDetailDto.NamedResourceDto.builder()
                .id(equipment.getId())
                .code(equipment.getCode())
                .nameI18n(translations.fieldMap("nameI18n", "name"))
                .descriptionI18n(translations.fieldMap("descriptionI18n", "description"))
                .build())
            .isRequired(exerciseEquipment.isRequired())
            .isPrimary(exerciseEquipment.isPrimary())
            .quantityNeeded(exerciseEquipment.getQuantityNeeded())
            .build();
    }

    private ExerciseDetailDto.TagDto toTag(ExerciseTag exerciseTag) {
        Tag tag = exerciseTag.getTag();
        TranslationEnvelope translations = parseTranslations(tag.getTranslations());
        return ExerciseDetailDto.TagDto.builder()
            .id(tag.getId())
            .code(tag.getCode())
            .nameI18n(translations.fieldMap("nameI18n", "name"))
            .descriptionI18n(translations.fieldMap("descriptionI18n", "description"))
            .tagType(tag.getTagType())
            .build();
    }

    private boolean matchesI18n(Map<String, String> values, List<String> languageCandidates, String textFilter) {
        if (values == null || values.isEmpty()) {
            return false;
        }

        if (!languageCandidates.isEmpty()) {
            for (String languageCandidate : languageCandidates) {
                for (Map.Entry<String, String> entry : values.entrySet()) {
                    if (normalize(entry.getKey()).equals(languageCandidate) && containsNormalized(entry.getValue(), textFilter)) {
                        return true;
                    }
                }
            }
        }

        return containsAnyNormalized(values.values(), textFilter);
    }

    private boolean containsAnyNormalized(Collection<String> values, String token) {
        return values.stream().anyMatch(value -> containsNormalized(value, token));
    }

    private boolean containsNormalized(String rawValue, String normalizedToken) {
        return rawValue != null && normalize(rawValue).contains(normalizedToken);
    }

    private List<String> languageCandidates(String rawLangFilter) {
        if (rawLangFilter == null || rawLangFilter.isBlank()) {
            return List.of();
        }

        String normalized = normalize(rawLangFilter);
        if (normalized.contains("_")) {
            return List.of(normalized, normalized.substring(0, normalized.indexOf('_')));
        }
        return List.of(normalized);
    }

    private String normalize(String value) {
        return value == null ? "" : value.trim().toLowerCase(Locale.ROOT).replace('-', '_');
    }

    private String enumValue(Enum<?> value) {
        return value == null ? null : value.name().toLowerCase(Locale.ROOT);
    }

    private TranslationEnvelope parseTranslations(String rawTranslations) {
        if (rawTranslations == null || rawTranslations.isBlank()) {
            return new TranslationEnvelope(Map.of());
        }

        try {
            return new TranslationEnvelope(objectMapper.readValue(rawTranslations, MAP_TYPE));
        } catch (Exception ex) {
            return new TranslationEnvelope(Map.of());
        }
    }

    private static final class TranslationEnvelope {
        private final Map<String, Object> root;

        private TranslationEnvelope(Map<String, Object> root) {
            this.root = root == null ? Map.of() : root;
        }

        private Map<String, String> fieldMap(String... preferredKeys) {
            for (String preferredKey : preferredKeys) {
                Map<String, String> directMap = asStringMap(root.get(preferredKey));
                if (!directMap.isEmpty()) {
                    return directMap;
                }
            }

            Map<String, String> localeDrivenMap = new LinkedHashMap<>();
            for (Map.Entry<String, Object> entry : root.entrySet()) {
                if (!(entry.getValue() instanceof Map<?, ?> localePayload)) {
                    continue;
                }
                for (String preferredKey : preferredKeys) {
                    Object localizedValue = localePayload.get(preferredKey);
                    if (localizedValue == null) {
                        continue;
                    }
                    localeDrivenMap.put(entry.getKey(), String.valueOf(localizedValue));
                    break;
                }
            }
            return localeDrivenMap;
        }

        private Map<String, String> asStringMap(Object value) {
            if (!(value instanceof Map<?, ?> rawMap)) {
                return Map.of();
            }

            Map<String, String> result = new LinkedHashMap<>();
            for (Map.Entry<?, ?> entry : rawMap.entrySet()) {
                if (entry.getKey() == null || entry.getValue() == null) {
                    continue;
                }
                result.put(String.valueOf(entry.getKey()), String.valueOf(entry.getValue()));
            }
            return result;
        }
    }
}
