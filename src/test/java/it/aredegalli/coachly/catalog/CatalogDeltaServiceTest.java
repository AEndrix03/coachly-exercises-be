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
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.contains;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class CatalogDeltaServiceTest {

    @Mock
    private JdbcTemplate jdbc;

    @Mock
    private CatalogProjectionService projectionService;

    @InjectMocks
    private CatalogDeltaService service;

    private static Map<String, Object> projection(long version, String sha, boolean deleted) {
        Map<String, Object> row = new LinkedHashMap<>();
        row.put("exercise_id", UUID.randomUUID().toString());
        row.put("payload", "{\"name\":\"squat\"}");
        row.put("sha", sha);
        row.put("deleted", deleted);
        row.put("row_version", version);
        return row;
    }

    private void givenProjections(List<Map<String, Object>> rows) {
        when(jdbc.queryForList(contains("exercise_projection"), anyLong(), anyInt()))
            .thenReturn(rows);
    }

    @Test
    void smaltisceLaCodaPrimaDiLeggere() {
        // Un client che chiede un delta subito dopo una modifica non deve
        // ricevere una risposta vuota e poi fermarsi: il watermark che porta a
        // casa deve valere davvero.
        givenProjections(List.of());
        when(jdbc.queryForObject(anyString(), eq(Long.class))).thenReturn(7L);

        service.delta(0, 100);

        verify(projectionService).refreshDirty();
    }

    @Test
    void riportaGliEserciziCambiatiConLaLoroImpronta() {
        givenProjections(List.of(projection(10, "abc", false)));
        when(jdbc.queryForObject(anyString(), eq(Long.class))).thenReturn(10L);

        CatalogDelta delta = service.delta(0, 100);

        assertEquals(1, delta.exercises().size());
        assertEquals("abc", delta.exercises().getFirst().sha());
        assertFalse(delta.exercises().getFirst().deleted());
        assertTrue(delta.complete());
    }

    @Test
    void unEsercizioRitiratoViaggiaComeCancellato() {
        // Una cancellazione va comunicata: se sparisse dal delta, il client se
        // lo terrebbe per sempre.
        givenProjections(List.of(projection(11, "abc", true)));
        when(jdbc.queryForObject(anyString(), eq(Long.class))).thenReturn(11L);

        CatalogDelta delta = service.delta(0, 100);

        assertTrue(delta.exercises().getFirst().deleted());
    }

    @Test
    void unDeltaTroncatoNonSuperaLUltimaRigaRestituita() {
        // Con il troncamento il watermark deve restare sull'ultima riga
        // effettivamente mandata, altrimenti il client salterebbe per sempre
        // quelle che stavano oltre il tetto.
        givenProjections(List.of(projection(10, "a", false), projection(20, "b", false)));

        CatalogDelta delta = service.delta(0, 2);

        assertFalse(delta.complete());
        assertEquals(20, delta.version());
    }

    @Test
    void senzaCambiamentiIlWatermarkSaleAllaVersioneCorrente() {
        // Il caso normale: nessun trasferimento, ma il client aggiorna comunque
        // il proprio watermark e al giro dopo non richiede le stesse righe.
        givenProjections(List.of());
        when(jdbc.queryForObject(anyString(), eq(Long.class))).thenReturn(99L);

        CatalogDelta delta = service.delta(50, 100);

        assertTrue(delta.exercises().isEmpty());
        assertTrue(delta.complete());
        assertEquals(99, delta.version());
    }
}
