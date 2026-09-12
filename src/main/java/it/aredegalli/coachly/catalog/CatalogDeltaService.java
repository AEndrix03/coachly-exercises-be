package it.aredegalli.coachly.catalog;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/**
 * Il canale a delta del catalogo.
 *
 * <p>L'unita' di versionamento e' <strong>l'esercizio come lo consuma il
 * client</strong>, non la riga di una tabella del backend. Prima il delta
 * restituiva righe grezze di ventidue tabelle, e il client avrebbe dovuto
 * rifare le join del backend per ricostruirsi il dettaglio: un accoppiamento
 * che lo schema locale rifiuta per progetto.
 *
 * <p>Le proiezioni le costruisce {@link CatalogProjectionService}; qui si
 * legge soltanto.
 */
@Service
public class CatalogDeltaService {

    static final String SCHEMA = "exercises";

    /** Tetto di esercizi per risposta. */
    static final int MAX_LIMIT = 1000;

    private final JdbcTemplate jdbc;
    private final CatalogProjectionService projectionService;

    public CatalogDeltaService(JdbcTemplate jdbc, CatalogProjectionService projectionService) {
        this.jdbc = jdbc;
        this.projectionService = projectionService;
    }

    /**
     * Gli esercizi cambiati da [since] in poi.
     *
     * <p>Prima di leggere si smaltisce la coda di ricostruzione, cosi' un
     * client che chiede subito dopo una modifica non riceve una risposta vuota
     * e poi si ferma: il watermark che porta a casa deve valere davvero.
     */
    @Transactional
    public CatalogDelta delta(long since, int limit) {
        projectionService.refreshDirty();

        int pageSize = Math.max(1, Math.min(limit, MAX_LIMIT));

        List<Map<String, Object>> rows = jdbc.queryForList(
            """
            SELECT exercise_id, payload, sha, deleted, row_version
            FROM %s.exercise_projection
            WHERE row_version > ?
            ORDER BY row_version ASC
            LIMIT ?
            """.formatted(SCHEMA),
            since, pageSize
        );

        List<CatalogDelta.ExerciseChange> changes = new ArrayList<>(rows.size());
        long watermark = since;

        for (Map<String, Object> row : rows) {
            watermark = Math.max(watermark, ((Number) row.get("row_version")).longValue());
            changes.add(new CatalogDelta.ExerciseChange(
                String.valueOf(row.get("exercise_id")),
                (String) row.get("sha"),
                Boolean.TRUE.equals(row.get("deleted")),
                // Il payload viaggia come oggetto, non come stringa: il client
                // lo salva cosi' com'e'.
                String.valueOf(row.get("payload"))
            ));
        }

        boolean complete = rows.size() < pageSize;
        return new CatalogDelta(
            since,
            complete ? currentVersion() : watermark,
            complete,
            changes
        );
    }

    /**
     * Versione corrente del catalogo.
     *
     * <p>E' la chiamata che nel caso normale — nessun cambiamento — sostituisce
     * un trasferimento: si confronta un intero invece di scaricare un delta
     * vuoto.
     */
    @Transactional(readOnly = true)
    public long currentVersion() {
        Long value = jdbc.queryForObject(
            "SELECT COALESCE(max(row_version), 0) FROM %s.exercise_projection".formatted(SCHEMA),
            Long.class
        );
        return value == null ? 0L : value;
    }
}
