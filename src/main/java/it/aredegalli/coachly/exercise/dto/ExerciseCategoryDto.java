package it.aredegalli.coachly.exercise.dto;

import java.util.UUID;

public record ExerciseCategoryDto(
        UUID exerciseId,
        UUID categoryId,
        boolean primary
) {
}
