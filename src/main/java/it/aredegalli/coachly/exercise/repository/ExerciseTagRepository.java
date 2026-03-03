package it.aredegalli.coachly.exercise.repository;

import it.aredegalli.coachly.exercise.model.ExerciseTag;
import it.aredegalli.coachly.exercise.model.id.ExerciseTagId;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ExerciseTagRepository extends JpaRepository<ExerciseTag, ExerciseTagId> {
}
