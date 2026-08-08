package it.aredegalli.coachly.exercise.model.id;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import java.io.Serializable;
import java.util.Objects;
import java.util.UUID;

@Embeddable
public class ExerciseJointActionId implements Serializable {

    @Column(name = "exercise_id", nullable = false)
    private UUID exerciseId;

    @Column(name = "joint_action_id", nullable = false)
    private UUID jointActionId;

    public ExerciseJointActionId() {
    }

    public ExerciseJointActionId(UUID exerciseId, UUID jointActionId) {
        this.exerciseId = exerciseId;
        this.jointActionId = jointActionId;
    }

    public UUID getExerciseId() {
        return exerciseId;
    }

    public void setExerciseId(UUID exerciseId) {
        this.exerciseId = exerciseId;
    }

    public UUID getJointActionId() {
        return jointActionId;
    }

    public void setJointActionId(UUID jointActionId) {
        this.jointActionId = jointActionId;
    }

    @Override
    public boolean equals(Object other) {
        if (this == other) {
            return true;
        }
        if (!(other instanceof ExerciseJointActionId that)) {
            return false;
        }
        return Objects.equals(exerciseId, that.exerciseId) && Objects.equals(jointActionId, that.jointActionId);
    }

    @Override
    public int hashCode() {
        return Objects.hash(exerciseId, jointActionId);
    }
}
