package it.aredegalli.coachly.exercise.repository;

import it.aredegalli.coachly.exercise.model.Category;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface CategoryRepository extends JpaRepository<Category, UUID> {
}
