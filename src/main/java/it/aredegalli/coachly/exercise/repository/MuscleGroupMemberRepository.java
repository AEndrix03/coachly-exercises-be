package it.aredegalli.coachly.exercise.repository;

import it.aredegalli.coachly.exercise.model.MuscleGroupMember;
import it.aredegalli.coachly.exercise.model.id.MuscleGroupMemberId;
import java.util.Collection;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

public interface MuscleGroupMemberRepository
        extends JpaRepository<MuscleGroupMember, MuscleGroupMemberId> {

    @Query("""
        select member
        from MuscleGroupMember member
        join fetch member.group
        where member.muscle.id in :muscleIds
        """)
    List<MuscleGroupMember> findAllByMuscleIds(Collection<UUID> muscleIds);
}
