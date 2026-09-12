package it.aredegalli.coachly.catalog;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * Protegge l'invariante su cui poggia tutto il canale a delta:
 * <strong>ricostruire una proiezione senza che i dati siano cambiati non deve
 * produrre nessun cambiamento</strong>.
 *
 * <p>Se salta, il sintomo in produzione non e' un errore: e' il catalogo che si
 * riscarica da solo, su tutti i dispositivi, senza che nessun dato sia
 * diverso. E' un guasto silenzioso, ed e' la ragione per cui questo test
 * esiste.
 *
 * <p>Gira contro il database vero, come {@code CoachlyExercisesBeApplicationTests}:
 * servono {@code COACHLY_DB_URL}, {@code COACHLY_DB_USERNAME} e
 * {@code COACHLY_DB_PASSWORD}. Ogni test sta in una transazione che viene
 * annullata, quindi non lascia niente dietro di se'.
 */
@SpringBootTest
@Transactional
class CatalogProjectionIntegrationTest {

    @Autowired
    private CatalogProjectionService projectionService;

    @Autowired
    private JdbcTemplate jdbc;

    @Test
    void ricostruireSenzaModificheNonMuoveNulla() {
        List<Map<String, Object>> before = projectionSample(50);
        if (before.isEmpty()) return; // catalogo vuoto: niente da proteggere

        markDirty(before.stream().map(row -> (UUID) row.get("exercise_id")).toList());
        projectionService.refreshDirty();

        for (Map<String, Object> row : before) {
            UUID id = (UUID) row.get("exercise_id");
            Map<String, Object> after = projectionOf(id);
            assertEquals(row.get("sha"), after.get("sha"),
                "l'impronta e' cambiata senza che i dati cambiassero: " + id);
            assertEquals(row.get("row_version"), after.get("row_version"),
                "la versione e' avanzata senza che i dati cambiassero: " + id);
        }
    }

    @Test
    void ilPayloadNonDipendeDallaDimensioneDelBatch() {
        // E' il difetto che si e' presentato davvero: le query dei ponti non
        // avevano `order by`, l'ordine delle righe dipendeva dal piano scelto
        // da Postgres, e il piano cambia fra un batch di cinquanta e uno
        // singolo. Le liste finivano nel JSON in ordine diverso e l'impronta
        // cambiava da sola.
        List<Map<String, Object>> sample = projectionSample(50);
        if (sample.size() < 2) return;

        UUID target = (UUID) sample.getFirst().get("exercise_id");

        // Ricostruzione da sola.
        markDirty(List.of(target));
        projectionService.refreshDirty();
        String shaAlone = (String) projectionOf(target).get("sha");

        // Ricostruzione dentro un batch con altri quarantanove.
        markDirty(sample.stream().map(row -> (UUID) row.get("exercise_id")).toList());
        projectionService.refreshDirty();
        String shaInBatch = (String) projectionOf(target).get("sha");

        assertEquals(shaAlone, shaInBatch,
            "l'impronta dipende da quanti esercizi si ricostruiscono insieme");
    }

    @Test
    void laCodaSiSvuotaDopoUnGiro() {
        List<Map<String, Object>> sample = projectionSample(10);
        if (sample.isEmpty()) return;

        markDirty(sample.stream().map(row -> (UUID) row.get("exercise_id")).toList());
        assertTrue(pendingCount() > 0, "la coda doveva contenere gli esercizi marcati");

        projectionService.refreshDirty();

        assertEquals(0, pendingCount(), "gli esercizi ricostruiti devono uscire dalla coda");
    }

    @Test
    void unEsercizioNonPubblicabileDiventaCancellato() {
        List<Map<String, Object>> sample = projectionSample(1);
        if (sample.isEmpty()) return;

        UUID target = (UUID) sample.getFirst().get("exercise_id");
        assertFalse((Boolean) projectionOf(target).get("deleted"));

        // Lo ritiro dal catalogo: la proiezione deve restare come riga marcata,
        // perche' una cancellazione va comunicata al client, non taciuta.
        jdbc.update("UPDATE exercises.exercise SET status = 'archived' WHERE id = ?", target);
        markDirty(List.of(target));
        projectionService.refreshDirty();

        Map<String, Object> after = projectionOf(target);
        assertTrue((Boolean) after.get("deleted"), "l'esercizio ritirato doveva risultare cancellato");
    }

    // ── Utilita' ─────────────────────────────────────────────────────────────

    private List<Map<String, Object>> projectionSample(int size) {
        return jdbc.queryForList(
            """
            SELECT exercise_id, sha, row_version
            FROM exercises.exercise_projection
            WHERE NOT deleted
            ORDER BY exercise_id
            LIMIT ?
            """,
            size
        );
    }

    private Map<String, Object> projectionOf(UUID exerciseId) {
        return jdbc.queryForMap(
            "SELECT exercise_id, sha, row_version, deleted FROM exercises.exercise_projection WHERE exercise_id = ?",
            exerciseId
        );
    }

    private void markDirty(List<UUID> exerciseIds) {
        for (UUID id : exerciseIds) {
            jdbc.update(
                "INSERT INTO exercises.exercise_projection_dirty (exercise_id) VALUES (?) ON CONFLICT DO NOTHING",
                id
            );
        }
    }

    private int pendingCount() {
        Integer count = jdbc.queryForObject(
            "SELECT count(*) FROM exercises.exercise_projection_dirty", Integer.class);
        return count == null ? 0 : count;
    }
}
