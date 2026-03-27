-- =============================================================
-- Exercise: Air Squat
-- Disciplines: calisthenics
-- =============================================================
DO $$
DECLARE v_ex_id UUID; v_var_id UUID; v_id UUID;
BEGIN
    IF EXISTS (SELECT 1 FROM exercises.exercise WHERE name = 'Air Squat') THEN
        RAISE NOTICE 'Already exists: Air Squat'; RETURN;
    END IF;
    v_ex_id := gen_random_uuid();

    INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
    VALUES (v_ex_id,'Air Squat','beginner','compound','push',false,true,'low',false,NULL,'public','active',
        jsonb_build_object('it',jsonb_build_object('name','Squat a Corpo Libero','description','In piedi stabile e core in brace, scendi portando il bacino indietro e in basso con ginocchia in linea coi piedi. Mantieni pressione sul mesopiede e risali fino a estendere senza collassare col busto.'),
                           'en',jsonb_build_object('name','Air Squat','description','Stand tall with feet stable and brace your core, then sit down and back while tracking the knees over the toes. Keep the midfoot pressure and drive up to full extension without collapsing the torso.')),NOW(),NOW());

    -- MUSCLES
    SELECT id INTO v_id FROM exercises.muscle WHERE code='rectus_femoris'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'primary',80,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='vastus_lateralis'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'primary',70,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='gluteus_maximus'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'secondary',55,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='adductor_magnus'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'secondary',45,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- CATEGORIES
    SELECT id INTO v_id FROM exercises.category WHERE code='calisthenics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_ex_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- EQUIPMENT
    SELECT id INTO v_id FROM exercises.equipment WHERE code='none_bodyweight'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_ex_id,v_id,true,true,1,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- TAGS
    FOR v_id IN SELECT id FROM exercises.tag WHERE code IN('compound','horizontal_push','knee_dominant','bilateral','lower_body','no_equipment','home_friendly','calisthenics_skill') LOOP INSERT INTO exercises.exercise_tag VALUES(v_ex_id,v_id,NOW()) ON CONFLICT DO NOTHING; END LOOP;

    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Tempo Air Squat') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Tempo Air Squat','beginner','compound','push',false,true,'low',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Tempo Squat a Corpo Libero','description','Variante di Air Squat che modifica leva o tempo per lavorare lo stesso schema. Mantieni un setup solido e muoviti in controllo senza perdere posizione.'),
                               'en',jsonb_build_object('name','Tempo Air Squat','description','Variation of Air Squat that changes leverage or tempo to target the same pattern. Keep the same tight setup and move under control without losing position.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='rectus_femoris'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',75,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='calisthenics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='none_bodyweight'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,true,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        INSERT INTO exercises.exercise_variation VALUES(v_ex_id,v_var_id,0,NOW()) ON CONFLICT DO NOTHING;
    ELSE
        SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Tempo Air Squat';
        INSERT INTO exercises.exercise_variation VALUES(v_ex_id,v_var_id,0,NOW()) ON CONFLICT DO NOTHING;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Paused Air Squat') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Paused Air Squat','beginner','compound','push',false,true,'low',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Paused Squat a Corpo Libero','description','Variante di Air Squat che modifica leva o tempo per lavorare lo stesso schema. Mantieni un setup solido e muoviti in controllo senza perdere posizione.'),
                               'en',jsonb_build_object('name','Paused Air Squat','description','Variation of Air Squat that changes leverage or tempo to target the same pattern. Keep the same tight setup and move under control without losing position.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='rectus_femoris'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',75,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='calisthenics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='none_bodyweight'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,true,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        INSERT INTO exercises.exercise_variation VALUES(v_ex_id,v_var_id,0,NOW()) ON CONFLICT DO NOTHING;
    ELSE
        SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Paused Air Squat';
        INSERT INTO exercises.exercise_variation VALUES(v_ex_id,v_var_id,0,NOW()) ON CONFLICT DO NOTHING;
    END IF;
END $$;

