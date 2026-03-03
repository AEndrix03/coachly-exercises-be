package it.aredegalli.coachly.exercise.dto;

import java.util.UUID;

public record ExerciseVariationDto(
        UUID baseExerciseId,
        UUID variantExerciseId,
        String variationType,
        Integer difficultyDelta
) {
}
