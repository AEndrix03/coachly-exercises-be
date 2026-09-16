-- Due colonne su `exercises.exercise`:
--
--   1. `data_exclusions` - mappa campo -> motivazione testuale del perche' quel
--      campo e' legittimamente vuoto per quell'esercizio (es. l'attrezzatura
--      non richiesta per un movimento a corpo libero). Senza, un campo vuoto e
--      un campo dimenticato sono indistinguibili in fase di editoriale.
--   2. `ranking_tier` - dove l'esercizio sta nella distribuzione d'uso reale,
--      indipendente dalla qualita' editoriale gia' coperta da `catalog_status`.
--
-- Additivo e idempotente: le colonne aggiunte alla tabella `exercise` sono gia'
-- coperte dai trigger generici di V1 (stamp_catalog_version) e V2
-- (mark_projection_dirty su 'exercise','id'), quindi non serve toccare nessun
-- trigger qui.

DO $$ BEGIN
  CREATE TYPE exercises.ranking_tier AS ENUM ('core', 'common', 'standard', 'niche', 'specialized');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

ALTER TABLE exercises.exercise
  ADD COLUMN IF NOT EXISTS data_exclusions jsonb NOT NULL DEFAULT '{}'::jsonb;

ALTER TABLE exercises.exercise
  ADD COLUMN IF NOT EXISTS ranking_tier exercises.ranking_tier NOT NULL DEFAULT 'standard';

-- Il payload di proiezione guadagna due campi: lo SHA di ogni esercizio
-- esistente cambia al prossimo giro di ricostruzione, ed e' atteso - il
-- contenuto e' davvero diverso. Si marcano tutti gli esercizi come da
-- ricostruire cosi' la proiezione si allinea subito, invece di aspettare la
-- prossima scrittura casuale su ciascuno.
INSERT INTO exercises.exercise_projection_dirty (exercise_id)
SELECT id FROM exercises.exercise
ON CONFLICT (exercise_id) DO NOTHING;
