package it.aredegalli.coachly.exercise.model.id;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import java.io.Serializable;
import java.util.Objects;
import java.util.UUID;

/**
 * A variation edge is identified by its two endpoints. variation_type used to
 * be part of this key, but it was 'default' on every row and the table never
 * had a real primary key to match; what differs between the two exercises is
 * now the variation_axis attribute, not part of their identity.
 */
@Embeddable
public class ExerciseVariationId implements Serializable {

    @Column(name = "base_exercise_id", nullable = false)
    private UUID baseExerciseId;

    @Column(name = "variant_exercise_id", nullable = false)
    private UUID variantExerciseId;

    public ExerciseVariationId() {
    }

    public ExerciseVariationId(UUID baseExerciseId, UUID variantExerciseId) {
        this.baseExerciseId = baseExerciseId;
        this.variantExerciseId = variantExerciseId;
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

    @Override
    public boolean equals(Object other) {
        if (this == other) {
            return true;
        }
        if (!(other instanceof ExerciseVariationId that)) {
            return false;
        }
        return Objects.equals(baseExerciseId, that.baseExerciseId)
            && Objects.equals(variantExerciseId, that.variantExerciseId);
    }

    @Override
    public int hashCode() {
        return Objects.hash(baseExerciseId, variantExerciseId);
    }
}
