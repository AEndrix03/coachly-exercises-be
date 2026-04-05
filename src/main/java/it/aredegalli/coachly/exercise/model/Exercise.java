package it.aredegalli.coachly.exercise.model;

import it.aredegalli.coachly.exercise.enums.DifficultyLevel;
import it.aredegalli.coachly.exercise.enums.ForceType;
import it.aredegalli.coachly.exercise.enums.MechanicsType;
import it.aredegalli.coachly.exercise.enums.RecordStatus;
import it.aredegalli.coachly.exercise.enums.RiskLevel;
import it.aredegalli.coachly.exercise.enums.Visibility;
import it.aredegalli.coachly.exercise.model.converter.DifficultyLevelConverter;
import it.aredegalli.coachly.exercise.model.converter.ForceTypeConverter;
import it.aredegalli.coachly.exercise.model.converter.MechanicsTypeConverter;
import it.aredegalli.coachly.exercise.model.converter.RecordStatusConverter;
import it.aredegalli.coachly.exercise.model.converter.RiskLevelConverter;
import it.aredegalli.coachly.exercise.model.converter.VisibilityConverter;
import jakarta.persistence.Column;
import jakarta.persistence.Convert;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "exercise", schema = "exercises")
public class Exercise {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", nullable = false, updatable = false)
    private UUID id;

    @Column(name = "name", nullable = false, length = 255)
    private String name;

    @Convert(converter = DifficultyLevelConverter.class)
    @Column(name = "difficulty", nullable = false, columnDefinition = "exercises.difficulty_level")
    private DifficultyLevel difficulty;

    @Convert(converter = MechanicsTypeConverter.class)
    @Column(name = "mechanics", nullable = false, columnDefinition = "exercises.mechanics_type")
    private MechanicsType mechanics;

    @Convert(converter = ForceTypeConverter.class)
    @Column(name = "force", columnDefinition = "exercises.force_type")
    private ForceType force;

    @Column(name = "unilateral", nullable = false)
    private boolean unilateral;

    @Column(name = "bodyweight", nullable = false)
    private boolean bodyweight;

    @Convert(converter = RiskLevelConverter.class)
    @Column(name = "overall_risk", nullable = false, columnDefinition = "exercises.risk_level")
    private RiskLevel overallRisk;

    @Column(name = "spotter_required", nullable = false)
    private boolean spotterRequired;

    @Column(name = "owner_user_id")
    private UUID ownerUserId;

    @Column(name = "created_by")
    private UUID createdByUserId;

    @Convert(converter = VisibilityConverter.class)
    @Column(name = "visibility", nullable = false, columnDefinition = "exercises.visibility")
    private Visibility visibility;

    @Convert(converter = RecordStatusConverter.class)
    @Column(name = "status", nullable = false, columnDefinition = "exercises.record_status")
    private RecordStatus status;

    @Column(name = "deleted_at")
    private OffsetDateTime deletedAt;

    @Column(name = "translations", nullable = false, columnDefinition = "jsonb")
    private String translations;

    @Column(name = "created_at", nullable = false, updatable = false)
    private OffsetDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private OffsetDateTime updatedAt;

    public UUID getId() {
        return id;
    }

    public void setId(UUID id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public DifficultyLevel getDifficulty() {
        return difficulty;
    }

    public void setDifficulty(DifficultyLevel difficulty) {
        this.difficulty = difficulty;
    }

    public MechanicsType getMechanics() {
        return mechanics;
    }

    public void setMechanics(MechanicsType mechanics) {
        this.mechanics = mechanics;
    }

    public ForceType getForce() {
        return force;
    }

    public void setForce(ForceType force) {
        this.force = force;
    }

    public boolean isUnilateral() {
        return unilateral;
    }

    public void setUnilateral(boolean unilateral) {
        this.unilateral = unilateral;
    }

    public boolean isBodyweight() {
        return bodyweight;
    }

    public void setBodyweight(boolean bodyweight) {
        this.bodyweight = bodyweight;
    }

    public RiskLevel getOverallRisk() {
        return overallRisk;
    }

    public void setOverallRisk(RiskLevel overallRisk) {
        this.overallRisk = overallRisk;
    }

    public boolean isSpotterRequired() {
        return spotterRequired;
    }

    public void setSpotterRequired(boolean spotterRequired) {
        this.spotterRequired = spotterRequired;
    }

    public UUID getOwnerUserId() {
        return ownerUserId;
    }

    public void setOwnerUserId(UUID ownerUserId) {
        this.ownerUserId = ownerUserId;
    }

    public UUID getCreatedByUserId() {
        return createdByUserId;
    }

    public void setCreatedByUserId(UUID createdByUserId) {
        this.createdByUserId = createdByUserId;
    }

    public UUID getEffectiveCreatedByUserId() {
        return createdByUserId != null ? createdByUserId : ownerUserId;
    }

    public Visibility getVisibility() {
        return visibility;
    }

    public void setVisibility(Visibility visibility) {
        this.visibility = visibility;
    }

    public RecordStatus getStatus() {
        return status;
    }

    public void setStatus(RecordStatus status) {
        this.status = status;
    }

    public OffsetDateTime getDeletedAt() {
        return deletedAt;
    }

    public void setDeletedAt(OffsetDateTime deletedAt) {
        this.deletedAt = deletedAt;
    }

    public String getTranslations() {
        return translations;
    }

    public void setTranslations(String translations) {
        this.translations = translations;
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
