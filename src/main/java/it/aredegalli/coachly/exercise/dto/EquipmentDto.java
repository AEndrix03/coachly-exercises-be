package it.aredegalli.coachly.exercise.dto;

import java.util.UUID;

public record EquipmentDto(
        UUID id,
        String code,
        String category,
        String translations
) {
}
