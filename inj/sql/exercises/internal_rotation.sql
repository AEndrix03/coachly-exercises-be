-- =============================================================
-- Exercise: Internal Rotation
-- Disciplines: bodybuilding
-- =============================================================
DO $$
DECLARE
    v_ex_id  UUID;
    v_var_id UUID;
    v_id     UUID;
BEGIN
    IF EXISTS (SELECT 1 FROM exercises.exercise WHERE name = 'Internal Rotation') THEN
        RAISE NOTICE 'Already exists: Internal Rotation'; RETURN;
    END IF;
    v_ex_id := gen_random_uuid();

    INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
    VALUES (
        v_ex_id, 'Internal Rotation', 'beginner', 'isolation', 'push',
        true, false, 'low', false, NULL, 'public', 'active',
        jsonb_build_object(
            'it', jsonb_build_object('name','Rotazione Interna','description','Esercizio di cuffia dei rotatori per rinforzare soprattutto il sottoscapolare. Mantieni gomito vicino al fianco (o appoggiato) e ruota l''avambraccio verso l''interno senza compensi della spalla; carichi leggeri e controllo totale.'),
            'en', jsonb_build_object('name','Internal Rotation','description','Rotator cuff exercise primarily targeting the subscapularis. Keep the elbow tucked (or supported) and rotate the forearm inward without shoulder compensation; use light resistance and full control.')
        ),
        NOW(), NOW()
    );

    -- MUSCLES
    SELECT id INTO v_id FROM exercises.muscle WHERE code='subscapularis'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'primary',75,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='teres_major'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'secondary',30,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- CATEGORIES
    SELECT id INTO v_id FROM exercises.category WHERE code='bodybuilding'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_ex_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- EQUIPMENT
    SELECT id INTO v_id FROM exercises.equipment WHERE code='cable_machine'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_ex_id,v_id,true,true,1,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- TAGS
    FOR v_id IN SELECT id FROM exercises.tag WHERE code IN('isolation','upper_body','unilateral','prehab','rehabilitation','cable_tag','gym_required','beginner_safe')
    LOOP INSERT INTO exercises.exercise_tag VALUES(v_ex_id,v_id,NOW()) ON CONFLICT DO NOTHING; END LOOP;

    -- VARIANTS
    -- Cable Internal Rotation
    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Cable Internal Rotation') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES (v_var_id,'Cable Internal Rotation','beginner','compound','static',true,false,'medium',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Rotazione Interna ai Cavi','description','Rotazione interna al cavo per tensione costante su tutto il ROM. Mantieni gomito fermo vicino al fianco e ruota solo l''avambraccio verso l''addome senza “chiudere” la spalla.'),'en',jsonb_build_object('name','Cable Internal Rotation','description','Cable internal rotation provides constant tension through the ROM. Keep the elbow fixed by the side and rotate the forearm toward the abdomen without collapsing the shoulder.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='subscapularis'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',75,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.muscle WHERE code='teres_major'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'secondary',30,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='bodybuilding'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='cable_machine'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,true,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        FOR v_id IN SELECT id FROM exercises.tag WHERE code IN('isolation','upper_body','unilateral','prehab','rehabilitation','cable_tag','gym_required')
        LOOP INSERT INTO exercises.exercise_tag VALUES(v_var_id,v_id,NOW()) ON CONFLICT DO NOTHING; END LOOP;
        INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',0,NOW()) ON CONFLICT DO NOTHING;
    ELSE
        SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Cable Internal Rotation';
        INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',0,NOW()) ON CONFLICT DO NOTHING;
    END IF;

    -- Band Internal Rotation
    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Band Internal Rotation') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES (v_var_id,'Band Internal Rotation','beginner','compound','static',true,false,'medium',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Rotazione Interna con Elastico','description','Rotazione interna con elastico per warm-up e lavoro di cuffia in home workout. Mantieni gomito vicino al fianco e usa tensione leggera, privilegiando qualità e controllo.'),'en',jsonb_build_object('name','Band Internal Rotation','description','Band internal rotation for warm-up and cuff work in home workouts. Keep the elbow tucked and use light tension, prioritizing quality and control.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='subscapularis'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',70,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.muscle WHERE code='teres_major'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'secondary',25,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='bodybuilding'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='resistance_band'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,true,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        FOR v_id IN SELECT id FROM exercises.tag WHERE code IN('isolation','upper_body','unilateral','prehab','rehabilitation','band_tag','home_friendly')
        LOOP INSERT INTO exercises.exercise_tag VALUES(v_var_id,v_id,NOW()) ON CONFLICT DO NOTHING; END LOOP;
        INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',-1,NOW()) ON CONFLICT DO NOTHING;
    ELSE
        SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Band Internal Rotation';
        INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',-1,NOW()) ON CONFLICT DO NOTHING;
    END IF;

END $$;

