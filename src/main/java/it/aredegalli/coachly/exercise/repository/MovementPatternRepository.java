package it.aredegalli.coachly.exercise.repository;

import it.aredegalli.coachly.exercise.model.MovementPattern;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface MovementPatternRepository extends JpaRepository<MovementPattern, UUID> {
}
