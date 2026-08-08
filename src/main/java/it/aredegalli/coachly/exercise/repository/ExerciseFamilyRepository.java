package it.aredegalli.coachly.exercise.repository;

import it.aredegalli.coachly.exercise.model.ExerciseFamily;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ExerciseFamilyRepository extends JpaRepository<ExerciseFamily, UUID> {
}
