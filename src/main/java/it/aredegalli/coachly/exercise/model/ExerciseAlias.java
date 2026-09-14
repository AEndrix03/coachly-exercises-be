package it.aredegalli.coachly.exercise.model;

import it.aredegalli.coachly.exercise.enums.AliasStatus;
import it.aredegalli.coachly.exercise.enums.AliasType;
import it.aredegalli.coachly.exercise.model.converter.AliasStatusConverter;
import it.aredegalli.coachly.exercise.model.converter.AliasTypeConverter;
import jakarta.persistence.Column;
import jakarta.persistence.Convert;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import java.util.UUID;

@Entity
@Table(name = "exercise_alias", schema = "exercises")
public class ExerciseAlias {
    @Id private UUID id;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "exercise_id", nullable = false)
    private Exercise exercise;
    @Column(nullable = false, length = 8) private String locale;
    @Column(nullable = false, length = 160) private String label;
    @Convert(converter = AliasTypeConverter.class)
    @Column(name = "alias_type", nullable = false, columnDefinition = "exercises.alias_type")
    private AliasType aliasType;
    @Column(nullable = false) private Integer weight;
    @Convert(converter = AliasStatusConverter.class)
    @Column(nullable = false, columnDefinition = "exercises.alias_status")
    private AliasStatus status;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "replaced_by_id")
    private ExerciseAlias replacedBy;

    public UUID getId() { return id; }
    public Exercise getExercise() { return exercise; }
    public String getLocale() { return locale; }
    public String getLabel() { return label; }
    public AliasType getAliasType() { return aliasType; }
    public Integer getWeight() { return weight; }
    public AliasStatus getStatus() { return status; }
    public ExerciseAlias getReplacedBy() { return replacedBy; }
}
