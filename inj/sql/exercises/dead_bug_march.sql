-- =============================================================
-- Exercise: Dead Bug March
-- Disciplines: functional_training
-- =============================================================
DO 
DECLARE
    v_ex_id  UUID;
    v_var_id UUID;
    v_id     UUID;
BEGIN
    IF EXISTS (SELECT 1 FROM exercises.exercise WHERE name = 'Dead Bug March') THEN
        RAISE NOTICE 'Already exists: Dead Bug March'; RETURN;
    END IF;
    v_ex_id := gen_random_uuid();

    INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
    VALUES (
        v_ex_id, 'Dead Bug March', 'intermediate', 'compound', 'dynamic',
        false, false, 'medium', false, NULL, 'public', 'active',
        jsonb_build_object(
            'it', jsonb_build_object('name','Dead Bug March','description','Mantieni coste giu e core attivo mentre esegui lentamente il pattern. Bacino in squadra e assetto della colonna stabile; usa respirazione controllata per mantenere tensione.'),
            'en', jsonb_build_object('name','Dead Bug March','description','Maintain ribs down and a braced core while moving slowly through the pattern. Keep hips square and avoid losing spinal position; use controlled breathing to hold tension.')
        ),
        NOW(), NOW()
    );

    -- MUSCLES
    SELECT id INTO v_id FROM exercises.muscle WHERE code='rectus_abdominis'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'primary',75,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- CATEGORIES
    SELECT id INTO v_id FROM exercises.category WHERE code='functional_training'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_ex_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- EQUIPMENT

    -- TAGS
    FOR v_id IN SELECT id FROM exercises.tag WHERE code IN('compound','core_focus','bilateral') LOOP INSERT INTO exercises.exercise_tag VALUES(v_ex_id,v_id,NOW()) ON CONFLICT DO NOTHING; END LOOP;

    -- VARIANTS
    -- Banded Dead Bug March
    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Banded Dead Bug March') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Banded Dead Bug March','beginner','compound','dynamic',false,false,'medium',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Dead Bug in Marcia con banda','description','Variante di Dead Bug March. Mantieni coste giu e core attivo mentre esegui lentamente il pattern. Bacino in squadra e assetto della colonna stabile; usa respirazione controllata per mantenere tensione.'),'en',jsonb_build_object('name','Banded Dead Bug March','description','Variation of Dead Bug March. Maintain ribs down and a braced core while moving slowly through the pattern. Keep hips square and avoid losing spinal position; use controlled breathing to hold tension.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='rectus_abdominis'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',70,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='functional_training'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='resistance_band'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,true,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        FOR v_id IN SELECT id FROM exercises.tag WHERE code IN('compound','core_focus','bilateral','band_tag') LOOP INSERT INTO exercises.exercise_tag VALUES(v_var_id,v_id,NOW()) ON CONFLICT DO NOTHING; END LOOP;
        INSERT INTO exercises.exercise_variation VALUES(v_ex_id,v_var_id,0,NOW()) ON CONFLICT DO NOTHING;
    ELSE
        SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Banded Dead Bug March';
        INSERT INTO exercises.exercise_variation VALUES(v_ex_id,v_var_id,0,NOW()) ON CONFLICT DO NOTHING;
    END IF;

    -- Wall Dead Bug March
    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Wall Dead Bug March') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Wall Dead Bug March','beginner','compound','dynamic',false,false,'medium',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Dead Bug in Marcia al muro','description','Variante di Dead Bug March. Mantieni coste giu e core attivo mentre esegui lentamente il pattern. Bacino in squadra e assetto della colonna stabile; usa respirazione controllata per mantenere tensione.'),'en',jsonb_build_object('name','Wall Dead Bug March','description','Variation of Dead Bug March. Maintain ribs down and a braced core while moving slowly through the pattern. Keep hips square and avoid losing spinal position; use controlled breathing to hold tension.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='rectus_abdominis'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',70,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='functional_training'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        FOR v_id IN SELECT id FROM exercises.tag WHERE code IN('compound','core_focus','bilateral') LOOP INSERT INTO exercises.exercise_tag VALUES(v_var_id,v_id,NOW()) ON CONFLICT DO NOTHING; END LOOP;
        INSERT INTO exercises.exercise_variation VALUES(v_ex_id,v_var_id,0,NOW()) ON CONFLICT DO NOTHING;
    ELSE
        SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Wall Dead Bug March';
        INSERT INTO exercises.exercise_variation VALUES(v_ex_id,v_var_id,0,NOW()) ON CONFLICT DO NOTHING;
    END IF;

END ;


