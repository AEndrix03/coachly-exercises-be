package it.aredegalli.coachly.exercise.model.id;

import it.aredegalli.coachly.exercise.enums.InvolvementLevel;
import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import java.io.Serializable;
import java.util.Objects;
import java.util.UUID;

@Embeddable
public class ExerciseMuscleId implements Serializable {

    @Column(name = "exercise_id", nullable = false)
    private UUID exerciseId;

    @Column(name = "muscle_id", nullable = false)
    private UUID muscleId;

    @Enumerated(EnumType.STRING)
    @Column(name = "involvement", nullable = false, columnDefinition = "exercises.involvement_level")
    private InvolvementLevel involvement;

    public ExerciseMuscleId() {
    }

    public ExerciseMuscleId(UUID exerciseId, UUID muscleId, InvolvementLevel involvement) {
        this.exerciseId = exerciseId;
        this.muscleId = muscleId;
        this.involvement = involvement;
    }

    public UUID getExerciseId() {
        return exerciseId;
    }

    public void setExerciseId(UUID exerciseId) {
        this.exerciseId = exerciseId;
    }

    public UUID getMuscleId() {
        return muscleId;
    }

    public void setMuscleId(UUID muscleId) {
        this.muscleId = muscleId;
    }

    public InvolvementLevel getInvolvement() {
        return involvement;
    }

    public void setInvolvement(InvolvementLevel involvement) {
        this.involvement = involvement;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) {
            return true;
        }
        if (!(o instanceof ExerciseMuscleId that)) {
            return false;
        }
        return Objects.equals(exerciseId, that.exerciseId)
                && Objects.equals(muscleId, that.muscleId)
                && involvement == that.involvement;
    }

    @Override
    public int hashCode() {
        return Objects.hash(exerciseId, muscleId, involvement);
    }
}
