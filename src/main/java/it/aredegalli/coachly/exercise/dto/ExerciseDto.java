package it.aredegalli.coachly.exercise.dto;

import it.aredegalli.coachly.exercise.enums.DifficultyLevel;
import it.aredegalli.coachly.exercise.enums.ForceType;
import it.aredegalli.coachly.exercise.enums.MechanicsType;
import it.aredegalli.coachly.exercise.enums.RiskLevel;
import it.aredegalli.coachly.exercise.enums.Visibility;
import java.util.UUID;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ExerciseDto {
    private UUID id;
    private String name;
    private DifficultyLevel difficulty;
    private MechanicsType mechanics;
    private ForceType force;
    private boolean unilateral;
    private boolean bodyweight;
    private RiskLevel overallRisk;
    private boolean spotterRequired;
    private UUID ownerUserId;
    private Visibility visibility;
    private String translations;
}
