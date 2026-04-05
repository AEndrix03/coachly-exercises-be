package it.aredegalli.coachly.exercise.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import it.aredegalli.coachly.exercise.dto.command.ExerciseUpsertRequestDto;
import it.aredegalli.coachly.exercise.dto.retrieve.ExerciseDetailDto;
import it.aredegalli.coachly.exercise.dto.retrieve.ExerciseFilterDto;
import it.aredegalli.coachly.exercise.dto.retrieve.ExerciseSummaryDto;
import it.aredegalli.coachly.exercise.enums.DifficultyLevel;
import it.aredegalli.coachly.exercise.enums.ForceType;
import it.aredegalli.coachly.exercise.enums.MechanicsType;
import it.aredegalli.coachly.exercise.enums.RecordStatus;
import it.aredegalli.coachly.exercise.enums.RiskLevel;
import it.aredegalli.coachly.exercise.enums.Visibility;
import it.aredegalli.coachly.exercise.model.Exercise;
import it.aredegalli.coachly.exercise.model.ExerciseCategory;
import it.aredegalli.coachly.exercise.model.ExerciseEquipment;
import it.aredegalli.coachly.exercise.model.ExerciseMedia;
import it.aredegalli.coachly.exercise.model.ExerciseMuscle;
import it.aredegalli.coachly.exercise.model.ExerciseTag;
import it.aredegalli.coachly.exercise.model.ExerciseVariation;
import it.aredegalli.coachly.exercise.repository.ExerciseCategoryRepository;
import it.aredegalli.coachly.exercise.repository.ExerciseEquipmentRepository;
import it.aredegalli.coachly.exercise.repository.ExerciseMediaRepository;
import it.aredegalli.coachly.exercise.repository.ExerciseMuscleRepository;
import it.aredegalli.coachly.exercise.repository.ExerciseRepository;
import it.aredegalli.coachly.exercise.repository.ExerciseTagRepository;
import it.aredegalli.coachly.exercise.repository.ExerciseVariationRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.util.Collection;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.HashMap;
import java.util.Optional;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;

@Service
public class ExerciseService {

    private final ExerciseRepository exerciseRepository;
    private final ExerciseCategoryRepository exerciseCategoryRepository;
    private final ExerciseEquipmentRepository exerciseEquipmentRepository;
    private final ExerciseMediaRepository exerciseMediaRepository;
    private final ExerciseMuscleRepository exerciseMuscleRepository;
    private final ExerciseTagRepository exerciseTagRepository;
    private final ExerciseVariationRepository exerciseVariationRepository;
    private final ExerciseRetrieveMapper exerciseRetrieveMapper;
    private final ObjectMapper objectMapper;

    public ExerciseService(
        ExerciseRepository exerciseRepository,
        ExerciseCategoryRepository exerciseCategoryRepository,
        ExerciseEquipmentRepository exerciseEquipmentRepository,
        ExerciseMediaRepository exerciseMediaRepository,
        ExerciseMuscleRepository exerciseMuscleRepository,
        ExerciseTagRepository exerciseTagRepository,
        ExerciseVariationRepository exerciseVariationRepository,
        ExerciseRetrieveMapper exerciseRetrieveMapper,
        ObjectMapper objectMapper
    ) {
        this.exerciseRepository = exerciseRepository;
        this.exerciseCategoryRepository = exerciseCategoryRepository;
        this.exerciseEquipmentRepository = exerciseEquipmentRepository;
        this.exerciseMediaRepository = exerciseMediaRepository;
        this.exerciseMuscleRepository = exerciseMuscleRepository;
        this.exerciseTagRepository = exerciseTagRepository;
        this.exerciseVariationRepository = exerciseVariationRepository;
        this.exerciseRetrieveMapper = exerciseRetrieveMapper;
        this.objectMapper = objectMapper;
    }

    @Transactional(readOnly = true)
    public List<ExerciseSummaryDto> getExercises() {
        return exerciseRepository.findAllByStatusAndOwnerUserIdIsNullAndCreatedByUserIdIsNullOrderByNameAsc(RecordStatus.ACTIVE).stream()
            .filter(this::isActive)
            .map(exerciseRetrieveMapper::toSummary)
            .toList();
    }

    @Transactional(readOnly = true)
    public ExerciseDetailDto getExerciseDetails(UUID userId, UUID exerciseId) {
        Exercise exercise = exerciseRepository.findById(exerciseId)
            .filter(this::isActive)
            .filter(ex -> canAccessExercise(userId, ex))
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Exercise not found"));
        return buildDetailDtos(List.of(exercise)).stream()
            .findFirst()
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Exercise not found"));
    }

    @Transactional(readOnly = true)
    public List<ExerciseSummaryDto> getFilteredExercises(UUID userId, ExerciseFilterDto filter) {
        ExerciseScope scope = ExerciseScope.parse(filter.getScope());
        List<String> categoryTokens = safeTokens(filter.getCategoryIds());
        List<String> muscleTokens = safeTokens(filter.getMuscleIds());
        List<UUID> categoryIds = parseUuidTokens(categoryTokens);
        List<UUID> muscleIds = parseUuidTokens(muscleTokens);
        List<String> muscleTextTokens = parseTextTokens(muscleTokens);

        List<Exercise> exercises = findByScope(userId, scope).stream()
            .filter(this::isActive)
            .filter(exercise -> matchesDifficulty(exercise, filter.getDifficultyLevel()))
            .filter(exercise -> matchesMechanics(exercise, filter.getMechanicsType()))
            .filter(exercise -> matchesForce(exercise, filter.getForceType()))
            .filter(exercise -> matchesUnilateral(exercise, filter.getIsUnilateral()))
            .filter(exercise -> matchesBodyweight(exercise, filter.getIsBodyweight()))
            .toList();
        if (exercises.isEmpty()) {
            return List.of();
        }

        Map<UUID, List<ExerciseCategory>> categoriesByExercise = groupByExerciseId(
            exerciseCategoryRepository.findAllByExerciseIds(exercises.stream().map(Exercise::getId).toList()),
            relation -> relation.getExercise().getId()
        );
        Map<UUID, List<ExerciseMuscle>> musclesByExercise = groupByExerciseId(
            exerciseMuscleRepository.findAllByExerciseIds(exercises.stream().map(Exercise::getId).toList()),
            relation -> relation.getExercise().getId()
        );

        return exercises.stream()
            .filter(exercise -> matchesCategories(categoriesByExercise.getOrDefault(exercise.getId(), List.of()), categoryIds))
            .filter(exercise -> matchesMuscles(musclesByExercise.getOrDefault(exercise.getId(), List.of()), muscleIds))
            .filter(exercise -> exerciseRetrieveMapper.matchesText(exercise, filter.getTextFilter(), filter.getLangFilter()))
            .filter(exercise -> exerciseRetrieveMapper.matchesMuscles(musclesByExercise.getOrDefault(exercise.getId(), List.of()), muscleTextTokens))
            .map(exerciseRetrieveMapper::toSummary)
            .toList();
    }

    @Transactional(readOnly = true)
    public List<ExerciseSummaryDto> getMyExercises(UUID userId) {
        return exerciseRepository.findPersonalExercises(RecordStatus.ACTIVE, userId).stream()
            .map(exerciseRetrieveMapper::toSummary)
            .toList();
    }

    @Transactional
    public ExerciseDetailDto createPersonalExercise(UUID userId, ExerciseUpsertRequestDto request) {
        Exercise exercise = new Exercise();
        applyUpsert(exercise, request);
        exercise.setOwnerUserId(userId);
        exercise.setCreatedByUserId(userId);
        exercise.setVisibility(Visibility.PRIVATE);
        exercise.setStatus(RecordStatus.ACTIVE);
        exercise.setCreatedAt(java.time.OffsetDateTime.now());
        exercise.setUpdatedAt(java.time.OffsetDateTime.now());
        Exercise saved = exerciseRepository.save(exercise);
        return getExerciseDetails(userId, saved.getId());
    }

    @Transactional
    public ExerciseDetailDto updatePersonalExercise(UUID userId, UUID exerciseId, ExerciseUpsertRequestDto request) {
        Exercise exercise = exerciseRepository.findById(exerciseId)
            .filter(this::isActive)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Exercise not found"));
        ensureOwner(userId, exercise);
        applyUpsert(exercise, request);
        exercise.setUpdatedAt(java.time.OffsetDateTime.now());
        Exercise saved = exerciseRepository.save(exercise);
        return getExerciseDetails(userId, saved.getId());
    }

    @Transactional
    public void deletePersonalExercise(UUID userId, UUID exerciseId) {
        Exercise exercise = exerciseRepository.findById(exerciseId)
            .filter(this::isActive)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Exercise not found"));
        ensureOwner(userId, exercise);
        exercise.setStatus(RecordStatus.ARCHIVED);
        exercise.setDeletedAt(java.time.OffsetDateTime.now());
        exercise.setUpdatedAt(java.time.OffsetDateTime.now());
        exerciseRepository.save(exercise);
    }

    private List<ExerciseDetailDto> buildDetailDtos(List<Exercise> exercises) {
        if (exercises.isEmpty()) {
            return List.of();
        }

        List<UUID> exerciseIds = exercises.stream().map(Exercise::getId).toList();
        Map<UUID, List<ExerciseVariation>> variationsByExercise = groupByExerciseId(
            exerciseVariationRepository.findAllByBaseExerciseIds(exerciseIds),
            relation -> relation.getBaseExercise().getId()
        );
        Map<UUID, List<ExerciseMedia>> mediaByExercise = groupByExerciseId(
            exerciseMediaRepository.findAllByExercise_IdInOrderByDisplayOrderAsc(exerciseIds),
            relation -> relation.getExercise().getId()
        );
        Map<UUID, List<ExerciseCategory>> categoriesByExercise = groupByExerciseId(
            exerciseCategoryRepository.findAllByExerciseIds(exerciseIds),
            relation -> relation.getExercise().getId()
        );
        Map<UUID, List<ExerciseMuscle>> musclesByExercise = groupByExerciseId(
            exerciseMuscleRepository.findAllByExerciseIds(exerciseIds),
            relation -> relation.getExercise().getId()
        );
        Map<UUID, List<ExerciseEquipment>> equipmentsByExercise = groupByExerciseId(
            exerciseEquipmentRepository.findAllByExerciseIds(exerciseIds),
            relation -> relation.getExercise().getId()
        );
        Map<UUID, List<ExerciseTag>> tagsByExercise = groupByExerciseId(
            exerciseTagRepository.findAllByExerciseIds(exerciseIds),
            relation -> relation.getExercise().getId()
        );

        return exercises.stream()
            .map(exercise -> exerciseRetrieveMapper.toDetail(
                exercise,
                variationsByExercise.getOrDefault(exercise.getId(), List.of()),
                mediaByExercise.getOrDefault(exercise.getId(), List.of()),
                categoriesByExercise.getOrDefault(exercise.getId(), List.of()),
                musclesByExercise.getOrDefault(exercise.getId(), List.of()),
                equipmentsByExercise.getOrDefault(exercise.getId(), List.of()),
                tagsByExercise.getOrDefault(exercise.getId(), List.of())
            ))
            .toList();
    }

    private <T> Map<UUID, List<T>> groupByExerciseId(Collection<T> relations, Function<T, UUID> extractor) {
        if (relations.isEmpty()) {
            return Collections.emptyMap();
        }
        return relations.stream()
            .collect(Collectors.groupingBy(extractor, LinkedHashMap::new, Collectors.toList()));
    }

    private boolean isActive(Exercise exercise) {
        return exercise.getStatus() == RecordStatus.ACTIVE;
    }

    private List<Exercise> findByScope(UUID userId, ExerciseScope scope) {
        return switch (scope) {
            case DEFAULT -> exerciseRepository.findAllByStatusAndOwnerUserIdIsNullAndCreatedByUserIdIsNullOrderByNameAsc(RecordStatus.ACTIVE);
            case MINE -> {
                if (userId == null) {
                    throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Missing or invalid X-User-Id header");
                }
                yield exerciseRepository.findPersonalExercises(RecordStatus.ACTIVE, userId);
            }
            case COMMUNITY -> {
                if (userId == null) {
                    throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Missing or invalid X-User-Id header");
                }
                yield exerciseRepository.findCommunityExercises(RecordStatus.ACTIVE, userId);
            }
        };
    }

    private boolean canAccessExercise(UUID userId, Exercise exercise) {
        UUID owner = exercise.getEffectiveCreatedByUserId();
        return owner == null || (userId != null && owner.equals(userId));
    }

    private void ensureOwner(UUID userId, Exercise exercise) {
        UUID owner = exercise.getEffectiveCreatedByUserId();
        if (userId == null || owner == null || !owner.equals(userId)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Exercise is not editable by current user");
        }
    }

    private void applyUpsert(Exercise exercise, ExerciseUpsertRequestDto request) {
        Map<String, String> nameI18n = normalizeI18n(request.getNameI18n());
        if (nameI18n.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "nameI18n is required");
        }

        exercise.setName(nameI18n.values().stream().findFirst().orElseThrow());
        exercise.setDifficulty(Optional.ofNullable(parseEnum(DifficultyLevel.class, request.getDifficultyLevel())).orElse(DifficultyLevel.BEGINNER));
        exercise.setMechanics(Optional.ofNullable(parseEnum(MechanicsType.class, request.getMechanicsType())).orElse(MechanicsType.COMPOUND));
        exercise.setForce(parseEnum(ForceType.class, request.getForceType()));
        exercise.setUnilateral(Boolean.TRUE.equals(request.getIsUnilateral()));
        exercise.setBodyweight(Boolean.TRUE.equals(request.getIsBodyweight()));
        exercise.setSpotterRequired(Boolean.TRUE.equals(request.getSpotterRequired()));
        exercise.setOverallRisk(Optional.ofNullable(parseEnum(RiskLevel.class, request.getOverallRiskLevel())).orElse(RiskLevel.LOW));

        Map<String, Object> translations = new HashMap<>();
        translations.put("nameI18n", nameI18n);
        translations.put("descriptionI18n", normalizeI18n(request.getDescriptionI18n()));
        translations.put("tipsI18n", normalizeI18n(request.getTipsI18n()));
        exercise.setTranslations(serializeJson(translations));
    }

    private Map<String, String> normalizeI18n(Map<String, String> input) {
        if (input == null || input.isEmpty()) {
            return Map.of();
        }
        return input.entrySet().stream()
            .filter(e -> e.getKey() != null && !e.getKey().isBlank() && e.getValue() != null && !e.getValue().isBlank())
            .collect(Collectors.toMap(
                e -> e.getKey().trim().toLowerCase(Locale.ROOT),
                e -> e.getValue().trim(),
                (a, b) -> b,
                LinkedHashMap::new
            ));
    }

    private String serializeJson(Map<String, Object> input) {
        try {
            return objectMapper.writeValueAsString(input);
        } catch (JsonProcessingException ex) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "Failed to serialize exercise translations");
        }
    }

    private boolean matchesDifficulty(Exercise exercise, String difficultyLevel) {
        DifficultyLevel difficulty = parseEnum(DifficultyLevel.class, difficultyLevel);
        return difficulty == null || exercise.getDifficulty() == difficulty;
    }

    private boolean matchesMechanics(Exercise exercise, String mechanicsType) {
        MechanicsType mechanics = parseEnum(MechanicsType.class, mechanicsType);
        return mechanics == null || exercise.getMechanics() == mechanics;
    }

    private boolean matchesForce(Exercise exercise, String forceType) {
        ForceType force = parseEnum(ForceType.class, forceType);
        return force == null || exercise.getForce() == force;
    }

    private boolean matchesUnilateral(Exercise exercise, Boolean isUnilateral) {
        return isUnilateral == null || exercise.isUnilateral() == isUnilateral;
    }

    private boolean matchesBodyweight(Exercise exercise, Boolean isBodyweight) {
        return isBodyweight == null || exercise.isBodyweight() == isBodyweight;
    }

    private boolean matchesCategories(List<ExerciseCategory> categories, List<UUID> categoryIds) {
        if (categoryIds.isEmpty()) {
            return true;
        }
        return categories.stream()
            .map(relation -> relation.getCategory().getId())
            .anyMatch(categoryIds::contains);
    }

    private boolean matchesMuscles(List<ExerciseMuscle> muscles, List<UUID> muscleIds) {
        if (muscleIds.isEmpty()) {
            return true;
        }
        return muscles.stream()
            .map(relation -> relation.getMuscle().getId())
            .anyMatch(muscleIds::contains);
    }

    private List<String> safeTokens(List<String> rawTokens) {
        if (rawTokens == null) {
            return List.of();
        }
        return rawTokens.stream()
            .filter(token -> token != null && !token.isBlank())
            .map(String::trim)
            .toList();
    }

    private List<UUID> parseUuidTokens(List<String> tokens) {
        return tokens.stream()
            .map(this::tryParseUuid)
            .flatMap(Optional::stream)
            .toList();
    }

    private List<String> parseTextTokens(List<String> tokens) {
        return tokens.stream()
            .filter(token -> tryParseUuid(token).isEmpty())
            .toList();
    }

    private Optional<UUID> tryParseUuid(String token) {
        try {
            return Optional.of(UUID.fromString(token));
        } catch (IllegalArgumentException ex) {
            return Optional.empty();
        }
    }

    private <E extends Enum<E>> E parseEnum(Class<E> enumType, String rawValue) {
        if (rawValue == null || rawValue.isBlank()) {
            return null;
        }

        String normalizedValue = rawValue.trim()
            .replace('-', '_')
            .replace(' ', '_')
            .toUpperCase(Locale.ROOT);

        try {
            return Enum.valueOf(enumType, normalizedValue);
        } catch (IllegalArgumentException ex) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Invalid value for " + enumType.getSimpleName());
        }
    }
}
