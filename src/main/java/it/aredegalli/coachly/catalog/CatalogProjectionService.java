package it.aredegalli.coachly.catalog;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import it.aredegalli.coachly.exercise.dto.ExerciseDetailDto;
import it.aredegalli.coachly.exercise.service.ExerciseService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Ricostruisce la proiezione del catalogo per gli esercizi marcati obsoleti.
 *
 * <p>Il payload si costruisce <strong>qui</strong> e non in SQL perche' e' qui
 * che vive la logica che lo produce: replicarla in una vista sarebbe un secondo
 * posto da cui puo' divergere, e la divergenza fra cio' che serve
 * {@code /exercises/{id}/details} e cio' che finisce nel delta sarebbe invisibile
 * fino al primo utente che vede due dati diversi per lo stesso esercizio.
 *
 * <p><strong>La riga che conta</strong> e' il confronto sullo SHA: la versione
 * avanza solo se il contenuto e' cambiato davvero. Senza, un reimport che
 * riscrive il catalogo con gli stessi valori farebbe riscaricare tutto a tutti.
 */
@Service
public class CatalogProjectionService {

    private static final Logger log = LoggerFactory.getLogger(CatalogProjectionService.class);

    /** Quanti esercizi ricostruire per giro. */
    static final int REFRESH_BATCH = 500;

    private final JdbcTemplate jdbc;
    private final ExerciseService exerciseService;
    /**
     * L'ordine delle chiavi resta deterministico anche qui, benche' lo SHA sia
     * calcolato dal database sul `jsonb` e quindi non dipenda da questa
     * impostazione. E' una difesa in piu': rende il payload confrontabile a
     * occhio fra due esecuzioni, e toglie di mezzo una variabile quando si
     * indaga perche' una proiezione risulta cambiata.
     */
    private final ObjectMapper objectMapper = new ObjectMapper()
        .configure(SerializationFeature.ORDER_MAP_ENTRIES_BY_KEYS, true);

    public CatalogProjectionService(JdbcTemplate jdbc, ExerciseService exerciseService) {
        this.jdbc = jdbc;
        this.exerciseService = exerciseService;
    }

    /**
     * Ricostruisce fino a {@link #REFRESH_BATCH} esercizi obsoleti.
     *
     * @return quanti esercizi restano da ricostruire dopo questo giro
     */
    @Transactional
    public int refreshDirty() {
        List<UUID> dirty = jdbc.queryForList(
            """
            SELECT exercise_id
            FROM exercises.exercise_projection_dirty
            ORDER BY marked_at
            LIMIT ?
            """,
            UUID.class, REFRESH_BATCH
        );
        if (dirty.isEmpty()) return 0;

        Map<UUID, ExerciseDetailDto> details = exerciseService.getPublishableDetails(dirty).stream()
            .collect(Collectors.toMap(ExerciseDetailDto::getId, detail -> detail, (a, b) -> a));

        int changed = 0;
        for (UUID exerciseId : dirty) {
            ExerciseDetailDto detail = details.get(exerciseId);
            changed += detail == null
                ? markDeleted(exerciseId)
                : upsertProjection(exerciseId, detail);
        }

        jdbc.update(
            "DELETE FROM exercises.exercise_projection_dirty WHERE exercise_id = ANY (?)",
            dirty.toArray(UUID[]::new)
        );

        int remaining = pendingCount();
        log.info("Catalog projection refreshed: {} dirty, {} changed, {} remaining",
            dirty.size(), changed, remaining);
        return remaining;
    }

    /** Quanti esercizi restano in coda di ricostruzione. */
    @Transactional(readOnly = true)
    public int pendingCount() {
        Integer count = jdbc.queryForObject(
            "SELECT count(*) FROM exercises.exercise_projection_dirty", Integer.class);
        return count == null ? 0 : count;
    }

    /**
     * Scrive la proiezione solo se il contenuto e' cambiato.
     *
     * <p>{@code WHERE sha <> :sha} e' il cuore del meccanismo: una scrittura
     * che non cambia nulla non tocca {@code row_version}, quindi nessun client
     * vede un delta.
     */
    private int upsertProjection(UUID exerciseId, ExerciseDetailDto detail) {
        return jdbc.update(
            """
            WITH incoming AS (SELECT CAST(? AS jsonb) AS payload)
            INSERT INTO exercises.exercise_projection (exercise_id, payload, sha, deleted)
            SELECT ?, payload, exercises.catalog_sha(payload), false FROM incoming
            ON CONFLICT (exercise_id) DO UPDATE
               SET payload     = EXCLUDED.payload,
                   sha         = EXCLUDED.sha,
                   deleted     = false,
                   row_version = nextval('exercises.catalog_version'),
                   updated_at  = now()
             WHERE exercises.exercise_projection.sha <> EXCLUDED.sha
                OR exercises.exercise_projection.deleted
            """,
            serialize(detail), exerciseId
        );
    }

    /**
     * Un esercizio che non e' piu' pubblicabile resta come riga marcata.
     *
     * <p>Cancellare la riga lo farebbe sparire dal delta, e il client se lo
     * terrebbe per sempre: una cancellazione va comunicata, non taciuta.
     */
    private int markDeleted(UUID exerciseId) {
        return jdbc.update(
            """
            UPDATE exercises.exercise_projection
               SET deleted     = true,
                   row_version = nextval('exercises.catalog_version'),
                   updated_at  = now()
             WHERE exercise_id = ? AND NOT deleted
            """,
            exerciseId
        );
    }

    private String serialize(ExerciseDetailDto detail) {
        try {
            return objectMapper.writeValueAsString(detail);
        } catch (JsonProcessingException e) {
            throw new IllegalStateException("Exercise detail is not serializable: " + detail.getId(), e);
        }
    }

}
