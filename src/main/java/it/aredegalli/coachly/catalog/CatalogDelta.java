package it.aredegalli.coachly.catalog;

import com.fasterxml.jackson.annotation.JsonRawValue;

import java.util.List;

/**
 * Risposta di {@code GET /catalog/delta}.
 *
 * @param since    watermark da cui il client ha chiesto
 * @param version  nuovo watermark: applicato questo delta, si riparte da qui
 * @param complete {@code false} se il delta e' stato troncato e il client deve
 *                 richiamare con il nuovo {@code since}
 * @param exercises esercizi cambiati, in ordine di versione
 */
public record CatalogDelta(
    long since,
    long version,
    boolean complete,
    List<ExerciseChange> exercises
) {

    /**
     * Un esercizio cambiato.
     *
     * @param id      id dell'esercizio
     * @param sha     impronta del contenuto: il client la conserva e la
     *                riespone, cosi' puo' verificare di avere davvero cio' che
     *                il server crede che abbia
     * @param deleted l'esercizio non fa piu' parte del catalogo; il payload e'
     *                l'ultimo noto e va ignorato
     * @param payload il dettaglio completo, gia' JSON
     */
    public record ExerciseChange(
        String id,
        String sha,
        boolean deleted,
        // Il payload e' gia' una stringa JSON che arriva da `jsonb`:
        // riserializzarla la trasformerebbe in una stringa dentro il JSON, e
        // il client dovrebbe fare due parsing invece di uno.
        @JsonRawValue String payload
    ) {
    }
}
