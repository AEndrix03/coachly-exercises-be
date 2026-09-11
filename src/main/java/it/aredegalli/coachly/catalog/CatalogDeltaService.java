package it.aredegalli.coachly.catalog;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Calcolo del delta del catalogo.
 *
 * <p>Legge le tabelle in modo generico invece di mappare ventidue entita': il
 * client non interpreta queste righe, le copia in SQLite. Un mapping esplicito
 * aggiungerebbe ventidue punti in cui lo schema e il trasporto possono
 * divergere in silenzio, e nessuno dei ventidue darebbe qualcosa in cambio.
 */
@Service
public class CatalogDeltaService {

    static final String SCHEMA = "exercises";
    static final String TOMBSTONE_TABLE = "catalog_tombstone";

    /** Tetto per tabella, per non costruire in memoria un catalogo intero. */
    static final int MAX_ROWS_PER_TABLE = 2000;

    private final JdbcTemplate jdbc;
    private final ObjectMapper objectMapper = new ObjectMapper();

    public CatalogDeltaService(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    @Transactional(readOnly = true)
    public CatalogDelta delta(long since, int limitPerTable) {
        int limit = Math.max(1, Math.min(limitPerTable, MAX_ROWS_PER_TABLE));
        List<String> tables = catalogTables();

        Map<String, CatalogDelta.TableDelta> result = new LinkedHashMap<>();
        long highestSeen = since;
        // Watermark sicuro: vedi safeVersion().
        long lowestTruncated = Long.MAX_VALUE;

        for (String table : tables) {
            List<Map<String, Object>> rows = jdbc.queryForList(
                "SELECT * FROM %s.%s WHERE row_version > ? ORDER BY row_version ASC LIMIT ?"
                    .formatted(SCHEMA, quoted(table)),
                since, limit
            );

            List<Map<String, Object>> deleted = jdbc.queryForList(
                """
                SELECT entity_key, row_version
                FROM %s.%s
                WHERE row_version > ? AND table_name = ?
                ORDER BY row_version ASC
                LIMIT ?
                """.formatted(SCHEMA, TOMBSTONE_TABLE),
                since, table, limit
            );

            long tableMax = since;
            for (Map<String, Object> row : rows) {
                tableMax = Math.max(tableMax, toLong(row.get("row_version")));
            }
            for (Map<String, Object> row : deleted) {
                tableMax = Math.max(tableMax, toLong(row.get("row_version")));
            }
            highestSeen = Math.max(highestSeen, tableMax);

            if (rows.size() == limit || deleted.size() == limit) {
                lowestTruncated = Math.min(lowestTruncated, tableMax);
            }

            CatalogDelta.TableDelta tableDelta = new CatalogDelta.TableDelta(
                rows.stream().map(CatalogDeltaService::normalizeRow).toList(),
                deleted.stream().map(this::entityKeyOf).toList()
            );
            if (!tableDelta.isEmpty()) {
                result.put(table, tableDelta);
            }
        }

        boolean complete = lowestTruncated == Long.MAX_VALUE;

        return new CatalogDelta(
            since, safeVersion(lowestTruncated, highestSeen), complete, result);
    }

    /**
     * Il watermark restituito deve rispettare un invariante: <em>tutte</em> le
     * righe con versione minore o uguale sono nella risposta.
     *
     * <p>Con un tetto per tabella il massimo globale non lo rispetta. Se la
     * tabella A e' stata troncata a versione 100 e la tabella B e' completa
     * fino a 500, restituire 500 farebbe ripartire il client da li', e le
     * righe di A fra 101 e 500 non le vedrebbe mai piu'. Per questo, quando
     * c'e' un troncamento, il watermark e' il <strong>minimo</strong> fra i
     * massimi delle tabelle troncate: le righe ordinate per versione
     * garantiscono che sotto quella soglia non manchi nulla. Il client rilegge
     * qualcosa due volte, e va bene: l'applicazione del delta e' un upsert per
     * chiave, quindi e' idempotente.
     */
    private static long safeVersion(long lowestTruncated, long highestSeen) {
        return lowestTruncated == Long.MAX_VALUE ? highestSeen : lowestTruncated;
    }

    /** Versione corrente del catalogo, senza scaricare nulla. */
    @Transactional(readOnly = true)
    public long currentVersion() {
        Long value = jdbc.queryForObject(
            "SELECT last_value FROM %s.catalog_version".formatted(SCHEMA), Long.class);
        return value == null ? 0L : value;
    }

    /**
     * Le tabelle versionate, lette dal catalogo di sistema invece che da un
     * elenco scritto a mano: una tabella aggiunta al catalogo e coperta dalla
     * migrazione entra nel delta da sola.
     */
    List<String> catalogTables() {
        return jdbc.queryForList(
            """
            SELECT table_name
            FROM information_schema.columns
            WHERE table_schema = ?
              AND column_name = 'row_version'
              AND table_name <> ?
            ORDER BY table_name
            """,
            String.class, SCHEMA, TOMBSTONE_TABLE
        );
    }

    /**
     * `row_version` serve al server per calcolare il watermark, non al client:
     * togliendolo si evita che finisca dentro SQLite come se fosse un campo
     * del dominio.
     */
    private static Map<String, Object> normalizeRow(Map<String, Object> row) {
        Map<String, Object> copy = new LinkedHashMap<>(row);
        copy.remove("row_version");
        copy.replaceAll((key, value) -> normalizeValue(value));
        return copy;
    }

    @SuppressWarnings("unchecked")
    private Map<String, Object> entityKeyOf(Map<String, Object> tombstone) {
        Object key = tombstone.get("entity_key");
        if (key instanceof Map<?, ?> map) {
            return (Map<String, Object>) map;
        }
        // `entity_key` arriva come jsonb, quindi come PGobject: va riportato a
        // oggetto, altrimenti il client riceverebbe una stringa da riparsare.
        try {
            return objectMapper.readValue(String.valueOf(key), new TypeReference<>() {
            });
        } catch (JsonProcessingException e) {
            throw new IllegalStateException("Malformed tombstone key: " + key, e);
        }
    }

    /**
     * I tipi Postgres che Jackson non serializza da solo diventano stringhe.
     * `jsonb` arriva come {@code PGobject}, e senza questa conversione
     * finirebbe nel JSON come un oggetto con dentro {@code type} e
     * {@code value} invece che come il suo contenuto.
     */
    private static Object normalizeValue(Object value) {
        if (value == null) return null;
        String className = value.getClass().getName();
        if (className.equals("org.postgresql.util.PGobject")) {
            return String.valueOf(value);
        }
        return value;
    }

    private static long toLong(Object value) {
        return value instanceof Number number ? number.longValue() : 0L;
    }

    /** Il nome arriva dal catalogo di sistema, ma non si concatena mai grezzo. */
    private static String quoted(String identifier) {
        if (!identifier.matches("[a-z_][a-z0-9_]*")) {
            throw new IllegalStateException("Unexpected table name: " + identifier);
        }
        return identifier;
    }

}
