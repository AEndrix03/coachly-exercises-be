package it.aredegalli.coachly.exercise.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import it.aredegalli.coachly.exercise.dto.command.ExerciseUpsertRequestDto;
import it.aredegalli.coachly.exercise.dto.retrieve.ExerciseDetailDto;
import it.aredegalli.coachly.exercise.dto.retrieve.ExerciseFilterDto;
import it.aredegalli.coachly.exercise.dto.retrieve.ExerciseSummaryDto;
import it.aredegalli.coachly.exercise.enums.CatalogStatus;
import it.aredegalli.coachly.exercise.enums.ComparisonScope;
import it.aredegalli.coachly.exercise.enums.EquipmentClass;
import it.aredegalli.coachly.exercise.enums.ExerciseKind;
import it.aredegalli.coachly.exercise.enums.InvolvementLevel;
import it.aredegalli.coachly.exercise.enums.JointClass;
import it.aredegalli.coachly.exercise.enums.KineticChain;
import it.aredegalli.coachly.exercise.enums.LoadLevel;
import it.aredegalli.coachly.exercise.enums.RecordStatus;
import it.aredegalli.coachly.exercise.enums.SpotterPolicy;
import it.aredegalli.coachly.exercise.enums.TechnicalDemand;
import it.aredegalli.coachly.exercise.enums.TensionLevel;
import it.aredegalli.coachly.exercise.enums.TrackingType;
import it.aredegalli.coachly.exercise.enums.Visibility;
import it.aredegalli.coachly.exercise.model.Exercise;
import it.aredegalli.coachly.exercise.model.ExerciseBiomechanics;
import it.aredegalli.coachly.exercise.model.ExerciseCategory;
import it.aredegalli.coachly.exercise.model.ExerciseJointAction;
import it.aredegalli.coachly.exercise.model.ExerciseMovementPattern;
import it.aredegalli.coachly.exercise.model.ExerciseTrackingProfile;
import it.aredegalli.coachly.exercise.model.MuscleGroup;
import it.aredegalli.coachly.exercise.model.ExerciseEquipment;
import it.aredegalli.coachly.exercise.model.ExerciseMedia;
import it.aredegalli.coachly.exercise.model.ExerciseMuscle;
import it.aredegalli.coachly.exercise.model.ExerciseTag;
import it.aredegalli.coachly.exercise.model.ExerciseVariation;
import it.aredegalli.coachly.exercise.repository.ExerciseBiomechanicsRepository;
import it.aredegalli.coachly.exercise.repository.ExerciseAliasRepository;
import it.aredegalli.coachly.exercise.repository.ExerciseCategoryRepository;
import it.aredegalli.coachly.exercise.repository.ExerciseJointActionRepository;
import it.aredegalli.coachly.exercise.repository.ExerciseMovementPatternRepository;
import it.aredegalli.coachly.exercise.repository.ExerciseTrackingProfileRepository;
import it.aredegalli.coachly.exercise.repository.MuscleGroupMemberRepository;
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

    private static final String ACTIVE_STATUS = RecordStatus.ACTIVE.name().toLowerCase(Locale.ROOT);

    private final ExerciseRepository exerciseRepository;
    private final ExerciseAliasRepository exerciseAliasRepository;
    private final ExerciseBiomechanicsRepository exerciseBiomechanicsRepository;
    private final ExerciseTrackingProfileRepository exerciseTrackingProfileRepository;
    private final ExerciseMovementPatternRepository exerciseMovementPatternRepository;
    private final ExerciseJointActionRepository exerciseJointActionRepository;
    private final MuscleGroupMemberRepository muscleGroupMemberRepository;
    private final ExerciseCategoryRepository exerciseCategoryRepository;
    private final ExerciseEquipmentRepository exerciseEquipmentRepository;
    private final ExerciseMediaRepository exerciseMediaRepository;
    private final ExerciseMuscleRepository exerciseMuscleRepository;
    private final ExerciseTagRepository exerciseTagRepository;
    private final ExerciseVariationRepository exerciseVariationRepository;
    private final ExerciseRetrieveMapper exerciseRetrieveMapper;
    private final ObjectMapper objectMapper = new ObjectMapper();

    public ExerciseService(
        ExerciseRepository exerciseRepository,
        ExerciseAliasRepository exerciseAliasRepository,
        ExerciseBiomechanicsRepository exerciseBiomechanicsRepository,
        ExerciseTrackingProfileRepository exerciseTrackingProfileRepository,
        ExerciseMovementPatternRepository exerciseMovementPatternRepository,
        ExerciseJointActionRepository exerciseJointActionRepository,
        MuscleGroupMemberRepository muscleGroupMemberRepository,
        ExerciseCategoryRepository exerciseCategoryRepository,
        ExerciseEquipmentRepository exerciseEquipmentRepository,
        ExerciseMediaRepository exerciseMediaRepository,
        ExerciseMuscleRepository exerciseMuscleRepository,
        ExerciseTagRepository exerciseTagRepository,
        ExerciseVariationRepository exerciseVariationRepository,
        ExerciseRetrieveMapper exerciseRetrieveMapper
    ) {
        this.exerciseRepository = exerciseRepository;
        this.exerciseAliasRepository = exerciseAliasRepository;
        this.exerciseBiomechanicsRepository = exerciseBiomechanicsRepository;
        this.exerciseTrackingProfileRepository = exerciseTrackingProfileRepository;
        this.exerciseMovementPatternRepository = exerciseMovementPatternRepository;
        this.exerciseJointActionRepository = exerciseJointActionRepository;
        this.muscleGroupMemberRepository = muscleGroupMemberRepository;
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
        return exerciseRepository.findDefaultExercises(ACTIVE_STATUS).stream()
            .filter(this::isActive)
            .map(exerciseRetrieveMapper::toSummary)
            .toList();
    }

    /**
     * I dettagli pubblicabili nel catalogo, per un insieme di id.
     *
     * <p>Serve alla proiezione del canale a delta
     * ({@code CatalogProjectionService}): usa la stessa costruzione del
     * dettaglio servito da {@code /exercises/{id}/details}, perche' il payload
     * che il client scarica a delta e quello che leggerebbe a richiesta devono
     * essere lo stesso oggetto. Due costruzioni separate divergerebbero, e la
     * divergenza sarebbe invisibile fino al primo utente che vede due dati
     * diversi per lo stesso esercizio.
     *
     * <p>Un id che non compare nel risultato non e' pubblicabile: cancellato,
     * non attivo, oppure personale di un utente. Per il catalogo sono lo stesso
     * caso, ed e' il chiamante a decidere cosa farne.
     */
    @Transactional(readOnly = true)
    public List<ExerciseDetailDto> getPublishableDetails(List<UUID> exerciseIds) {
        if (exerciseIds == null || exerciseIds.isEmpty()) return List.of();

        List<Exercise> exercises = exerciseRepository.findAllById(exerciseIds).stream()
            .filter(this::isActive)
            .filter(exercise -> exercise.getOwnerUserId() == null)
            .toList();

        return exercises.isEmpty() ? List.of() : buildDetailDtos(exercises, true);
    }

    @Transactional(readOnly = true)
    public ExerciseDetailDto getExerciseDetails(UUID userId, UUID exerciseId) {
        Exercise exercise = exerciseRepository.findById(exerciseId)
            .filter(this::isActive)
            .filter(ex -> canAccessExercise(userId, ex))
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Exercise not found"));
        return buildDetailDtos(List.of(exercise), true).stream()
            .findFirst()
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Exercise not found"));
    }

    @Transactional(readOnly = true)
    public List<ExerciseSummaryDto> getMyExercises(UUID userId) {
        return exerciseRepository.findPersonalExercises(ACTIVE_STATUS, userId).stream()
            .map(exerciseRetrieveMapper::toSummary)
            .toList();
    }

    @Transactional
    public ExerciseDetailDto createPersonalExercise(UUID userId, ExerciseUpsertRequestDto request) {
        if (request.getId() != null) {
            var existing = exerciseRepository.findById(request.getId());
            if (existing.isPresent()) {
                ensureOwner(userId, existing.get());
                return getExerciseDetails(userId, existing.get().getId());
            }
        }
        Exercise exercise = new Exercise();
        exercise.setId(request.getId());
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
        return buildDetailDtos(exercises, true);
    }

    private List<ExerciseDetailDto> buildDetailDtos(List<Exercise> exercises, boolean includeVariants) {
        if (exercises.isEmpty()) {
            return List.of();
        }

        List<UUID> exerciseIds = exercises.stream().map(Exercise::getId).toList();
        List<ExerciseVariation> variations = includeVariants
            ? exerciseVariationRepository.findAllWithExercises()
            : List.of();
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
        Map<UUID, List<it.aredegalli.coachly.exercise.model.ExerciseAlias>> aliasesByExercise = groupByExerciseId(
            exerciseAliasRepository.findAllByExerciseIds(exerciseIds),
            relation -> relation.getExercise().getId()
        );
        Map<UUID, ExerciseBiomechanics> biomechanicsByExercise = exerciseBiomechanicsRepository
            .findAllByExerciseIds(exerciseIds).stream()
            .collect(Collectors.toMap(ExerciseBiomechanics::getExerciseId, Function.identity(), (first, ignored) -> first));
        Map<UUID, ExerciseTrackingProfile> trackingByExercise = exerciseTrackingProfileRepository
            .findAllByExerciseIds(exerciseIds).stream()
            .collect(Collectors.toMap(ExerciseTrackingProfile::getExerciseId, Function.identity(), (first, ignored) -> first));
        Map<UUID, List<ExerciseMovementPattern>> patternsByExercise = groupByExerciseId(
            exerciseMovementPatternRepository.findAllByExerciseIds(exerciseIds),
            relation -> relation.getExercise().getId()
        );
        Map<UUID, List<ExerciseJointAction>> jointActionsByExercise = groupByExerciseId(
            exerciseJointActionRepository.findAllByExerciseIds(exerciseIds),
            relation -> relation.getExercise().getId()
        );
        List<UUID> muscleIds = musclesByExercise.values().stream()
            .flatMap(List::stream)
            .map(relation -> relation.getMuscle().getId())
            .distinct()
            .toList();
        Map<UUID, List<MuscleGroup>> groupsByMuscleId = muscleIds.isEmpty()
            ? Map.of()
            : exerciseRetrieveMapper.groupsByMuscleId(
                muscleGroupMemberRepository.findAllByMuscleIds(muscleIds));

        return exercises.stream()
            .map(exercise -> exerciseRetrieveMapper.toDetail(
                exercise,
                variations,
                includeVariants,
                mediaByExercise.getOrDefault(exercise.getId(), List.of()),
                categoriesByExercise.getOrDefault(exercise.getId(), List.of()),
                musclesByExercise.getOrDefault(exercise.getId(), List.of()),
                equipmentsByExercise.getOrDefault(exercise.getId(), List.of()),
                tagsByExercise.getOrDefault(exercise.getId(), List.of()),
                biomechanicsByExercise.get(exercise.getId()),
                trackingByExercise.get(exercise.getId()),
                patternsByExercise.getOrDefault(exercise.getId(), List.of()),
                jointActionsByExercise.getOrDefault(exercise.getId(), List.of()),
                groupsByMuscleId,
                aliasesByExercise.getOrDefault(exercise.getId(), List.of())
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

        String name = nameI18n.values().stream().findFirst().orElseThrow();
        exercise.setName(name);
        if (exercise.getCode() == null || exercise.getCode().isBlank()) {
            exercise.setCode(personalCode(name));
        }
        exercise.setExerciseKind(Optional.ofNullable(parseEnum(ExerciseKind.class, request.getExerciseKind()))
            .orElse(ExerciseKind.RESISTANCE));
        exercise.setTechnicalDemand(Optional.ofNullable(parseEnum(TechnicalDemand.class, request.getTechnicalDemand()))
            .orElse(TechnicalDemand.MODERATE));
        exercise.setJointClass(Optional.ofNullable(parseEnum(JointClass.class, request.getJointClass()))
            .orElse(JointClass.MULTI_JOINT));
        exercise.setUnilateral(Boolean.TRUE.equals(request.getIsUnilateral()));
        exercise.setBodyweight(Boolean.TRUE.equals(request.getIsBodyweight()));
        exercise.setSpotterPolicy(Optional.ofNullable(parseEnum(SpotterPolicy.class, request.getSpotterPolicy()))
            .orElse(SpotterPolicy.NONE));
        // a user-created exercise has not been reviewed by anyone
        if (exercise.getCatalogStatus() == null) {
            exercise.setCatalogStatus(CatalogStatus.DRAFT);
        }

        Map<String, Object> translations = new HashMap<>();
        translations.put("nameI18n", nameI18n);
        translations.put("descriptionI18n", normalizeI18n(request.getDescriptionI18n()));
        translations.put("tipsI18n", normalizeI18n(request.getTipsI18n()));
        exercise.setTranslations(serializeJson(translations));
    }

    /**
     * Personal exercises still need the stable identity key, and it must not
     * collide with the curated catalogue, hence the prefix and the uuid tail.
     */
    private String personalCode(String name) {
        String slug = java.text.Normalizer.normalize(name, java.text.Normalizer.Form.NFD)
            .replaceAll("\\p{M}", "")
            .toLowerCase(Locale.ROOT)
            .replaceAll("[^a-z0-9]+", "_")
            .replaceAll("^_|_$", "");
        if (slug.isBlank()) {
            slug = "exercise";
        }
        return "personal_" + slug + "_" + UUID.randomUUID().toString().substring(0, 8);
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

    /**
     * Where the caller wants the target muscle loaded. A muscle qualifies when
     * the requested end of its range carries at least MODERATE tension.
     */
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
