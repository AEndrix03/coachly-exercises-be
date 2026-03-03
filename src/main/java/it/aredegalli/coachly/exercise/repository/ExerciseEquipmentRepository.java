package it.aredegalli.coachly.exercise.repository;

import it.aredegalli.coachly.exercise.model.ExerciseEquipment;
import it.aredegalli.coachly.exercise.model.id.ExerciseEquipmentId;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ExerciseEquipmentRepository extends JpaRepository<ExerciseEquipment, ExerciseEquipmentId> {
}
