package it.aredegalli.coachly.exercise.repository;

import it.aredegalli.coachly.exercise.model.MuscleGroup;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface MuscleGroupRepository extends JpaRepository<MuscleGroup, UUID> {
}
