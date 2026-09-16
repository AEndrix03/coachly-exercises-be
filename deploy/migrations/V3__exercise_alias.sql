-- Alias strutturati per la ricerca: come gli utenti chiamano davvero un
-- esercizio in palestra, distinti dal nome canonico (`exercise.name` /
-- `exercise.translations`).
--
-- Vedi EXERCISE_SEARCH_PERSONAL_VOCABULARY_PLAN.md §6.1 e
-- EXERCISE_SEARCH_PLAN_CONTINUE.txt §36-38 per la specifica.
--
-- Non ancora applicata: puo' essere corretta liberamente, senza passare da
-- un ALTER TYPE su dati vivi.

-- Tre tipi bastano in P0 (§6.1): TRANSLATION non serve perche' la traduzione
-- e' gia' il nome canonico nell'altra locale; LEGACY_NAME, ALTERNATIVE_NAME e
-- GYM_SLANG collassano su common_name perche' nessuna regola di ranking o di
-- display li tratta diversamente (se un domani servira' penalizzare lo slang,
-- lo fa `weight`, che si tara).
DO
$$
    BEGIN
        CREATE TYPE exercises.alias_type AS ENUM (
            'common_name',        -- "Pulley", "Lat Machine": come lo chiamano in palestra
            'abbreviation',       -- "RDL", "OHP"
            'brand_machine_name', -- "Technogym Low Row": il marchio del macchinario, non il gesto
            'machine_name'        -- "Lat Machine" quando il nome del macchinario e' usato
                                   -- per indicare l'esercizio stesso (non un marchio)
            );
    EXCEPTION
        WHEN duplicate_object THEN NULL;
    END
$$;

-- 'merged' oltre ad 'active'/'deprecated': un alias che viene assorbito da un
-- altro (duplicato editoriale, refuso corretto) punta a `replaced_by_id` e non
-- deve piu' comparire come alias a se stante, ma la riga resta per non
-- rompere chi la referenzia (es. una preferenza personale).
DO
$$
    BEGIN
        CREATE TYPE exercises.alias_status AS ENUM ('active', 'deprecated', 'merged');
    EXCEPTION
        WHEN duplicate_object THEN NULL;
    END
$$;

CREATE OR REPLACE FUNCTION exercises.normalize_alias(value text)
    RETURNS text
    LANGUAGE sql
    IMMUTABLE
    STRICT
    PARALLEL SAFE
AS
$$
SELECT trim(regexp_replace(
        translate(lower(value), 'àáâãäåèéêëìíîïòóôõöùúûü', 'aaaaaaeeeeiiiiooooouuuu'),
        '[^[:alnum:]]+', ' ', 'g'))
$$;

CREATE TABLE IF NOT EXISTS exercises.exercise_alias
(
    id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    exercise_id      uuid                        NOT NULL REFERENCES exercises.exercise (id),
    locale           varchar(8)                  NOT NULL CHECK (locale IN ('it', 'en')),
    label            varchar(160)                NOT NULL CHECK (length(trim(label)) > 0),
    normalized_label varchar(160) GENERATED ALWAYS AS (exercises.normalize_alias(label)) STORED,
    alias_type       exercises.alias_type         NOT NULL,
    weight           smallint                    NOT NULL DEFAULT 100 CHECK (weight BETWEEN 0 AND 100),
    status           exercises.alias_status       NOT NULL DEFAULT 'active',
    replaced_by_id   uuid REFERENCES exercises.exercise_alias (id),
    -- Traccia il target del CSV che ha generato questa riga tramite l'importer
    -- (`inj/_tools/import_aliases.py`), es. 'family:cable_row' o
    -- 'category:core'. NULL per le righe inserite a mano o per import di tipo
    -- 'exercise:<code>' che generano sempre una sola riga.
    --
    -- Serve a rendere le espansioni family:/category: idempotenti: una
    -- ri-esecuzione dello stesso target deve poter ritrovare (e aggiornare o
    -- rimuovere) esattamente le righe che aveva generato lei, anche quando la
    -- famiglia/categoria nel frattempo ha guadagnato o perso esercizi, senza
    -- toccare le righe scritte a mano (source_target NULL) o generate da un
    -- altro target.
    source_target    varchar(200),
    row_version      bigint                      NOT NULL DEFAULT 0,
    created_at       timestamptz                 NOT NULL DEFAULT now(),
    updated_at       timestamptz                 NOT NULL DEFAULT now(),
    UNIQUE (exercise_id, locale, normalized_label)
);

-- `locale` e' la PROVENIENZA del termine (in che lingua e' nato l'alias), non
-- il pubblico a cui e' rivolto. Un utente italiano che cerca "bench press"
-- deve trovare l'esercizio anche se quell'alias ha locale 'en': la ricerca
-- non deve MAI filtrare per locale. Chi in futuro sara' tentato di aggiungere
-- `WHERE locale = :userLocale` a una query di ricerca, legga questo commento
-- prima.
COMMENT ON COLUMN exercises.exercise_alias.locale IS
    'Provenienza linguistica del termine (in che lingua e'' stato scritto), NON il pubblico a cui e'' rivolto. '
    'La ricerca non deve filtrare per questa colonna: un utente italiano che cerca "bench press" deve trovare '
    'l''esercizio anche se l''alias ha locale ''en''.';

COMMENT ON COLUMN exercises.exercise_alias.source_target IS
    'Target del CSV importato da inj/_tools/import_aliases.py che ha generato questa riga '
    '(''exercise:<code>'', ''family:<code>'' o ''category:<code>''). NULL per le righe inserite a mano: '
    'l''importer non le tocca mai. Permette a una ri-esecuzione dello stesso target di aggiornare/rimuovere '
    'solo le righe che aveva generato lui, anche se la famiglia o la categoria e'' cambiata nel frattempo.';

CREATE INDEX IF NOT EXISTS exercise_alias_lookup_idx
    ON exercises.exercise_alias (locale, normalized_label, status);
CREATE INDEX IF NOT EXISTS exercise_alias_exercise_idx
    ON exercises.exercise_alias (exercise_id);
CREATE INDEX IF NOT EXISTS exercise_alias_source_target_idx
    ON exercises.exercise_alias (source_target)
    WHERE source_target IS NOT NULL;

DROP TRIGGER IF EXISTS exercise_alias_dirty_exercise_id ON exercises.exercise_alias;
CREATE TRIGGER exercise_alias_dirty_exercise_id
    AFTER INSERT OR UPDATE OR DELETE
    ON exercises.exercise_alias
    FOR EACH ROW
EXECUTE FUNCTION exercises.mark_projection_dirty('exercise_id');
