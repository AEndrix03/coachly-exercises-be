package it.aredegalli.coachly.exercise.model;

import it.aredegalli.coachly.exercise.enums.MuscleGroupType;
import it.aredegalli.coachly.exercise.model.converter.MuscleGroupTypeConverter;
import jakarta.persistence.Column;
import jakarta.persistence.Convert;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.OffsetDateTime;
import java.util.UUID;

/**
 * Grouping taxonomy, moved out of generator code into the database so
 * "hamstrings" is not a hard-coded rule.
 */
@Entity
@Table(name = "muscle_group", schema = "exercises")
public class MuscleGroup {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", nullable = false, updatable = false)
    private UUID id;
    @Column(name = "code")
    private String code;
    @Convert(converter = MuscleGroupTypeConverter.class)
    @Column(name = "group_type")
    private MuscleGroupType groupType;
    @Column(name = "display_order")
    private Integer displayOrder;
    @Column(name = "translations", nullable = false, columnDefinition = "jsonb")
    private String translations;
    @Column(name = "created_at")
    private OffsetDateTime createdAt;
    @Column(name = "updated_at")
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

    public MuscleGroupType getGroupType() {
        return groupType;
    }

    public void setGroupType(MuscleGroupType groupType) {
        this.groupType = groupType;
    }

    public Integer getDisplayOrder() {
        return displayOrder;
    }

    public void setDisplayOrder(Integer displayOrder) {
        this.displayOrder = displayOrder;
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
