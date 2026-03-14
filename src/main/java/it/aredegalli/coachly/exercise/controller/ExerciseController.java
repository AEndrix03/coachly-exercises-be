package it.aredegalli.coachly.exercise.controller;

import it.aredegalli.coachly.exercise.dto.retrieve.ExerciseDetailDto;
import it.aredegalli.coachly.exercise.dto.retrieve.ExerciseFilterDto;
import it.aredegalli.coachly.exercise.dto.retrieve.ExerciseSummaryDto;
import it.aredegalli.coachly.exercise.service.ExerciseService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.Arrays;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/exercises")
public class ExerciseController {

    private final ExerciseService exerciseService;

    public ExerciseController(ExerciseService exerciseService) {
        this.exerciseService = exerciseService;
    }

    @GetMapping
    public List<ExerciseSummaryDto> getExercises() {
        return exerciseService.getExercises();
    }

    @GetMapping("/{exerciseId}/details")
    public ExerciseDetailDto getExerciseDetails(@PathVariable UUID exerciseId) {
        return exerciseService.getExerciseDetails(exerciseId);
    }

    @GetMapping("/filtered")
    public List<ExerciseDetailDto> getFilteredExercises(
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
        return exerciseService.getFilteredExercises(filter);
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
}
