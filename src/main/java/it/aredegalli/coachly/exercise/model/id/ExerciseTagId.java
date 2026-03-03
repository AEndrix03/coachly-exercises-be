package it.aredegalli.coachly.exercise.model.id;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import java.io.Serializable;
import java.util.Objects;
import java.util.UUID;

@Embeddable
public class ExerciseTagId implements Serializable {

    @Column(name = "exercise_id", nullable = false)
    private UUID exerciseId;

    @Column(name = "tag_id", nullable = false)
    private UUID tagId;

    public ExerciseTagId() {
    }

    public ExerciseTagId(UUID exerciseId, UUID tagId) {
        this.exerciseId = exerciseId;
        this.tagId = tagId;
    }

    public UUID getExerciseId() {
        return exerciseId;
    }

    public void setExerciseId(UUID exerciseId) {
        this.exerciseId = exerciseId;
    }

    public UUID getTagId() {
        return tagId;
    }

    public void setTagId(UUID tagId) {
        this.tagId = tagId;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) {
            return true;
        }
        if (!(o instanceof ExerciseTagId that)) {
            return false;
        }
        return Objects.equals(exerciseId, that.exerciseId)
                && Objects.equals(tagId, that.tagId);
    }

    @Override
    public int hashCode() {
        return Objects.hash(exerciseId, tagId);
    }
}
