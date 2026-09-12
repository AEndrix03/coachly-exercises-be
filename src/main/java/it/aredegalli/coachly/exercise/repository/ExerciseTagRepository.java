package it.aredegalli.coachly.exercise.repository;

import it.aredegalli.coachly.exercise.model.ExerciseTag;
import it.aredegalli.coachly.exercise.model.id.ExerciseTagId;
import java.util.Collection;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

public interface ExerciseTagRepository extends JpaRepository<ExerciseTag, ExerciseTagId> {
    /**
     * Retired tags keep their links so the decision stays reversible, so the
     * archived ones have to be filtered out here rather than deleted.
     */
    /**
     * L'{@code order by} non e' estetico: senza, l'ordine delle righe dipende
     * dal piano scelto da Postgres, che cambia fra un batch di cinquecento
     * esercizi e uno singolo. Le liste finiscono nel JSON del dettaglio in
     * ordine diverso, e la proiezione del catalogo — che identifica il
     * contenuto con uno SHA — vedrebbe un cambiamento dove non c'e'.
     */
    @Query("""
        select exerciseTag
        from ExerciseTag exerciseTag
        join fetch exerciseTag.tag tag
        where exerciseTag.exercise.id in :exerciseIds
          and tag.deletedAt is null
        order by exerciseTag.exercise.id, tag.id
        """)
    List<ExerciseTag> findAllByExerciseIds(Collection<UUID> exerciseIds);
}
