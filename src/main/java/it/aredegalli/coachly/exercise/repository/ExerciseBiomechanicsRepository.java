package it.aredegalli.coachly.exercise.repository;

import it.aredegalli.coachly.exercise.model.ExerciseBiomechanics;
import java.util.Collection;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

public interface ExerciseBiomechanicsRepository extends JpaRepository<ExerciseBiomechanics, UUID> {

    @Query("""
        select biomechanics
        from ExerciseBiomechanics biomechanics
        where biomechanics.exerciseId in :exerciseIds
        """)
    List<ExerciseBiomechanics> findAllByExerciseIds(Collection<UUID> exerciseIds);
}
