package it.aredegalli.coachly.exercise.repository;

import it.aredegalli.coachly.exercise.model.ExerciseMedia;
import java.util.Collection;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ExerciseMediaRepository extends JpaRepository<ExerciseMedia, UUID> {
    List<ExerciseMedia> findAllByExercise_IdInOrderByDisplayOrderAsc(Collection<UUID> exerciseIds);
}
