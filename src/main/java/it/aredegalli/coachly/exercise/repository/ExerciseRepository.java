package it.aredegalli.coachly.exercise.repository;

import it.aredegalli.coachly.exercise.enums.RecordStatus;
import it.aredegalli.coachly.exercise.model.Exercise;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;

public interface ExerciseRepository extends JpaRepository<Exercise, UUID>, JpaSpecificationExecutor<Exercise> {
    List<Exercise> findAllByStatusOrderByNameAsc(RecordStatus status);

    Optional<Exercise> findByIdAndStatus(UUID id, RecordStatus status);
}
