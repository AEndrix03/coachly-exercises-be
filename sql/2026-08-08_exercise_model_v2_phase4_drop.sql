-- =============================================================
-- Exercise model V2 — PHASE 4: drop the superseded columns
--
-- DO NOT RUN until every consumer (exercises BE + lib, and any other
-- service reading the exercises schema) has moved to the V2 model.
-- Running this while the current BE is deployed WILL break it: the
-- deployed ExerciseBiomechanics entity still maps resistance_curve,
-- peak_torque_rom_pct, moment_arm_*, sfr_rating, joint_position_bias,
-- strength_curve_points and data_confidence.
--
-- Preconditions checked below; the script aborts if the V2 backfill is
-- incomplete, so a half-migrated catalogue cannot silently lose data.
-- =============================================================

BEGIN;

-- ---------- preconditions ----------
DO $$
DECLARE
    missing_code      BIGINT;
    missing_kind      BIGINT;
    missing_tracking  BIGINT;
    missing_tension   BIGINT;
    missing_spinal    BIGINT;
BEGIN
    SELECT count(*) INTO missing_code
      FROM exercises.exercise WHERE deleted_at IS NULL AND code IS NULL;
    SELECT count(*) INTO missing_kind
      FROM exercises.exercise WHERE deleted_at IS NULL AND exercise_kind IS NULL;

    SELECT count(*) INTO missing_tracking
      FROM exercises.exercise e
      LEFT JOIN exercises.exercise_tracking_profile t ON t.exercise_id = e.id
     WHERE e.deleted_at IS NULL AND t.exercise_id IS NULL;

    -- every PRIMARY muscle must carry a tension profile
    SELECT count(*) INTO missing_tension
      FROM exercises.exercise_muscle
     WHERE involvement = 'primary'
       AND (tension_lengthened IS NULL OR tension_midrange IS NULL
            OR tension_shortened IS NULL OR evidence_basis IS NULL
            OR confidence IS NULL);

    SELECT count(*) INTO missing_spinal
      FROM exercises.exercise_biomechanics WHERE spinal_loading IS NULL;

    IF missing_code > 0 OR missing_kind > 0 OR missing_tracking > 0
       OR missing_tension > 0 OR missing_spinal > 0 THEN
        RAISE EXCEPTION
            'V2 backfill incomplete - refusing to drop. missing: code=%, kind=%, tracking=%, primary muscle tension=%, spinal_loading=%',
            missing_code, missing_kind, missing_tracking, missing_tension, missing_spinal;
    END IF;
END $$;

-- ---------- dependent view ----------
-- v_exercise_active selects difficulty, mechanics, force, overall_risk and
-- spotter_required, so the drops below fail unless it is rebuilt first.
DROP VIEW IF EXISTS exercises.v_exercise_active;

-- ---------- exercise ----------
-- superseded by movement patterns + joint actions
ALTER TABLE exercises.exercise DROP COLUMN IF EXISTS force;
-- 72% of the catalogue was 'medium': near-zero information, and it implied a
-- precision that does not exist. Safety notes stay in translations.
ALTER TABLE exercises.exercise DROP COLUMN IF EXISTS overall_risk;
-- replaced by technical_demand / joint_class / spotter_policy
ALTER TABLE exercises.exercise DROP COLUMN IF EXISTS difficulty;
ALTER TABLE exercises.exercise DROP COLUMN IF EXISTS mechanics;
ALTER TABLE exercises.exercise DROP COLUMN IF EXISTS spotter_required;

-- now that every row has one, lock the identity key down
ALTER TABLE exercises.exercise ALTER COLUMN code SET NOT NULL;
ALTER TABLE exercises.exercise ALTER COLUMN exercise_kind SET NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS idx_exercise_code ON exercises.exercise(code);

-- ---------- exercise_muscle ----------
-- invented precision: no basis for "chest 87%"
ALTER TABLE exercises.exercise_muscle DROP COLUMN IF EXISTS activation_percentage;
-- derivable from the three tension levels
ALTER TABLE exercises.exercise_muscle DROP COLUMN IF EXISTS length_bias;
ALTER TABLE exercises.exercise_muscle DROP COLUMN IF EXISTS rom_stretch_pct;
ALTER TABLE exercises.exercise_muscle DROP COLUMN IF EXISTS rom_contract_pct;
ALTER TABLE exercises.exercise_muscle DROP COLUMN IF EXISTS tension_at_stretch;
ALTER TABLE exercises.exercise_muscle DROP COLUMN IF EXISTS tension_at_contraction;
-- real concepts, but no decision in Coachly depends on them
ALTER TABLE exercises.exercise_muscle DROP COLUMN IF EXISTS active_insufficiency;
ALTER TABLE exercises.exercise_muscle DROP COLUMN IF EXISTS passive_insufficiency;

-- ---------- exercise_biomechanics ----------
-- the implement's curve is not the muscle's tension curve; the latter now
-- lives per-muscle in exercise_muscle
ALTER TABLE exercises.exercise_biomechanics DROP COLUMN IF EXISTS resistance_curve;
ALTER TABLE exercises.exercise_biomechanics DROP COLUMN IF EXISTS peak_torque_rom_pct;
ALTER TABLE exercises.exercise_biomechanics DROP COLUMN IF EXISTS moment_arm_profile;
ALTER TABLE exercises.exercise_biomechanics DROP COLUMN IF EXISTS moment_arm_peak_rom_pct;
-- SFR is contextual output, not a catalogue property
ALTER TABLE exercises.exercise_biomechanics DROP COLUMN IF EXISTS sfr_rating;
-- redundant once joint actions and per-muscle tension exist
ALTER TABLE exercises.exercise_biomechanics DROP COLUMN IF EXISTS joint_position_bias;
-- derived data must not be persisted: it goes stale silently
ALTER TABLE exercises.exercise_biomechanics DROP COLUMN IF EXISTS strength_curve_points;
-- replaced by the evidence_basis / confidence pair
ALTER TABLE exercises.exercise_biomechanics DROP COLUMN IF EXISTS data_confidence;
ALTER TABLE exercises.exercise_biomechanics DROP COLUMN IF EXISTS source_note;
ALTER TABLE exercises.exercise_biomechanics RENAME COLUMN axial_load TO axial_load_legacy;
ALTER TABLE exercises.exercise_biomechanics DROP COLUMN IF EXISTS axial_load_legacy;

-- ---------- exercise_variation ----------
-- "harder" says nothing useful; the axis of variation does
ALTER TABLE exercises.exercise_variation DROP COLUMN IF EXISTS difficulty_delta;
-- 'default' on all 908 rows
ALTER TABLE exercises.exercise_variation DROP COLUMN IF EXISTS variation_type;

-- The table never had a primary key: variation_type was only part of the JPA
-- composite id, with nothing enforcing it in the database. An edge is
-- identified by its two endpoints, so declare that properly.
ALTER TABLE exercises.exercise_variation
    ADD CONSTRAINT exercise_variation_pkey
    PRIMARY KEY (base_exercise_id, variant_exercise_id);

-- ---------- enum types are deliberately NOT dropped ----------
-- risk_level, force_type, difficulty_level and mechanics_type are still used
-- by the exercises_staging schema, which is a separate populated ingestion
-- area (2551 rows) outside this migration's scope. DROP TYPE ... CASCADE
-- would silently strip columns there, so the now-unused types are simply left
-- in place: they cost nothing and can be removed once staging is migrated too.
--
-- The ones only this schema ever used could go, but keeping the whole set
-- together makes the remaining cleanup a single, obvious follow-up:
--   resistance_curve, moment_arm_profile, length_bias, data_confidence,
--   risk_level, force_type, difficulty_level, mechanics_type

-- ---------- rebuild the view on the V2 shape ----------
CREATE VIEW exercises.v_exercise_active AS
SELECT e.id,
       e.code,
       e.name,
       e.family_id,
       e.exercise_kind,
       e.technical_demand,
       e.joint_class,
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
