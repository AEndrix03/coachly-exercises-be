package it.aredegalli.coachly.exercise.service;

import it.aredegalli.coachly.exercise.dto.retrieve.ExerciseDetailDto;
import it.aredegalli.coachly.exercise.enums.CatalogStatus;
import it.aredegalli.coachly.exercise.enums.ExerciseKind;
import it.aredegalli.coachly.exercise.enums.RankingTier;
import it.aredegalli.coachly.exercise.model.Exercise;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * Copre l'aggiunta di `dataExclusions` e `rankingTier` al payload di
 * proiezione (vedi {@code CatalogProjectionService}): il payload che finisce
 * nel delta e' esattamente quello costruito da {@link ExerciseRetrieveMapper},
 * quindi basta verificare qui che i due campi arrivino nel DTO cosi' come
 * salvati sull'entita'.
 */
class ExerciseRetrieveMapperTest {

    private final ExerciseRetrieveMapper mapper = new ExerciseRetrieveMapper();

    @Test
    void toDetailMappaDataExclusionsERankingTier() {
        Exercise exercise = new Exercise();
        exercise.setId(UUID.randomUUID());
        exercise.setCode("push-up");
        exercise.setName("Push Up");
        exercise.setExerciseKind(ExerciseKind.RESISTANCE);
        exercise.setCatalogStatus(CatalogStatus.STANDARD);
        exercise.setTranslations("{\"nameI18n\":{\"en\":\"Push Up\"}}");
        exercise.setDataExclusions("{\"equipment\":\"bodyweight, nessun attrezzo richiesto\"}");
        exercise.setRankingTier(RankingTier.CORE);

        ExerciseDetailDto detail = mapper.toDetail(
            exercise,
            List.of(),
            false,
            List.of(),
            List.of(),
            List.of(),
            List.of(),
            List.of(),
            null,
            null,
            List.of(),
            List.of(),
            Map.of(),
            List.of()
        );

        assertEquals("core", detail.getRankingTier());
        assertEquals(
            Map.of("equipment", "bodyweight, nessun attrezzo richiesto"),
            detail.getDataExclusions()
        );
    }

    @Test
    void dataExclusionsVuotoOMalformatoDiventaMappaVuota() {
        Exercise exercise = new Exercise();
        exercise.setId(UUID.randomUUID());
        exercise.setCode("squat");
        exercise.setName("Squat");
        exercise.setTranslations("{}");
        exercise.setDataExclusions("{}");
        exercise.setRankingTier(RankingTier.STANDARD);

        ExerciseDetailDto detail = mapper.toDetail(
            exercise,
            List.of(),
            false,
            List.of(),
            List.of(),
            List.of(),
            List.of(),
            List.of(),
            null,
            null,
            List.of(),
            List.of(),
            Map.of(),
            List.of()
        );

        assertTrue(detail.getDataExclusions().isEmpty());
        assertEquals("standard", detail.getRankingTier());
    }
}
