package it.aredegalli.coachly.exercise.model.id;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import java.io.Serializable;
import java.util.Objects;
import java.util.UUID;

@Embeddable
public class ExerciseCategoryId implements Serializable {

    @Column(name = "exercise_id", nullable = false)
    private UUID exerciseId;

    @Column(name = "category_id", nullable = false)
    private UUID categoryId;

    public ExerciseCategoryId() {
    }

    public ExerciseCategoryId(UUID exerciseId, UUID categoryId) {
        this.exerciseId = exerciseId;
        this.categoryId = categoryId;
    }

    public UUID getExerciseId() {
        return exerciseId;
    }

    public void setExerciseId(UUID exerciseId) {
        this.exerciseId = exerciseId;
    }

    public UUID getCategoryId() {
        return categoryId;
    }

    public void setCategoryId(UUID categoryId) {
        this.categoryId = categoryId;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) {
            return true;
        }
        if (!(o instanceof ExerciseCategoryId that)) {
            return false;
        }
        return Objects.equals(exerciseId, that.exerciseId)
                && Objects.equals(categoryId, that.categoryId);
    }

    @Override
    public int hashCode() {
        return Objects.hash(exerciseId, categoryId);
    }
}
