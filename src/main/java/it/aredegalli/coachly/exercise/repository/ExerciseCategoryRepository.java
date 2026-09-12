package it.aredegalli.coachly.exercise.repository;

import it.aredegalli.coachly.exercise.model.ExerciseCategory;
import it.aredegalli.coachly.exercise.model.id.ExerciseCategoryId;
import java.util.Collection;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

public interface ExerciseCategoryRepository extends JpaRepository<ExerciseCategory, ExerciseCategoryId> {
    /**
     * L'{@code order by} non e' estetico: senza, l'ordine delle righe dipende
     * dal piano scelto da Postgres, che cambia fra un batch di cinquecento
     * esercizi e uno singolo. Le liste finiscono nel JSON del dettaglio in
     * ordine diverso, e la proiezione del catalogo — che identifica il
     * contenuto con uno SHA — vedrebbe un cambiamento dove non c'e'.
     */
    @Query("""
        select exerciseCategory
        from ExerciseCategory exerciseCategory
        join fetch exerciseCategory.category
        where exerciseCategory.exercise.id in :exerciseIds
        order by exerciseCategory.exercise.id, exerciseCategory.category.id
        """)
    List<ExerciseCategory> findAllByExerciseIds(Collection<UUID> exerciseIds);
}
