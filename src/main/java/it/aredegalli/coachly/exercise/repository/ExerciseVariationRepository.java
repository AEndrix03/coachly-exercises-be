package it.aredegalli.coachly.exercise.repository;

import it.aredegalli.coachly.exercise.model.ExerciseVariation;
import it.aredegalli.coachly.exercise.model.id.ExerciseVariationId;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

public interface ExerciseVariationRepository extends JpaRepository<ExerciseVariation, ExerciseVariationId> {
    @Query("""
        select exerciseVariation
        from ExerciseVariation exerciseVariation
        join fetch exerciseVariation.baseExercise
        join fetch exerciseVariation.variantExercise
        """)
    List<ExerciseVariation> findAllWithExercises();
}
