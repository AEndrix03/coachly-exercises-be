-- =============================================================
-- Exercise: Spoto Press
-- Disciplines: powerlifting
-- =============================================================
DO $$
DECLARE v_ex_id UUID; v_var_id UUID; v_id UUID;
BEGIN
    IF EXISTS (SELECT 1 FROM exercises.exercise WHERE name = 'Spoto Press') THEN
        RAISE NOTICE 'Already exists: Spoto Press'; RETURN;
    END IF;
    v_ex_id := gen_random_uuid();

    INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
    VALUES (v_ex_id,'Spoto Press','advanced','compound','push',false,false,'medium',true,NULL,'public','active',
        jsonb_build_object(
            'it',jsonb_build_object('name','Spoto Press','description','Variante della panca ideata da Eric Spoto: il bilanciere viene abbassato finche non e a circa 2-3 cm dal petto, tenuto in posizione sospesa per 1-2 secondi senza toccare, poi premuto esplosivamente. Elimina il rimbalzo mantenendo tensione muscolare massima e sviluppa controllo eccentrico. Ottimo per correggere il tocco troppo duro in gara.'),
            'en',jsonb_build_object('name','Spoto Press','description','Bench press variant invented by Eric Spoto: lower the bar to ~2-3 cm above the chest, hold in suspension for 1-2 seconds without contact, then press explosively. Eliminates bounce while maintaining maximum muscular tension and develops eccentric control. Excellent for correcting overly aggressive chest contact in competition.')),
        NOW(),NOW());

    -- MUSCLES
    SELECT id INTO v_id FROM exercises.muscle WHERE code='pec_major_mid'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'primary',70,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='deltoid_anterior'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'secondary',40,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='triceps_lateral_head'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'secondary',50,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- CATEGORIES
    SELECT id INTO v_id FROM exercises.category WHERE code='powerlifting'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_ex_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- EQUIPMENT
    SELECT id INTO v_id FROM exercises.equipment WHERE code='barbell'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_ex_id,v_id,true,true,1,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.equipment WHERE code='flat_bench'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_ex_id,v_id,true,true,2,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.equipment WHERE code='power_rack'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_ex_id,v_id,true,true,3,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- TAGS
    FOR v_id IN SELECT id FROM exercises.tag WHERE code IN('powerlifting','accessory','compound','advanced','gym_required') LOOP INSERT INTO exercises.exercise_tag VALUES(v_ex_id,v_id,NOW()) ON CONFLICT DO NOTHING; END LOOP;

END $$;
