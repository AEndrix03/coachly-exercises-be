package it.aredegalli.coachly.exercise.model.id;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import java.io.Serializable;
import java.util.Objects;
import java.util.UUID;

@Embeddable
public class ExerciseMovementPatternId implements Serializable {

    @Column(name = "exercise_id", nullable = false)
    private UUID exerciseId;

    @Column(name = "movement_pattern_id", nullable = false)
    private UUID movementPatternId;

    public ExerciseMovementPatternId() {
    }

    public ExerciseMovementPatternId(UUID exerciseId, UUID movementPatternId) {
        this.exerciseId = exerciseId;
        this.movementPatternId = movementPatternId;
    }

    public UUID getExerciseId() {
        return exerciseId;
    }

    public void setExerciseId(UUID exerciseId) {
        this.exerciseId = exerciseId;
    }

    public UUID getMovementPatternId() {
        return movementPatternId;
    }

    public void setMovementPatternId(UUID movementPatternId) {
        this.movementPatternId = movementPatternId;
    }

    @Override
    public boolean equals(Object other) {
        if (this == other) {
            return true;
        }
        if (!(other instanceof ExerciseMovementPatternId that)) {
            return false;
        }
        return Objects.equals(exerciseId, that.exerciseId) && Objects.equals(movementPatternId, that.movementPatternId);
    }

    @Override
    public int hashCode() {
        return Objects.hash(exerciseId, movementPatternId);
    }
}
