package it.aredegalli.coachly.exercise.dto;

import java.util.UUID;

public record CategoryDto(
        UUID id,
        String code,
        int displayOrder,
        String translations
) {
}
