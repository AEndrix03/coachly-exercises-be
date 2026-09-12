-- Proiezione del catalogo: il dettaglio di un esercizio come unita' di
-- versionamento, identificata dal contenuto.
--
-- CONTESTO. La V1 versiona le *righe del backend*. Va bene finche' il client
-- conserva riepiloghi, che si costruiscono dalla sola tabella `exercise`. Non
-- va piu' bene ora che il dettaglio smette di essere pigro: il dettaglio nasce
-- da undici tabelle ponte piu' le dimensioni che ci stanno dentro
-- (`muscle.code`, `equipment.code`...), e un delta di righe grezze
-- costringerebbe il client a rifare le join del backend.
--
-- SOLUZIONE. Una proiezione materializzata per esercizio, con il payload che il
-- client consuma e il suo SHA. Lo SHA e' la parte che conta: la versione
-- avanza **solo se il contenuto e' davvero cambiato**, quindi un reimport che
-- riscrive tutto con gli stessi valori non fa scaricare niente a nessuno.
--
-- Additivo e idempotente.

-- ── 1. Le scritture a vuoto non muovono piu' la versione ────────────────────
--
-- Dentro un trigger si hanno OLD e NEW tutti e due sotto mano, quindi il
-- confronto sul contenuto si fa direttamente: non serve memorizzare nessun
-- hash per le righe base. `UPDATE tag SET code = code` smette di produrre un
-- delta.
CREATE OR REPLACE FUNCTION exercises.stamp_catalog_version()
    RETURNS trigger
    LANGUAGE plpgsql
AS
$$
BEGIN
    IF to_jsonb(OLD) - 'row_version' IS NOT DISTINCT FROM to_jsonb(NEW) - 'row_version' THEN
        RETURN NEW;
    END IF;

    NEW.row_version := nextval('exercises.catalog_version');
    RETURN NEW;
END;
$$;

-- ── 2. L'impronta del contenuto ─────────────────────────────────────────────
--
-- Lo SHA si calcola **nel database sul jsonb**, non nel servizio. `jsonb` e'
-- gia' una forma canonica — chiavi ordinate, spazi normalizzati, duplicati
-- rimossi — quindi l'impronta e' una funzione pura del contenuto salvato e non
-- dipende da come la libreria JSON del servizio decide di serializzare. Se un
-- domani qualcuno cambia una configurazione di Jackson, gli SHA non si
-- invalidano tutti insieme.
CREATE OR REPLACE FUNCTION exercises.catalog_sha(payload jsonb)
    RETURNS text
    LANGUAGE sql
    IMMUTABLE
    PARALLEL SAFE
AS
$$
SELECT encode(digest(payload::text, 'sha256'), 'hex')
$$;

-- ── 3. La proiezione ────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS exercises.exercise_projection
(
    exercise_id uuid        NOT NULL PRIMARY KEY,

    -- Esattamente il JSON che il client salva. Non lo interpreta nessuno qui.
    payload     jsonb       NOT NULL,

    -- sha256 del payload. `jsonb` normalizza gia' ordine delle chiavi e spazi,
    -- quindi l'hash e' stabile senza canonicalizzazione scritta a mano.
    sha         text        NOT NULL,

    -- Un esercizio ritirato resta come riga marcata: e' cosi' che il client
    -- viene a sapere che deve rimuoverlo. Senza, se lo terrebbe per sempre.
    deleted     boolean     NOT NULL DEFAULT false,

    row_version bigint      NOT NULL DEFAULT nextval('exercises.catalog_version'),
    updated_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS exercise_projection_version_idx
    ON exercises.exercise_projection (row_version);

-- ── 4. Coda di ricostruzione ────────────────────────────────────────────────
--
-- I trigger non costruiscono il payload: segnano solo *quale* esercizio e'
-- diventato obsoleto. Il payload lo ricostruisce il servizio, perche' e' li'
-- che vive la logica che lo produce — replicarla in SQL sarebbe un secondo
-- posto da cui puo' divergere.
CREATE TABLE IF NOT EXISTS exercises.exercise_projection_dirty
(
    exercise_id uuid        NOT NULL PRIMARY KEY,
    marked_at   timestamptz NOT NULL DEFAULT now()
);

-- La coda si consuma in ordine di marcatura: senza indice, dopo un import
-- massivo ogni giro di ricostruzione ordinerebbe l'intera coda.
CREATE INDEX IF NOT EXISTS exercise_projection_dirty_marked_idx
    ON exercises.exercise_projection_dirty (marked_at);

-- Marca gli esercizi nominati direttamente dalla riga che e' cambiata.
-- Le colonne che contengono l'id arrivano come argomenti del trigger.
CREATE OR REPLACE FUNCTION exercises.mark_projection_dirty()
    RETURNS trigger
    LANGUAGE plpgsql
AS
$$
DECLARE
    touched    jsonb := to_jsonb(COALESCE(NEW, OLD));
    previous   jsonb := CASE WHEN OLD IS NULL THEN NULL ELSE to_jsonb(OLD) END;
    key_column text;
    value      text;
BEGIN
    FOREACH key_column IN ARRAY TG_ARGV
        LOOP
            value := touched ->> key_column;
            IF value IS NOT NULL THEN
                INSERT INTO exercises.exercise_projection_dirty (exercise_id)
                VALUES (value::uuid)
                ON CONFLICT (exercise_id) DO NOTHING;
            END IF;

            -- Un UPDATE che sposta la riga da un esercizio a un altro li rende
            -- obsoleti tutti e due.
            IF previous IS NOT NULL THEN
                value := previous ->> key_column;
                IF value IS NOT NULL THEN
                    INSERT INTO exercises.exercise_projection_dirty (exercise_id)
                    VALUES (value::uuid)
                    ON CONFLICT (exercise_id) DO NOTHING;
                END IF;
            END IF;
        END LOOP;

    RETURN COALESCE(NEW, OLD);
END;
$$;

-- Marca gli esercizi che raggiungono la riga cambiata **attraverso un ponte**.
-- Serve alle tabelle dimensione: cambiare `muscle.code` cambia il dettaglio di
-- ogni esercizio che quel muscolo ce l'ha.
--
-- TG_ARGV: [0] tabella ponte, [1] colonna del ponte che punta alla dimensione,
--          [2] colonna del ponte che punta all'esercizio.
CREATE OR REPLACE FUNCTION exercises.mark_projection_dirty_via_bridge()
    RETURNS trigger
    LANGUAGE plpgsql
AS
$$
DECLARE
    dimension_id uuid := (to_jsonb(COALESCE(NEW, OLD)) ->> 'id')::uuid;
BEGIN
    IF dimension_id IS NULL THEN
        RETURN COALESCE(NEW, OLD);
    END IF;

    EXECUTE format(
            'INSERT INTO exercises.exercise_projection_dirty (exercise_id)
             SELECT %I FROM exercises.%I WHERE %I = $1
             ON CONFLICT (exercise_id) DO NOTHING',
            TG_ARGV[2], TG_ARGV[0], TG_ARGV[1])
        USING dimension_id;

    RETURN COALESCE(NEW, OLD);
END;
$$;

-- ── 5. I trigger di invalidazione ───────────────────────────────────────────
DO
$$
    DECLARE
        direct    record;
        bridged   record;
        trigger_name text;
    BEGIN
        -- Tabelle che nominano l'esercizio direttamente.
        FOR direct IN
            SELECT *
            FROM (VALUES ('exercise', 'id'),
                         ('exercise_biomechanics', 'exercise_id'),
                         ('exercise_category', 'exercise_id'),
                         ('exercise_equipment', 'exercise_id'),
                         ('exercise_joint_action', 'exercise_id'),
                         ('exercise_media', 'exercise_id'),
                         ('exercise_movement_pattern', 'exercise_id'),
                         ('exercise_muscle', 'exercise_id'),
                         ('exercise_reference', 'exercise_id'),
                         ('exercise_tag', 'exercise_id'),
                         ('exercise_tracking_profile', 'exercise_id'),
                         ('exercise_variation', 'base_exercise_id'),
                         ('exercise_variation', 'variant_exercise_id')
                 ) AS t(table_name, id_column)
            LOOP
                trigger_name := direct.table_name || '_dirty_' || direct.id_column;
                EXECUTE format('DROP TRIGGER IF EXISTS %I ON exercises.%I',
                               trigger_name, direct.table_name);
                EXECUTE format(
                        'CREATE TRIGGER %I AFTER INSERT OR UPDATE OR DELETE ON exercises.%I
                         FOR EACH ROW EXECUTE FUNCTION exercises.mark_projection_dirty(%L)',
                        trigger_name, direct.table_name, direct.id_column);
            END LOOP;

        -- Tabelle dimensione, raggiunte attraverso il loro ponte.
        FOR bridged IN
            SELECT *
            FROM (VALUES ('muscle', 'exercise_muscle', 'muscle_id', 'exercise_id'),
                         ('equipment', 'exercise_equipment', 'equipment_id', 'exercise_id'),
                         ('category', 'exercise_category', 'category_id', 'exercise_id'),
                         ('tag', 'exercise_tag', 'tag_id', 'exercise_id'),
                         ('movement_pattern', 'exercise_movement_pattern', 'movement_pattern_id', 'exercise_id'),
                         ('joint_action', 'exercise_joint_action', 'joint_action_id', 'exercise_id'),
                         ('reference_source', 'exercise_reference', 'reference_id', 'exercise_id')
                 ) AS t(dimension_table, bridge_table, bridge_fk, bridge_exercise)
            LOOP
                trigger_name := bridged.dimension_table || '_dirty_via_bridge';
                EXECUTE format('DROP TRIGGER IF EXISTS %I ON exercises.%I',
                               trigger_name, bridged.dimension_table);
                EXECUTE format(
                        'CREATE TRIGGER %I AFTER INSERT OR UPDATE OR DELETE ON exercises.%I
                         FOR EACH ROW EXECUTE FUNCTION exercises.mark_projection_dirty_via_bridge(%L, %L, %L)',
                        trigger_name, bridged.dimension_table,
                        bridged.bridge_table, bridged.bridge_fk, bridged.bridge_exercise);
            END LOOP;
    END
$$;

-- ── 6. Indici mancanti per l'invalidazione ──────────────────────────────────
--
-- I ponti sono gia' indicizzati su entrambi i lati, tranne questo: senza,
-- toccare una fonte bibliografica scandirebbe l'intera tabella dei riferimenti
-- per scoprire quali esercizi invalidare.
CREATE INDEX IF NOT EXISTS idx_exercise_reference_reference
    ON exercises.exercise_reference (reference_id);

-- ── 7. Primo popolamento ────────────────────────────────────────────────────
-- Tutti gli esercizi esistenti risultano da ricostruire: al primo giro il
-- servizio li proietta e da li' in avanti si muove solo cio' che cambia.
INSERT INTO exercises.exercise_projection_dirty (exercise_id)
SELECT id FROM exercises.exercise
ON CONFLICT (exercise_id) DO NOTHING;
