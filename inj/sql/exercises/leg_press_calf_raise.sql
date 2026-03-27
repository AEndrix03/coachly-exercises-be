-- =============================================================
-- Exercise: Leg Press Calf Raise
-- Disciplines: bodybuilding
-- =============================================================
DO $$
DECLARE v_ex_id UUID; v_var_id UUID; v_id UUID;
BEGIN
    IF EXISTS (SELECT 1 FROM exercises.exercise WHERE name = 'Leg Press Calf Raise') THEN
        RAISE NOTICE 'Already exists: Leg Press Calf Raise'; RETURN;
    END IF;
    v_ex_id := gen_random_uuid();

    INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
    VALUES (v_ex_id,'Leg Press Calf Raise','beginner','isolation','push',false,false,'low',false,NULL,'public','active',
        jsonb_build_object(
            'it',jsonb_build_object('name','Calf Raise alla Leg Press','description','Imposta sedile/schienale per colonna neutra e bacino stabile. Abbassa la slitta controllando profondita senza retroversione, poi spingi in salita senza iperestendere le ginocchia.'),
            'en',jsonb_build_object('name','Leg Press Calf Raise','description','Set the seat/backrest for a neutral spine and stable pelvis. Lower the sled without posteriorly tucking the hips, then press up without hyperextending the knees.')
        ),NOW(),NOW());

    -- MUSCLES
    SELECT id INTO v_id FROM exercises.muscle WHERE code='gastrocnemius_medial'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'primary',75,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='gastrocnemius_lateral'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'primary',75,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='soleus'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'secondary',45,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- CATEGORIES
    SELECT id INTO v_id FROM exercises.category WHERE code='bodybuilding'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_ex_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- EQUIPMENT
    SELECT id INTO v_id FROM exercises.equipment WHERE code='leg_press_machine'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_ex_id,v_id,true,true,1,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- TAGS
    FOR v_id IN SELECT id FROM exercises.tag WHERE code IN('isolation','knee_dominant','lower_body','bilateral','machine_tag','gym_required') LOOP INSERT INTO exercises.exercise_tag VALUES(v_ex_id,v_id,NOW()) ON CONFLICT DO NOTHING; END LOOP;

    -- VARIANTS

    -- Single Leg Press Calf Raise
    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Single Leg Press Calf Raise') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Single Leg Press Calf Raise','beginner','isolation','push',true,false,'low',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Calf Raise Monogamba alla Leg Press','description','Imposta sedile/schienale per colonna neutra e bacino stabile. Abbassa la slitta controllando profondita senza retroversione, poi spingi in salita senza iperestendere le ginocchia.'),
                               'en',jsonb_build_object('name','Single Leg Press Calf Raise','description','Set the seat/backrest for a neutral spine and stable pelvis. Lower the sled without posteriorly tucking the hips, then press up without hyperextending the knees.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='gastrocnemius_medial'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',75,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.muscle WHERE code='gastrocnemius_lateral'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',75,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.muscle WHERE code='soleus'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'secondary',45,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='bodybuilding'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='leg_press_machine'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,true,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        FOR v_id IN SELECT id FROM exercises.tag WHERE code IN('isolation','knee_dominant','lower_body','unilateral','machine_tag','gym_required') LOOP INSERT INTO exercises.exercise_tag VALUES(v_var_id,v_id,NOW()) ON CONFLICT DO NOTHING; END LOOP;
        INSERT INTO exercises.exercise_variation VALUES(v_ex_id,v_var_id,0,NOW()) ON CONFLICT DO NOTHING;
    ELSE
        SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Single Leg Press Calf Raise';
        INSERT INTO exercises.exercise_variation VALUES(v_ex_id,v_var_id,0,NOW()) ON CONFLICT DO NOTHING;
    END IF;

END $$;
