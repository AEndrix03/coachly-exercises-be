package it.aredegalli.coachly.exercise.repository;

import it.aredegalli.coachly.exercise.model.ExerciseEquipment;
import it.aredegalli.coachly.exercise.model.id.ExerciseEquipmentId;
import java.util.Collection;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

public interface ExerciseEquipmentRepository extends JpaRepository<ExerciseEquipment, ExerciseEquipmentId> {
    /**
     * L'{@code order by} non e' estetico: senza, l'ordine delle righe dipende
     * dal piano scelto da Postgres, che cambia fra un batch di cinquecento
     * esercizi e uno singolo. Le liste finiscono nel JSON del dettaglio in
     * ordine diverso, e la proiezione del catalogo — che identifica il
     * contenuto con uno SHA — vedrebbe un cambiamento dove non c'e'.
     */
    @Query("""
        select exerciseEquipment
        from ExerciseEquipment exerciseEquipment
        join fetch exerciseEquipment.equipment
        where exerciseEquipment.exercise.id in :exerciseIds
        order by exerciseEquipment.exercise.id, exerciseEquipment.equipment.id
        """)
    List<ExerciseEquipment> findAllByExerciseIds(Collection<UUID> exerciseIds);
}
