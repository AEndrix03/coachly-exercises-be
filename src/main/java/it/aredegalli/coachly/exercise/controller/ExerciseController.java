package it.aredegalli.coachly.exercise.controller;

import it.aredegalli.coachly.exercise.dto.command.ExerciseUpsertRequestDto;
import it.aredegalli.coachly.exercise.dto.retrieve.ExerciseDetailDto;
import it.aredegalli.coachly.exercise.dto.retrieve.ExerciseFilterDto;
import it.aredegalli.coachly.exercise.dto.retrieve.ExerciseSummaryDto;
import it.aredegalli.coachly.exercise.service.ExerciseService;
import it.aredegalli.coachly.user.commons.services.AuditRetriever;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import java.util.Arrays;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/exercises")
public class ExerciseController {

    private final AuditRetriever auditRetriever;
    private final ExerciseService exerciseService;

    public ExerciseController(AuditRetriever auditRetriever, ExerciseService exerciseService) {
        this.auditRetriever = auditRetriever;
        this.exerciseService = exerciseService;
    }

    @GetMapping
    public List<ExerciseSummaryDto> getExercises() {
        return exerciseService.getExercises();
    }

    @GetMapping("/{exerciseId}/details")
    public ExerciseDetailDto getExerciseDetails(@PathVariable UUID exerciseId) {
        return exerciseService.getExerciseDetails(currentUserIdNullable(), exerciseId);
    }

    @GetMapping("/mine")
    public List<ExerciseSummaryDto> getMyExercises() {
        return exerciseService.getMyExercises(requireUserId());
    }

    @GetMapping("/filtered")
    public List<ExerciseDetailDto> getFilteredExercises(
        @RequestParam(required = false) String scope,
        @RequestParam(required = false) String textFilter,
        @RequestParam(required = false) String langFilter,
        @RequestParam(required = false) String exerciseKind,
        @RequestParam(required = false) String technicalDemand,
        @RequestParam(required = false) String jointClass,
        @RequestParam(required = false) String kineticChain,
        @RequestParam(required = false) Boolean isUnilateral,
        @RequestParam(required = false) Boolean isBodyweight,
        @RequestParam(required = false) String categoryIds,
        @RequestParam(required = false) String muscleIds,
        @RequestParam(required = false) String muscleGroupIds,
        @RequestParam(required = false) String movementPatternIds,
        @RequestParam(required = false) String jointActionIds,
        @RequestParam(required = false) String familyIds,
        @RequestParam(required = false) String tensionBias,
        @RequestParam(required = false) String equipmentIds,
        @RequestParam(required = false) String equipmentClasses,
        @RequestParam(required = false) String stabilityDemand,
        @RequestParam(required = false) String maxSpinalLoading,
        @RequestParam(required = false) String trackingTypes,
        @RequestParam(required = false) Integer offset,
        @RequestParam(required = false) Integer limit
    ) {
        ExerciseFilterDto filter = ExerciseFilterDto.builder()
            .textFilter(textFilter)
            .langFilter(langFilter)
            .exerciseKind(exerciseKind)
            .technicalDemand(technicalDemand)
            .jointClass(jointClass)
            .kineticChain(kineticChain)
            .isUnilateral(isUnilateral)
            .isBodyweight(isBodyweight)
            .categoryIds(splitCsv(categoryIds))
            .muscleIds(splitCsv(muscleIds))
            .muscleGroupIds(splitCsv(muscleGroupIds))
            .movementPatternIds(splitCsv(movementPatternIds))
            .jointActionIds(splitCsv(jointActionIds))
            .familyIds(splitCsv(familyIds))
            .tensionBias(tensionBias)
            .equipmentIds(splitCsv(equipmentIds))
            .equipmentClasses(splitCsv(equipmentClasses))
            .stabilityDemand(stabilityDemand)
            .maxSpinalLoading(maxSpinalLoading)
            .trackingTypes(splitCsv(trackingTypes))
            .build();
        return exerciseService.getFilteredExercises(currentUserIdNullable(), scope, filter, offset, limit);
    }

    @PostMapping
    public ExerciseDetailDto createPersonalExercise(@Valid @RequestBody ExerciseUpsertRequestDto request) {
        return exerciseService.createPersonalExercise(requireUserId(), request);
    }

    @PutMapping("/{exerciseId}")
    public ExerciseDetailDto updatePersonalExercise(@PathVariable UUID exerciseId, @Valid @RequestBody ExerciseUpsertRequestDto request) {
        return exerciseService.updatePersonalExercise(requireUserId(), exerciseId, request);
    }

    @DeleteMapping("/{exerciseId}")
    public void deletePersonalExercise(@PathVariable UUID exerciseId) {
        exerciseService.deletePersonalExercise(requireUserId(), exerciseId);
    }

    private List<String> splitCsv(String value) {
        if (value == null || value.isBlank()) {
            return List.of();
        }
        return Arrays.stream(value.split(","))
            .map(String::trim)
            .filter(token -> !token.isEmpty())
            .toList();
    }

    private UUID currentUserIdNullable() {
        return auditRetriever.retrieve().getUserId();
    }

    private UUID requireUserId() {
        UUID userId = currentUserIdNullable();
        if (userId == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Missing or invalid X-User-Id header");
        }
        return userId;
    }
}
