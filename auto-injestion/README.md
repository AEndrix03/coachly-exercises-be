# Exercise enrichment

Pipeline stageda per scansione del progetto Spring, snapshot/audit del dataset e arricchimento controllato via Ollama.

Installazione: `python -m pip install -e .`

La connessione viene letta da `.env` tramite `COACHLY_DB_*`; il file non va committato.
Per Gemini sono usati due worker in parallelo, `gemma-4-31b-it` e `gemma-4-26b-it`, con massimo 30 richieste/minuto per modello e retry dopo 429.

Esecuzione dalla directory `auto-injestion`:

```bash
python -m exercise_enrichment run --spring-project .. --ollama-url http://localhost:11434 --model qwen3:4b-instruct
```

Gli artefatti sono scritti in `data/`. Il database originale non viene modificato: la promozione è intenzionalmente separata.
