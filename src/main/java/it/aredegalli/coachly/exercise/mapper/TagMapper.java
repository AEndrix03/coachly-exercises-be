package it.aredegalli.coachly.exercise.mapper;

import it.aredegalli.coachly.exercise.dto.TagDto;
import it.aredegalli.coachly.exercise.model.Tag;
import org.mapstruct.Mapper;
import org.mapstruct.ReportingPolicy;

@Mapper(componentModel = "spring", unmappedTargetPolicy = ReportingPolicy.IGNORE)
public interface TagMapper {

    TagDto toDto(Tag entity);

    Tag toEntity(TagDto dto);
}
