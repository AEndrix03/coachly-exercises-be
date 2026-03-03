package it.aredegalli.coachly.exercise.repository;

import it.aredegalli.coachly.exercise.model.ExerciseCategory;
import it.aredegalli.coachly.exercise.model.id.ExerciseCategoryId;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ExerciseCategoryRepository extends JpaRepository<ExerciseCategory, ExerciseCategoryId> {
}
