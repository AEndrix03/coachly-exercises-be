package it.aredegalli.coachly.exercise.model;

import it.aredegalli.coachly.exercise.enums.CatalogStatus;
import it.aredegalli.coachly.exercise.enums.ExerciseKind;
import it.aredegalli.coachly.exercise.enums.JointClass;
import it.aredegalli.coachly.exercise.enums.RecordStatus;
import it.aredegalli.coachly.exercise.enums.SpotterPolicy;
import it.aredegalli.coachly.exercise.enums.TechnicalDemand;
import it.aredegalli.coachly.exercise.enums.Visibility;
import it.aredegalli.coachly.exercise.model.converter.CatalogStatusConverter;
import it.aredegalli.coachly.exercise.model.converter.ExerciseKindConverter;
import it.aredegalli.coachly.exercise.model.converter.JointClassConverter;
import it.aredegalli.coachly.exercise.model.converter.RecordStatusConverter;
import it.aredegalli.coachly.exercise.model.converter.SpotterPolicyConverter;
import it.aredegalli.coachly.exercise.model.converter.TechnicalDemandConverter;
import it.aredegalli.coachly.exercise.model.converter.VisibilityConverter;
import jakarta.persistence.Column;
import jakarta.persistence.Convert;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import java.time.OffsetDateTime;
import java.util.UUID;

/**
 * An exercise describes what a movement mechanically IS. Why it appears in a
 * session - strength, hypertrophy, technique - is a property of the program,
 * not of the catalogue, so no goal or quality score lives here.
 *
 * <p>{@code code} is the stable identity key; {@code name} is free to change.
 */
@Entity
@Table(name = "exercise", schema = "exercises")
public class Exercise {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", nullable = false, updatable = false)
    private UUID id;

    @Column(name = "code", nullable = false, length = 120)
    private String code;

    @Column(name = "name", nullable = false, length = 255)
    private String name;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "family_id")
    private ExerciseFamily family;

    @Convert(converter = ExerciseKindConverter.class)
    @Column(name = "exercise_kind", columnDefinition = "exercises.exercise_kind")
    private ExerciseKind exerciseKind;

    /** How hard the movement is to execute WELL, not how advanced the lifter is. */
    @Convert(converter = TechnicalDemandConverter.class)
    @Column(name = "technical_demand", columnDefinition = "exercises.technical_demand")
    private TechnicalDemand technicalDemand;

    @Convert(converter = JointClassConverter.class)
    @Column(name = "joint_class", columnDefinition = "exercises.joint_class")
    private JointClass jointClass;

    @Column(name = "unilateral", nullable = false)
    private boolean unilateral;

    @Column(name = "bodyweight", nullable = false)
    private boolean bodyweight;

    @Convert(converter = SpotterPolicyConverter.class)
    @Column(name = "spotter_policy", columnDefinition = "exercises.spotter_policy")
    private SpotterPolicy spotterPolicy;

    /** Editorial quality of the record, independent of who owns it. */
    @Convert(converter = CatalogStatusConverter.class)
    @Column(name = "catalog_status", nullable = false, columnDefinition = "exercises.catalog_status")
    private CatalogStatus catalogStatus;

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

    public String getCode() {
        return code;
    }

    public void setCode(String code) {
        this.code = code;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public ExerciseFamily getFamily() {
        return family;
    }

    public void setFamily(ExerciseFamily family) {
        this.family = family;
    }

    public ExerciseKind getExerciseKind() {
        return exerciseKind;
    }

    public void setExerciseKind(ExerciseKind exerciseKind) {
        this.exerciseKind = exerciseKind;
    }

    public TechnicalDemand getTechnicalDemand() {
        return technicalDemand;
    }

    public void setTechnicalDemand(TechnicalDemand technicalDemand) {
        this.technicalDemand = technicalDemand;
    }

    public JointClass getJointClass() {
        return jointClass;
    }

    public void setJointClass(JointClass jointClass) {
        this.jointClass = jointClass;
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

    public SpotterPolicy getSpotterPolicy() {
        return spotterPolicy;
    }

    public void setSpotterPolicy(SpotterPolicy spotterPolicy) {
        this.spotterPolicy = spotterPolicy;
    }

    public CatalogStatus getCatalogStatus() {
        return catalogStatus;
    }

    public void setCatalogStatus(CatalogStatus catalogStatus) {
        this.catalogStatus = catalogStatus;
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
