# Codex Agent Prompt — Exercise Database Population

> Copia l'intero contenuto di questo file come prompt per Codex / GPT-4o agent.

---

## CONTESTO

Stai lavorando su un backend Spring Boot per un'app di fitness (Coachly).
Il DB è PostgreSQL con schema `exercises`. Devi popolare la cartella `inj/` con file
`.md` contenenti tutti gli esercizi possibili, suddivisi per disciplina e gruppo muscolare.

La cartella `inj/` ha già questa struttura:

```
inj/
├── _registry/                  ← indice deduplicazione (scrivi qui i tuoi esercizi)
├── bodybuilding/               ← già presente, con file per gruppo muscolare
├── powerlifting/
├── olympic_weightlifting/
├── strongman/
├── crossfit/
├── functional_training/
├── hiit/
├── calisthenics/
├── gymnastics/
├── home_workout/
├── yoga/
├── pilates/
├── cardio/
├── kettlebell/
├── resistance_bands/
├── trx/
├── stretching/
├── mobility/
├── foam_rolling/
├── warm_up/
├── core_training/
├── boxing/
├── martial_arts/
├── rehabilitation/
├── balance_stability/
└── sport_specific/
```

Ogni cartella disciplina contiene già file `.md` per gruppo muscolare, es:
- `bodybuilding/chest.md`
- `bodybuilding/back.md`
- `crossfit/core.md`
- ecc.

Ogni file `.md` ha già in cima la lista dei muscoli del gruppo. **Devi aggiungere esercizi SOTTO quella lista**, senza modificarla.

---

## TUO OBIETTIVO

Per ogni disciplina e per ogni file di gruppo muscolare esistente:

1. **Leggi** il file esistente
2. **Aggiungi** tutti gli esercizi possibili per quel gruppo muscolare in quella disciplina
3. **Riscrivi** il file con la lista muscoli intatta in cima + esercizi aggiunti
4. **Aggiorna** il registry parziale della tua sessione

Cerca online (ExRx.net, bodybuilding.com, PubMed, ACE Fitness, NSCA, CrossFit journal,
yoga databases, PNF stretching guides, calisthenics skill lists, etc.) per trovare
quanti più esercizi possibile. Includi **tutte le varianti**.

---

## FORMATO OBBLIGATORIO PER OGNI ESERCIZIO

```markdown
## <Nome Inglese Canonico>
- **IT**: <Nome Italiano>
- **Difficulty**: <beginner|intermediate|advanced|elite>
- **Mechanics**: <compound|isolation>
- **Force**: <push|pull|static|dynamic>
- **Unilateral**: <true|false>
- **Bodyweight**: <true|false>
- **Risk**: <low|medium|high|very_high>
- **Spotter**: <true|false>
- **Primary Muscles**: <lista muscoli principali, dal file esistente>
- **Secondary Muscles**: <lista muscoli secondari>
- **Equipment**: <attrezzatura necessaria, oppure "None (Bodyweight)">
- **Tags**: <tag1>, <tag2>, <tag3>

**Variants:**
- <Variant Name EN> | <Nome Italiano> | diff: <level> | spot: <true|false>
- <Variant Name EN> | <Nome Italiano> | diff: <level> | spot: <true|false>
```

### Regole formato
- Le varianti vanno **subito dopo** l'esercizio padre, non come esercizi separati
- Se un esercizio è già presente nel file (scritto da un altro agente), **non duplicarlo** — aggiungi solo varianti mancanti
- Per stretching/mobility: `mechanics: isolation`, `force: static`, `bodyweight: true`
- Per foam rolling: `mechanics: isolation`, `force: static`, `bodyweight: true`, `risk: low`
- Per yoga: usa sia il nome Sanskrit che l'inglese nel campo nome, italiano nel campo IT
- Per CrossFit: usa la nomenclatura ufficiale CrossFit
- Per calisthenics: scrivi le progressioni in ordine (beginner → elite)

### Valori validi per i campi (corrispondono agli enum del DB)

**Difficulty:**
- `beginner` — adatto a chi inizia
- `intermediate` — richiede esperienza di base
- `advanced` — richiede esperienza solida
- `elite` — atleti professionisti/specializzati

**Mechanics:**
- `compound` — coinvolge più articolazioni
- `isolation` — coinvolge una sola articolazione

**Force:**
- `push` — spinta (push-up, squat, press)
- `pull` — trazione (pull-up, row, deadlift)
- `static` — isometrico (plank, hold)
- `dynamic` — cardio/metabolico (run, jump)

**Risk:**
- `low` — sicuro per tutti
- `medium` — richiede tecnica base
- `high` — richiede tecnica avanzata, possibile infortunio
- `very_high` — rischio elevato (spotter obbligatorio o movimento molto tecnico)

---

## ESEMPIO COMPLETO

```markdown
## Barbell Back Squat
- **IT**: Squat con Bilanciere
- **Difficulty**: intermediate
- **Mechanics**: compound
- **Force**: push
- **Unilateral**: false
- **Bodyweight**: false
- **Risk**: medium
- **Spotter**: false
- **Primary Muscles**: Rectus Femoris, Vastus Lateralis, Vastus Medialis, Vastus Intermedius, Gluteus Maximus
- **Secondary Muscles**: Hamstrings, Erector Spinae, Adductor Magnus, Gluteus Medius, Core
- **Equipment**: Barbell, Squat Rack
- **Tags**: strength, mass, lower_body, knee_dominant, bilateral, compound_king

**Variants:**
- High Bar Back Squat | Squat Alta | diff: intermediate | spot: false
- Low Bar Back Squat | Squat Bassa | diff: intermediate | spot: false
- Box Squat | Squat sulla Box | diff: intermediate | spot: false
- Pause Squat | Squat con Pausa | diff: intermediate | spot: false
- Tempo Squat | Squat Tempo | diff: intermediate | spot: false
- Heels Elevated Squat | Squat con Talloni Rialzati | diff: beginner | spot: false
- Pin Squat | Squat da Pin | diff: intermediate | spot: false
- Anderson Squat | Anderson Squat | diff: intermediate | spot: false
- Hatfield Squat | Hatfield Squat | diff: advanced | spot: false
```

---

## REGISTRY — FORMATO

Dopo aver scritto tutti i file esercizi, crea un file:

```
inj/_registry/codex_<tuo_nome_agente>_exercises.md
```

es. `inj/_registry/codex_batch_a_exercises.md`

Con questo formato tabella markdown:

```markdown
| Exercise Name (EN) | Italian Name | Disciplines | Parent Exercise |
|---|---|---|---|
| Barbell Back Squat | Squat con Bilanciere | bodybuilding, powerlifting, crossfit | null |
| High Bar Back Squat | Squat Alta | bodybuilding, powerlifting | Barbell Back Squat |
| Box Squat | Squat sulla Box | bodybuilding, powerlifting | Barbell Back Squat |
```

**Colonna Disciplines**: lista delle discipline dove appare l'esercizio, separate da virgola.
**Colonna Parent Exercise**: nome del padre se è una variante, `null` se è esercizio principale.

---

## DISCIPLINE E FILE ESISTENTI

Ecco la mappa completa di discipline → file muscolo già presenti:

| Disciplina | File muscolo |
|---|---|
| bodybuilding | chest, back, shoulders, biceps, triceps, forearms, core, quads, hamstrings, glutes, calves, adductors, neck |
| powerlifting | chest, back, shoulders, triceps, biceps, forearms, core, quads, hamstrings, glutes, adductors |
| olympic_weightlifting | back, quads, hamstrings, glutes, shoulders, core, calves, forearms, hip_flexors |
| strongman | back, chest, shoulders, quads, hamstrings, glutes, core, forearms, neck, calves, adductors |
| crossfit | chest, back, shoulders, biceps, triceps, forearms, core, quads, hamstrings, glutes, calves, hip_flexors |
| functional_training | core, back, shoulders, glutes, quads, hamstrings, hip_flexors, calves, chest |
| hiit | quads, hamstrings, glutes, calves, core, shoulders, back, chest, hip_flexors |
| calisthenics | chest, back, shoulders, biceps, triceps, forearms, core, quads, hamstrings, glutes, calves |
| gymnastics | shoulders, core, back, chest, biceps, triceps, forearms, hip_flexors, quads, glutes, hamstrings |
| home_workout | chest, back, core, shoulders, biceps, triceps, quads, hamstrings, glutes, calves |
| yoga | hip_flexors, hamstrings, back, core, shoulders, adductors, glutes, calves, chest, neck |
| pilates | core, back, glutes, hip_flexors, adductors, shoulders, hamstrings, quads |
| cardio | quads, hamstrings, calves, glutes, hip_flexors, core |
| kettlebell | back, glutes, hamstrings, shoulders, core, forearms, quads, chest, triceps |
| resistance_bands | chest, back, shoulders, biceps, triceps, glutes, quads, hamstrings, adductors, core, calves |
| trx | core, back, chest, shoulders, biceps, triceps, glutes, quads, hamstrings, calves |
| stretching | hip_flexors, hamstrings, quads, back, chest, shoulders, calves, adductors, glutes, neck, forearms |
| mobility | shoulders, hip_flexors, back, calves, forearms, neck, thoracic, adductors, glutes |
| foam_rolling | quads, hamstrings, glutes, back, calves, chest, shoulders, adductors, hip_flexors |
| warm_up | shoulders, back, core, glutes, hip_flexors, quads, hamstrings, calves, chest, neck |
| core_training | core, back, hip_flexors, glutes, adductors, shoulders |
| boxing | shoulders, core, back, forearms, calves, quads, neck, triceps, biceps |
| martial_arts | shoulders, core, back, quads, hamstrings, glutes, calves, forearms, hip_flexors, neck, adductors |
| rehabilitation | shoulders, core, glutes, hip_flexors, adductors, back, calves, quads, hamstrings |
| balance_stability | glutes, core, calves, hip_flexors, back, adductors, quads |
| sport_specific | quads, hamstrings, glutes, calves, core, back, shoulders, chest, hip_flexors, adductors, forearms |

---

## STRATEGIA CONSIGLIATA

1. Dividi le discipline in batch da 4-5 tra i tuoi agenti
2. Ogni agente lavora su batch non sovrapposti (nessun conflitto di file)
3. Ogni agente salva il suo registry in un file separato (`codex_batch_a_exercises.md`, `codex_batch_b_exercises.md`, ecc.)
4. Cerca sempre online per arricchire le liste — non fermarti a quello che sai
5. Per le discipline "full body" (CrossFit, Functional, HIIT), includi esercizi da più gruppi muscolari nello stesso file
6. Per Calisthenics, scrivi le progressioni complete (livello 1 → livello N) per ogni skill
7. Per Yoga, includi sia il nome Sanskrit che quello inglese

### Numero minimo esercizi per file
- Bodybuilding: 15-25 esercizi per gruppo muscolare
- Powerlifting: 10-20 per gruppo
- CrossFit: 10-15 per gruppo
- Calisthenics: 8-15 progressioni per gruppo
- Yoga: 8-15 posture per gruppo
- Stretching: 8-12 stretches per gruppo
- Mobility: 6-10 tecniche per gruppo
- Foam Rolling: 4-8 tecniche per gruppo
- Altri: 8-15 per gruppo

---

## NOTE TECNICHE

Il DB ha questi campi per `exercise`:

```
id (UUID)
name (VARCHAR 255) ← nome canonico inglese
difficulty (ENUM: beginner|intermediate|advanced|elite)
mechanics (ENUM: compound|isolation)
force (ENUM: push|pull|static|dynamic)
unilateral (BOOLEAN)
bodyweight (BOOLEAN)
overall_risk (ENUM: low|medium|high|very_high)
spotter_required (BOOLEAN)
visibility (ENUM: public|private) ← usa sempre "public"
status (ENUM: active|inactive|deleted) ← usa sempre "active"
translations (JSONB) ← { "it": { "name": "...", "description": "..." }, "en": { "name": "...", "description": "..." } }
```

Muscles si collegano via tabella `exercise_muscle` con campo `involvement_level` (ENUM: `primary|secondary|tertiary`).

Categories si collegano via `exercise_category` con campo `is_primary` (BOOLEAN).

Equipment si collega via `exercise_equipment`.

Tags si collegano via `exercise_tag`.

Queste info serviranno per generare le INSERT SQL nel passo successivo.

---

## OUTPUT ATTESO

Alla fine del lavoro, ogni file disciplina/muscolo deve avere questa struttura:

```markdown
# <Muscle Group Title>

- <Muscle 1>
- <Muscle 2>
...

---

## <Exercise 1 Name>
- **IT**: ...
...

**Variants:**
- ...

## <Exercise 2 Name>
...
```

E il file registry della tua sessione deve essere presente in `inj/_registry/`.

**Obiettivo finale: almeno 800-1000 esercizi unici (escludendo varianti) distribuiti su tutte le discipline.**
