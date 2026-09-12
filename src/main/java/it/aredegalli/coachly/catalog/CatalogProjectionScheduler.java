package it.aredegalli.coachly.catalog;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.util.concurrent.atomic.AtomicBoolean;

/**
 * Smaltisce da solo la coda di ricostruzione della proiezione.
 *
 * <p>Senza, il canale a delta si pianta in silenzio. Il client normale chiede
 * {@code GET /catalog/version}, che e' una lettura e non ricostruisce niente:
 * se un import ha marcato duemila esercizi come obsoleti, la versione non si
 * muove finche' qualcuno non chiede un delta — ma nessuno chiede un delta
 * <em>proprio perche'</em> la versione non si e' mossa. Le modifiche non
 * raggiungerebbero mai nessuno.
 *
 * <p>Il giro periodico rompe quel cerchio. E' anche la rete di sicurezza per i
 * trigger di invalidazione: se un domani ne manca uno, un riempimento
 * periodico della coda basta a rimettere tutto in pari, e costa poco perche'
 * le proiezioni invariate non vengono riscritte.
 */
@Component
public class CatalogProjectionScheduler {

    private static final Logger log = LoggerFactory.getLogger(CatalogProjectionScheduler.class);

    private final CatalogProjectionService projectionService;

    /**
     * Un giro alla volta: il lavoro e' idempotente, ma due esecuzioni
     * sovrapposte si contenderebbero le stesse righe della coda per niente.
     */
    private final AtomicBoolean running = new AtomicBoolean(false);

    private final boolean enabled;

    public CatalogProjectionScheduler(
        CatalogProjectionService projectionService,
        @Value("${coachly.catalog.projection.scheduler-enabled:true}") boolean enabled
    ) {
        this.projectionService = projectionService;
        this.enabled = enabled;
    }

    @Scheduled(
        initialDelayString = "${coachly.catalog.projection.initial-delay:PT20S}",
        fixedDelayString = "${coachly.catalog.projection.interval:PT30S}"
    )
    public void drainQueue() {
        if (!enabled || !running.compareAndSet(false, true)) return;

        try {
            int remaining = projectionService.refreshDirty();
            if (remaining > 0) {
                log.info("Catalog projection queue not empty yet: {} remaining", remaining);
            }
        } catch (RuntimeException e) {
            // Un giro fallito non deve fermare quelli successivi: la coda resta
            // com'e' e si ritenta fra trenta secondi.
            log.warn("Catalog projection refresh failed; retrying on the next tick", e);
        } finally {
            running.set(false);
        }
    }
}
