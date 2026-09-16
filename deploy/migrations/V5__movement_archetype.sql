-- `exercises.movement_archetype` — la geometria da cui nascono le curve di
-- resistenza.
--
-- PERCHE' UNA TABELLA E NON UN FILE PYTHON.
-- Le ~90 righe di questa tabella sono l'unica conoscenza biomeccanica
-- originale del catalogo: articolazione e arco angolare percorso da ogni
-- archetipo di movimento. Finche' vivevano dentro `inj/_tools/
-- derive_resistance_profile.py`, correggere un angolo era una modifica al
-- codice, e chiunque riprendesse il lavoro avrebbe ridedotto gli stessi
-- angoli da capo. Qui la revisione e' un UPDATE piu' una rigenerazione.
--
-- PERCHE' `geometry` E' jsonb E NON TABELLE PONTE.
-- Stessa regola applicata a `exercise.data_exclusions`: si normalizza cio'
-- che si interroga. Nessuna query chiedera' mai "gli archetipi con angolo
-- d'anca sopra i 30 gradi" — la geometria viene letta in blocco dallo script
-- che genera le curve. Cio' che serve davvero e' un'identita' stabile per
-- archetipo (`code`), perche' le proposte la referenziano e la revisione
-- avviene per archetipo. Quella ce l'ha la chiave primaria, non le colonne.
--
-- LA CONVENZIONE DEGLI ANGOLI, che rende falsificabile ogni riga:
--   angolo = inclinazione del segmento rispetto all'ORIZZONTALE, con segno.
--   0 = orizzontale = braccio di leva massimo; +-90 = verticale = leva ~0.
--   Un cambio di segno fra inizio e fine significa che il segmento attraversa
--   l'orizzontale, ed e' cio' che produce un picco interno (il curl) invece
--   di una rampa monotona (l'alzata laterale).
-- Il campionamento e' sulla CONCENTRICA: fase 0 = inizio, fase 1 = fine.

DO $$ BEGIN
  CREATE TYPE exercises.archetype_model AS ENUM (
    'lever',          -- un'articolazione, arco da angle_start ad angle_end
    'multi_segment',  -- piu' articolazioni, i termini cos(theta) si SOMMANO
    'control_points'  -- un'articolazione, picco decentrato per punti (fase, angolo)
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

CREATE TABLE IF NOT EXISTS exercises.movement_archetype (
  code            varchar(80) PRIMARY KEY,
  model           exercises.archetype_model NOT NULL,

  -- Forma di `geometry` per modello:
  --   lever          {"joint":"elbow","start":-90,"end":60}
  --   multi_segment  {"segments":[{"joint":"hip","start":25,"end":85}, ...]}
  --   control_points {"joint":"shoulder","points":[[0,65],[0.3,8],[1,78]]}
  geometry        jsonb NOT NULL,

  -- Linea d'azione della resistenza. 'vertical' = gravita' e carichi liberi.
  resistance_line varchar(20) NOT NULL DEFAULT 'vertical',

  -- Quanto e' solida LA GEOMETRIA, non il dato che ne deriva: sono due cose
  -- diverse e vanno tenute separate. Questa e' a quattro livelli perche'
  -- 'medium-high' ("il modello di leva si applica, ma l'esecuzione reale
  -- varia parecchio") e' una distinzione che serve in revisione. La mappatura
  -- verso `exercises.confidence_level`, che di livelli ne ha tre, avviene
  -- quando si scrive il dato derivato, e sta nello script.
  confidence      varchar(16) NOT NULL
                  CHECK (confidence IN ('high', 'medium-high', 'medium', 'low-medium')),

  -- Obbligatoria e non vuota: un angolo senza motivazione non e'
  -- contestabile, e un archetipo non contestabile non e' un dato.
  rationale       text NOT NULL CHECK (length(trim(rationale)) > 0),

  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now(),
  row_version     bigint NOT NULL DEFAULT 0
);

COMMENT ON TABLE exercises.movement_archetype IS
  'Geometria articolare per archetipo di movimento: la sorgente da cui si '
  'generano le curve di resistenza esterna. Un revisore contesta UN ANGOLO, '
  'che e'' verificabile, invece di una curva disegnata a mano.';

COMMENT ON COLUMN exercises.movement_archetype.code IS
  'Combacia con il tag archetype=<code> in exercise_biomechanics.method_note.';

COMMENT ON COLUMN exercises.movement_archetype.geometry IS
  'Angoli in gradi rispetto all''orizzontale, con segno. 0 = orizzontale = '
  'braccio di leva massimo. Un cambio di segno fra inizio e fine = il segmento '
  'attraversa l''orizzontale = picco interno.';

-- Nessun trigger di riproiezione: questa tabella non entra nel payload degli
-- esercizi. Alimenta uno script offline che propone valori per
-- exercise_biomechanics, ed e' quella scrittura a marcare gli esercizi dirty.
