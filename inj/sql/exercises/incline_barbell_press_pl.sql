-- =============================================================
-- Exercise: Incline Barbell Press (Powerlifting Accessory)
-- Disciplines: powerlifting
-- =============================================================
DO $$
DECLARE v_ex_id UUID; v_var_id UUID; v_id UUID;
BEGIN
    IF EXISTS (SELECT 1 FROM exercises.exercise WHERE name = 'Incline Barbell Press') THEN
        -- Add powerlifting category if not present
        SELECT id INTO v_ex_id FROM exercises.exercise WHERE name = 'Incline Barbell Press';
        SELECT id INTO v_id FROM exercises.category WHERE code='powerlifting';
        IF v_id IS NOT NULL AND v_ex_id IS NOT NULL THEN
            INSERT INTO exercises.exercise_category VALUES(v_ex_id,v_id,false,NOW()) ON CONFLICT DO NOTHING;
        END IF;
        RAISE NOTICE 'Already exists, category updated: Incline Barbell Press'; RETURN;
    END IF;
    v_ex_id := gen_random_uuid();

    INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
    VALUES (v_ex_id,'Incline Barbell Press','intermediate','compound','push',false,false,'medium',true,NULL,'public','active',
        jsonb_build_object(
            'it',jsonb_build_object('name','Panca Inclinata con Bilanciere','description','Panca inclinata (30-45 gradi) con bilanciere, accessorio powerlifting per sviluppare il pettorale superiore e il deltoide anteriore, muscoli fondamentali nella fase iniziale della panca piana. Impugnatura leggermente piu stretta rispetto alla panca piatta, abbassare il bilanciere alla clavicola.'),
            'en',jsonb_build_object('name','Incline Barbell Press','description','Incline bench press (30-45 degrees) with barbell, a powerlifting accessory for developing the upper pectoral and anterior deltoid, key muscles in the initial phase of the flat bench press. Slightly narrower grip than flat bench, lower the bar to the clavicle.')),
        NOW(),NOW());

    -- MUSCLES
    SELECT id INTO v_id FROM exercises.muscle WHERE code='pec_major_upper'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'primary',70,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='deltoid_anterior'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'secondary',50,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='triceps_long_head'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'secondary',40,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- CATEGORIES
    SELECT id INTO v_id FROM exercises.category WHERE code='powerlifting'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_ex_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.category WHERE code='bodybuilding'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_ex_id,v_id,false,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- EQUIPMENT
    SELECT id INTO v_id FROM exercises.equipment WHERE code='barbell'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_ex_id,v_id,true,true,1,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.equipment WHERE code='incline_bench'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_ex_id,v_id,true,true,2,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- TAGS
    FOR v_id IN SELECT id FROM exercises.tag WHERE code IN('powerlifting','accessory','compound','upper_chest','gym_required') LOOP INSERT INTO exercises.exercise_tag VALUES(v_ex_id,v_id,NOW()) ON CONFLICT DO NOTHING; END LOOP;

END $$;
