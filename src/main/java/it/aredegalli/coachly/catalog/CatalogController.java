package it.aredegalli.coachly.catalog;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

/**
 * Canale a delta del catalogo (`04-data-layer.md` del client).
 *
 * <p>Il catalogo viaggia nel bundle della app; questo endpoint serve solo a
 * tenerlo aggiornato, una volta per sessione applicativa e mai in modo
 * bloccante per la UI. Non e' il percorso con cui il client si procura il
 * catalogo: quello e' una copia di file al primo avvio.
 */
@RestController
@RequestMapping("/catalog")
public class CatalogController {

    private final CatalogDeltaService deltaService;
    private final CatalogProjectionService projectionService;

    public CatalogController(
        CatalogDeltaService deltaService,
        CatalogProjectionService projectionService
    ) {
        this.deltaService = deltaService;
        this.projectionService = projectionService;
    }

    /**
     * @param since  watermark dell'ultimo delta applicato; 0 al primo giro
     * @param limit  righe massime per tabella
     */
    @GetMapping("/delta")
    public ResponseEntity<CatalogDelta> delta(
        @RequestParam(defaultValue = "0") long since,
        @RequestParam(defaultValue = "1000") int limit
    ) {
        return ResponseEntity.ok(deltaService.delta(Math.max(0, since), limit));
    }

    /**
     * Versione corrente, per decidere se scaricare un delta senza scaricarlo.
     * E' la chiamata che nel caso normale — nessun cambiamento — sostituisce
     * un trasferimento.
     */
    @GetMapping("/version")
    public Map<String, Long> version() {
        return Map.of("version", deltaService.currentVersion());
    }

    /**
     * Smaltisce la coda di ricostruzione della proiezione.
     *
     * <p>Il delta la smaltisce gia' da solo; questo endpoint serve dopo un
     * import massivo, per non far pagare la ricostruzione al primo client che
     * chiede un delta.
     *
     * @return quanti esercizi restano da ricostruire
     */
    @PostMapping("/projection/refresh")
    public Map<String, Integer> refreshProjection() {
        return Map.of("remaining", projectionService.refreshDirty());
    }
}
