package it.aredegalli.coachly.exercise.repository;

import it.aredegalli.coachly.exercise.model.Equipment;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface EquipmentRepository extends JpaRepository<Equipment, UUID> {
}
