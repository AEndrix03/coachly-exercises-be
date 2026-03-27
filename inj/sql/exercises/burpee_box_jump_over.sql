-- =============================================================
-- Exercise: Burpee Box Jump Over
-- Disciplines: crossfit
-- =============================================================
DO 
DECLARE
    v_ex_id  UUID;
    v_var_id UUID;
    v_id     UUID;
BEGIN
    IF EXISTS (SELECT 1 FROM exercises.exercise WHERE name = 'Burpee Box Jump Over') THEN
        RAISE NOTICE 'Already exists: Burpee Box Jump Over'; RETURN;
    END IF;
    v_ex_id := gen_random_uuid();

    INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
    VALUES (
        v_ex_id, 'Burpee Box Jump Over', 'intermediate', 'compound', 'dynamic',
        false, false, 'medium', false, NULL, 'public', 'active',
        jsonb_build_object(
            'it', jsonb_build_object('name','Burpee Box Jump Over','description','Scendi a terra con mani sotto le spalle, controlla la fase petto-a-terra, poi riporta i piedi sotto il bacino e salta in estensione. Mantieni ritmo respiratorio e atterra morbido.'),
            'en', jsonb_build_object('name','Burpee Box Jump Over','description','Drop to the floor with hands under shoulders, complete the chest-to-floor portion with control, then snap feet under hips and jump tall. Keep breathing steady and land softly each rep.')
        ),
        NOW(), NOW()
    );

    -- MUSCLES
    SELECT id INTO v_id FROM exercises.muscle WHERE code='rectus_abdominis'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'primary',75,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- CATEGORIES
    SELECT id INTO v_id FROM exercises.category WHERE code='crossfit'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_ex_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- EQUIPMENT

    -- TAGS
    FOR v_id IN SELECT id FROM exercises.tag WHERE code IN('compound','plyometric','bilateral','crossfit_movement') LOOP INSERT INTO exercises.exercise_tag VALUES(v_ex_id,v_id,NOW()) ON CONFLICT DO NOTHING; END LOOP;

    -- VARIANTS
    -- Burpee Step-Over
    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Burpee Step-Over') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES (v_var_id,'Burpee Step-Over','beginner','compound','static',false,false,'medium',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Burpee con Step-Over','description','Variante di Burpee Box Jump Over. Scendi a terra con mani sotto le spalle, controlla la fase petto-a-terra, poi riporta i piedi sotto il bacino e salta in estensione. Mantieni ritmo respiratorio e atterra morbido.'),'en',jsonb_build_object('name','Burpee Step-Over','description','Variation of Burpee Box Jump Over. Drop to the floor with hands under shoulders, complete the chest-to-floor portion with control, then snap feet under hips and jump tall. Keep breathing steady and land softly each rep.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='rectus_abdominis'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',70,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='crossfit'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        FOR v_id IN SELECT id FROM exercises.tag WHERE code IN('compound','bilateral','crossfit_movement') LOOP INSERT INTO exercises.exercise_tag VALUES(v_var_id,v_id,NOW()) ON CONFLICT DO NOTHING; END LOOP;
        INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,0,NOW()) ON CONFLICT DO NOTHING;
    ELSE
        SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Burpee Step-Over';
        INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,0,NOW()) ON CONFLICT DO NOTHING;
    END IF;

    -- Bar-Facing Burpee
    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Bar-Facing Burpee') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES (v_var_id,'Bar-Facing Burpee','intermediate','compound','static',false,false,'medium',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Burpee davanti alla Sbarra','description','Variante di Burpee Box Jump Over. Scendi a terra con mani sotto le spalle, controlla la fase petto-a-terra, poi riporta i piedi sotto il bacino e salta in estensione. Mantieni ritmo respiratorio e atterra morbido.'),'en',jsonb_build_object('name','Bar-Facing Burpee','description','Variation of Burpee Box Jump Over. Drop to the floor with hands under shoulders, complete the chest-to-floor portion with control, then snap feet under hips and jump tall. Keep breathing steady and land softly each rep.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='rectus_abdominis'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',70,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='crossfit'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        FOR v_id IN SELECT id FROM exercises.tag WHERE code IN('compound','bilateral','crossfit_movement') LOOP INSERT INTO exercises.exercise_tag VALUES(v_var_id,v_id,NOW()) ON CONFLICT DO NOTHING; END LOOP;
        INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,0,NOW()) ON CONFLICT DO NOTHING;
    ELSE
        SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Bar-Facing Burpee';
        INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,0,NOW()) ON CONFLICT DO NOTHING;
    END IF;

    -- Lateral Burpee
    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Lateral Burpee') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES (v_var_id,'Lateral Burpee','intermediate','compound','static',false,false,'medium',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Burpee Laterale','description','Variante di Burpee Box Jump Over. Scendi a terra con mani sotto le spalle, controlla la fase petto-a-terra, poi riporta i piedi sotto il bacino e salta in estensione. Mantieni ritmo respiratorio e atterra morbido.'),'en',jsonb_build_object('name','Lateral Burpee','description','Variation of Burpee Box Jump Over. Drop to the floor with hands under shoulders, complete the chest-to-floor portion with control, then snap feet under hips and jump tall. Keep breathing steady and land softly each rep.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='rectus_abdominis'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',70,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='crossfit'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        FOR v_id IN SELECT id FROM exercises.tag WHERE code IN('compound','bilateral','crossfit_movement') LOOP INSERT INTO exercises.exercise_tag VALUES(v_var_id,v_id,NOW()) ON CONFLICT DO NOTHING; END LOOP;
        INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,0,NOW()) ON CONFLICT DO NOTHING;
    ELSE
        SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Lateral Burpee';
        INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,0,NOW()) ON CONFLICT DO NOTHING;
    END IF;

END ;


