package it.aredegalli.coachly.exercise.mapper;

import it.aredegalli.coachly.exercise.dto.ExerciseDto;
import it.aredegalli.coachly.exercise.model.Exercise;
import org.mapstruct.Mapper;
import org.mapstruct.ReportingPolicy;

@Mapper(componentModel = "spring", unmappedTargetPolicy = ReportingPolicy.IGNORE)
public interface ExerciseMapper {

    ExerciseDto toDto(Exercise entity);

    Exercise toEntity(ExerciseDto dto);
}
