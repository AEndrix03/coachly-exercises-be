package it.aredegalli.coachly.exercise.repository;

import it.aredegalli.coachly.exercise.model.ExerciseCategory;
import it.aredegalli.coachly.exercise.model.id.ExerciseCategoryId;
import java.util.Collection;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

public interface ExerciseCategoryRepository extends JpaRepository<ExerciseCategory, ExerciseCategoryId> {
    @Query("""
        select exerciseCategory
        from ExerciseCategory exerciseCategory
        join fetch exerciseCategory.category
        where exerciseCategory.exercise.id in :exerciseIds
        """)
    List<ExerciseCategory> findAllByExerciseIds(Collection<UUID> exerciseIds);
}
