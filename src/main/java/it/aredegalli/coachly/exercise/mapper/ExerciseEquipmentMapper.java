package it.aredegalli.coachly.exercise.mapper;

import it.aredegalli.coachly.exercise.dto.ExerciseEquipmentDto;
import it.aredegalli.coachly.exercise.model.Equipment;
import it.aredegalli.coachly.exercise.model.Exercise;
import it.aredegalli.coachly.exercise.model.ExerciseEquipment;
import it.aredegalli.coachly.exercise.model.id.ExerciseEquipmentId;
import java.util.UUID;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.ReportingPolicy;

@Mapper(componentModel = "spring", unmappedTargetPolicy = ReportingPolicy.IGNORE)
public interface ExerciseEquipmentMapper {

    @Mapping(target = "exerciseId", source = "exercise.id")
    @Mapping(target = "equipmentId", source = "equipment.id")
    ExerciseEquipmentDto toDto(ExerciseEquipment entity);

    @Mapping(target = "id", expression = "java(new ExerciseEquipmentId(dto.getExerciseId(), dto.getEquipmentId()))")
    @Mapping(target = "exercise", expression = "java(exerciseFromId(dto.getExerciseId()))")
    @Mapping(target = "equipment", expression = "java(equipmentFromId(dto.getEquipmentId()))")
    ExerciseEquipment toEntity(ExerciseEquipmentDto dto);

    default Exercise exerciseFromId(UUID id) {
        if (id == null) {
            return null;
        }
        Exercise exercise = new Exercise();
        exercise.setId(id);
        return exercise;
    }

    default Equipment equipmentFromId(UUID id) {
        if (id == null) {
            return null;
        }
        Equipment equipment = new Equipment();
        equipment.setId(id);
        return equipment;
    }
}
