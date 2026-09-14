DO $$ BEGIN
  CREATE TYPE exercises.alias_type AS ENUM ('common_name', 'abbreviation', 'slang', 'legacy_name');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  CREATE TYPE exercises.alias_status AS ENUM ('active', 'deprecated');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

CREATE OR REPLACE FUNCTION exercises.normalize_alias(value text)
RETURNS text LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE AS $$
  SELECT trim(regexp_replace(
    translate(lower(value), 'àáâãäåèéêëìíîïòóôõöùúûü', 'aaaaaaeeeeiiiiooooouuuu'),
    '[^[:alnum:]]+', ' ', 'g'))
$$;

CREATE TABLE IF NOT EXISTS exercises.exercise_alias (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  exercise_id uuid NOT NULL REFERENCES exercises.exercise(id),
  locale varchar(8) NOT NULL CHECK (locale IN ('it', 'en')),
  label varchar(160) NOT NULL CHECK (length(trim(label)) > 0),
  normalized_label varchar(160) GENERATED ALWAYS AS (exercises.normalize_alias(label)) STORED,
  alias_type exercises.alias_type NOT NULL,
  weight smallint NOT NULL DEFAULT 100 CHECK (weight BETWEEN 0 AND 100),
  status exercises.alias_status NOT NULL DEFAULT 'active',
  replaced_by_id uuid REFERENCES exercises.exercise_alias(id),
  row_version bigint NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (exercise_id, locale, normalized_label)
);

CREATE INDEX IF NOT EXISTS exercise_alias_lookup_idx
  ON exercises.exercise_alias (locale, normalized_label, status);
CREATE INDEX IF NOT EXISTS exercise_alias_exercise_idx
  ON exercises.exercise_alias (exercise_id);

DROP TRIGGER IF EXISTS exercise_alias_dirty_exercise_id ON exercises.exercise_alias;
CREATE TRIGGER exercise_alias_dirty_exercise_id
AFTER INSERT OR UPDATE OR DELETE ON exercises.exercise_alias
FOR EACH ROW EXECUTE FUNCTION exercises.mark_projection_dirty('exercise_id');
