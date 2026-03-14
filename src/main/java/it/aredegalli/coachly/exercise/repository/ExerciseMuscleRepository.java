package it.aredegalli.coachly.exercise.repository;

import it.aredegalli.coachly.exercise.model.ExerciseMuscle;
import it.aredegalli.coachly.exercise.model.id.ExerciseMuscleId;
import java.util.Collection;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

public interface ExerciseMuscleRepository extends JpaRepository<ExerciseMuscle, ExerciseMuscleId> {
    @Query("""
        select exerciseMuscle
        from ExerciseMuscle exerciseMuscle
        join fetch exerciseMuscle.muscle
        where exerciseMuscle.exercise.id in :exerciseIds
        """)
    List<ExerciseMuscle> findAllByExerciseIds(Collection<UUID> exerciseIds);
}
