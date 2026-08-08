package it.aredegalli.coachly.exercise.repository;

import it.aredegalli.coachly.exercise.model.JointAction;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface JointActionRepository extends JpaRepository<JointAction, UUID> {
}
