package it.aredegalli.coachly.exercise.dto;

import java.util.UUID;

public record ExerciseTagDto(
        UUID exerciseId,
        UUID tagId
) {
}
