package it.aredegalli.coachly.exercise.mapper;

import it.aredegalli.coachly.exercise.dto.ExerciseTagDto;
import it.aredegalli.coachly.exercise.model.Exercise;
import it.aredegalli.coachly.exercise.model.ExerciseTag;
import it.aredegalli.coachly.exercise.model.Tag;
import it.aredegalli.coachly.exercise.model.id.ExerciseTagId;
import java.util.UUID;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.ReportingPolicy;

@Mapper(
        componentModel = "spring",
        unmappedTargetPolicy = ReportingPolicy.IGNORE,
        imports = {ExerciseTagId.class}
)
public interface ExerciseTagMapper {

    @Mapping(target = "exerciseId", source = "exercise.id")
    @Mapping(target = "tagId", source = "tag.id")
    ExerciseTagDto toDto(ExerciseTag entity);

    @Mapping(target = "id", expression = "java(new ExerciseTagId(dto.getExerciseId(), dto.getTagId()))")
    @Mapping(target = "exercise", expression = "java(exerciseFromId(dto.getExerciseId()))")
    @Mapping(target = "tag", expression = "java(tagFromId(dto.getTagId()))")
    ExerciseTag toEntity(ExerciseTagDto dto);

    default Exercise exerciseFromId(UUID id) {
        if (id == null) {
            return null;
        }
        Exercise exercise = new Exercise();
        exercise.setId(id);
        return exercise;
    }

    default Tag tagFromId(UUID id) {
        if (id == null) {
            return null;
        }
        Tag tag = new Tag();
        tag.setId(id);
        return tag;
    }
}
