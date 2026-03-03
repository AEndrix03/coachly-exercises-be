package it.aredegalli.coachly.exercise.model;

import it.aredegalli.coachly.exercise.model.id.ExerciseMuscleId;
import jakarta.persistence.Column;
import jakarta.persistence.EmbeddedId;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.MapsId;
import jakarta.persistence.Table;
import java.time.OffsetDateTime;

@Entity
@Table(name = "exercise_muscle", schema = "exercises")
public class ExerciseMuscle {

    @EmbeddedId
    private ExerciseMuscleId id;

    @MapsId("exerciseId")
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "exercise_id", nullable = false)
    private Exercise exercise;

    @MapsId("muscleId")
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "muscle_id", nullable = false)
    private Muscle muscle;

    @Column(name = "activation_percentage")
    private Integer activationPercentage;

    @Column(name = "created_at", nullable = false, updatable = false)
    private OffsetDateTime createdAt;

    public ExerciseMuscleId getId() {
        return id;
    }

    public void setId(ExerciseMuscleId id) {
        this.id = id;
    }

    public Exercise getExercise() {
        return exercise;
    }

    public void setExercise(Exercise exercise) {
        this.exercise = exercise;
    }

    public Muscle getMuscle() {
        return muscle;
    }

    public void setMuscle(Muscle muscle) {
        this.muscle = muscle;
    }

    public Integer getActivationPercentage() {
        return activationPercentage;
    }

    public void setActivationPercentage(Integer activationPercentage) {
        this.activationPercentage = activationPercentage;
    }

    public OffsetDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(OffsetDateTime createdAt) {
        this.createdAt = createdAt;
    }
}
