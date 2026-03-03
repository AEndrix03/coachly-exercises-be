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
public class ExerciseEquipmentDto {
    private UUID exerciseId;
    private UUID equipmentId;
    private boolean required;
    private boolean primary;
    private int quantityNeeded;
}
