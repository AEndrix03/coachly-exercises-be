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
public class MuscleDto {
    private UUID id;
    private String code;
    private String groupCode;
    private String translations;
}
