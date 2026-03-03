package it.aredegalli.coachly.exercise.mapper;

import it.aredegalli.coachly.exercise.dto.ExerciseVariationDto;
import it.aredegalli.coachly.exercise.model.Exercise;
import it.aredegalli.coachly.exercise.model.ExerciseVariation;
import it.aredegalli.coachly.exercise.model.id.ExerciseVariationId;
import java.util.UUID;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.ReportingPolicy;

@Mapper(componentModel = "spring", unmappedTargetPolicy = ReportingPolicy.IGNORE)
public interface ExerciseVariationMapper {

    @Mapping(target = "baseExerciseId", source = "baseExercise.id")
    @Mapping(target = "variantExerciseId", source = "variantExercise.id")
    @Mapping(target = "variationType", source = "id.variationType")
    ExerciseVariationDto toDto(ExerciseVariation entity);

    @Mapping(target = "id", expression = "java(new ExerciseVariationId(dto.getBaseExerciseId(), dto.getVariantExerciseId(), dto.getVariationType()))")
    @Mapping(target = "baseExercise", expression = "java(exerciseFromId(dto.getBaseExerciseId()))")
    @Mapping(target = "variantExercise", expression = "java(exerciseFromId(dto.getVariantExerciseId()))")
    ExerciseVariation toEntity(ExerciseVariationDto dto);

    default Exercise exerciseFromId(UUID id) {
        if (id == null) {
            return null;
        }
        Exercise exercise = new Exercise();
        exercise.setId(id);
        return exercise;
    }
}
