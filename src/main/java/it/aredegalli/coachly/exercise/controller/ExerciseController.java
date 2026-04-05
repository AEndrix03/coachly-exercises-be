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
    public List<ExerciseSummaryDto> getFilteredExercises(
        @RequestParam(required = false) String scope,
        @RequestParam(required = false) String textFilter,
        @RequestParam(required = false) String langFilter,
        @RequestParam(required = false) String difficultyLevel,
        @RequestParam(required = false) String mechanicsType,
        @RequestParam(required = false) String forceType,
        @RequestParam(required = false) Boolean isUnilateral,
        @RequestParam(required = false) Boolean isBodyweight,
        @RequestParam(required = false) String categoryIds,
        @RequestParam(required = false) String muscleIds
    ) {
        ExerciseFilterDto filter = ExerciseFilterDto.builder()
            .scope(scope)
            .textFilter(textFilter)
            .langFilter(langFilter)
            .difficultyLevel(difficultyLevel)
            .mechanicsType(mechanicsType)
            .forceType(forceType)
            .isUnilateral(isUnilateral)
            .isBodyweight(isBodyweight)
            .categoryIds(splitCsv(categoryIds))
            .muscleIds(splitCsv(muscleIds))
            .build();
        return exerciseService.getFilteredExercises(currentUserIdNullable(), filter);
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
