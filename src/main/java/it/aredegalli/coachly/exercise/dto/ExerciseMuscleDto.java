package it.aredegalli.coachly.exercise.dto;

import it.aredegalli.coachly.exercise.enums.InvolvementLevel;
import java.util.UUID;

public record ExerciseMuscleDto(
        UUID exerciseId,
        UUID muscleId,
        InvolvementLevel involvement,
        Integer activationPercentage
) {
}
