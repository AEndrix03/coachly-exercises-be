package it.aredegalli.coachly.exercise.repository;

import it.aredegalli.coachly.exercise.model.ExerciseVariation;
import it.aredegalli.coachly.exercise.model.id.ExerciseVariationId;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ExerciseVariationRepository extends JpaRepository<ExerciseVariation, ExerciseVariationId> {
}
