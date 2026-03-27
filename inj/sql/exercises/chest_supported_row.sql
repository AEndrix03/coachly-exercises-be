-- =============================================================
-- Exercise: Chest-Supported Row
-- Disciplines: powerlifting
-- =============================================================
DO $$
DECLARE v_ex_id UUID; v_var_id UUID; v_id UUID;
BEGIN
    IF EXISTS (SELECT 1 FROM exercises.exercise WHERE name = 'Chest-Supported Row') THEN
        RAISE NOTICE 'Already exists: Chest-Supported Row'; RETURN;
    END IF;
    v_ex_id := gen_random_uuid();

    INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
    VALUES (v_ex_id,'Chest-Supported Row','beginner','compound','pull',false,false,'medium',false,NULL,'public','active',
        jsonb_build_object(
            'it',jsonb_build_object('name','Rematore con Supporto al Petto','description','Rematore con petto appoggiato su panca inclinata o supporto per ridurre il carico sulla zona lombare. Tira i gomiti verso i fianchi retrando le scapole, fai una breve pausa in contrazione e torna controllato senza perdere assetto.'),
            'en',jsonb_build_object('name','Chest-Supported Row','description','Row with the chest supported on an incline bench/pad to reduce low-back loading. Row the elbows toward the hips while retracting the scapulae, pause briefly at peak contraction, and return under control without losing position.')
        ), NOW(), NOW());

    -- MUSCLES
    SELECT id INTO v_id FROM exercises.muscle WHERE code='lat_dorsi'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'primary',70,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='rhomboid_major'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'secondary',55,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='trap_mid'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'secondary',50,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='biceps_long_head'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'secondary',40,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- CATEGORIES
    SELECT id INTO v_id FROM exercises.category WHERE code='powerlifting'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_ex_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- EQUIPMENT
    SELECT id INTO v_id FROM exercises.equipment WHERE code='adjustable_bench'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_ex_id,v_id,true,true,1,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.equipment WHERE code='dumbbell'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_ex_id,v_id,true,false,2,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- TAGS
    FOR v_id IN SELECT id FROM exercises.tag WHERE code IN('compound','horizontal_pull','upper_body','bilateral','strength','hypertrophy','dumbbell_tag','gym_required')
    LOOP INSERT INTO exercises.exercise_tag VALUES(v_ex_id,v_id,NOW()) ON CONFLICT DO NOTHING; END LOOP;

    -- VARIANTS
    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Pendlay Chest-Supported Row') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Pendlay Chest-Supported Row','intermediate','compound','pull',false,false,'medium',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Rematore Chest-Supported stile Pendlay','description','Variante con enfasi su ripetizioni esplosive e reset controllato, mantenendo il petto supportato per ridurre stress lombare.'),
                               'en',jsonb_build_object('name','Pendlay Chest-Supported Row','description','Variant emphasizing explosive reps and controlled reset while keeping the chest supported to reduce low-back stress.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='lat_dorsi'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',70,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='powerlifting'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='adjustable_bench'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,true,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        INSERT INTO exercises.exercise_variation VALUES(v_ex_id,v_var_id,0,NOW()) ON CONFLICT DO NOTHING;
    ELSE
        SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Pendlay Chest-Supported Row';
        INSERT INTO exercises.exercise_variation VALUES(v_ex_id,v_var_id,0,NOW()) ON CONFLICT DO NOTHING;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Chest-Supported Chest-Supported Row') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Chest-Supported Chest-Supported Row','beginner','compound','pull',false,false,'medium',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Rematore Chest-Supported (Base)','description','Variante tecnica equivalente al rematore chest-supported, utile per standardizzare impostazione e traiettoria.'),
                               'en',jsonb_build_object('name','Chest-Supported Chest-Supported Row','description','Technique-equivalent variation to standardize setup and pulling path on the chest-supported row.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='lat_dorsi'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',70,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='powerlifting'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='adjustable_bench'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,true,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        INSERT INTO exercises.exercise_variation VALUES(v_ex_id,v_var_id,0,NOW()) ON CONFLICT DO NOTHING;
    ELSE
        SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Chest-Supported Chest-Supported Row';
        INSERT INTO exercises.exercise_variation VALUES(v_ex_id,v_var_id,0,NOW()) ON CONFLICT DO NOTHING;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Seal Chest-Supported Row') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Seal Chest-Supported Row','intermediate','compound','pull',false,false,'medium',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Rematore Chest-Supported stile Seal','description','Variante piu rigida e controllata (stile seal) con supporto al petto, ideale per ridurre cheating e aumentare contrazione in retrazione scapolare.'),
                               'en',jsonb_build_object('name','Seal Chest-Supported Row','description','Stricter seal-style variation with chest support to reduce cheating and emphasize scapular retraction.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='rhomboid_major'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',60,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='powerlifting'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='adjustable_bench'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,true,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        INSERT INTO exercises.exercise_variation VALUES(v_ex_id,v_var_id,0,NOW()) ON CONFLICT DO NOTHING;
    ELSE
        SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Seal Chest-Supported Row';
        INSERT INTO exercises.exercise_variation VALUES(v_ex_id,v_var_id,0,NOW()) ON CONFLICT DO NOTHING;
    END IF;

END $$;

