package it.aredegalli.coachly.exercise.mapper;

import it.aredegalli.coachly.exercise.dto.CategoryDto;
import it.aredegalli.coachly.exercise.model.Category;
import org.mapstruct.Mapper;
import org.mapstruct.ReportingPolicy;

@Mapper(componentModel = "spring", unmappedTargetPolicy = ReportingPolicy.IGNORE)
public interface CategoryMapper {

    CategoryDto toDto(Category entity);

    Category toEntity(CategoryDto dto);
}
