package it.aredegalli.coachly.exercise.mapper;

import it.aredegalli.coachly.exercise.dto.ExerciseTrackingProfileDto;
import it.aredegalli.coachly.exercise.model.Exercise;
import it.aredegalli.coachly.exercise.model.ExerciseTrackingProfile;
import java.util.UUID;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.ReportingPolicy;

@Mapper(
        componentModel = "spring",
        unmappedTargetPolicy = ReportingPolicy.IGNORE
)
public interface ExerciseTrackingProfileMapper {

    ExerciseTrackingProfileDto toDto(ExerciseTrackingProfile entity);

    @Mapping(target = "exercise", expression = "java(exerciseFromId(dto.getExerciseId()))")
    ExerciseTrackingProfile toEntity(ExerciseTrackingProfileDto dto);

    default Exercise exerciseFromId(UUID id) {
        if (id == null) {
            return null;
        }
        Exercise exercise = new Exercise();
        exercise.setId(id);
        return exercise;
    }
}
