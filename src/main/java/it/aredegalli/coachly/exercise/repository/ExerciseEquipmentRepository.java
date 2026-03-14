package it.aredegalli.coachly.exercise.repository;

import it.aredegalli.coachly.exercise.model.ExerciseEquipment;
import it.aredegalli.coachly.exercise.model.id.ExerciseEquipmentId;
import java.util.Collection;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

public interface ExerciseEquipmentRepository extends JpaRepository<ExerciseEquipment, ExerciseEquipmentId> {
    @Query("""
        select exerciseEquipment
        from ExerciseEquipment exerciseEquipment
        join fetch exerciseEquipment.equipment
        where exerciseEquipment.exercise.id in :exerciseIds
        """)
    List<ExerciseEquipment> findAllByExerciseIds(Collection<UUID> exerciseIds);
}
