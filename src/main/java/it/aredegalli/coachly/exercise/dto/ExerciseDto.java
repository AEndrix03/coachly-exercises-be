package it.aredegalli.coachly.exercise.dto;

import it.aredegalli.coachly.exercise.enums.DifficultyLevel;
import it.aredegalli.coachly.exercise.enums.ForceType;
import it.aredegalli.coachly.exercise.enums.MechanicsType;
import it.aredegalli.coachly.exercise.enums.RiskLevel;
import it.aredegalli.coachly.exercise.enums.Visibility;
import java.util.UUID;

public record ExerciseDto(
        UUID id,
        String name,
        DifficultyLevel difficulty,
        MechanicsType mechanics,
        ForceType force,
        boolean unilateral,
        boolean bodyweight,
        RiskLevel overallRisk,
        boolean spotterRequired,
        UUID ownerUserId,
        Visibility visibility,
        String translations
) {
}
