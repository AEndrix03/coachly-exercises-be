package it.aredegalli.coachly.exercise.dto;

import it.aredegalli.coachly.exercise.enums.MediaPurpose;
import it.aredegalli.coachly.exercise.enums.MediaType;
import it.aredegalli.coachly.exercise.enums.Visibility;
import java.util.UUID;

public record ExerciseMediaDto(
        UUID id,
        UUID exerciseId,
        MediaType type,
        MediaPurpose purpose,
        String url,
        String thumbnailUrl,
        String viewAngle,
        int displayOrder,
        boolean primary,
        Visibility visibility
) {
}
