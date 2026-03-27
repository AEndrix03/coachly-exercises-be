-- =============================================================
-- Exercise: Burpee
-- Disciplines: crossfit
-- =============================================================
DO 
DECLARE
    v_ex_id  UUID;
    v_var_id UUID;
    v_id     UUID;
BEGIN
    IF EXISTS (SELECT 1 FROM exercises.exercise WHERE name = 'Burpee') THEN
        RAISE NOTICE 'Already exists: Burpee'; RETURN;
    END IF;
    v_ex_id := gen_random_uuid();

    INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
    VALUES (
        v_ex_id, 'Burpee', 'intermediate', 'compound', 'dynamic',
        false, false, 'medium', false, NULL, 'public', 'active',
        jsonb_build_object(
            'it', jsonb_build_object('name','Burpee','description','Scendi a terra con mani sotto le spalle, controlla la fase petto-a-terra, poi riporta i piedi sotto il bacino e salta in estensione. Mantieni ritmo respiratorio e atterra morbido.'),
            'en', jsonb_build_object('name','Burpee','description','Drop to the floor with hands under shoulders, complete the chest-to-floor portion with control, then snap feet under hips and jump tall. Keep breathing steady and land softly each rep.')
        ),
        NOW(), NOW()
    );

    -- MUSCLES
    SELECT id INTO v_id FROM exercises.muscle WHERE code='rectus_abdominis'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'primary',75,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- CATEGORIES
    SELECT id INTO v_id FROM exercises.category WHERE code='crossfit'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_ex_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- EQUIPMENT

    -- TAGS
    FOR v_id IN SELECT id FROM exercises.tag WHERE code IN('compound','bilateral','crossfit_movement') LOOP INSERT INTO exercises.exercise_tag VALUES(v_ex_id,v_id,NOW()) ON CONFLICT DO NOTHING; END LOOP;

    -- VARIANTS
    -- Bar-Facing Burpee
    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Bar-Facing Burpee') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Bar-Facing Burpee','intermediate','compound','dynamic',false,false,'medium',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Burpee davanti alla Sbarra','description','Variante di Burpee. Scendi a terra con mani sotto le spalle, controlla la fase petto-a-terra, poi riporta i piedi sotto il bacino e salta in estensione. Mantieni ritmo respiratorio e atterra morbido.'),'en',jsonb_build_object('name','Bar-Facing Burpee','description','Variation of Burpee. Drop to the floor with hands under shoulders, complete the chest-to-floor portion with control, then snap feet under hips and jump tall. Keep breathing steady and land softly each rep.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='rectus_abdominis'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',70,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='crossfit'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        FOR v_id IN SELECT id FROM exercises.tag WHERE code IN('compound','bilateral','crossfit_movement') LOOP INSERT INTO exercises.exercise_tag VALUES(v_var_id,v_id,NOW()) ON CONFLICT DO NOTHING; END LOOP;
        INSERT INTO exercises.exercise_variation VALUES(v_ex_id,v_var_id,0,NOW()) ON CONFLICT DO NOTHING;
    ELSE
        SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Bar-Facing Burpee';
        INSERT INTO exercises.exercise_variation VALUES(v_ex_id,v_var_id,0,NOW()) ON CONFLICT DO NOTHING;
    END IF;

    -- Burpee Box Jump Over
    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Burpee Box Jump Over') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Burpee Box Jump Over','intermediate','compound','dynamic',false,false,'medium',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Burpee con Salto sul Box','description','Variante di Burpee. Scendi a terra con mani sotto le spalle, controlla la fase petto-a-terra, poi riporta i piedi sotto il bacino e salta in estensione. Mantieni ritmo respiratorio e atterra morbido.'),'en',jsonb_build_object('name','Burpee Box Jump Over','description','Variation of Burpee. Drop to the floor with hands under shoulders, complete the chest-to-floor portion with control, then snap feet under hips and jump tall. Keep breathing steady and land softly each rep.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='rectus_abdominis'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',70,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='crossfit'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        FOR v_id IN SELECT id FROM exercises.tag WHERE code IN('compound','plyometric','bilateral','crossfit_movement') LOOP INSERT INTO exercises.exercise_tag VALUES(v_var_id,v_id,NOW()) ON CONFLICT DO NOTHING; END LOOP;
        INSERT INTO exercises.exercise_variation VALUES(v_ex_id,v_var_id,0,NOW()) ON CONFLICT DO NOTHING;
    ELSE
        SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Burpee Box Jump Over';
        INSERT INTO exercises.exercise_variation VALUES(v_ex_id,v_var_id,0,NOW()) ON CONFLICT DO NOTHING;
    END IF;

    -- Burpee Pull-Up
    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Burpee Pull-Up') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Burpee Pull-Up','advanced','compound','dynamic',false,false,'medium',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Burpee con Trazioni','description','Variante di Burpee. Parti da dead hang con spalle attive e tira portando i gomiti in basso e indietro. Raggiungi l''altezza target in controllo e scendi fino a estensione completa senza perdere tensione. Scendi a terra con mani sotto le spalle, controlla la fase petto-a-terra, poi riporta i piedi sotto il bacino e salta in estensione. Mantieni ritmo respiratorio e atterra morbido.'),'en',jsonb_build_object('name','Burpee Pull-Up','description','Variation of Burpee. Start from a dead hang with shoulders engaged, then pull by driving elbows down and back. Reach the target height with control and lower to a full hang without losing tension. Drop to the floor with hands under shoulders, complete the chest-to-floor portion with control, then snap feet under hips and jump tall. Keep breathing steady and land softly each rep.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='rectus_abdominis'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',70,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='crossfit'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        FOR v_id IN SELECT id FROM exercises.tag WHERE code IN('compound','vertical_pull','bilateral','advanced_only','crossfit_movement') LOOP INSERT INTO exercises.exercise_tag VALUES(v_var_id,v_id,NOW()) ON CONFLICT DO NOTHING; END LOOP;
        INSERT INTO exercises.exercise_variation VALUES(v_ex_id,v_var_id,0,NOW()) ON CONFLICT DO NOTHING;
    ELSE
        SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Burpee Pull-Up';
        INSERT INTO exercises.exercise_variation VALUES(v_ex_id,v_var_id,0,NOW()) ON CONFLICT DO NOTHING;
    END IF;

    -- Chest-to-Floor Burpee
    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Chest-to-Floor Burpee') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Chest-to-Floor Burpee','intermediate','compound','dynamic',false,false,'medium',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Burpee Petto al Suolo','description','Variante di Burpee. Scendi a terra con mani sotto le spalle, controlla la fase petto-a-terra, poi riporta i piedi sotto il bacino e salta in estensione. Mantieni ritmo respiratorio e atterra morbido.'),'en',jsonb_build_object('name','Chest-to-Floor Burpee','description','Variation of Burpee. Drop to the floor with hands under shoulders, complete the chest-to-floor portion with control, then snap feet under hips and jump tall. Keep breathing steady and land softly each rep.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='rectus_abdominis'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',70,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='crossfit'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        FOR v_id IN SELECT id FROM exercises.tag WHERE code IN('compound','bilateral','crossfit_movement') LOOP INSERT INTO exercises.exercise_tag VALUES(v_var_id,v_id,NOW()) ON CONFLICT DO NOTHING; END LOOP;
        INSERT INTO exercises.exercise_variation VALUES(v_ex_id,v_var_id,0,NOW()) ON CONFLICT DO NOTHING;
    ELSE
        SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Chest-to-Floor Burpee';
        INSERT INTO exercises.exercise_variation VALUES(v_ex_id,v_var_id,0,NOW()) ON CONFLICT DO NOTHING;
    END IF;

END ;


