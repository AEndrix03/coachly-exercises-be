package it.aredegalli.coachly.exercise.repository;

import it.aredegalli.coachly.exercise.model.ExerciseMovementPattern;
import it.aredegalli.coachly.exercise.model.id.ExerciseMovementPatternId;
import java.util.Collection;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

public interface ExerciseMovementPatternRepository
        extends JpaRepository<ExerciseMovementPattern, ExerciseMovementPatternId> {

    @Query("""
        select link
        from ExerciseMovementPattern link
        join fetch link.movementPattern
        where link.exercise.id in :exerciseIds
        """)
    List<ExerciseMovementPattern> findAllByExerciseIds(Collection<UUID> exerciseIds);
}
