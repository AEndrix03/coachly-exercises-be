package it.aredegalli.coachly.exercise.service;

import it.aredegalli.coachly.exercise.dto.retrieve.ExerciseDetailDto;
import it.aredegalli.coachly.exercise.dto.retrieve.ExerciseFilterDto;
import it.aredegalli.coachly.exercise.dto.retrieve.ExerciseSummaryDto;
import it.aredegalli.coachly.exercise.enums.DifficultyLevel;
import it.aredegalli.coachly.exercise.enums.ForceType;
import it.aredegalli.coachly.exercise.enums.MechanicsType;
import it.aredegalli.coachly.exercise.enums.RecordStatus;
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

    public ExerciseService(
        ExerciseRepository exerciseRepository,
        ExerciseCategoryRepository exerciseCategoryRepository,
        ExerciseEquipmentRepository exerciseEquipmentRepository,
        ExerciseMediaRepository exerciseMediaRepository,
        ExerciseMuscleRepository exerciseMuscleRepository,
        ExerciseTagRepository exerciseTagRepository,
        ExerciseVariationRepository exerciseVariationRepository,
        ExerciseRetrieveMapper exerciseRetrieveMapper
    ) {
        this.exerciseRepository = exerciseRepository;
        this.exerciseCategoryRepository = exerciseCategoryRepository;
        this.exerciseEquipmentRepository = exerciseEquipmentRepository;
        this.exerciseMediaRepository = exerciseMediaRepository;
        this.exerciseMuscleRepository = exerciseMuscleRepository;
        this.exerciseTagRepository = exerciseTagRepository;
        this.exerciseVariationRepository = exerciseVariationRepository;
        this.exerciseRetrieveMapper = exerciseRetrieveMapper;
    }

    @Transactional(readOnly = true)
    public List<ExerciseSummaryDto> getExercises() {
        return exerciseRepository.findAllByStatusOrderByNameAsc(RecordStatus.ACTIVE).stream()
            .map(exerciseRetrieveMapper::toSummary)
            .toList();
    }

    @Transactional(readOnly = true)
    public ExerciseDetailDto getExerciseDetails(UUID exerciseId) {
        Exercise exercise = exerciseRepository.findByIdAndStatus(exerciseId, RecordStatus.ACTIVE)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Exercise not found"));
        return buildDetailDtos(List.of(exercise)).stream()
            .findFirst()
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Exercise not found"));
    }

    @Transactional(readOnly = true)
    public List<ExerciseSummaryDto> getFilteredExercises(ExerciseFilterDto filter) {
        List<String> categoryTokens = safeTokens(filter.getCategoryIds());
        List<String> muscleTokens = safeTokens(filter.getMuscleIds());
        List<UUID> categoryIds = parseUuidTokens(categoryTokens);
        List<UUID> muscleIds = parseUuidTokens(muscleTokens);
        List<String> muscleTextTokens = parseTextTokens(muscleTokens);

        List<Exercise> exercises = exerciseRepository.findAllByStatusOrderByNameAsc(RecordStatus.ACTIVE).stream()
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
