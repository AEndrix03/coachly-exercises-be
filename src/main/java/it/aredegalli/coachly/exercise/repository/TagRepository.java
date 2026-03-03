package it.aredegalli.coachly.exercise.repository;

import it.aredegalli.coachly.exercise.model.Tag;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface TagRepository extends JpaRepository<Tag, UUID> {
}
