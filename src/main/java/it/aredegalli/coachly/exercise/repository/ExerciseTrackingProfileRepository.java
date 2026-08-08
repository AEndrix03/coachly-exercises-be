package it.aredegalli.coachly.exercise.repository;

import it.aredegalli.coachly.exercise.model.ExerciseTrackingProfile;
import java.util.Collection;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

public interface ExerciseTrackingProfileRepository
        extends JpaRepository<ExerciseTrackingProfile, UUID> {

    @Query("""
        select profile
        from ExerciseTrackingProfile profile
        where profile.exerciseId in :exerciseIds
        """)
    List<ExerciseTrackingProfile> findAllByExerciseIds(Collection<UUID> exerciseIds);
}
