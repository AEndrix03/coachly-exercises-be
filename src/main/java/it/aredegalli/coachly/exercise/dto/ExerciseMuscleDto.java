package it.aredegalli.coachly.exercise.dto;

import it.aredegalli.coachly.exercise.enums.InvolvementLevel;
import java.util.UUID;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ExerciseMuscleDto {
    private UUID exerciseId;
    private UUID muscleId;
    private InvolvementLevel involvement;
    private Integer activationPercentage;
}
