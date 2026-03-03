package it.aredegalli.coachly.exercise.mapper;

import it.aredegalli.coachly.exercise.dto.ExerciseMuscleDto;
import it.aredegalli.coachly.exercise.model.Exercise;
import it.aredegalli.coachly.exercise.model.ExerciseMuscle;
import it.aredegalli.coachly.exercise.model.Muscle;
import it.aredegalli.coachly.exercise.model.id.ExerciseMuscleId;
import java.util.UUID;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.ReportingPolicy;

@Mapper(componentModel = "spring", unmappedTargetPolicy = ReportingPolicy.IGNORE)
public interface ExerciseMuscleMapper {

    @Mapping(target = "exerciseId", source = "exercise.id")
    @Mapping(target = "muscleId", source = "muscle.id")
    @Mapping(target = "involvement", source = "id.involvement")
    ExerciseMuscleDto toDto(ExerciseMuscle entity);

    @Mapping(target = "id", expression = "java(new ExerciseMuscleId(dto.getExerciseId(), dto.getMuscleId(), dto.getInvolvement()))")
    @Mapping(target = "exercise", expression = "java(exerciseFromId(dto.getExerciseId()))")
    @Mapping(target = "muscle", expression = "java(muscleFromId(dto.getMuscleId()))")
    ExerciseMuscle toEntity(ExerciseMuscleDto dto);

    default Exercise exerciseFromId(UUID id) {
        if (id == null) {
            return null;
        }
        Exercise exercise = new Exercise();
        exercise.setId(id);
        return exercise;
    }

    default Muscle muscleFromId(UUID id) {
        if (id == null) {
            return null;
        }
        Muscle muscle = new Muscle();
        muscle.setId(id);
        return muscle;
    }
}
