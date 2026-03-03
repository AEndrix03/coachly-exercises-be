package it.aredegalli.coachly.exercise.mapper;

import it.aredegalli.coachly.exercise.dto.EquipmentDto;
import it.aredegalli.coachly.exercise.model.Equipment;
import org.mapstruct.Mapper;
import org.mapstruct.ReportingPolicy;

@Mapper(componentModel = "spring", unmappedTargetPolicy = ReportingPolicy.IGNORE)
public interface EquipmentMapper {

    EquipmentDto toDto(Equipment entity);

    Equipment toEntity(EquipmentDto dto);
}
