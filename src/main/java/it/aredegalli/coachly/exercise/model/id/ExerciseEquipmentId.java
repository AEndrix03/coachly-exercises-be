package it.aredegalli.coachly.exercise.model.id;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import java.io.Serializable;
import java.util.Objects;
import java.util.UUID;

@Embeddable
public class ExerciseEquipmentId implements Serializable {

    @Column(name = "exercise_id", nullable = false)
    private UUID exerciseId;

    @Column(name = "equipment_id", nullable = false)
    private UUID equipmentId;

    public ExerciseEquipmentId() {
    }

    public ExerciseEquipmentId(UUID exerciseId, UUID equipmentId) {
        this.exerciseId = exerciseId;
        this.equipmentId = equipmentId;
    }

    public UUID getExerciseId() {
        return exerciseId;
    }

    public void setExerciseId(UUID exerciseId) {
        this.exerciseId = exerciseId;
    }

    public UUID getEquipmentId() {
        return equipmentId;
    }

    public void setEquipmentId(UUID equipmentId) {
        this.equipmentId = equipmentId;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) {
            return true;
        }
        if (!(o instanceof ExerciseEquipmentId that)) {
            return false;
        }
        return Objects.equals(exerciseId, that.exerciseId)
                && Objects.equals(equipmentId, that.equipmentId);
    }

    @Override
    public int hashCode() {
        return Objects.hash(exerciseId, equipmentId);
    }
}
