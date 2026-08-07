package it.aredegalli.coachly.exercise.model;

import it.aredegalli.coachly.exercise.enums.DataConfidence;
import it.aredegalli.coachly.exercise.enums.LoadLevel;
import it.aredegalli.coachly.exercise.enums.MomentArmProfile;
import it.aredegalli.coachly.exercise.enums.ResistanceCurve;
import it.aredegalli.coachly.exercise.enums.ResistanceSource;
import it.aredegalli.coachly.exercise.model.converter.DataConfidenceConverter;
import it.aredegalli.coachly.exercise.model.converter.LoadLevelConverter;
import it.aredegalli.coachly.exercise.model.converter.MomentArmProfileConverter;
import it.aredegalli.coachly.exercise.model.converter.ResistanceCurveConverter;
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
 * Biomechanical profile of an exercise: where the external load peaks along the
 * range of motion and what causes it.
 *
 * <p>{@code jointPositionBias} and {@code strengthCurvePoints} are stored as raw
 * jsonb strings, mirroring how {@link Exercise#getTranslations()} is handled;
 * parsing happens in the retrieve mapper.
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

    @Convert(converter = ResistanceCurveConverter.class)
    @Column(name = "resistance_curve", columnDefinition = "exercises.resistance_curve")
    private ResistanceCurve resistanceCurve;

    @Column(name = "peak_torque_rom_pct")
    private Short peakTorqueRomPct;

    @Convert(converter = MomentArmProfileConverter.class)
    @Column(name = "moment_arm_profile", columnDefinition = "exercises.moment_arm_profile")
    private MomentArmProfile momentArmProfile;

    @Column(name = "moment_arm_peak_rom_pct")
    private Short momentArmPeakRomPct;

    @Convert(converter = LoadLevelConverter.class)
    @Column(name = "stability_demand", columnDefinition = "exercises.load_level")
    private LoadLevel stabilityDemand;

    @Convert(converter = LoadLevelConverter.class)
    @Column(name = "axial_load", columnDefinition = "exercises.load_level")
    private LoadLevel axialLoad;

    @Column(name = "sfr_rating")
    private Short sfrRating;

    @Column(name = "joint_position_bias", columnDefinition = "jsonb")
    private String jointPositionBias;

    @Column(name = "strength_curve_points", columnDefinition = "jsonb")
    private String strengthCurvePoints;

    @Convert(converter = DataConfidenceConverter.class)
    @Column(name = "data_confidence", nullable = false, columnDefinition = "exercises.data_confidence")
    private DataConfidence dataConfidence;

    @Column(name = "source_note")
    private String sourceNote;

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

    public ResistanceCurve getResistanceCurve() {
        return resistanceCurve;
    }

    public void setResistanceCurve(ResistanceCurve resistanceCurve) {
        this.resistanceCurve = resistanceCurve;
    }

    public Short getPeakTorqueRomPct() {
        return peakTorqueRomPct;
    }

    public void setPeakTorqueRomPct(Short peakTorqueRomPct) {
        this.peakTorqueRomPct = peakTorqueRomPct;
    }

    public MomentArmProfile getMomentArmProfile() {
        return momentArmProfile;
    }

    public void setMomentArmProfile(MomentArmProfile momentArmProfile) {
        this.momentArmProfile = momentArmProfile;
    }

    public Short getMomentArmPeakRomPct() {
        return momentArmPeakRomPct;
    }

    public void setMomentArmPeakRomPct(Short momentArmPeakRomPct) {
        this.momentArmPeakRomPct = momentArmPeakRomPct;
    }

    public LoadLevel getStabilityDemand() {
        return stabilityDemand;
    }

    public void setStabilityDemand(LoadLevel stabilityDemand) {
        this.stabilityDemand = stabilityDemand;
    }

    public LoadLevel getAxialLoad() {
        return axialLoad;
    }

    public void setAxialLoad(LoadLevel axialLoad) {
        this.axialLoad = axialLoad;
    }

    public Short getSfrRating() {
        return sfrRating;
    }

    public void setSfrRating(Short sfrRating) {
        this.sfrRating = sfrRating;
    }

    public String getJointPositionBias() {
        return jointPositionBias;
    }

    public void setJointPositionBias(String jointPositionBias) {
        this.jointPositionBias = jointPositionBias;
    }

    public String getStrengthCurvePoints() {
        return strengthCurvePoints;
    }

    public void setStrengthCurvePoints(String strengthCurvePoints) {
        this.strengthCurvePoints = strengthCurvePoints;
    }

    public DataConfidence getDataConfidence() {
        return dataConfidence;
    }

    public void setDataConfidence(DataConfidence dataConfidence) {
        this.dataConfidence = dataConfidence;
    }

    public String getSourceNote() {
        return sourceNote;
    }

    public void setSourceNote(String sourceNote) {
        this.sourceNote = sourceNote;
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
