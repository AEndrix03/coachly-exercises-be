package it.aredegalli.coachly.exercise.repository;

import it.aredegalli.coachly.exercise.model.ExerciseJointAction;
import it.aredegalli.coachly.exercise.model.id.ExerciseJointActionId;
import java.util.Collection;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

public interface ExerciseJointActionRepository
        extends JpaRepository<ExerciseJointAction, ExerciseJointActionId> {

    /**
     * L'{@code order by} non e' estetico: senza, l'ordine delle righe dipende
     * dal piano scelto da Postgres, che cambia fra un batch di cinquecento
     * esercizi e uno singolo. Le liste finiscono nel JSON del dettaglio in
     * ordine diverso, e la proiezione del catalogo — che identifica il
     * contenuto con uno SHA — vedrebbe un cambiamento dove non c'e'.
     */
    @Query("""
        select link
        from ExerciseJointAction link
        join fetch link.jointAction
        where link.exercise.id in :exerciseIds
        order by link.exercise.id, link.jointAction.id
        """)
    List<ExerciseJointAction> findAllByExerciseIds(Collection<UUID> exerciseIds);
}
