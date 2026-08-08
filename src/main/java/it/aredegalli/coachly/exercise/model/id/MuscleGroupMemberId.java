package it.aredegalli.coachly.exercise.model.id;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import java.io.Serializable;
import java.util.Objects;
import java.util.UUID;

@Embeddable
public class MuscleGroupMemberId implements Serializable {

    @Column(name = "group_id", nullable = false)
    private UUID groupId;

    @Column(name = "muscle_id", nullable = false)
    private UUID muscleId;

    public MuscleGroupMemberId() {
    }

    public MuscleGroupMemberId(UUID groupId, UUID muscleId) {
        this.groupId = groupId;
        this.muscleId = muscleId;
    }

    public UUID getGroupId() {
        return groupId;
    }

    public void setGroupId(UUID groupId) {
        this.groupId = groupId;
    }

    public UUID getMuscleId() {
        return muscleId;
    }

    public void setMuscleId(UUID muscleId) {
        this.muscleId = muscleId;
    }

    @Override
    public boolean equals(Object other) {
        if (this == other) {
            return true;
        }
        if (!(other instanceof MuscleGroupMemberId that)) {
            return false;
        }
        return Objects.equals(groupId, that.groupId) && Objects.equals(muscleId, that.muscleId);
    }

    @Override
    public int hashCode() {
        return Objects.hash(groupId, muscleId);
    }
}
