package it.aredegalli.coachly.exercise.dto;

import it.aredegalli.coachly.exercise.enums.MediaPurpose;
import it.aredegalli.coachly.exercise.enums.MediaType;
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
public class ExerciseMediaDto {
    private UUID id;
    private UUID exerciseId;
    private MediaType type;
    private MediaPurpose purpose;
    private String url;
    private String thumbnailUrl;
    private String viewAngle;
    private int displayOrder;
    private boolean primary;
    private Visibility visibility;
}
