package it.aredegalli.coachly.exercise.dto;

import java.util.UUID;

public record MuscleDto(
        UUID id,
        String code,
        String groupCode,
        String translations
) {
}
