package it.aredegalli.coachly.exercise.repository;

import it.aredegalli.coachly.exercise.model.Exercise;
import it.aredegalli.coachly.exercise.enums.RecordStatus;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface ExerciseRepository extends JpaRepository<Exercise, UUID>, JpaSpecificationExecutor<Exercise> {
    List<Exercise> findAllByOrderByNameAsc();

    List<Exercise> findAllByStatusAndOwnerUserIdIsNullAndCreatedByUserIdIsNullOrderByNameAsc(RecordStatus status);

    @Query("""
        select e
        from Exercise e
        where e.status = :status
          and (e.createdByUserId = :userId or e.ownerUserId = :userId)
        order by e.name asc
        """)
    List<Exercise> findPersonalExercises(@Param("status") RecordStatus status, @Param("userId") UUID userId);

    @Query("""
        select e
        from Exercise e
        where e.status = :status
          and (e.ownerUserId is null and e.createdByUserId is null or e.createdByUserId = :userId or e.ownerUserId = :userId)
        order by e.name asc
        """)
    List<Exercise> findCommunityExercises(@Param("status") RecordStatus status, @Param("userId") UUID userId);
}
