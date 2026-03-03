package it.aredegalli.coachly.exercise.dto;

import java.util.UUID;

public record ExerciseEquipmentDto(
        UUID exerciseId,
        UUID equipmentId,
        boolean required,
        boolean primary,
        int quantityNeeded
) {
}
