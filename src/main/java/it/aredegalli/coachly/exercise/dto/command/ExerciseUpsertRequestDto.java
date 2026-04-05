package it.aredegalli.coachly.exercise.dto.command;

import jakarta.validation.constraints.NotEmpty;
import java.util.Map;

public class ExerciseUpsertRequestDto {

    @NotEmpty
    private Map<String, String> nameI18n;

    private Map<String, String> descriptionI18n;
    private Map<String, String> tipsI18n;
    private String difficultyLevel;
    private String mechanicsType;
    private String forceType;
    private Boolean isUnilateral;
    private Boolean isBodyweight;
    private Boolean spotterRequired;
    private String overallRiskLevel;

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

    public String getDifficultyLevel() {
        return difficultyLevel;
    }

    public void setDifficultyLevel(String difficultyLevel) {
        this.difficultyLevel = difficultyLevel;
    }

    public String getMechanicsType() {
        return mechanicsType;
    }

    public void setMechanicsType(String mechanicsType) {
        this.mechanicsType = mechanicsType;
    }

    public String getForceType() {
        return forceType;
    }

    public void setForceType(String forceType) {
        this.forceType = forceType;
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

    public Boolean getSpotterRequired() {
        return spotterRequired;
    }

    public void setSpotterRequired(Boolean spotterRequired) {
        this.spotterRequired = spotterRequired;
    }

    public String getOverallRiskLevel() {
        return overallRiskLevel;
    }

    public void setOverallRiskLevel(String overallRiskLevel) {
        this.overallRiskLevel = overallRiskLevel;
    }
}

