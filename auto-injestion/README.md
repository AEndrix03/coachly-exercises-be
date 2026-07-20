# Exercise enrichment

Pipeline stageda per scansione del progetto Spring, snapshot/audit del dataset e arricchimento controllato via Ollama.

Installazione: `python -m pip install -e .`

La connessione viene letta da `.env` tramite `COACHLY_DB_*`; il file non va committato.

Esecuzione dalla directory `auto-injestion`:

```bash
python -m exercise_enrichment run --spring-project .. --ollama-url http://localhost:11434 --model qwen3:4b-instruct
```

Gli artefatti sono scritti in `data/`. Il database originale non viene modificato: la promozione è intenzionalmente separata.
