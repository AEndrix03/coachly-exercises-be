package it.aredegalli.coachly.exercise.repository;

import it.aredegalli.coachly.exercise.model.ExerciseVariation;
import it.aredegalli.coachly.exercise.model.id.ExerciseVariationId;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

public interface ExerciseVariationRepository extends JpaRepository<ExerciseVariation, ExerciseVariationId> {
    /**
     * Ordine deterministico, per la stessa ragione delle altre tabelle ponte:
     * la proiezione del catalogo identifica il contenuto con uno SHA, e un
     * ordine che dipende dal piano di esecuzione lo farebbe cambiare senza che
     * sia cambiato niente.
     */
    @Query("""
        select exerciseVariation
        from ExerciseVariation exerciseVariation
        join fetch exerciseVariation.baseExercise
        join fetch exerciseVariation.variantExercise
        order by exerciseVariation.baseExercise.id, exerciseVariation.variantExercise.id
        """)
    List<ExerciseVariation> findAllWithExercises();
}
