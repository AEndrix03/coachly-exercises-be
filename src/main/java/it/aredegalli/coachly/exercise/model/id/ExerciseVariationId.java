package it.aredegalli.coachly.exercise.model.id;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import java.io.Serializable;
import java.util.Objects;
import java.util.UUID;

@Embeddable
public class ExerciseVariationId implements Serializable {

    @Column(name = "base_exercise_id", nullable = false)
    private UUID baseExerciseId;

    @Column(name = "variant_exercise_id", nullable = false)
    private UUID variantExerciseId;

    @Column(name = "variation_type", nullable = false, length = 50)
    private String variationType;

    public ExerciseVariationId() {
    }

    public ExerciseVariationId(UUID baseExerciseId, UUID variantExerciseId, String variationType) {
        this.baseExerciseId = baseExerciseId;
        this.variantExerciseId = variantExerciseId;
        this.variationType = variationType;
    }

    public UUID getBaseExerciseId() {
        return baseExerciseId;
    }

    public void setBaseExerciseId(UUID baseExerciseId) {
        this.baseExerciseId = baseExerciseId;
    }

    public UUID getVariantExerciseId() {
        return variantExerciseId;
    }

    public void setVariantExerciseId(UUID variantExerciseId) {
        this.variantExerciseId = variantExerciseId;
    }

    public String getVariationType() {
        return variationType;
    }

    public void setVariationType(String variationType) {
        this.variationType = variationType;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) {
            return true;
        }
        if (!(o instanceof ExerciseVariationId that)) {
            return false;
        }
        return Objects.equals(baseExerciseId, that.baseExerciseId)
                && Objects.equals(variantExerciseId, that.variantExerciseId)
                && Objects.equals(variationType, that.variationType);
    }

    @Override
    public int hashCode() {
        return Objects.hash(baseExerciseId, variantExerciseId, variationType);
    }
}
