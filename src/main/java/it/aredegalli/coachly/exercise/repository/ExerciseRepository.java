package it.aredegalli.coachly.exercise.repository;

import it.aredegalli.coachly.exercise.model.Exercise;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface ExerciseRepository extends JpaRepository<Exercise, UUID>, JpaSpecificationExecutor<Exercise> {
    List<Exercise> findAllByOrderByNameAsc();

    @Query(value = """
        select e.*
        from exercises.exercise e
        where cast(e.status as text) = :status
          and e.owner_user_id is null
          and e.created_by is null
        order by e.name asc
        """, nativeQuery = true)
    List<Exercise> findDefaultExercises(@Param("status") String status);

    @Query(value = """
        select e.*
        from exercises.exercise e
        where cast(e.status as text) = :status
          and (e.created_by = :userId or e.owner_user_id = :userId)
        order by e.name asc
        """, nativeQuery = true)
    List<Exercise> findPersonalExercises(@Param("status") String status, @Param("userId") UUID userId);

    @Query(value = """
        select e.*
        from exercises.exercise e
        where cast(e.status as text) = :status
          and (e.owner_user_id is null and e.created_by is null or e.created_by = :userId or e.owner_user_id = :userId)
        order by e.name asc
        """, nativeQuery = true)
    List<Exercise> findCommunityExercises(@Param("status") String status, @Param("userId") UUID userId);
}
