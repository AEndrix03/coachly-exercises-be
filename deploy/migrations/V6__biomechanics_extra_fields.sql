-- Quattro campi su `exercises.exercise_biomechanics`.
--
-- Tre sono dati nuovi, uno e' il posto dove finisce la curva a 11 punti che
-- oggi vive solo nel CSV delle proposte.

-- ---------------------------------------------------------------------------
-- 1. LA CURVA
-- ---------------------------------------------------------------------------
-- `external_resistance_profile` e' un'etichetta a 5 valori: seleziona una delle
-- 5 curve scritte a mano nel frontend, quindi due esercizi con profili davvero
-- diversi disegnano lo stesso grafico, e 'variable' e' un cestino dove
-- finiscono forme diverse fra loro (picco decentrato, doppio picco, sticking
-- point). Con la curva nel dato:
--   - ogni esercizio puo' avere la sua forma;
--   - un grafico sbagliato si corregge con un delta di catalogo invece che con
--     un rilascio dell'app, che e' il verso giusto per un catalogo che si
--     sincronizza a delta;
--   - l'etichetta smette di essere una classificazione e diventa un'etichetta
--     DERIVATA dalla curva, quindi non puo' piu' divergere da essa.
-- Il frontend continua a ricadere sull'etichetta quando la curva e' NULL.
ALTER TABLE exercises.exercise_biomechanics
  ADD COLUMN IF NOT EXISTS resistance_curve numeric(4,3)[];

COMMENT ON COLUMN exercises.exercise_biomechanics.resistance_curve IS
  'Domanda meccanica esterna campionata sulla CONCENTRICA a incrementi del 10%: '
  '11 valori, indice 0 = inizio concentrica (per la maggior parte degli esercizi '
  'anche massimo allungamento dell''agonista), indice 10 = fine. Normalizzata col '
  'massimo a 1.0: confrontabile nella FORMA fra esercizi, non nella magnitudine. '
  'NON e'' tensione muscolare: quella dipende anche da tecnica, anatomia e capacita'' '
  'di forza alle varie lunghezze. Assume la ROM completa designata.';

-- Un CHECK non puo' contenere una subquery, e `unnest(...)` in una condizione
-- lo e'. Serve quindi una funzione IMMUTABLE, che nei CHECK e' ammessa.
CREATE OR REPLACE FUNCTION exercises.is_unit_curve(curve numeric[], expected_len int)
RETURNS boolean LANGUAGE sql IMMUTABLE AS $$
  SELECT curve IS NULL OR (
    array_length(curve, 1) = expected_len
    AND NOT EXISTS (SELECT 1 FROM unnest(curve) v WHERE v IS NULL OR v < 0 OR v > 1)
  )
$$;

DO $$ BEGIN
  ALTER TABLE exercises.exercise_biomechanics
    ADD CONSTRAINT exercise_biomechanics_resistance_curve_shape
    CHECK (exercises.is_unit_curve(resistance_curve, 11));
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- ---------------------------------------------------------------------------
-- 2. IMPATTO -- su tutto il catalogo, non solo sui balistici
-- ---------------------------------------------------------------------------
-- Nasce dai pliometrici ma non e' loro: corsa e corda hanno impatto, uno squat
-- no. E' l'unico di questi campi su cui un utente cerca ATTIVAMENTE: ginocchio
-- malandato, vicini di casa, gravidanza. Oggi non c'e' modo di filtrare i salti.
DO $$ BEGIN
  CREATE TYPE exercises.impact_level AS ENUM ('none', 'low', 'moderate', 'high');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

ALTER TABLE exercises.exercise_biomechanics
  ADD COLUMN IF NOT EXISTS impact_level exercises.impact_level;

COMMENT ON COLUMN exercises.exercise_biomechanics.impact_level IS
  'Carico da impatto al suolo. Filtrabile: e'' la domanda "niente salti" degli utenti.';

-- ---------------------------------------------------------------------------
-- 3. LUNGHEZZA DELLA TENUTA -- isometrici e stretch
-- ---------------------------------------------------------------------------
-- Una tenuta non ha una curva lungo la ROM perche' non ha una ROM. Ha pero' un
-- fatto allenante preciso: A QUALE LUNGHEZZA MUSCOLARE avviene. Riusa il
-- vocabolario di `exercise_muscle.tension_*`: per un isometrico esattamente una
-- delle tre regioni e' impegnata, mentre un esercizio dinamico le attraversa
-- tutte. Non e' un'assenza di dato, e' un dato piu' nitido -- ed e' l'unico
-- punto in cui la letteratura gia' citata in `reference_source` (Maeo 2021
-- sugli hamstring a lunghezze lunghe, Wolf 2025 sulle parziali allungate)
-- parla davvero di questo campo.
DO $$ BEGIN
  CREATE TYPE exercises.hold_muscle_length AS ENUM ('lengthened', 'mid', 'shortened');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

ALTER TABLE exercises.exercise_biomechanics
  ADD COLUMN IF NOT EXISTS hold_muscle_length exercises.hold_muscle_length;

COMMENT ON COLUMN exercises.exercise_biomechanics.hold_muscle_length IS
  'Solo per le tenute (tracking_type = time e simili): a quale lunghezza del '
  'muscolo bersaglio avviene la tenuta. NULL per gli esercizi dinamici, che le '
  'attraversano tutte.';

-- ---------------------------------------------------------------------------
-- 4. ORIGINE DELLA LINEA DI RESISTENZA -- sblocca i cavi
-- ---------------------------------------------------------------------------
-- 220 esercizi ai cavi restano senza curva non per ignoranza ma perche' il
-- catalogo non registra da dove arriva il cavo, e quella e' LA variabile che
-- determina la forma. E' un dato di DEFINIZIONE dell'esercizio, non di
-- derivazione: nessun modello puo' dedurlo, va guardato.
DO $$ BEGIN
  CREATE TYPE exercises.resistance_line_origin AS ENUM (
    'low',        -- puleggia bassa / da terra
    'mid',        -- puleggia ad altezza del busto
    'high',       -- puleggia alta (lat machine, pushdown)
    'horizontal', -- linea orizzontale rispetto all'atleta (seated row)
    'vertical'    -- gravita': carichi liberi e corpo libero
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

ALTER TABLE exercises.exercise_biomechanics
  ADD COLUMN IF NOT EXISTS resistance_line_origin exercises.resistance_line_origin;

COMMENT ON COLUMN exercises.exercise_biomechanics.resistance_line_origin IS
  'Da dove arriva la resistenza. Per i cavi determina la curva e senza non e'' '
  'derivabile. ''vertical'' per gravita'' e corpo libero.';

-- Riproiezione: i campi entrano nel payload, quindi lo SHA cambia per tutti.
INSERT INTO exercises.exercise_projection_dirty (exercise_id)
SELECT id FROM exercises.exercise
ON CONFLICT (exercise_id) DO NOTHING;
