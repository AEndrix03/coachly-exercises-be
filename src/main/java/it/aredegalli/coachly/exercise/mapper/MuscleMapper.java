package it.aredegalli.coachly.exercise.mapper;

import it.aredegalli.coachly.exercise.dto.MuscleDto;
import it.aredegalli.coachly.exercise.model.Muscle;
import org.mapstruct.Mapper;
import org.mapstruct.ReportingPolicy;

@Mapper(componentModel = "spring", unmappedTargetPolicy = ReportingPolicy.IGNORE)
public interface MuscleMapper {

    MuscleDto toDto(Muscle entity);

    Muscle toEntity(MuscleDto dto);
}
