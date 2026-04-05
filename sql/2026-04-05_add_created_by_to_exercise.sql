ALTER TABLE exercises.exercise
    ADD COLUMN IF NOT EXISTS created_by UUID;

CREATE INDEX IF NOT EXISTS idx_exercise_created_by_status_name
    ON exercises.exercise (created_by, status, name);

-- Backfill from legacy owner_user_id if available.
UPDATE exercises.exercise
SET created_by = owner_user_id
WHERE created_by IS NULL
  AND owner_user_id IS NOT NULL;

