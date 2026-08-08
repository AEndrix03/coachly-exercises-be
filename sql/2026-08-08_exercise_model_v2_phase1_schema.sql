-- =============================================================
-- Exercise model V2 — PHASE 1: schema (additive only)
--
-- Builds the new model alongside the old one. Nothing is dropped here:
-- the currently deployed backend still reads the legacy biomechanics
-- columns. Drops live in 2026-08-08_exercise_model_v2_phase4_drop.sql and
-- must run only after the BE/lib no longer reference them.
--
-- Guiding rule: a fact about an exercise stays in the DB only if it helps
-- Coachly search, compare, substitute, program, log or explain it.
-- Contextual outputs (SFR, scores, recommended sets) do NOT belong here.
--
-- exercise.code is created NULLABLE here on purpose: 8 exercise names are
-- currently duplicated, so UNIQUE NOT NULL can only be enforced after the
-- phase 2 backfill deduplicates them.
-- =============================================================

BEGIN;

-- =============================================================
-- 1. ENUMS
-- =============================================================
DO $$ BEGIN CREATE TYPE exercises.exercise_kind AS ENUM
    ('resistance','mobility','conditioning');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN CREATE TYPE exercises.technical_demand AS ENUM
    ('low','moderate','high');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN CREATE TYPE exercises.joint_class AS ENUM
    ('single_joint','multi_joint');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN CREATE TYPE exercises.spotter_policy AS ENUM
    ('none','recommended_high_effort','recommended');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN CREATE TYPE exercises.catalog_status AS ENUM
    ('draft','standard','verified');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- role of a movement pattern / joint action within one exercise
DO $$ BEGIN CREATE TYPE exercises.contribution_role AS ENUM
    ('primary','secondary');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- qualitative tension a muscle receives at a given length
DO $$ BEGIN CREATE TYPE exercises.tension_level AS ENUM
    ('none','low','moderate','high');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- WHERE a datum comes from (origin), kept separate from HOW SURE we are
DO $$ BEGIN CREATE TYPE exercises.evidence_basis AS ENUM
    ('measured','literature','biomechanical_model','expert_curated','heuristic');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN CREATE TYPE exercises.confidence_level AS ENUM
    ('low','moderate','high');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN CREATE TYPE exercises.muscle_group_type AS ENUM
    ('anatomical','functional');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN CREATE TYPE exercises.equipment_class AS ENUM
    ('free_weight','selectorized_machine','plate_loaded_machine','cable',
     'bodyweight','elastic','fixed_implement','other');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN CREATE TYPE exercises.variation_axis AS ENUM
    ('equipment','grip','stance','angle','unilateral','rom','resistance',
     'technique','tempo','assistance');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- how a set of this exercise is recorded
DO $$ BEGIN CREATE TYPE exercises.tracking_type AS ENUM
    ('weight_reps','reps','bodyweight_reps','bodyweight_plus_weight',
     'assisted_bodyweight','time','distance','weight_time','weight_distance');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- Coachly convention: PER_IMPLEMENT means the logged number is the load of a
-- SINGLE implement (a 32 kg dumbbell curl is logged as 32, not 64).
DO $$ BEGIN CREATE TYPE exercises.load_input_mode AS ENUM
    ('none','total_load','per_implement','per_side','added_weight','assistance');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN CREATE TYPE exercises.side_mode AS ENUM
    ('none','optional','separate');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- how far a logged load can legitimately be compared
DO $$ BEGIN CREATE TYPE exercises.comparison_scope AS ENUM
    ('exercise','equipment_instance','bodyweight_aware','non_comparable');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- P1, optional: coarse shape of the EXTERNAL resistance (not muscle tension)
DO $$ BEGIN CREATE TYPE exercises.external_resistance_profile AS ENUM
    ('early_rom','mid_rom','late_rom','even','variable');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN CREATE TYPE exercises.reference_scope AS ENUM
    ('muscle','biomechanics','execution','safety','general');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN CREATE TYPE exercises.reference_source_type AS ENUM
    ('journal_article','systematic_review','meta_analysis','textbook',
     'expert_opinion','dataset','other');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- =============================================================
-- 2. EXERCISE FAMILY
--    Groups exercises that are the "same lift" done differently.
--    Barbell/Dumbbell/Smith Bench share a family; Bench and Cable Fly do not.
-- =============================================================
CREATE TABLE IF NOT EXISTS exercises.exercise_family (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code          VARCHAR(80) NOT NULL UNIQUE,
    translations  JSONB NOT NULL DEFAULT '{}'::jsonb,
    status        exercises.record_status NOT NULL DEFAULT 'active',
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================
-- 3. MOVEMENT PATTERN
-- =============================================================
CREATE TABLE IF NOT EXISTS exercises.movement_pattern (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code          VARCHAR(60) NOT NULL UNIQUE,
    parent_id     UUID REFERENCES exercises.movement_pattern(id) ON DELETE SET NULL,
    translations  JSONB NOT NULL DEFAULT '{}'::jsonb,
    display_order INTEGER NOT NULL DEFAULT 0,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS exercises.exercise_movement_pattern (
    exercise_id         UUID NOT NULL REFERENCES exercises.exercise(id) ON DELETE CASCADE,
    movement_pattern_id UUID NOT NULL REFERENCES exercises.movement_pattern(id) ON DELETE CASCADE,
    role                exercises.contribution_role NOT NULL,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (exercise_id, movement_pattern_id)
);
CREATE INDEX IF NOT EXISTS idx_ex_movement_pattern_pattern
    ON exercises.exercise_movement_pattern(movement_pattern_id, role);

-- =============================================================
-- 4. JOINT ACTION
--    Replaces exercise.force with something actually usable:
--    Bench = shoulder horizontal_adduction + elbow extension.
-- =============================================================
CREATE TABLE IF NOT EXISTS exercises.joint_action (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    joint_code    VARCHAR(40) NOT NULL,
    action_code   VARCHAR(40) NOT NULL,
    translations  JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (joint_code, action_code)
);

CREATE TABLE IF NOT EXISTS exercises.exercise_joint_action (
    exercise_id     UUID NOT NULL REFERENCES exercises.exercise(id) ON DELETE CASCADE,
    joint_action_id UUID NOT NULL REFERENCES exercises.joint_action(id) ON DELETE CASCADE,
    role            exercises.contribution_role NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (exercise_id, joint_action_id)
);
CREATE INDEX IF NOT EXISTS idx_ex_joint_action_action
    ON exercises.exercise_joint_action(joint_action_id, role);

-- =============================================================
-- 5. MUSCLE GROUPS
--    Moves the grouping taxonomy out of generator code into the DB.
--    muscle.group_code already carries 11 anatomical groups; phase 2
--    normalises it into these tables.
-- =============================================================
CREATE TABLE IF NOT EXISTS exercises.muscle_group (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code          VARCHAR(60) NOT NULL UNIQUE,
    group_type    exercises.muscle_group_type NOT NULL,
    translations  JSONB NOT NULL DEFAULT '{}'::jsonb,
    display_order INTEGER NOT NULL DEFAULT 0,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS exercises.muscle_group_member (
    group_id   UUID NOT NULL REFERENCES exercises.muscle_group(id) ON DELETE CASCADE,
    muscle_id  UUID NOT NULL REFERENCES exercises.muscle(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (group_id, muscle_id)
);
CREATE INDEX IF NOT EXISTS idx_muscle_group_member_muscle
    ON exercises.muscle_group_member(muscle_id);

-- =============================================================
-- 6. TRACKING PROFILE
--    Tells the client which logger to build and how far a load may be
--    compared across gyms and across bodyweight changes.
-- =============================================================
CREATE TABLE IF NOT EXISTS exercises.exercise_tracking_profile (
    exercise_id      UUID PRIMARY KEY REFERENCES exercises.exercise(id) ON DELETE CASCADE,
    tracking_type    exercises.tracking_type NOT NULL,
    load_input_mode  exercises.load_input_mode NOT NULL,
    side_mode        exercises.side_mode NOT NULL,
    comparison_scope exercises.comparison_scope NOT NULL,
    evidence_basis   exercises.evidence_basis,
    confidence       exercises.confidence_level,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_tracking_profile_type
    ON exercises.exercise_tracking_profile(tracking_type);

COMMENT ON COLUMN exercises.exercise_tracking_profile.load_input_mode IS
    'Coachly convention: per_implement means the logged value is the load of a SINGLE implement (32 kg dumbbell curl is logged as 32, not 64).';

-- =============================================================
-- 7. PROVENANCE
-- =============================================================
CREATE TABLE IF NOT EXISTS exercises.reference_source (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title       TEXT NOT NULL,
    authors     TEXT,
    year        SMALLINT,
    doi         VARCHAR(120),
    url         TEXT,
    source_type exercises.reference_source_type NOT NULL DEFAULT 'journal_article',
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE UNIQUE INDEX IF NOT EXISTS idx_reference_source_doi
    ON exercises.reference_source(doi) WHERE doi IS NOT NULL;

CREATE TABLE IF NOT EXISTS exercises.exercise_reference (
    exercise_id  UUID NOT NULL REFERENCES exercises.exercise(id) ON DELETE CASCADE,
    reference_id UUID NOT NULL REFERENCES exercises.reference_source(id) ON DELETE CASCADE,
    scope        exercises.reference_scope NOT NULL,
    note         TEXT,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (exercise_id, reference_id, scope)
);

-- =============================================================
-- 8. EXERCISE: new columns
-- =============================================================
ALTER TABLE exercises.exercise
    -- nullable for now: 8 duplicate names must be resolved in phase 2
    -- before UNIQUE NOT NULL can be enforced
    ADD COLUMN IF NOT EXISTS code             VARCHAR(120),
    ADD COLUMN IF NOT EXISTS family_id        UUID REFERENCES exercises.exercise_family(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS exercise_kind    exercises.exercise_kind,
    ADD COLUMN IF NOT EXISTS technical_demand exercises.technical_demand,
    ADD COLUMN IF NOT EXISTS joint_class      exercises.joint_class,
    ADD COLUMN IF NOT EXISTS spotter_policy   exercises.spotter_policy,
    ADD COLUMN IF NOT EXISTS catalog_status   exercises.catalog_status NOT NULL DEFAULT 'standard';

CREATE INDEX IF NOT EXISTS idx_exercise_family     ON exercises.exercise(family_id);
CREATE INDEX IF NOT EXISTS idx_exercise_kind       ON exercises.exercise(exercise_kind);
CREATE INDEX IF NOT EXISTS idx_exercise_joint_class ON exercises.exercise(joint_class);

-- =============================================================
-- 9. EXERCISE_MUSCLE: qualitative tension profile + provenance
--    Replaces activation_percentage / length_bias / rom_* / tension_at_*
--    with three qualitative levels. length_bias becomes derivable.
-- =============================================================
ALTER TABLE exercises.exercise_muscle
    ADD COLUMN IF NOT EXISTS tension_lengthened exercises.tension_level,
    ADD COLUMN IF NOT EXISTS tension_midrange   exercises.tension_level,
    ADD COLUMN IF NOT EXISTS tension_shortened  exercises.tension_level,
    ADD COLUMN IF NOT EXISTS evidence_basis     exercises.evidence_basis,
    ADD COLUMN IF NOT EXISTS confidence         exercises.confidence_level,
    ADD COLUMN IF NOT EXISTS updated_at         TIMESTAMPTZ NOT NULL DEFAULT NOW();

CREATE INDEX IF NOT EXISTS idx_ex_muscle_tension_lengthened
    ON exercises.exercise_muscle(tension_lengthened)
    WHERE tension_lengthened IS NOT NULL;

-- =============================================================
-- 10. EXERCISE_BIOMECHANICS: new slimmed columns
--     Legacy columns stay until phase 4.
-- =============================================================
ALTER TABLE exercises.exercise_biomechanics
    ADD COLUMN IF NOT EXISTS spinal_loading exercises.load_level,
    ADD COLUMN IF NOT EXISTS external_resistance_profile exercises.external_resistance_profile,
    ADD COLUMN IF NOT EXISTS evidence_basis exercises.evidence_basis,
    ADD COLUMN IF NOT EXISTS confidence     exercises.confidence_level,
    ADD COLUMN IF NOT EXISTS method_note    TEXT;

-- =============================================================
-- 11. EQUIPMENT: class
-- =============================================================
ALTER TABLE exercises.equipment
    ADD COLUMN IF NOT EXISTS equipment_class exercises.equipment_class;
CREATE INDEX IF NOT EXISTS idx_equipment_class ON exercises.equipment(equipment_class);

-- =============================================================
-- 12. VARIATION: axis replaces difficulty_delta
--     difficulty_delta is 0 on 629/908 rows and variation_type is 'default'
--     on all 908, so neither carries usable information today.
-- =============================================================
ALTER TABLE exercises.exercise_variation
    ADD COLUMN IF NOT EXISTS variation_axis exercises.variation_axis;
CREATE INDEX IF NOT EXISTS idx_exercise_variation_axis
    ON exercises.exercise_variation(variation_axis);

COMMIT;
