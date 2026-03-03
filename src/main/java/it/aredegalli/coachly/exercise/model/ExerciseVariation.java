package it.aredegalli.coachly.exercise.model;

import it.aredegalli.coachly.exercise.model.id.ExerciseVariationId;
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
@Table(name = "exercise_variation", schema = "exercises")
public class ExerciseVariation {

    @EmbeddedId
    private ExerciseVariationId id;

    @MapsId("baseExerciseId")
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "base_exercise_id", nullable = false)
    private Exercise baseExercise;

    @MapsId("variantExerciseId")
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "variant_exercise_id", nullable = false)
    private Exercise variantExercise;

    @Column(name = "difficulty_delta")
    private Integer difficultyDelta;

    @Column(name = "created_at", nullable = false, updatable = false)
    private OffsetDateTime createdAt;

    public ExerciseVariationId getId() {
        return id;
    }

    public void setId(ExerciseVariationId id) {
        this.id = id;
    }

    public Exercise getBaseExercise() {
        return baseExercise;
    }

    public void setBaseExercise(Exercise baseExercise) {
        this.baseExercise = baseExercise;
    }

    public Exercise getVariantExercise() {
        return variantExercise;
    }

    public void setVariantExercise(Exercise variantExercise) {
        this.variantExercise = variantExercise;
    }

    public Integer getDifficultyDelta() {
        return difficultyDelta;
    }

    public void setDifficultyDelta(Integer difficultyDelta) {
        this.difficultyDelta = difficultyDelta;
    }

    public OffsetDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(OffsetDateTime createdAt) {
        this.createdAt = createdAt;
    }
}
