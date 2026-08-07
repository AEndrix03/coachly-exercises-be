package it.aredegalli.coachly.exercise.model;

import it.aredegalli.coachly.exercise.enums.LengthBias;
import it.aredegalli.coachly.exercise.model.converter.LengthBiasConverter;
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

    /** Where peak tension lands relative to THIS muscle's own length. */
    @Convert(converter = LengthBiasConverter.class)
    @Column(name = "length_bias", columnDefinition = "exercises.length_bias")
    private LengthBias lengthBias;

    @Column(name = "rom_stretch_pct")
    private Short romStretchPct;

    @Column(name = "rom_contract_pct")
    private Short romContractPct;

    /**
     * Residual external load at maximum muscle length: distinguishes an
     * exercise that merely reaches the stretch from one that loads it.
     */
    @Column(name = "tension_at_stretch")
    private Short tensionAtStretch;

    @Column(name = "tension_at_contraction")
    private Short tensionAtContraction;

    @Column(name = "active_insufficiency", nullable = false)
    private boolean activeInsufficiency;

    @Column(name = "passive_insufficiency", nullable = false)
    private boolean passiveInsufficiency;

    @Column(name = "created_at", nullable = false, updatable = false)
    private OffsetDateTime createdAt;

    public LengthBias getLengthBias() {
        return lengthBias;
    }

    public void setLengthBias(LengthBias lengthBias) {
        this.lengthBias = lengthBias;
    }

    public Short getRomStretchPct() {
        return romStretchPct;
    }

    public void setRomStretchPct(Short romStretchPct) {
        this.romStretchPct = romStretchPct;
    }

    public Short getRomContractPct() {
        return romContractPct;
    }

    public void setRomContractPct(Short romContractPct) {
        this.romContractPct = romContractPct;
    }

    public Short getTensionAtStretch() {
        return tensionAtStretch;
    }

    public void setTensionAtStretch(Short tensionAtStretch) {
        this.tensionAtStretch = tensionAtStretch;
    }

    public Short getTensionAtContraction() {
        return tensionAtContraction;
    }

    public void setTensionAtContraction(Short tensionAtContraction) {
        this.tensionAtContraction = tensionAtContraction;
    }

    public boolean isActiveInsufficiency() {
        return activeInsufficiency;
    }

    public void setActiveInsufficiency(boolean activeInsufficiency) {
        this.activeInsufficiency = activeInsufficiency;
    }

    public boolean isPassiveInsufficiency() {
        return passiveInsufficiency;
    }

    public void setPassiveInsufficiency(boolean passiveInsufficiency) {
        this.passiveInsufficiency = passiveInsufficiency;
    }

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
