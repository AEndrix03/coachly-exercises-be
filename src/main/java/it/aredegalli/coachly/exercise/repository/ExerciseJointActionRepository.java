package it.aredegalli.coachly.exercise.repository;

import it.aredegalli.coachly.exercise.model.ExerciseJointAction;
import it.aredegalli.coachly.exercise.model.id.ExerciseJointActionId;
import java.util.Collection;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

public interface ExerciseJointActionRepository
        extends JpaRepository<ExerciseJointAction, ExerciseJointActionId> {

    @Query("""
        select link
        from ExerciseJointAction link
        join fetch link.jointAction
        where link.exercise.id in :exerciseIds
        """)
    List<ExerciseJointAction> findAllByExerciseIds(Collection<UUID> exerciseIds);
}
