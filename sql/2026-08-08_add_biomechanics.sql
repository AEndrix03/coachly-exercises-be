-- =============================================================
-- Biomechanics enrichment
-- Adds resistance-curve / moment-arm / muscle-length metadata
-- to the exercises schema.
--
-- Convention for resistance_curve (CSCS / Beardsley, consistent):
--   ascending  = hardest at the START of the concentric (stretched
--                position). Low peak_torque_rom_pct.  e.g. squat, preacher curl
--   descending = hardest at the END of the concentric (shortened
--                position). High peak_torque_rom_pct.  e.g. lateral raise, spider curl
--   bell       = hardest mid-range.                    e.g. standing barbell curl
--   flat       = evenly loaded throughout.             e.g. many cam machines
--
-- rom_pct is normalised: 0 = target muscle at maximum length,
--                        100 = target muscle at maximum shortening.
-- =============================================================

BEGIN;

-- ---------- enums ----------
DO $$ BEGIN
    CREATE TYPE exercises.resistance_curve AS ENUM ('ascending','descending','bell','flat');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE exercises.length_bias AS ENUM ('lengthened','mid_range','shortened');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE exercises.moment_arm_profile AS ENUM ('constant','increasing','decreasing','bell');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE exercises.resistance_source AS ENUM
        ('gravity','cable','band','cam_machine','bodyweight_leverage','hydraulic','isometric_external');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE exercises.load_level AS ENUM ('none','low','moderate','high');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    -- measured  = from published EMG / dynamometry data
    -- curated   = hand-authored from the biomechanics literature
    -- modeled   = derived from the movement archetype
    -- estimated = best guess, low confidence (do not present as fact in the UI)
    CREATE TYPE exercises.data_confidence AS ENUM
        ('measured','curated','modeled','estimated');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ---------- exercise-level biomechanics ----------
CREATE TABLE IF NOT EXISTS exercises.exercise_biomechanics (
    exercise_id             UUID PRIMARY KEY
                            REFERENCES exercises.exercise(id) ON DELETE CASCADE,

    -- external resistance profile
    resistance_source       exercises.resistance_source,
    resistance_curve        exercises.resistance_curve,
    peak_torque_rom_pct     SMALLINT CHECK (peak_torque_rom_pct BETWEEN 0 AND 100),

    -- external moment arm (the physical cause of the curve above)
    moment_arm_profile      exercises.moment_arm_profile,
    moment_arm_peak_rom_pct SMALLINT CHECK (moment_arm_peak_rom_pct BETWEEN 0 AND 100),

    -- programming-relevant demands
    stability_demand        exercises.load_level,
    axial_load              exercises.load_level,
    sfr_rating              SMALLINT CHECK (sfr_rating BETWEEN 1 AND 5),

    -- position of the NON-mobilised joints, drives bi-articular pre-stretch
    -- e.g. {"shoulder":"extension"} for a Bayesian curl
    joint_position_bias     JSONB,

    -- the graph: [{"rom_pct":0,"relative_load":85}, ...] 0..100 both axes
    strength_curve_points   JSONB,

    data_confidence         exercises.data_confidence NOT NULL DEFAULT 'estimated',
    source_note             TEXT,

    created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ex_biomech_curve
    ON exercises.exercise_biomechanics(resistance_curve);
CREATE INDEX IF NOT EXISTS idx_ex_biomech_source
    ON exercises.exercise_biomechanics(resistance_source);

-- ---------- per exercise x muscle: where the tension actually lands ----------
ALTER TABLE exercises.exercise_muscle
    ADD COLUMN IF NOT EXISTS length_bias            exercises.length_bias,
    ADD COLUMN IF NOT EXISTS rom_stretch_pct        SMALLINT CHECK (rom_stretch_pct BETWEEN 0 AND 100),
    ADD COLUMN IF NOT EXISTS rom_contract_pct       SMALLINT CHECK (rom_contract_pct BETWEEN 0 AND 100),
    ADD COLUMN IF NOT EXISTS tension_at_stretch     SMALLINT CHECK (tension_at_stretch BETWEEN 0 AND 100),
    ADD COLUMN IF NOT EXISTS tension_at_contraction SMALLINT CHECK (tension_at_contraction BETWEEN 0 AND 100),
    ADD COLUMN IF NOT EXISTS active_insufficiency   BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS passive_insufficiency  BOOLEAN NOT NULL DEFAULT FALSE;

CREATE INDEX IF NOT EXISTS idx_ex_muscle_length_bias
    ON exercises.exercise_muscle(length_bias);

COMMENT ON COLUMN exercises.exercise_muscle.length_bias IS
    'Where peak tension falls relative to THIS muscle''s length: lengthened / mid_range / shortened';
COMMENT ON COLUMN exercises.exercise_muscle.tension_at_stretch IS
    'Residual external load (0-100) at maximum muscle length. Distinguishes "reaches the stretch" from "loads the stretch".';

COMMIT;
