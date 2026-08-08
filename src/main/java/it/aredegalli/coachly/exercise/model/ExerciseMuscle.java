package it.aredegalli.coachly.exercise.model;

import it.aredegalli.coachly.exercise.enums.ConfidenceLevel;
import it.aredegalli.coachly.exercise.enums.EvidenceBasis;
import it.aredegalli.coachly.exercise.enums.TensionLevel;
import it.aredegalli.coachly.exercise.model.converter.ConfidenceLevelConverter;
import it.aredegalli.coachly.exercise.model.converter.EvidenceBasisConverter;
import it.aredegalli.coachly.exercise.model.converter.TensionLevelConverter;
import it.aredegalli.coachly.exercise.model.id.ExerciseMuscleId;
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

/**
 * What a muscle does in an exercise, and where along its own length it is
 * loaded.
 *
 * <p>The three tension levels replace the old numeric fields (activation
 * percentage, ROM percentages, tension-at-stretch): those implied a precision
 * that does not exist. A length bias - lengthened, mid-range or shortened
 * biased - is derivable from these three, so it is not stored.
 */
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

    @Convert(converter = TensionLevelConverter.class)
    @Column(name = "tension_lengthened", columnDefinition = "exercises.tension_level")
    private TensionLevel tensionLengthened;

    @Convert(converter = TensionLevelConverter.class)
    @Column(name = "tension_midrange", columnDefinition = "exercises.tension_level")
    private TensionLevel tensionMidrange;

    @Convert(converter = TensionLevelConverter.class)
    @Column(name = "tension_shortened", columnDefinition = "exercises.tension_level")
    private TensionLevel tensionShortened;

    /** Where the datum came from, kept separate from how sure we are of it. */
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

    public TensionLevel getTensionLengthened() {
        return tensionLengthened;
    }

    public void setTensionLengthened(TensionLevel tensionLengthened) {
        this.tensionLengthened = tensionLengthened;
    }

    public TensionLevel getTensionMidrange() {
        return tensionMidrange;
    }

    public void setTensionMidrange(TensionLevel tensionMidrange) {
        this.tensionMidrange = tensionMidrange;
    }

    public TensionLevel getTensionShortened() {
        return tensionShortened;
    }

    public void setTensionShortened(TensionLevel tensionShortened) {
        this.tensionShortened = tensionShortened;
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
