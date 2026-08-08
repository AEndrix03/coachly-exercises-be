package it.aredegalli.coachly.exercise.dto.command;

import jakarta.validation.constraints.NotEmpty;
import java.util.Map;

/**
 * What a user may set on a personal exercise. Classification fields the
 * catalogue derives (family, movement patterns, joint actions) are not exposed
 * here: a user-created exercise starts unclassified and is curated later.
 */
public class ExerciseUpsertRequestDto {

    @NotEmpty
    private Map<String, String> nameI18n;

    private Map<String, String> descriptionI18n;
    private Map<String, String> tipsI18n;
    private String exerciseKind;
    private String technicalDemand;
    private String jointClass;
    private Boolean isUnilateral;
    private Boolean isBodyweight;
    private String spotterPolicy;

    public Map<String, String> getNameI18n() {
        return nameI18n;
    }

    public void setNameI18n(Map<String, String> nameI18n) {
        this.nameI18n = nameI18n;
    }

    public Map<String, String> getDescriptionI18n() {
        return descriptionI18n;
    }

    public void setDescriptionI18n(Map<String, String> descriptionI18n) {
        this.descriptionI18n = descriptionI18n;
    }

    public Map<String, String> getTipsI18n() {
        return tipsI18n;
    }

    public void setTipsI18n(Map<String, String> tipsI18n) {
        this.tipsI18n = tipsI18n;
    }

    public String getExerciseKind() {
        return exerciseKind;
    }

    public void setExerciseKind(String exerciseKind) {
        this.exerciseKind = exerciseKind;
    }

    public String getTechnicalDemand() {
        return technicalDemand;
    }

    public void setTechnicalDemand(String technicalDemand) {
        this.technicalDemand = technicalDemand;
    }

    public String getJointClass() {
        return jointClass;
    }

    public void setJointClass(String jointClass) {
        this.jointClass = jointClass;
    }

    public Boolean getIsUnilateral() {
        return isUnilateral;
    }

    public void setIsUnilateral(Boolean unilateral) {
        isUnilateral = unilateral;
    }

    public Boolean getIsBodyweight() {
        return isBodyweight;
    }

    public void setIsBodyweight(Boolean bodyweight) {
        isBodyweight = bodyweight;
    }

    public String getSpotterPolicy() {
        return spotterPolicy;
    }

    public void setSpotterPolicy(String spotterPolicy) {
        this.spotterPolicy = spotterPolicy;
    }
}
