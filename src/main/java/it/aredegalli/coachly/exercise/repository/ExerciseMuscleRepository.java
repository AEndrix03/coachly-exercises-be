package it.aredegalli.coachly.exercise.repository;

import it.aredegalli.coachly.exercise.model.ExerciseMuscle;
import it.aredegalli.coachly.exercise.model.id.ExerciseMuscleId;
import java.util.Collection;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

public interface ExerciseMuscleRepository extends JpaRepository<ExerciseMuscle, ExerciseMuscleId> {
    /**
     * L'{@code order by} non e' estetico: senza, l'ordine delle righe dipende
     * dal piano scelto da Postgres, che cambia fra un batch di cinquecento
     * esercizi e uno singolo. Le liste finiscono nel JSON del dettaglio in
     * ordine diverso, e la proiezione del catalogo — che identifica il
     * contenuto con uno SHA — vedrebbe un cambiamento dove non c'e'.
     */
    @Query("""
        select exerciseMuscle
        from ExerciseMuscle exerciseMuscle
        join fetch exerciseMuscle.muscle
        where exerciseMuscle.exercise.id in :exerciseIds
        order by exerciseMuscle.exercise.id, exerciseMuscle.muscle.id, exerciseMuscle.id.involvement
        """)
    List<ExerciseMuscle> findAllByExerciseIds(Collection<UUID> exerciseIds);
}
