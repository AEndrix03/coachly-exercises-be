package it.aredegalli.coachly.exercise.dto;

import java.util.UUID;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ExerciseVariationDto {
    private UUID baseExerciseId;
    private UUID variantExerciseId;
    private String variationType;
    private Integer difficultyDelta;
}
