package it.aredegalli.coachly.exercise.repository;

import it.aredegalli.coachly.exercise.model.ExerciseMuscle;
import it.aredegalli.coachly.exercise.model.id.ExerciseMuscleId;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ExerciseMuscleRepository extends JpaRepository<ExerciseMuscle, ExerciseMuscleId> {
}
