package it.aredegalli.coachly.exercise.repository;

import it.aredegalli.coachly.exercise.model.Exercise;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ExerciseRepository extends JpaRepository<Exercise, UUID> {
}
