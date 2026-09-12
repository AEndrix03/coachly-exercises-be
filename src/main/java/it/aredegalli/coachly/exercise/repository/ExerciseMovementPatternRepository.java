package it.aredegalli.coachly.exercise.repository;

import it.aredegalli.coachly.exercise.model.ExerciseMovementPattern;
import it.aredegalli.coachly.exercise.model.id.ExerciseMovementPatternId;
import java.util.Collection;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

public interface ExerciseMovementPatternRepository
        extends JpaRepository<ExerciseMovementPattern, ExerciseMovementPatternId> {

    /**
     * L'{@code order by} non e' estetico: senza, l'ordine delle righe dipende
     * dal piano scelto da Postgres, che cambia fra un batch di cinquecento
     * esercizi e uno singolo. Le liste finiscono nel JSON del dettaglio in
     * ordine diverso, e la proiezione del catalogo — che identifica il
     * contenuto con uno SHA — vedrebbe un cambiamento dove non c'e'.
     */
    @Query("""
        select link
        from ExerciseMovementPattern link
        join fetch link.movementPattern
        where link.exercise.id in :exerciseIds
        order by link.exercise.id, link.movementPattern.id
        """)
    List<ExerciseMovementPattern> findAllByExerciseIds(Collection<UUID> exerciseIds);
}
