-- =============================================================
-- Exercise model V2 - kinetic chain + common mistakes
--
-- Requested by the frontend: two facts it needs that the model did not carry.
--
-- 1. kinetic_chain
--    CONVENTION MATTERS HERE, because the two common ones disagree.
--    We use the CLINICAL / biomechanical definition:
--        closed = the distal segment is fixed against a surface or apparatus
--                 and the body moves around it (squat, push-up, pull-up,
--                 leg press, lunge, dip, plank)
--        open   = the distal segment moves freely through space
--                 (leg extension, leg curl, curl, lateral raise, lat pulldown,
--                 bench press, fly)
--    NSCA instead defines closed as "multiple joints against a linear
--    resistance", which would classify the bench press as closed - but that
--    reading is almost a synonym of joint_class = multi_joint, and a field
--    that duplicates another one earns nothing. The clinical definition is
--    orthogonal to joint_class and therefore actually adds information.
--
-- 2. common mistakes
--    Editorial per-locale text, so it lives in the existing translations jsonb
--    under `commonMistakesI18n` (a list of strings per locale, exactly like
--    tips). No new table: normalising free text nobody queries buys nothing.
-- =============================================================

BEGIN;

DO $$ BEGIN
    CREATE TYPE exercises.kinetic_chain AS ENUM ('open', 'closed');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

ALTER TABLE exercises.exercise
    ADD COLUMN IF NOT EXISTS kinetic_chain exercises.kinetic_chain;

CREATE INDEX IF NOT EXISTS idx_exercise_kinetic_chain
    ON exercises.exercise(kinetic_chain);

COMMENT ON COLUMN exercises.exercise.kinetic_chain IS
    'Clinical definition: closed = distal segment fixed against a surface and the body moves around it; open = distal segment free. Deliberately NOT the NSCA reading, which would duplicate joint_class.';

COMMENT ON COLUMN exercises.exercise.translations IS
    'Per-locale jsonb: name, description, tips, safetyNotes, commonMistakes (list of strings).';

-- the view exposes the catalogue, so it has to carry the new column too
DROP VIEW IF EXISTS exercises.v_exercise_active;
CREATE VIEW exercises.v_exercise_active AS
SELECT e.id,
       e.code,
       e.name,
       e.family_id,
       e.exercise_kind,
       e.technical_demand,
       e.joint_class,
       e.kinetic_chain,
       e.unilateral,
       e.bodyweight,
       e.spotter_policy,
       e.catalog_status,
       e.owner_user_id,
       e.visibility,
       e.status,
       e.deleted_at,
       e.translations,
       e.created_at,
       e.updated_at
  FROM exercises.exercise e
 WHERE e.deleted_at IS NULL
   AND e.status = 'active'::exercises.record_status
   AND e.visibility = 'public'::exercises.visibility;

COMMIT;
