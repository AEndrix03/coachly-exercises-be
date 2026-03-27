-- =============================================================
-- Exercise: Front-Foot Elevated Split Squat
-- Disciplines: functional_training
-- =============================================================
DO 
DECLARE
    v_ex_id  UUID;
    v_var_id UUID;
    v_id     UUID;
BEGIN
    IF EXISTS (SELECT 1 FROM exercises.exercise WHERE name = 'Front-Foot Elevated Split Squat') THEN
        RAISE NOTICE 'Already exists: Front-Foot Elevated Split Squat'; RETURN;
    END IF;
    v_ex_id := gen_random_uuid();

    INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
    VALUES (
        v_ex_id, 'Front-Foot Elevated Split Squat', 'intermediate', 'compound', 'dynamic',
        false, false, 'medium', false, NULL, 'public', 'active',
        jsonb_build_object(
            'it', jsonb_build_object('name','Front-Foot Elevated Split Squat','description','Imposta una posizione stabile e crea bracing. Muoviti in ROM controllato con buoni allineamenti, poi resetta con intenzione tra le ripetizioni per mantenere tecnica consistente.'),
            'en', jsonb_build_object('name','Front-Foot Elevated Split Squat','description','Set up in a stable position and brace the core. Move through a controlled range of motion with good alignment, then reset deliberately between reps to keep technique consistent.')
        ),
        NOW(), NOW()
    );

    -- MUSCLES
    SELECT id INTO v_id FROM exercises.muscle WHERE code='rectus_abdominis'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'primary',75,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- CATEGORIES
    SELECT id INTO v_id FROM exercises.category WHERE code='functional_training'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_ex_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- EQUIPMENT

    -- TAGS
    FOR v_id IN SELECT id FROM exercises.tag WHERE code IN('compound','knee_dominant','bilateral') LOOP INSERT INTO exercises.exercise_tag VALUES(v_ex_id,v_id,NOW()) ON CONFLICT DO NOTHING; END LOOP;

    -- VARIANTS
    -- Tempo Front-Foot Elevated Split Squat
    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Tempo Front-Foot Elevated Split Squat') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Tempo Front-Foot Elevated Split Squat','intermediate','compound','dynamic',false,false,'medium',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Split Squat con Piede Anteriore Rialzato tempo','description','Variante di Front-Foot Elevated Split Squat. Imposta una posizione stabile e crea bracing. Muoviti in ROM controllato con buoni allineamenti, poi resetta con intenzione tra le ripetizioni per mantenere tecnica consistente.'),'en',jsonb_build_object('name','Tempo Front-Foot Elevated Split Squat','description','Variation of Front-Foot Elevated Split Squat. Set up in a stable position and brace the core. Move through a controlled range of motion with good alignment, then reset deliberately between reps to keep technique consistent.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='rectus_abdominis'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',70,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='functional_training'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        FOR v_id IN SELECT id FROM exercises.tag WHERE code IN('compound','knee_dominant','bilateral') LOOP INSERT INTO exercises.exercise_tag VALUES(v_var_id,v_id,NOW()) ON CONFLICT DO NOTHING; END LOOP;
        INSERT INTO exercises.exercise_variation VALUES(v_ex_id,v_var_id,0,NOW()) ON CONFLICT DO NOTHING;
    ELSE
        SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Tempo Front-Foot Elevated Split Squat';
        INSERT INTO exercises.exercise_variation VALUES(v_ex_id,v_var_id,0,NOW()) ON CONFLICT DO NOTHING;
    END IF;

    -- Pause Front-Foot Elevated Split Squat
    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Pause Front-Foot Elevated Split Squat') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Pause Front-Foot Elevated Split Squat','intermediate','compound','dynamic',false,false,'medium',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Split Squat con Piede Anteriore Rialzato con pausa','description','Variante di Front-Foot Elevated Split Squat. Imposta una posizione stabile e crea bracing. Muoviti in ROM controllato con buoni allineamenti, poi resetta con intenzione tra le ripetizioni per mantenere tecnica consistente.'),'en',jsonb_build_object('name','Pause Front-Foot Elevated Split Squat','description','Variation of Front-Foot Elevated Split Squat. Set up in a stable position and brace the core. Move through a controlled range of motion with good alignment, then reset deliberately between reps to keep technique consistent.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='rectus_abdominis'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',70,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='functional_training'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        FOR v_id IN SELECT id FROM exercises.tag WHERE code IN('compound','knee_dominant','bilateral') LOOP INSERT INTO exercises.exercise_tag VALUES(v_var_id,v_id,NOW()) ON CONFLICT DO NOTHING; END LOOP;
        INSERT INTO exercises.exercise_variation VALUES(v_ex_id,v_var_id,0,NOW()) ON CONFLICT DO NOTHING;
    ELSE
        SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Pause Front-Foot Elevated Split Squat';
        INSERT INTO exercises.exercise_variation VALUES(v_ex_id,v_var_id,0,NOW()) ON CONFLICT DO NOTHING;
    END IF;

END ;


