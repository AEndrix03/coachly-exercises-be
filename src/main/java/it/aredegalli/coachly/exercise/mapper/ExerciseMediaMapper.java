package it.aredegalli.coachly.exercise.mapper;

import it.aredegalli.coachly.exercise.dto.ExerciseMediaDto;
import it.aredegalli.coachly.exercise.model.Exercise;
import it.aredegalli.coachly.exercise.model.ExerciseMedia;
import java.util.UUID;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.ReportingPolicy;

@Mapper(componentModel = "spring", unmappedTargetPolicy = ReportingPolicy.IGNORE)
public interface ExerciseMediaMapper {

    @Mapping(target = "exerciseId", source = "exercise.id")
    ExerciseMediaDto toDto(ExerciseMedia entity);

    @Mapping(target = "exercise", expression = "java(exerciseFromId(dto.getExerciseId()))")
    ExerciseMedia toEntity(ExerciseMediaDto dto);

    default Exercise exerciseFromId(UUID id) {
        if (id == null) {
            return null;
        }
        Exercise exercise = new Exercise();
        exercise.setId(id);
        return exercise;
    }
}
