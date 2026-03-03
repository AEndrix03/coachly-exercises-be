package it.aredegalli.coachly.exercise.dto;

import java.util.UUID;

public record TagDto(
        UUID id,
        String code,
        String tagType,
        String translations
) {
}
