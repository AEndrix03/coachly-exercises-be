package it.aredegalli.coachly.exercise.repository;

import it.aredegalli.coachly.exercise.model.ExerciseAlias;
import java.util.Collection;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

public interface ExerciseAliasRepository extends JpaRepository<ExerciseAlias, UUID> {
    @Query("""
        select alias from ExerciseAlias alias
        left join fetch alias.replacedBy
        where alias.exercise.id in :exerciseIds
        order by alias.exercise.id, alias.weight desc, alias.id
        """)
    List<ExerciseAlias> findAllByExerciseIds(Collection<UUID> exerciseIds);
}
