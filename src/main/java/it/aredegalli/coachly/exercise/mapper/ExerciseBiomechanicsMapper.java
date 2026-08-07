package it.aredegalli.coachly.exercise.mapper;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import it.aredegalli.coachly.exercise.dto.ExerciseBiomechanicsDto;
import it.aredegalli.coachly.exercise.dto.StrengthCurvePointDto;
import it.aredegalli.coachly.exercise.model.Exercise;
import it.aredegalli.coachly.exercise.model.ExerciseBiomechanics;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.ReportingPolicy;

@Mapper(
        componentModel = "spring",
        unmappedTargetPolicy = ReportingPolicy.IGNORE
)
public interface ExerciseBiomechanicsMapper {

    ObjectMapper JSON = new ObjectMapper();
    /** The stored jsonb uses snake_case keys while the DTO stays camelCase. */
    ObjectMapper SNAKE_JSON = new ObjectMapper()
            .setPropertyNamingStrategy(com.fasterxml.jackson.databind.PropertyNamingStrategies.SNAKE_CASE)
            .configure(com.fasterxml.jackson.databind.DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false);
    TypeReference<Map<String, String>> JOINT_BIAS_TYPE = new TypeReference<>() {};
    TypeReference<List<StrengthCurvePointDto>> CURVE_TYPE = new TypeReference<>() {};

    @Mapping(target = "exerciseId", source = "exerciseId")
    @Mapping(target = "jointPositionBias", expression = "java(readJointPositionBias(entity.getJointPositionBias()))")
    @Mapping(target = "strengthCurvePoints", expression = "java(readStrengthCurvePoints(entity.getStrengthCurvePoints()))")
    ExerciseBiomechanicsDto toDto(ExerciseBiomechanics entity);

    @Mapping(target = "exercise", expression = "java(exerciseFromId(dto.getExerciseId()))")
    @Mapping(target = "jointPositionBias", expression = "java(writeJson(dto.getJointPositionBias()))")
    @Mapping(target = "strengthCurvePoints", expression = "java(writeJson(dto.getStrengthCurvePoints()))")
    ExerciseBiomechanics toEntity(ExerciseBiomechanicsDto dto);

    default Exercise exerciseFromId(UUID id) {
        if (id == null) {
            return null;
        }
        Exercise exercise = new Exercise();
        exercise.setId(id);
        return exercise;
    }

    default Map<String, String> readJointPositionBias(String raw) {
        if (raw == null || raw.isBlank()) {
            return Map.of();
        }
        try {
            return JSON.readValue(raw, JOINT_BIAS_TYPE);
        } catch (Exception ex) {
            return Map.of();
        }
    }

    default List<StrengthCurvePointDto> readStrengthCurvePoints(String raw) {
        if (raw == null || raw.isBlank()) {
            return List.of();
        }
        try {
            return SNAKE_JSON.readValue(raw, CURVE_TYPE);
        } catch (Exception ex) {
            return List.of();
        }
    }

    default String writeJson(Object value) {
        if (value == null) {
            return null;
        }
        try {
            return SNAKE_JSON.writeValueAsString(value);
        } catch (Exception ex) {
            return null;
        }
    }
}
