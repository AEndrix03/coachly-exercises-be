package it.aredegalli.coachly.exercise.model;

import it.aredegalli.coachly.exercise.enums.ContributionRole;
import it.aredegalli.coachly.exercise.model.converter.ContributionRoleConverter;
import it.aredegalli.coachly.exercise.model.id.ExerciseMovementPatternId;
import jakarta.persistence.Column;
import jakarta.persistence.Convert;
import jakarta.persistence.EmbeddedId;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.MapsId;
import jakarta.persistence.Table;
import java.time.OffsetDateTime;

@Entity
@Table(name = "exercise_movement_pattern", schema = "exercises")
public class ExerciseMovementPattern {

    @EmbeddedId
    private ExerciseMovementPatternId id;

    @MapsId("exerciseId")
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "exercise_id", nullable = false)
    private Exercise exercise;

    @MapsId("movementPatternId")
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "movement_pattern_id", nullable = false)
    private MovementPattern movementPattern;

    @Convert(converter = ContributionRoleConverter.class)
    @Column(name = "role", nullable = false, columnDefinition = "exercises.contribution_role")
    private ContributionRole role;

    @Column(name = "created_at", nullable = false, updatable = false)
    private OffsetDateTime createdAt;

    public ExerciseMovementPatternId getId() {
        return id;
    }

    public void setId(ExerciseMovementPatternId id) {
        this.id = id;
    }

    public Exercise getExercise() {
        return exercise;
    }

    public void setExercise(Exercise exercise) {
        this.exercise = exercise;
    }

    public MovementPattern getMovementPattern() {
        return movementPattern;
    }

    public void setMovementPattern(MovementPattern movementPattern) {
        this.movementPattern = movementPattern;
    }

    public ContributionRole getRole() {
        return role;
    }

    public void setRole(ContributionRole role) {
        this.role = role;
    }

    public OffsetDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(OffsetDateTime createdAt) {
        this.createdAt = createdAt;
    }
}
