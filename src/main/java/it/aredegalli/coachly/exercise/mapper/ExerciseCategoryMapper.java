package it.aredegalli.coachly.exercise.mapper;

import it.aredegalli.coachly.exercise.dto.ExerciseCategoryDto;
import it.aredegalli.coachly.exercise.model.Category;
import it.aredegalli.coachly.exercise.model.Exercise;
import it.aredegalli.coachly.exercise.model.ExerciseCategory;
import it.aredegalli.coachly.exercise.model.id.ExerciseCategoryId;
import java.util.UUID;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.ReportingPolicy;

@Mapper(
        componentModel = "spring",
        unmappedTargetPolicy = ReportingPolicy.IGNORE,
        imports = {ExerciseCategoryId.class}
)
public interface ExerciseCategoryMapper {

    @Mapping(target = "exerciseId", source = "exercise.id")
    @Mapping(target = "categoryId", source = "category.id")
    ExerciseCategoryDto toDto(ExerciseCategory entity);

    @Mapping(target = "id", expression = "java(new ExerciseCategoryId(dto.getExerciseId(), dto.getCategoryId()))")
    @Mapping(target = "exercise", expression = "java(exerciseFromId(dto.getExerciseId()))")
    @Mapping(target = "category", expression = "java(categoryFromId(dto.getCategoryId()))")
    ExerciseCategory toEntity(ExerciseCategoryDto dto);

    default Exercise exerciseFromId(UUID id) {
        if (id == null) {
            return null;
        }
        Exercise exercise = new Exercise();
        exercise.setId(id);
        return exercise;
    }

    default Category categoryFromId(UUID id) {
        if (id == null) {
            return null;
        }
        Category category = new Category();
        category.setId(id);
        return category;
    }
}
