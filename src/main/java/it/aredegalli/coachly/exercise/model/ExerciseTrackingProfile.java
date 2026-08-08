package it.aredegalli.coachly.exercise.model;

import it.aredegalli.coachly.exercise.enums.ComparisonScope;
import it.aredegalli.coachly.exercise.enums.ConfidenceLevel;
import it.aredegalli.coachly.exercise.enums.EvidenceBasis;
import it.aredegalli.coachly.exercise.enums.LoadInputMode;
import it.aredegalli.coachly.exercise.enums.SideMode;
import it.aredegalli.coachly.exercise.enums.TrackingType;
import it.aredegalli.coachly.exercise.model.converter.ComparisonScopeConverter;
import it.aredegalli.coachly.exercise.model.converter.ConfidenceLevelConverter;
import it.aredegalli.coachly.exercise.model.converter.EvidenceBasisConverter;
import it.aredegalli.coachly.exercise.model.converter.LoadInputModeConverter;
import it.aredegalli.coachly.exercise.model.converter.SideModeConverter;
import it.aredegalli.coachly.exercise.model.converter.TrackingTypeConverter;
import jakarta.persistence.Column;
import jakarta.persistence.Convert;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.MapsId;
import jakarta.persistence.OneToOne;
import jakarta.persistence.Table;
import java.time.OffsetDateTime;
import java.util.UUID;

/**
 * How a set of this exercise is recorded, and how far the recorded load may be
 * compared.
 *
 * <p>Coachly convention: {@link LoadInputMode#PER_IMPLEMENT} means the logged
 * number is the load of a SINGLE implement, so a 32 kg dumbbell curl is logged
 * as 32, not 64.
 *
 * <p>{@link ComparisonScope} is what stops the progression assistant comparing
 * numbers that are not comparable: 50 kg on one selectorized machine is not
 * 50 kg on another, and 10 pull-ups at 70 kg bodyweight is not 10 at 85 kg.
 */
@Entity
@Table(name = "exercise_tracking_profile", schema = "exercises")
public class ExerciseTrackingProfile {

    @Id
    @Column(name = "exercise_id", nullable = false, updatable = false)
    private UUID exerciseId;

    @MapsId
    @OneToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "exercise_id", nullable = false)
    private Exercise exercise;

    @Convert(converter = TrackingTypeConverter.class)
    @Column(name = "tracking_type", nullable = false, columnDefinition = "exercises.tracking_type")
    private TrackingType trackingType;

    @Convert(converter = LoadInputModeConverter.class)
    @Column(name = "load_input_mode", nullable = false, columnDefinition = "exercises.load_input_mode")
    private LoadInputMode loadInputMode;

    @Convert(converter = SideModeConverter.class)
    @Column(name = "side_mode", nullable = false, columnDefinition = "exercises.side_mode")
    private SideMode sideMode;

    @Convert(converter = ComparisonScopeConverter.class)
    @Column(name = "comparison_scope", nullable = false, columnDefinition = "exercises.comparison_scope")
    private ComparisonScope comparisonScope;

    @Convert(converter = EvidenceBasisConverter.class)
    @Column(name = "evidence_basis", columnDefinition = "exercises.evidence_basis")
    private EvidenceBasis evidenceBasis;

    @Convert(converter = ConfidenceLevelConverter.class)
    @Column(name = "confidence", columnDefinition = "exercises.confidence_level")
    private ConfidenceLevel confidence;

    @Column(name = "created_at", nullable = false, updatable = false)
    private OffsetDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private OffsetDateTime updatedAt;

    public UUID getExerciseId() {
        return exerciseId;
    }

    public void setExerciseId(UUID exerciseId) {
        this.exerciseId = exerciseId;
    }

    public Exercise getExercise() {
        return exercise;
    }

    public void setExercise(Exercise exercise) {
        this.exercise = exercise;
    }

    public TrackingType getTrackingType() {
        return trackingType;
    }

    public void setTrackingType(TrackingType trackingType) {
        this.trackingType = trackingType;
    }

    public LoadInputMode getLoadInputMode() {
        return loadInputMode;
    }

    public void setLoadInputMode(LoadInputMode loadInputMode) {
        this.loadInputMode = loadInputMode;
    }

    public SideMode getSideMode() {
        return sideMode;
    }

    public void setSideMode(SideMode sideMode) {
        this.sideMode = sideMode;
    }

    public ComparisonScope getComparisonScope() {
        return comparisonScope;
    }

    public void setComparisonScope(ComparisonScope comparisonScope) {
        this.comparisonScope = comparisonScope;
    }

    public EvidenceBasis getEvidenceBasis() {
        return evidenceBasis;
    }

    public void setEvidenceBasis(EvidenceBasis evidenceBasis) {
        this.evidenceBasis = evidenceBasis;
    }

    public ConfidenceLevel getConfidence() {
        return confidence;
    }

    public void setConfidence(ConfidenceLevel confidence) {
        this.confidence = confidence;
    }

    public OffsetDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(OffsetDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public OffsetDateTime getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(OffsetDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }
}
