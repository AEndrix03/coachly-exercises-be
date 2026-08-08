package it.aredegalli.coachly.exercise.repository;

import it.aredegalli.coachly.exercise.model.ExerciseTag;
import it.aredegalli.coachly.exercise.model.id.ExerciseTagId;
import java.util.Collection;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

public interface ExerciseTagRepository extends JpaRepository<ExerciseTag, ExerciseTagId> {
    /**
     * Retired tags keep their links so the decision stays reversible, so the
     * archived ones have to be filtered out here rather than deleted.
     */
    @Query("""
        select exerciseTag
        from ExerciseTag exerciseTag
        join fetch exerciseTag.tag tag
        where exerciseTag.exercise.id in :exerciseIds
          and tag.deletedAt is null
        """)
    List<ExerciseTag> findAllByExerciseIds(Collection<UUID> exerciseIds);
}
