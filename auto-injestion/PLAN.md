# Piano di implementazione one-shot per validazione e arricchimento automatico del dataset esercizi

## 1. Obiettivo

Realizzare un’applicazione Python eseguibile con un unico comando che:

1. analizza automaticamente il progetto Spring;
2. individua entity, enum, converter, relazioni JPA e campi JSONB;
3. interroga PostgreSQL e ricostruisce il dataset completo;
4. genera uno schema interno tipizzato;
5. analizza la qualità di tutti gli esercizi;
6. utilizza Ollama per correggere e completare i dati;
7. valida ogni risposta;
8. rileva duplicati, varianti e incoerenze globali;
9. costruisce un dataset candidato;
10. importa i risultati prima in staging;
11. esegue controlli finali;
12. aggiorna il database definitivo solo se tutte le verifiche sono superate.

L’utente deve soltanto:

- rendere disponibile il repository Spring;
- configurare il database;
- avviare Ollama;
- indicare il nome del modello;
- eseguire il comando principale.

---

# 2. Vincoli fondamentali

Il modello Ollama non deve:

- collegarsi direttamente al database;
- generare SQL;
- inventare UUID;
- inventare codici di muscoli, categorie, tag o attrezzature;
- modificare dati senza validazione;
- sovrascrivere il database originale durante l’elaborazione;
- inventare percentuali di attivazione muscolare;
- creare relazioni verso record inesistenti.

Il modello deve produrre soltanto una proposta JSON strutturata.

Tutte le operazioni sul database devono essere eseguite da codice deterministico.

---

# 3. Comando finale

L’intero sistema deve essere eseguibile con:

```bash
python -m exercise_enrichment run \
  --spring-project ../coachly-exercise-service \
  --ollama-url http://localhost:11434 \
  --model qwen3:4b-instruct
```

Comandi secondari:

```bash
python -m exercise_enrichment inspect
python -m exercise_enrichment extract
python -m exercise_enrichment audit
python -m exercise_enrichment benchmark
python -m exercise_enrichment enrich
python -m exercise_enrichment validate
python -m exercise_enrichment import-staging
python -m exercise_enrichment verify-staging
python -m exercise_enrichment promote
python -m exercise_enrichment report
python -m exercise_enrichment resume
```

Il comando `run` deve eseguire automaticamente tutti gli step nell’ordine corretto.

---

# 4. Struttura del progetto

```text
exercise_enrichment/
├── pyproject.toml
├── README.md
├── .env.example
├── config/
│   ├── application.yaml
│   ├── validation_rules.yaml
│   ├── prompt_rules.yaml
│   └── model_profiles.yaml
├── src/
│   └── exercise_enrichment/
│       ├── __main__.py
│       ├── cli.py
│       ├── config.py
│       ├── logging.py
│       ├── domain/
│       │   ├── models.py
│       │   ├── schemas.py
│       │   ├── enums.py
│       │   └── issues.py
│       ├── spring_scan/
│       │   ├── project_scanner.py
│       │   ├── java_parser.py
│       │   ├── entity_parser.py
│       │   ├── enum_parser.py
│       │   ├── converter_parser.py
│       │   ├── relation_parser.py
│       │   ├── jsonb_detector.py
│       │   └── schema_builder.py
│       ├── database/
│       │   ├── connection.py
│       │   ├── metadata.py
│       │   ├── extractor.py
│       │   ├── snapshot.py
│       │   ├── staging.py
│       │   ├── importer.py
│       │   └── promotion.py
│       ├── audit/
│       │   ├── field_validator.py
│       │   ├── relation_validator.py
│       │   ├── translation_validator.py
│       │   ├── semantic_rules.py
│       │   ├── duplicate_detector.py
│       │   ├── variation_validator.py
│       │   └── dataset_validator.py
│       ├── retrieval/
│       │   ├── embeddings.py
│       │   ├── vector_store.py
│       │   ├── similar_exercises.py
│       │   └── catalog_filter.py
│       ├── llm/
│       │   ├── ollama_client.py
│       │   ├── prompt_builder.py
│       │   ├── structured_output.py
│       │   ├── response_parser.py
│       │   ├── retry_policy.py
│       │   └── model_benchmark.py
│       ├── pipeline/
│       │   ├── orchestrator.py
│       │   ├── worker.py
│       │   ├── checkpoint.py
│       │   ├── job_store.py
│       │   └── recovery.py
│       ├── reporting/
│       │   ├── metrics.py
│       │   ├── json_report.py
│       │   ├── html_report.py
│       │   └── diff_report.py
│       └── tests/
├── data/
│   ├── metadata/
│   ├── raw/
│   ├── normalized/
│   ├── embeddings/
│   ├── proposals/
│   ├── validated/
│   ├── rejected/
│   ├── manual_review/
│   ├── staging/
│   └── reports/
└── tests/
    ├── unit/
    ├── integration/
    ├── fixtures/
    └── benchmark/
```

---

# 5. Fase 1 — Scansione automatica del progetto Spring

## 5.1 Individuazione del progetto

Lo scanner deve:

1. ricevere il path del progetto;
2. cercare:
   - `pom.xml`;
   - `build.gradle`;
   - `settings.gradle`;
   - directory `src/main/java`;
   - directory `src/main/resources`;

3. identificare i package Java;
4. individuare entity, enum, converter, repository e migration.

Output:

```text
data/metadata/project_manifest.json
```

Esempio:

```json
{
  "project_root": "../coachly-exercise-service",
  "build_system": "maven",
  "java_source_root": "src/main/java",
  "resource_root": "src/main/resources",
  "entities_found": 14,
  "enums_found": 11,
  "converters_found": 9,
  "migrations_found": 18
}
```

## 5.2 Parsing Java

Non usare regex come soluzione principale.

Usare un parser Java, per esempio:

```text
tree-sitter-java
```

Lo scanner deve leggere:

- package;
- import;
- nome classe;
- annotazioni;
- campi;
- tipo Java;
- generic type;
- getter e setter;
- costruttori;
- annotazioni sui campi;
- enum;
- converter JPA.

## 5.3 Rilevamento entity

Individuare classi annotate con:

```java
@Entity
```

Estrarre da:

```java
@Table(name = "exercise", schema = "exercises")
```

i metadati:

```json
{
  "entity": "Exercise",
  "table": "exercise",
  "schema": "exercises"
}
```

Per ogni campo rilevare:

- nome Java;
- nome colonna;
- tipo Java;
- nullable;
- unique;
- length;
- column definition;
- generated;
- updatable;
- enum converter;
- valore predefinito, se presente.

L’entity `Exercise` contiene campi strutturali come difficoltà, meccanica, forza, unilateralità, bodyweight, rischio generale e necessità dello spotter. Questi dati devono entrare nella validazione, mentre lo script attuale estrae soltanto `id`, `name` e `translations`.

## 5.4 Rilevamento relazioni

Analizzare:

```java
@ManyToOne
@OneToMany
@ManyToMany
@OneToOne
@EmbeddedId
@MapsId
@JoinColumn
@JoinTable
```

Costruire un grafo delle relazioni.

Esempio:

```json
{
  "source_entity": "ExerciseMuscle",
  "target_entity": "Exercise",
  "relation": "MANY_TO_ONE",
  "join_column": "exercise_id",
  "maps_id": "exerciseId",
  "nullable": false
}
```

Le relazioni esistenti devono essere ricostruite automaticamente, compresi attributi aggiuntivi come:

- `ExerciseCategory.primary`;

- `ExerciseEquipment.required`;

- `ExerciseEquipment.primary`;

- `ExerciseEquipment.quantityNeeded`;

- `ExerciseMuscle.activationPercentage`.

## 5.5 Embedded ID

Analizzare automaticamente gli `@Embeddable`.

Per esempio:

```java
ExerciseMuscleId {
    exerciseId;
    muscleId;
    involvement;
}
```

Il sistema deve comprendere che la chiave logica non è soltanto:

```text
exercise_id + muscle_id
```

ma:

```text
exercise_id + muscle_id + involvement
```

Questo dato deve essere usato per:

- individuare duplicati;
- generare le chiavi di staging;
- costruire gli upsert;
- validare le relazioni.

## 5.6 Enum e converter

Per ogni campo annotato con:

```java
@Convert(converter = ...)
```

lo scanner deve:

1. individuare il converter;
2. trovare il tipo enum associato;
3. analizzare i valori ammessi;
4. mappare valore Java e valore DB;
5. generare automaticamente un enum Python.

Output:

```text
data/metadata/enums.json
```

Esempio:

```json
{
  "DifficultyLevel": {
    "BEGINNER": "beginner",
    "INTERMEDIATE": "intermediate",
    "ADVANCED": "advanced"
  }
}
```

Il modello Ollama deve ricevere soltanto i valori effettivamente ammessi.

## 5.7 JSONB

I campi con:

```java
columnDefinition = "jsonb"
```

devono essere marcati come strutture dinamiche.

Nel progetto attuale `translations` è una stringa Java salvata come JSONB in più entity.
Lo scanner deve inferire lo schema reale del JSONB dal database:

1. campionare i valori;
2. individuare chiavi comuni;
3. rilevare tipi;
4. rilevare lingue;
5. rilevare campi mancanti;
6. produrre uno schema candidato.

Esempio:

```json
{
  "translations": {
    "languages": ["it", "en"],
    "fields": {
      "name": "string",
      "description": "string",
      "executionTips": "array[string]",
      "safetyTips": "array[string]"
    }
  }
}
```

Se la struttura è incoerente tra record, creare un issue globale.

---

# 6. Fase 2 — Verifica con metadata PostgreSQL

La scansione Java deve essere confrontata con PostgreSQL.

Interrogare:

```text
information_schema.tables
information_schema.columns
information_schema.table_constraints
information_schema.key_column_usage
information_schema.referential_constraints
pg_catalog.pg_type
pg_catalog.pg_enum
pg_catalog.pg_indexes
```

Obiettivi:

- verificare che tutte le entity abbiano una tabella;
- rilevare colonne presenti nel DB ma non nelle entity;
- rilevare campi Java non presenti nel DB;
- identificare enum PostgreSQL;
- identificare foreign key;
- identificare unique constraint;
- identificare check constraint;
- identificare colonne JSONB;
- identificare indici.

Produrre:

```text
data/metadata/schema_diff.json
```

Se Java e database non coincidono, il comando `run` deve fermarsi prima dell’arricchimento.

Eccezione:

```yaml
schema:
  allow_known_differences: true
  known_differences_file: config/schema_exceptions.yaml
```

---

# 7. Fase 3 — Generazione automatica del dominio Python

Dai metadati Java e PostgreSQL generare automaticamente:

```text
data/metadata/domain_schema.json
```

e classi Pydantic runtime.

Entità logica prevista:

```python
class ExerciseInput(BaseModel):
    id: UUID
    name: str
    difficulty: str
    mechanics: str
    force: str | None
    unilateral: bool
    bodyweight: bool
    overall_risk: str
    spotter_required: bool
    translations: dict[str, ExerciseTranslation]
    muscles: list[ExerciseMuscleInput]
    categories: list[ExerciseCategoryInput]
    equipment: list[ExerciseEquipmentInput]
    tags: list[ExerciseTagInput]
    variations: list[ExerciseVariationInput]
```

Il codice non deve assumere questi campi a priori. Deve generarli dal progetto, applicando plugin specifici per il dominio degli esercizi.

---

# 8. Fase 4 — Estrazione completa del dataset

Sostituire l’estrazione attuale, che legge soltanto tre colonne, con un estrattore generato dal grafo JPA.

Per ogni esercizio estrarre:

- record principale;
- traduzioni;
- muscoli;
- involvement;
- activation percentage;
- categorie;
- categoria primaria;
- attrezzature;
- obbligatorietà;
- attrezzatura primaria;
- quantità;
- tag;
- varianti in ingresso;
- varianti in uscita;
- eventuali media;
- status;
- visibility.

Output:

```text
data/raw/exercises.jsonl
data/raw/muscles.json
data/raw/categories.json
data/raw/equipment.json
data/raw/tags.json
data/raw/variations.jsonl
data/raw/manifest.json
```

Ogni riga deve contenere:

```json
{
  "source_hash": "sha256...",
  "extracted_at": "2026-07-21T...",
  "data": {}
}
```

Il database deve essere letto in transazione:

```sql
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ READ ONLY;
```

Questo garantisce uno snapshot coerente.

---

# 9. Fase 5 — Normalizzazione deterministica

Prima dell’LLM:

- trim delle stringhe;
- normalizzazione Unicode;
- eliminazione spazi duplicati;
- normalizzazione apostrofi;
- normalizzazione maiuscole e minuscole;
- deduplicazione liste;
- ordinamento stabile;
- conversione JSONB stringa → oggetto;
- verifica UUID;
- verifica enum;
- verifica foreign key;
- verifica valori numerici;
- normalizzazione dei codici.

Non modificare il contenuto semantico in questa fase.

Output:

```text
data/normalized/exercises.jsonl
```

---

# 10. Fase 6 — Audit deterministico

L’attuale validatore controlla soltanto la presenza di una descrizione. Deve essere sostituito completamente.

## 10.1 Controlli sul record principale

Verificare:

- nome presente;
- nome con lunghezza valida;
- difficoltà ammessa;
- meccanica ammessa;
- forza ammessa;
- rischio ammesso;
- combinazioni coerenti;
- visibility ammessa;
- status ammesso.

## 10.2 Traduzioni

Per ogni lingua richiesta:

- nome presente;
- descrizione presente;
- descrizione non troppo breve;
- descrizione non identica al nome;
- consigli di esecuzione presenti;
- consigli di sicurezza presenti;
- assenza di HTML;
- assenza di placeholder;
- assenza di testo generico;
- grammatica minima;
- nessuna lingua mischiata nello stesso campo.

## 10.3 Muscoli

Verificare:

- almeno un muscolo;
- almeno un muscolo primario;
- codici esistenti;
- nessuna relazione duplicata;
- involvement ammesso;
- activation percentage compresa tra 0 e 100;
- nessuna percentuale generata automaticamente;
- coerenza generale con il tipo di esercizio.

## 10.4 Categorie

Verificare:

- almeno una categoria;
- esattamente una categoria primaria;
- tutte le categorie esistenti;
- nessun duplicato.

## 10.5 Attrezzatura

Verificare:

- codici esistenti;
- quantità maggiore di zero;
- al massimo una attrezzatura primaria;
- attrezzatura primaria marcata come richiesta;
- coerenza con `bodyweight`;
- nessun duplicato.

## 10.6 Tag

Verificare:

- codici esistenti;
- nessun duplicato;
- tagType coerente;
- assenza di tag contraddittori.

## 10.7 Varianti

Verificare:

- nessuna variante verso se stesso;
- esercizio target esistente;
- variation type ammesso;
- nessun duplicato;
- relazione non circolare impropria;
- relazione inversa coerente;
- differenza reale tra base e variante.

## 10.8 Sicurezza

Verificare:

- consigli specifici;
- niente diagnosi;
- niente garanzie mediche;
- niente indicazioni per allenarsi con dolore;
- spotter coerente con rischio e attrezzatura.

Output:

```text
data/reports/initial_audit.json
data/reports/initial_audit.html
```

---

# 11. Fase 7 — Costruzione dell’indice degli esercizi

Creare una rappresentazione testuale canonica:

```text
nome
descrizione
categorie
muscoli
attrezzatura
tag
meccanica
forza
```

Generare embeddings usando un modello configurabile.

Configurazione:

```yaml
ollama:
  base_url: http://localhost:11434
  generation_model: qwen3:4b-instruct
  embedding_model: embeddinggemma
```

Se non è disponibile un modello embedding separato, usare una modalità fallback:

- TF-IDF;
- cosine similarity;
- token similarity;
- Jaccard sui cataloghi;
- trigram similarity.

Salvare localmente:

```text
data/embeddings/exercises.npy
data/embeddings/index.json
```

Per ogni esercizio recuperare:

- 10 esercizi più simili;
- 10 candidati variante;
- 5 possibili duplicati.

---

# 12. Fase 8 — Generazione automatica del JSON Schema Ollama

Dalle entity, enum e relazioni generare lo schema di output.

Il modello non deve restituire UUID per cataloghi relazionali. Deve restituire i codici.

Esempio:

```json
{
  "exercise_id": "uuid",
  "proposed": {
    "name": "string",
    "difficulty": "INTERMEDIATE",
    "mechanics": "COMPOUND",
    "force": "PUSH",
    "unilateral": false,
    "bodyweight": false,
    "overall_risk": "MEDIUM",
    "spotter_required": false,
    "translations": {},
    "muscles": [
      {
        "code": "PECTORALIS_MAJOR",
        "involvement": "PRIMARY"
      }
    ],
    "categories": [],
    "equipment": [],
    "tags": [],
    "variations": []
  },
  "changes": [],
  "unresolved_issues": [],
  "overall_confidence": 0.0
}
```

Gli enum devono essere esposti come `enum` JSON Schema, non come stringhe libere.

---

# 13. Fase 9 — Costruzione automatica del prompt

## 13.1 System prompt

Il prompt di sistema deve essere versionato.

```text
Sei un revisore tecnico di un catalogo strutturato di esercizi fisici.

Devi correggere e completare un singolo esercizio utilizzando esclusivamente
i valori ammessi e i cataloghi forniti.

Non inventare codici, UUID, enum, percentuali di attivazione o riferimenti.

Mantieni i dati originali quando sono plausibili e corretti.

Modifica soltanto i campi:
- mancanti;
- incoerenti;
- grammaticalmente scorretti;
- semanticamente errati;
- non conformi ai cataloghi.

I consigli di sicurezza devono essere specifici ma non devono contenere
diagnosi o prescrizioni mediche.

Quando un dato non è determinabile, inseriscilo in unresolved_issues.

Restituisci esclusivamente JSON conforme allo schema.
```

## 13.2 User prompt generato

Per ogni esercizio includere:

```text
RECORD ORIGINALE
AUDIT DETERMINISTICO
VALORI ENUM AMMESSI
CATALOGO MUSCOLI RILEVANTE
CATALOGO CATEGORIE
CATALOGO ATTREZZATURE RILEVANTE
CATALOGO TAG RILEVANTE
ESERCIZI SIMILI
POSSIBILI DUPLICATI
VARIANTI ATTUALI
REGOLE DI VALIDAZIONE
```

Non inviare l’intero catalogo se troppo grande.

Usare retrieval per restringere:

```yaml
prompt:
  max_muscles: 40
  max_equipment: 30
  max_tags: 60
  similar_exercises: 10
  duplicate_candidates: 5
```

---

# 14. Fase 10 — Client Ollama

Implementare tramite API HTTP, non chiamate shell.

Endpoint:

```text
POST /api/chat
POST /api/embed
GET /api/tags
POST /api/show
```

Configurazione:

```yaml
ollama:
  base_url: http://localhost:11434
  generation_model: qwen3:4b-instruct
  embedding_model: embeddinggemma
  temperature: 0.1
  seed: 42
  num_ctx: 8192
  timeout_seconds: 300
  max_retries: 2
```

All’avvio:

1. verificare raggiungibilità;
2. verificare presenza modello;
3. verificare supporto structured output;
4. eseguire una generazione minima;
5. eseguire un test JSON;
6. misurare il tempo di risposta.

Se il modello non supera il test, fermare la pipeline.

---

# 15. Fase 11 — Benchmark automatico iniziale

Prima di processare 2.524 esercizi selezionare automaticamente un campione stratificato di circa 40 record:

- 10 completi;
- 10 incompleti;
- 10 incoerenti;
- 5 con molte relazioni;
- 5 con possibili duplicati.

Eseguire due run per record.

Misurare:

- JSON valido;
- aderenza allo schema;
- valori inventati;
- stabilità;
- tempo;
- differenze tra run;
- numero di retry;
- tasso di unresolved issues.

Criteri minimi:

```yaml
benchmark:
  minimum_json_valid_rate: 0.98
  maximum_unknown_code_rate: 0.0
  minimum_schema_valid_rate: 0.98
  maximum_failure_rate: 0.05
```

Se il modello non supera le soglie, il sistema non avvia il batch completo.

---

# 16. Fase 12 — Elaborazione incrementale

Per ogni esercizio:

```text
PENDING
↓
LOCKED
↓
PROMPT_BUILT
↓
GENERATED
↓
SCHEMA_VALIDATED
↓
SEMANTIC_VALIDATED
↓
ACCEPTED oppure REJECTED oppure MANUAL_REVIEW
```

Tabella locale SQLite:

```sql
CREATE TABLE enrichment_job (
    exercise_id TEXT PRIMARY KEY,
    source_hash TEXT NOT NULL,
    model_name TEXT NOT NULL,
    prompt_version TEXT NOT NULL,
    schema_version TEXT NOT NULL,
    status TEXT NOT NULL,
    attempts INTEGER NOT NULL DEFAULT 0,
    input_path TEXT,
    output_path TEXT,
    error_message TEXT,
    started_at TEXT,
    completed_at TEXT
);
```

SQLite viene usato per:

- checkpoint;
- lock;
- resume;
- errori;
- metriche;
- versionamento.

Il database Coachly non viene modificato durante questa fase.

---

# 17. Fase 13 — Validazione della risposta LLM

Ogni risposta attraversa questi livelli.

## Livello 1 — Parsing JSON

Se fallisce:

- tentativo di estrazione del blocco JSON;
- un retry con prompt di repair;
- poi `REJECTED`.

## Livello 2 — JSON Schema

Verificare:

- campi obbligatori;
- tipi;
- enum;
- range;
- UUID esercizio;
- liste.

## Livello 3 — Cataloghi

Verificare:

- muscle code esistente;
- category code esistente;
- equipment code esistente;
- tag code esistente;
- variation target esistente.

## Livello 4 — Regole relazionali

Verificare:

- categoria primaria;
- attrezzatura primaria;
- muscolo primario;
- quantità;
- bodyweight;
- spotter;
- self-reference;
- duplicati.

## Livello 5 — Conservazione dati

Confrontare proposta e originale.

Rilevare:

- modifiche non motivate;
- perdita di dati;
- riduzione eccessiva delle descrizioni;
- eliminazione ingiustificata di relazioni;
- cambiamenti ad alta criticità.

## Livello 6 — Confidence gate

Configurazione:

```yaml
confidence:
  auto_accept_minimum: 0.85
  review_minimum: 0.65
```

Regole:

```text
confidence >= 0.85 e nessun errore → ACCEPTED
0.65 <= confidence < 0.85 → MANUAL_REVIEW
confidence < 0.65 → REJECTED
```

---

# 18. Fase 14 — Secondo passaggio globale

Dopo tutti gli esercizi, eseguire analisi dataset-level.

## 18.1 Duplicati

Combinare:

- similarità nome;
- embeddings;
- muscoli;
- categorie;
- attrezzatura;
- meccanica;
- forza;
- traduzioni.

Classificazione:

```text
SAME_EXERCISE
VARIATION
RELATED
UNRELATED
```

Il modello può classificare soltanto le coppie candidate selezionate deterministicamente.

Non confrontare tutte le coppie.

Con 2.524 esercizi, il confronto completo sarebbe:

```text
circa 3,18 milioni di coppie
```

Usare nearest-neighbor retrieval.

## 18.2 Coerenza delle famiglie

Raggruppare per famiglie:

- squat;
- bench press;
- row;
- pull-up;
- curl;
- extension;
- raise;
- press;
- hinge;
- lunge.

Controllare:

- naming;
- categorie;
- tag;
- involvement;
- attrezzatura;
- traduzioni.

## 18.3 Grafo varianti

Costruire un grafo diretto:

```text
base_exercise → variant_exercise
```

Controllare:

- cicli;
- componenti isolate;
- archi duplicati;
- archi simmetrici errati;
- variation type incoerenti;
- esercizi equivalenti non collegati.

---

# 19. Fase 15 — Dataset candidato

Produrre:

```text
data/validated/exercises.jsonl
data/validated/relations.jsonl
data/manual_review/exercises.jsonl
data/rejected/exercises.jsonl
```

Ogni record validato deve contenere:

```json
{
  "exercise_id": "...",
  "source_hash": "...",
  "model": "...",
  "prompt_version": "...",
  "proposal": {},
  "diff": [],
  "validation": {
    "schema_valid": true,
    "catalog_valid": true,
    "relation_valid": true,
    "global_valid": true
  }
}
```

---

# 20. Fase 16 — Staging PostgreSQL

Creare uno schema separato:

```sql
CREATE SCHEMA IF NOT EXISTS exercises_staging;
```

Clonare struttura:

```sql
CREATE TABLE exercises_staging.exercise
(LIKE exercises.exercise INCLUDING ALL);
```

Ripetere per tutte le tabelle coinvolte.

Non copiare automaticamente trigger distruttivi.

Importare nello staging:

1. cataloghi;
2. esercizi;
3. categorie;
4. attrezzature;
5. muscoli;
6. tag;
7. varianti;
8. media, se inclusi.

Gli UUID originali devono essere conservati.

---

# 21. Fase 17 — Verifica staging

Eseguire:

- conteggi;
- foreign key;
- unique constraint;
- enum;
- JSONB;
- nullabilità;
- relazioni orfane;
- primary category;
- primary equipment;
- variant self-reference;
- duplicati;
- hash dataset;
- confronto originale/candidato.

Generare:

```text
data/reports/staging_verification.html
```

La promozione deve essere bloccata se:

- esistono errori critici;
- il numero di esercizi diminuisce senza spiegazione;
- esistono relazioni orfane;
- esistono codici sconosciuti;
- esistono errori JSONB;
- esistono record non processati.

---

# 22. Fase 18 — Promozione finale

Default:

```yaml
promotion:
  automatic: false
```

Il comando one-shot deve terminare dopo lo staging e mostrare:

```text
STAGING VALIDATED
Run `python -m exercise_enrichment promote`
to apply the validated dataset.
```

Per un’esecuzione realmente automatica:

```bash
python -m exercise_enrichment run --auto-promote
```

Prima della promozione:

1. backup;
2. transazione;
3. advisory lock PostgreSQL;
4. verifica hash sorgente;
5. upsert;
6. controllo finale;
7. commit.

Schema logico:

```sql
BEGIN;

SELECT pg_advisory_xact_lock(...);

-- Verifica che il DB non sia cambiato dallo snapshot

-- Upsert esercizi
-- Sincronizzazione relazioni
-- Controlli

COMMIT;
```

Se un controllo fallisce:

```sql
ROLLBACK;
```

---

# 23. Politica di aggiornamento delle relazioni

Non fare:

```text
DELETE tutte le relazioni
INSERT proposta LLM
```

Usare diff.

Per ogni relazione:

```text
KEEP
ADD
REMOVE
UPDATE
```

Le rimozioni devono avere soglia più severa delle aggiunte.

Configurazione:

```yaml
changes:
  allow_auto_add_relation: true
  allow_auto_remove_relation: false
  allow_auto_replace_text: true
  allow_auto_change_risk: false
```

Campi sensibili:

- overall risk;
- spotter required;
- activation percentage;
- eliminazione di muscoli;
- eliminazione di attrezzature;
- rimozione di varianti;
- cambio esercizio base.

Questi devono finire in review oppure richiedere regole più severe.

---

# 24. Logging e osservabilità

Usare logging strutturato JSON.

Ogni chiamata deve registrare:

- exercise ID;
- modello;
- prompt version;
- durata;
- retry;
- dimensione input;
- dimensione output;
- validità;
- errori;
- confidence;
- stato finale.

Non registrare credenziali DB.

Output:

```text
logs/pipeline.jsonl
logs/errors.jsonl
```

Dashboard finale:

- esercizi totali;
- completi inizialmente;
- modificati;
- invariati;
- rejected;
- review;
- tempo medio;
- retry;
- errori per campo;
- distribuzione confidence;
- modifiche per relazione.

---

# 25. Configurazione

## `.env`

```dotenv
COACHLY_DB_NAME=coachly
COACHLY_DB_USERNAME=coachly
COACHLY_DB_PASSWORD=secret
COACHLY_DB_HOST=localhost
COACHLY_DB_PORT=5432

OLLAMA_BASE_URL=http://localhost:11434
OLLAMA_GENERATION_MODEL=qwen3:4b-instruct
OLLAMA_EMBEDDING_MODEL=embeddinggemma
```

## `application.yaml`

```yaml
project:
  spring_root: ../coachly-exercise-service

database:
  schema: exercises
  staging_schema: exercises_staging
  snapshot_isolation: repeatable_read

ollama:
  base_url: ${OLLAMA_BASE_URL}
  generation_model: ${OLLAMA_GENERATION_MODEL}
  embedding_model: ${OLLAMA_EMBEDDING_MODEL}
  temperature: 0.1
  seed: 42
  num_ctx: 8192
  timeout_seconds: 300
  max_retries: 2

pipeline:
  workers: 1
  resume: true
  fail_fast_on_schema_mismatch: true
  max_records: null
  auto_promote: false

languages:
  required:
    - it

confidence:
  auto_accept_minimum: 0.85
  review_minimum: 0.65
```

Con una RX 6600 conviene partire con un worker solo. Più worker Ollama non garantiscono maggiore velocità e possono aumentare memoria, contention e instabilità.

---

# 26. Dipendenze

```toml
[project]
dependencies = [
    "pydantic>=2",
    "pydantic-settings",
    "psycopg[binary]",
    "sqlalchemy",
    "httpx",
    "tenacity",
    "typer",
    "rich",
    "pyyaml",
    "orjson",
    "jsonschema",
    "tree-sitter",
    "tree-sitter-java",
    "numpy",
    "scikit-learn",
    "rapidfuzz",
    "jinja2",
    "networkx"
]
```

Opzionali:

```toml
[project.optional-dependencies]
dev = [
    "pytest",
    "pytest-cov",
    "pytest-asyncio",
    "ruff",
    "mypy"
]
```

---

# 27. Sequenza di implementazione

## Step 1

Creare CLI, configurazione, logging e struttura progetto.

## Step 2

Implementare Java scanner con tree-sitter.

## Step 3

Implementare parser:

- entity;
- field;
- enum;
- converter;
- embedded ID;
- relation;
- JSONB.

## Step 4

Implementare introspezione PostgreSQL.

## Step 5

Generare manifest e diff Java/DB.

## Step 6

Implementare estrazione completa guidata dai metadata.

## Step 7

Implementare schema Pydantic runtime.

## Step 8

Implementare audit deterministico.

## Step 9

Implementare client Ollama e health check.

## Step 10

Implementare structured output.

## Step 11

Implementare retrieval e similarità.

## Step 12

Implementare benchmark automatico.

## Step 13

Implementare orchestrator, job store, lock e resume.

## Step 14

Implementare validazione multilivello.

## Step 15

Implementare analisi globale e varianti.

## Step 16

Implementare staging.

## Step 17

Implementare verifica staging.

## Step 18

Implementare promozione transazionale.

## Step 19

Implementare report HTML.

## Step 20

Aggiungere test end-to-end su database temporaneo.

---

# 28. Test obbligatori

## Unit test

- parsing entity;
- parsing enum;
- parsing converter;
- parsing embedded ID;
- parsing relazione;
- parsing JSONB;
- schema generation;
- validazione codici;
- diff relazioni;
- duplicate detection.

## Integration test

- scansione repository;
- connessione PostgreSQL;
- estrazione;
- Ollama mock;
- import staging;
- rollback;
- resume.

## End-to-end

Usare un dataset ridotto con:

- 10 esercizi;
- 5 muscoli;
- 3 categorie;
- 5 attrezzature;
- 8 tag;
- 5 varianti.

Verificare:

```text
scan → extract → audit → enrich → validate → staging → verify
```

---

# 29. Criteri di completamento

Il sistema è completato quando:

1. individua automaticamente tutte le entity;
2. individua automaticamente enum e converter;
3. ricostruisce tutte le relazioni;
4. rileva differenze tra Java e PostgreSQL;
5. estrae tutti i 2.524 esercizi;
6. supporta interruzione e resume;
7. non accetta codici inventati;
8. non genera SQL tramite LLM;
9. produce JSON valido per almeno il 98% delle risposte;
10. importa correttamente nello staging;
11. esegue tutti i constraint;
12. produce un report dettagliato;
13. non modifica il DB originale senza promozione esplicita;
14. permette di rieseguire soltanto record modificati;
15. conserva audit completo di ogni cambiamento.

---

# 30. Flusso finale one-shot

```text
START
  ↓
Load configuration
  ↓
Check Spring project
  ↓
Scan Java sources
  ↓
Scan PostgreSQL metadata
  ↓
Compare Java and DB
  ↓
Generate domain schema
  ↓
Create immutable snapshot
  ↓
Normalize dataset
  ↓
Run deterministic audit
  ↓
Check Ollama
  ↓
Build semantic index
  ↓
Run model benchmark
  ↓
Process exercises incrementally
  ↓
Validate all proposals
  ↓
Run global duplicate analysis
  ↓
Run variation graph analysis
  ↓
Generate candidate dataset
  ↓
Create staging schema
  ↓
Import candidate dataset
  ↓
Verify staging
  ↓
Generate reports
  ↓
Optional transactional promotion
  ↓
END
```

---

# 31. Decisioni tecniche definitive

- Python come orchestratore.
- Tree-sitter per la scansione Java.
- PostgreSQL introspection come seconda fonte di verità.
- Pydantic per schemi e validazione.
- Ollama solo per analisi semantica e generazione controllata.
- JSON Schema obbligatorio.
- JSONL per snapshot e risultati.
- SQLite per checkpoint e resume.
- Embeddings per trovare esercizi simili.
- Staging PostgreSQL prima del database reale.
- Diff incrementale anziché sostituzione completa.
- Un worker iniziale sulla RX 6600.
- Nessuna percentuale di attivazione inventata.
- Nessuna modifica automatica distruttiva.
- Promozione finale disabilitata per default.
