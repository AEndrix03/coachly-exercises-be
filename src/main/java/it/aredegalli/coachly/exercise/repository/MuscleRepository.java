package it.aredegalli.coachly.exercise.repository;

import it.aredegalli.coachly.exercise.model.Muscle;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface MuscleRepository extends JpaRepository<Muscle, UUID> {
}
