package it.aredegalli.coachly.catalog;

import java.util.List;
import java.util.Map;

/**
 * Risposta di {@code GET /catalog/delta}.
 *
 * @param since    watermark da cui il client ha chiesto
 * @param version  nuovo watermark: il client puo' ripartire da qui ed essere
 *                 certo di non aver saltato nulla
 * @param complete {@code false} se il delta e' stato troncato e il client deve
 *                 richiamare con il nuovo {@code since}
 * @param tables   per ogni tabella del catalogo, righe da inserire o aggiornare
 *                 e chiavi da cancellare
 */
public record CatalogDelta(
    long since,
    long version,
    boolean complete,
    Map<String, TableDelta> tables
) {

    /**
     * @param upserted righe intere: il client le sovrascrive per chiave
     * @param deleted  chiavi primarie delle righe sparite, come oggetti perche'
     *                 nove tabelle su ventidue hanno una chiave composta
     */
    public record TableDelta(
        List<Map<String, Object>> upserted,
        List<Map<String, Object>> deleted
    ) {
        boolean isEmpty() {
            return upserted.isEmpty() && deleted.isEmpty();
        }
    }
}
