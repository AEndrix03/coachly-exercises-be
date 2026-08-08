package it.aredegalli.coachly.exercise.service;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import it.aredegalli.coachly.exercise.dto.retrieve.ExerciseDetailDto;
import it.aredegalli.coachly.exercise.dto.retrieve.ExerciseSummaryDto;
import it.aredegalli.coachly.exercise.enums.TensionLevel;
import it.aredegalli.coachly.exercise.enums.Visibility;
import it.aredegalli.coachly.exercise.model.Category;
import it.aredegalli.coachly.exercise.model.Equipment;
import it.aredegalli.coachly.exercise.model.Exercise;
import it.aredegalli.coachly.exercise.model.ExerciseBiomechanics;
import it.aredegalli.coachly.exercise.model.ExerciseCategory;
import it.aredegalli.coachly.exercise.model.ExerciseEquipment;
import it.aredegalli.coachly.exercise.model.ExerciseFamily;
import it.aredegalli.coachly.exercise.model.ExerciseJointAction;
import it.aredegalli.coachly.exercise.model.ExerciseMedia;
import it.aredegalli.coachly.exercise.model.ExerciseMovementPattern;
import it.aredegalli.coachly.exercise.model.ExerciseMuscle;
import it.aredegalli.coachly.exercise.model.ExerciseTag;
import it.aredegalli.coachly.exercise.model.ExerciseTrackingProfile;
import it.aredegalli.coachly.exercise.model.ExerciseVariation;
import it.aredegalli.coachly.exercise.model.JointAction;
import it.aredegalli.coachly.exercise.model.MovementPattern;
import it.aredegalli.coachly.exercise.model.Muscle;
import it.aredegalli.coachly.exercise.model.MuscleGroup;
import it.aredegalli.coachly.exercise.model.MuscleGroupMember;
import it.aredegalli.coachly.exercise.model.Tag;
import org.springframework.stereotype.Component;

import java.text.Normalizer;
import java.util.Collection;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;

@Component
public class ExerciseRetrieveMapper {

    private static final TypeReference<Map<String, Object>> MAP_TYPE = new TypeReference<>() {};

    private final ObjectMapper objectMapper = new ObjectMapper();

    public ExerciseSummaryDto toSummary(Exercise exercise) {
        TranslationEnvelope translations = parseTranslations(exercise.getTranslations());
        return ExerciseSummaryDto.builder()
            .id(exercise.getId())
            .code(exercise.getCode())
            .nameI18n(translations.fieldMap("nameI18n", "name"))
            .descriptionI18n(translations.fieldMap("descriptionI18n", "description"))
            .tipsI18n(translations.fieldMap("tipsI18n", "tips", "executionTips"))
            .exerciseKind(enumValue(exercise.getExerciseKind()))
            .technicalDemand(enumValue(exercise.getTechnicalDemand()))
            .jointClass(enumValue(exercise.getJointClass()))
            .isUnilateral(exercise.isUnilateral())
            .isBodyweight(exercise.isBodyweight())
            .build();
    }

    public ExerciseDetailDto toDetail(
        Exercise exercise,
        List<ExerciseVariation> variations,
        boolean includeVariants,
        List<ExerciseMedia> media,
        List<ExerciseCategory> categories,
        List<ExerciseMuscle> muscles,
        List<ExerciseEquipment> equipments,
        List<ExerciseTag> tags,
        ExerciseBiomechanics biomechanics,
        ExerciseTrackingProfile tracking,
        List<ExerciseMovementPattern> movementPatterns,
        List<ExerciseJointAction> jointActions,
        Map<UUID, List<MuscleGroup>> groupsByMuscleId
    ) {
        TranslationEnvelope translations = parseTranslations(exercise.getTranslations());
        return ExerciseDetailDto.builder()
            .id(exercise.getId())
            .code(exercise.getCode())
            .nameI18n(translations.fieldMap("nameI18n", "name"))
            .descriptionI18n(translations.fieldMap("descriptionI18n", "description"))
            .tipsI18n(translations.fieldMap("tipsI18n", "tips", "executionTips"))
            .family(toFamily(exercise.getFamily()))
            .exerciseKind(enumValue(exercise.getExerciseKind()))
            .technicalDemand(enumValue(exercise.getTechnicalDemand()))
            .jointClass(enumValue(exercise.getJointClass()))
            .catalogStatus(enumValue(exercise.getCatalogStatus()))
            .isUnilateral(exercise.isUnilateral())
            .isBodyweight(exercise.isBodyweight())
            .movementProfile(ExerciseDetailDto.MovementProfileDto.builder()
                .patterns(movementPatterns.stream().map(this::toMovementPattern).toList())
                .jointActions(jointActions.stream().map(this::toJointAction).toList())
                .build())
            .muscles(muscles.stream().map(m -> toMuscle(m, groupsByMuscleId)).toList())
            .biomechanics(toBiomechanics(biomechanics))
            .tracking(toTracking(tracking))
            .safety(ExerciseDetailDto.SafetyDto.builder()
                .spotterPolicy(enumValue(exercise.getSpotterPolicy()))
                .notesI18n(translations.fieldMap("safetyNotesI18n", "safetyNotes", "safetyTips"))
                .build())
            .equipments(equipments.stream().map(this::toEquipment).toList())
            .variants(includeVariants ? toDirectVariants(exercise, variations) : List.of())
            .media(media.stream().map(this::toMedia).toList())
            .categories(categories.stream().map(this::toCategory).toList())
            .tags(tags.stream().map(this::toTag).toList())
            .build();
    }

    public boolean matchesText(Exercise exercise, String rawTextFilter, String rawLangFilter) {
        return rawTextFilter == null || rawTextFilter.isBlank()
            || searchScore(exercise, List.of(), rawTextFilter, rawLangFilter) > 0;
    }

    /**
     * Scores lexical matches across every translated name, description, tip and
     * muscle name. Name matches deliberately dominate; prefix and close-word
     * matches keep searches useful for partial terms and minor typos.
     */
    public int searchScore(
        Exercise exercise,
        List<ExerciseMuscle> muscles,
        String rawQuery,
        String rawLangFilter
    ) {
        if (rawQuery == null || rawQuery.isBlank()) {
            return 0;
        }

        TranslationEnvelope translations = parseTranslations(exercise.getTranslations());
        String query = normalize(rawQuery);
        List<String> languages = languageCandidates(rawLangFilter);
        int score = scoreI18n(translations.fieldMap("nameI18n", "name"), languages, query, 1000, 180);
        score += scoreI18n(translations.fieldMap("descriptionI18n", "description"), languages, query, 260, 45);
        score += scoreI18n(translations.fieldMap("tipsI18n", "tips", "executionTips"), languages, query, 120, 25);
        score += lexicalScore(exercise.getCode(), query, 400, 90);

        for (ExerciseMuscle relation : muscles) {
            if (relation.getMuscle() == null) {
                continue;
            }
            Muscle muscle = relation.getMuscle();
            TranslationEnvelope muscleTranslations = parseTranslations(muscle.getTranslations());
            score += scoreI18n(
                muscleTranslations.fieldMap("nameI18n", "name"), languages, query, 320, 70
            );
            score += lexicalScore(muscle.getCode(), query, 180, 40);
        }
        return score;
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

    /**
     * Only DIRECT variation edges. The old transitive walk implied that
     * "A is like B, B is like C" makes A like C, which is not true; real
     * similarity is computed from family, patterns, muscles and equipment.
     */
    private List<ExerciseDetailDto.VariantDto> toDirectVariants(
        Exercise sourceExercise,
        List<ExerciseVariation> variations
    ) {
        UUID sourceId = sourceExercise.getId();
        return variations.stream()
            .map(variation -> {
                if (sourceId.equals(variation.getBaseExercise().getId())) {
                    return Map.entry(variation.getVariantExercise(), variation);
                }
                if (sourceId.equals(variation.getVariantExercise().getId())) {
                    return Map.entry(variation.getBaseExercise(), variation);
                }
                return null;
            })
            .filter(java.util.Objects::nonNull)
            .sorted(Comparator.comparing(entry -> entry.getKey().getName(), String.CASE_INSENSITIVE_ORDER))
            .map(entry -> toVariant(entry.getKey(), entry.getValue()))
            .toList();
    }

    private ExerciseDetailDto.VariantDto toVariant(Exercise related, ExerciseVariation edge) {
        TranslationEnvelope translations = parseTranslations(related.getTranslations());
        return ExerciseDetailDto.VariantDto.builder()
            .id(related.getId())
            .code(related.getCode())
            .nameI18n(translations.fieldMap("nameI18n", "name"))
            .descriptionI18n(translations.fieldMap("descriptionI18n", "description"))
            .exerciseKind(enumValue(related.getExerciseKind()))
            .technicalDemand(enumValue(related.getTechnicalDemand()))
            .jointClass(enumValue(related.getJointClass()))
            .isUnilateral(related.isUnilateral())
            .isBodyweight(related.isBodyweight())
            .variationAxis(enumValue(edge.getVariationAxis()))
            .build();
    }

    private ExerciseDetailDto.FamilyDto toFamily(ExerciseFamily family) {
        if (family == null) {
            return null;
        }
        return ExerciseDetailDto.FamilyDto.builder()
            .id(family.getId())
            .code(family.getCode())
            .nameI18n(parseTranslations(family.getTranslations()).fieldMap("nameI18n", "name"))
            .build();
    }

    private ExerciseDetailDto.MovementPatternDto toMovementPattern(ExerciseMovementPattern link) {
        MovementPattern pattern = link.getMovementPattern();
        return ExerciseDetailDto.MovementPatternDto.builder()
            .id(pattern.getId())
            .code(pattern.getCode())
            .nameI18n(parseTranslations(pattern.getTranslations()).fieldMap("nameI18n", "name"))
            .role(enumValue(link.getRole()))
            .build();
    }

    private ExerciseDetailDto.JointActionDto toJointAction(ExerciseJointAction link) {
        JointAction action = link.getJointAction();
        return ExerciseDetailDto.JointActionDto.builder()
            .id(action.getId())
            .jointCode(action.getJointCode())
            .actionCode(action.getActionCode())
            .nameI18n(parseTranslations(action.getTranslations()).fieldMap("nameI18n", "name"))
            .role(enumValue(link.getRole()))
            .build();
    }

    private ExerciseDetailDto.MuscleAssociationDto toMuscle(
        ExerciseMuscle exerciseMuscle,
        Map<UUID, List<MuscleGroup>> groupsByMuscleId
    ) {
        Muscle muscle = exerciseMuscle.getMuscle();
        TranslationEnvelope translations = parseTranslations(muscle.getTranslations());
        List<MuscleGroup> groups = groupsByMuscleId.getOrDefault(muscle.getId(), List.of());
        return ExerciseDetailDto.MuscleAssociationDto.builder()
            .muscle(ExerciseDetailDto.NamedResourceDto.builder()
                .id(muscle.getId())
                .code(muscle.getCode())
                .nameI18n(translations.fieldMap("nameI18n", "name"))
                .descriptionI18n(translations.fieldMap("descriptionI18n", "description"))
                .build())
            .groups(groups.stream().map(this::toMuscleGroup).toList())
            .involvement(enumValue(exerciseMuscle.getId() == null ? null
                : exerciseMuscle.getId().getInvolvement()))
            .tensionProfile(toTensionProfile(exerciseMuscle))
            .evidenceBasis(enumValue(exerciseMuscle.getEvidenceBasis()))
            .confidence(enumValue(exerciseMuscle.getConfidence()))
            .build();
    }

    private ExerciseDetailDto.MuscleGroupDto toMuscleGroup(MuscleGroup group) {
        return ExerciseDetailDto.MuscleGroupDto.builder()
            .id(group.getId())
            .code(group.getCode())
            .groupType(enumValue(group.getGroupType()))
            .nameI18n(parseTranslations(group.getTranslations()).fieldMap("nameI18n", "name"))
            .build();
    }

    private ExerciseDetailDto.TensionProfileDto toTensionProfile(ExerciseMuscle exerciseMuscle) {
        TensionLevel lengthened = exerciseMuscle.getTensionLengthened();
        TensionLevel midrange = exerciseMuscle.getTensionMidrange();
        TensionLevel shortened = exerciseMuscle.getTensionShortened();
        if (lengthened == null && midrange == null && shortened == null) {
            return null;
        }
        return ExerciseDetailDto.TensionProfileDto.builder()
            .lengthened(enumValue(lengthened))
            .midrange(enumValue(midrange))
            .shortened(enumValue(shortened))
            .lengthBias(deriveLengthBias(lengthened, midrange, shortened))
            .build();
    }

    /**
     * Derived on read rather than stored, so the bias can never contradict the
     * three levels it comes from. "broad" means the exercise loads the muscle
     * evenly instead of favouring one end.
     */
    private String deriveLengthBias(TensionLevel lengthened, TensionLevel midrange, TensionLevel shortened) {
        int atLength = rank(lengthened);
        int atMid = rank(midrange);
        int atShort = rank(shortened);
        int peak = Math.max(atLength, Math.max(atMid, atShort));
        if (peak <= 0) {
            return null;
        }
        boolean lengthenedPeaks = atLength == peak;
        boolean shortenedPeaks = atShort == peak;
        if (lengthenedPeaks && shortenedPeaks) {
            return "broad";
        }
        if (lengthenedPeaks) {
            return "lengthened";
        }
        if (shortenedPeaks) {
            return "shortened";
        }
        return "mid_range";
    }

    private int rank(TensionLevel level) {
        return level == null ? -1 : level.ordinal();
    }

    private ExerciseDetailDto.BiomechanicsDto toBiomechanics(ExerciseBiomechanics biomechanics) {
        if (biomechanics == null) {
            return null;
        }
        return ExerciseDetailDto.BiomechanicsDto.builder()
            .resistanceSource(enumValue(biomechanics.getResistanceSource()))
            .stabilityDemand(enumValue(biomechanics.getStabilityDemand()))
            .spinalLoading(enumValue(biomechanics.getSpinalLoading()))
            .externalResistanceProfile(enumValue(biomechanics.getExternalResistanceProfile()))
            .evidenceBasis(enumValue(biomechanics.getEvidenceBasis()))
            .confidence(enumValue(biomechanics.getConfidence()))
            .build();
    }

    private ExerciseDetailDto.TrackingDto toTracking(ExerciseTrackingProfile tracking) {
        if (tracking == null) {
            return null;
        }
        return ExerciseDetailDto.TrackingDto.builder()
            .trackingType(enumValue(tracking.getTrackingType()))
            .loadInputMode(enumValue(tracking.getLoadInputMode()))
            .sideMode(enumValue(tracking.getSideMode()))
            .comparisonScope(enumValue(tracking.getComparisonScope()))
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

    private ExerciseDetailDto.CategoryDto toCategory(ExerciseCategory exerciseCategory) {
        Category category = exerciseCategory.getCategory();
        TranslationEnvelope translations = parseTranslations(category.getTranslations());
        return ExerciseDetailDto.CategoryDto.builder()
            .id(category.getId())
            .code(category.getCode())
            .nameI18n(translations.fieldMap("nameI18n", "name"))
            .descriptionI18n(translations.fieldMap("descriptionI18n", "description"))
            .isPrimary(exerciseCategory.isPrimary())
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
            .equipmentClass(enumValue(equipment.getEquipmentClass()))
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

    public Map<UUID, List<MuscleGroup>> groupsByMuscleId(List<MuscleGroupMember> members) {
        Map<UUID, List<MuscleGroup>> result = new LinkedHashMap<>();
        for (MuscleGroupMember member : members) {
            result.computeIfAbsent(member.getMuscle().getId(), key -> new java.util.ArrayList<>())
                .add(member.getGroup());
        }
        return result;
    }

    private int scoreI18n(
        Map<String, String> values,
        List<String> languageCandidates,
        String query,
        int phraseWeight,
        int tokenWeight
    ) {
        if (values == null || values.isEmpty()) {
            return 0;
        }
        int score = 0;
        for (Map.Entry<String, String> entry : values.entrySet()) {
            int languageBoost = languageCandidates.contains(normalize(entry.getKey())) ? 25 : 0;
            score = Math.max(score, lexicalScore(entry.getValue(), query, phraseWeight, tokenWeight) + languageBoost);
        }
        return score;
    }

    private int lexicalScore(String value, String query, int phraseWeight, int tokenWeight) {
        String candidate = normalize(value);
        if (candidate.isEmpty() || query.isEmpty()) {
            return 0;
        }
        if (candidate.equals(query)) {
            return phraseWeight;
        }
        int score = candidate.startsWith(query) ? (phraseWeight * 3) / 4
            : candidate.contains(query) ? phraseWeight / 2 : 0;
        for (String token : query.split("[^\\p{L}\\p{N}]+")) {
            if (token.length() < 2) {
                continue;
            }
            for (String word : candidate.split("[^\\p{L}\\p{N}]+")) {
                if (word.equals(token)) {
                    score += tokenWeight;
                } else if (word.startsWith(token) || token.startsWith(word)) {
                    score += (tokenWeight * 2) / 3;
                } else if (isSimilarWord(word, token)) {
                    score += tokenWeight / 2;
                }
            }
        }
        return score;
    }

    private boolean isSimilarWord(String candidate, String query) {
        if (candidate.length() < 4 || query.length() < 4) {
            return false;
        }
        int maxDistance = Math.max(1, Math.min(candidate.length(), query.length()) / 4);
        if (Math.abs(candidate.length() - query.length()) > maxDistance) {
            return false;
        }
        return levenshteinDistance(candidate, query) <= maxDistance;
    }

    private int levenshteinDistance(String left, String right) {
        int[] previous = new int[right.length() + 1];
        for (int j = 0; j <= right.length(); j++) previous[j] = j;
        for (int i = 1; i <= left.length(); i++) {
            int[] current = new int[right.length() + 1];
            current[0] = i;
            for (int j = 1; j <= right.length(); j++) {
                current[j] = Math.min(Math.min(current[j - 1], previous[j]), previous[j - 1]) +
                    (left.charAt(i - 1) == right.charAt(j - 1) ? 0 : 1);
            }
            previous = current;
        }
        return previous[right.length()];
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
        if (value == null) {
            return "";
        }
        return Normalizer.normalize(value, Normalizer.Form.NFD)
            .replaceAll("\\p{M}", "")
            .trim()
            .toLowerCase(Locale.ROOT)
            .replace('-', '_');
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
                    String text = localizedText(localizedValue);
                    if (!text.isBlank()) {
                        localeDrivenMap.put(entry.getKey(), text);
                    }
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
                String text = localizedText(entry.getValue());
                if (!text.isBlank()) {
                    result.put(String.valueOf(entry.getKey()), text);
                }
            }
            return result;
        }

        private String localizedText(Object value) {
            if (value instanceof Collection<?> collection) {
                return collection.stream()
                    .filter(item -> item != null && !String.valueOf(item).isBlank())
                    .map(item -> "• " + String.valueOf(item).trim())
                    .collect(java.util.stream.Collectors.joining("\n"));
            }
            return String.valueOf(value).trim();
        }
    }
}
