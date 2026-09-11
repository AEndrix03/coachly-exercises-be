package it.aredegalli.coachly.catalog;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import org.springframework.jdbc.core.JdbcTemplate;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.contains;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class CatalogDeltaServiceTest {

    @Mock
    private JdbcTemplate jdbc;

    @InjectMocks
    private CatalogDeltaService service;

    private static Map<String, Object> row(long version, String id) {
        Map<String, Object> row = new LinkedHashMap<>();
        row.put("id", id);
        row.put("row_version", version);
        return row;
    }

    private void givenTables(String... tables) {
        when(jdbc.queryForList(contains("information_schema"), eq(String.class), any(), any()))
            .thenReturn(List.of(tables));
    }

    @Test
    void removesRowVersionFromThePayload() {
        givenTables("muscle");
        when(jdbc.queryForList(contains("FROM exercises.muscle"), anyLong(), anyLong()))
            .thenReturn(List.of(row(10, "m1")));
        when(jdbc.queryForList(contains("catalog_tombstone"), anyLong(), anyString(), anyLong()))
            .thenReturn(List.of());

        CatalogDelta delta = service.delta(0, 100);

        Map<String, Object> upserted = delta.tables().get("muscle").upserted().getFirst();
        assertEquals("m1", upserted.get("id"));
        assertFalse(upserted.containsKey("row_version"),
            "row_version serve al watermark, non al client");
    }

    @Test
    void completeDeltaReportsTheHighestVersionSeen() {
        givenTables("muscle");
        when(jdbc.queryForList(contains("FROM exercises.muscle"), anyLong(), anyLong()))
            .thenReturn(List.of(row(10, "m1"), row(42, "m2")));
        when(jdbc.queryForList(contains("catalog_tombstone"), anyLong(), anyString(), anyLong()))
            .thenReturn(List.of());

        CatalogDelta delta = service.delta(0, 100);

        assertTrue(delta.complete());
        assertEquals(42, delta.version());
    }

    @Test
    void truncatedDeltaNeverAdvancesPastTheTruncatedTable() {
        // L'invariante che conta: se una tabella e' stata troncata a 100 e
        // un'altra e' completa fino a 500, restituire 500 farebbe saltare al
        // client le righe fra 101 e 500 della prima, per sempre.
        givenTables("equipment", "muscle");
        when(jdbc.queryForList(contains("FROM exercises.equipment"), anyLong(), anyLong()))
            .thenReturn(List.of(row(100, "e1"), row(100, "e2")));
        when(jdbc.queryForList(contains("FROM exercises.muscle"), anyLong(), anyLong()))
            .thenReturn(List.of(row(500, "m1")));
        when(jdbc.queryForList(contains("catalog_tombstone"), anyLong(), anyString(), anyLong()))
            .thenReturn(List.of());

        CatalogDelta delta = service.delta(0, 2);

        assertFalse(delta.complete());
        assertEquals(100, delta.version());
    }

    @Test
    void deletionsTravelAsStructuredKeys() {
        givenTables("exercise_tag");
        UUID exerciseId = UUID.randomUUID();
        UUID tagId = UUID.randomUUID();
        Map<String, Object> tombstone = new LinkedHashMap<>();
        tombstone.put("entity_key", Map.of("exercise_id", exerciseId.toString(), "tag_id", tagId.toString()));
        tombstone.put("row_version", 7L);

        when(jdbc.queryForList(contains("FROM exercises.exercise_tag"), anyLong(), anyLong()))
            .thenReturn(List.of());
        when(jdbc.queryForList(contains("catalog_tombstone"), anyLong(), anyString(), anyLong()))
            .thenReturn(List.of(tombstone));

        CatalogDelta delta = service.delta(0, 100);

        Map<String, Object> deleted = delta.tables().get("exercise_tag").deleted().getFirst();
        assertEquals(exerciseId.toString(), deleted.get("exercise_id"));
        assertEquals(tagId.toString(), deleted.get("tag_id"));
        assertEquals(7, delta.version());
    }

    @Test
    void tablesWithoutChangesAreOmitted() {
        givenTables("muscle");
        when(jdbc.queryForList(contains("FROM exercises.muscle"), anyLong(), anyLong()))
            .thenReturn(List.of());
        when(jdbc.queryForList(contains("catalog_tombstone"), anyLong(), anyString(), anyLong()))
            .thenReturn(List.of());

        CatalogDelta delta = service.delta(5, 100);

        assertTrue(delta.tables().isEmpty());
        assertEquals(5, delta.version(), "senza cambiamenti il watermark non si muove");
    }
}
