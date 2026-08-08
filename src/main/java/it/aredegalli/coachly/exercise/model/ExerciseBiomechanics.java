package it.aredegalli.coachly.exercise.model;

import it.aredegalli.coachly.exercise.enums.ConfidenceLevel;
import it.aredegalli.coachly.exercise.enums.EvidenceBasis;
import it.aredegalli.coachly.exercise.enums.ExternalResistanceProfile;
import it.aredegalli.coachly.exercise.enums.LoadLevel;
import it.aredegalli.coachly.exercise.enums.ResistanceSource;
import it.aredegalli.coachly.exercise.model.converter.ConfidenceLevelConverter;
import it.aredegalli.coachly.exercise.model.converter.EvidenceBasisConverter;
import it.aredegalli.coachly.exercise.model.converter.ExternalResistanceProfileConverter;
import it.aredegalli.coachly.exercise.model.converter.LoadLevelConverter;
import it.aredegalli.coachly.exercise.model.converter.ResistanceSourceConverter;
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
 * How the exercise loads the body, reduced to what actually drives decisions.
 *
 * <p>The implement's resistance curve is deliberately NOT here: it is not the
 * same thing as the tension curve of each muscle, and the latter is what the
 * engine uses. That lives per-muscle on {@link ExerciseMuscle}. Nor is there an
 * SFR rating - stimulus-to-fatigue is contextual output, not a catalogue fact.
 */
@Entity
@Table(name = "exercise_biomechanics", schema = "exercises")
public class ExerciseBiomechanics {

    @Id
    @Column(name = "exercise_id", nullable = false, updatable = false)
    private UUID exerciseId;

    @MapsId
    @OneToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "exercise_id", nullable = false)
    private Exercise exercise;

    @Convert(converter = ResistanceSourceConverter.class)
    @Column(name = "resistance_source", columnDefinition = "exercises.resistance_source")
    private ResistanceSource resistanceSource;

    @Convert(converter = LoadLevelConverter.class)
    @Column(name = "stability_demand", columnDefinition = "exercises.load_level")
    private LoadLevel stabilityDemand;

    @Convert(converter = LoadLevelConverter.class)
    @Column(name = "spinal_loading", columnDefinition = "exercises.load_level")
    private LoadLevel spinalLoading;

    /** Coarse shape of the EXTERNAL resistance. Optional. */
    @Convert(converter = ExternalResistanceProfileConverter.class)
    @Column(name = "external_resistance_profile",
            columnDefinition = "exercises.external_resistance_profile")
    private ExternalResistanceProfile externalResistanceProfile;

    @Convert(converter = EvidenceBasisConverter.class)
    @Column(name = "evidence_basis", columnDefinition = "exercises.evidence_basis")
    private EvidenceBasis evidenceBasis;

    @Convert(converter = ConfidenceLevelConverter.class)
    @Column(name = "confidence", columnDefinition = "exercises.confidence_level")
    private ConfidenceLevel confidence;

    @Column(name = "method_note")
    private String methodNote;

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

    public ResistanceSource getResistanceSource() {
        return resistanceSource;
    }

    public void setResistanceSource(ResistanceSource resistanceSource) {
        this.resistanceSource = resistanceSource;
    }

    public LoadLevel getStabilityDemand() {
        return stabilityDemand;
    }

    public void setStabilityDemand(LoadLevel stabilityDemand) {
        this.stabilityDemand = stabilityDemand;
    }

    public LoadLevel getSpinalLoading() {
        return spinalLoading;
    }

    public void setSpinalLoading(LoadLevel spinalLoading) {
        this.spinalLoading = spinalLoading;
    }

    public ExternalResistanceProfile getExternalResistanceProfile() {
        return externalResistanceProfile;
    }

    public void setExternalResistanceProfile(ExternalResistanceProfile externalResistanceProfile) {
        this.externalResistanceProfile = externalResistanceProfile;
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

    public String getMethodNote() {
        return methodNote;
    }

    public void setMethodNote(String methodNote) {
        this.methodNote = methodNote;
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
