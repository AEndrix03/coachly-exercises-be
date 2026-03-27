-- =============================================================
-- Exercise: Spider Curl
-- =============================================================
DO $$
DECLARE v_ex_id UUID; v_var_id UUID; v_id UUID;
BEGIN
    IF EXISTS (SELECT 1 FROM exercises.exercise WHERE name = 'Spider Curl') THEN
        SELECT id INTO v_ex_id FROM exercises.exercise WHERE name = 'Spider Curl';
        SELECT id INTO v_id FROM exercises.category WHERE code='bodybuilding'; IF v_id IS NOT NULL AND v_ex_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_ex_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        RAISE NOTICE 'Already exists, category updated: Spider Curl'; RETURN;
    END IF;
    v_ex_id := gen_random_uuid();

    INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,
        overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
    VALUES (v_ex_id,'Spider Curl','beginner','isolation','pull',
        false,false,'low',false,NULL,'public','active',
        jsonb_build_object(
            'it',jsonb_build_object('name','Spider Curl','description','Curl per bicipiti: impugna l''attrezzo, gomiti vicini ai fianchi e spalle stabili, fletti il gomito senza oscillare il busto. Sali in controllo, poi scendi lentamente mantenendo tensione continua.'),
            'en',jsonb_build_object('name','Spider Curl','description','Biceps curl: grip the implement with elbows pinned close to your sides and shoulders stable, flex the elbow without swinging. Curl up under control, then lower slowly keeping constant tension.')
        ), NOW(), NOW());

    -- MUSCLES
    SELECT id INTO v_id FROM exercises.muscle WHERE code='biceps_short_head'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'primary',80,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='brachialis'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'secondary',55,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- CATEGORIES
    SELECT id INTO v_id FROM exercises.category WHERE code='bodybuilding'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_ex_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- EQUIPMENT
    SELECT id INTO v_id FROM exercises.equipment WHERE code='dumbbell'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_ex_id,v_id,true,true,1,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.equipment WHERE code='incline_bench'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_ex_id,v_id,true,false,1,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- TAGS
    FOR v_id IN SELECT id FROM exercises.tag WHERE code IN('isolation','bilateral','upper_body','hypertrophy','strength','gym_required','dumbbell_tag','beginner_safe')
    LOOP INSERT INTO exercises.exercise_tag VALUES(v_ex_id,v_id,NOW()) ON CONFLICT DO NOTHING; END LOOP;

    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='EZ Bar Spider Curl') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,
            overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'EZ Bar Spider Curl','beginner','isolation','pull',false,false,'low',false,
            NULL,'public','active',jsonb_build_object('it',jsonb_build_object('name','Spider Curl EZ Bar','description','Variante di Spider Curl - Curl per bicipiti: impugna l''attrezzo, gomiti vicini ai fianchi e spalle stabili, fletti il gomito senza oscillare il busto. Sali in controllo, poi scendi lentamente mantenendo tensione continua.'),
                                 'en',jsonb_build_object('name','EZ Bar Spider Curl','description','Variation of Spider Curl - Biceps curl: grip the implement with elbows pinned close to your sides and shoulders stable, flex the elbow without swinging. Curl up under control, then lower slowly keeping constant tension.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='biceps_short_head'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',70,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.muscle WHERE code='brachialis'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'secondary',45,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='bodybuilding'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='dumbbell'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,true,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='incline_bench'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,false,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        FOR v_id IN SELECT id FROM exercises.tag WHERE code IN('isolation','bilateral','upper_body','hypertrophy','strength','gym_required','dumbbell_tag','beginner_safe') LOOP INSERT INTO exercises.exercise_tag VALUES(v_var_id,v_id,NOW()) ON CONFLICT DO NOTHING; END LOOP;
        INSERT INTO exercises.exercise_variation VALUES(v_ex_id,v_var_id,0,NOW()) ON CONFLICT DO NOTHING;
    ELSE
        SELECT id INTO v_var_id FROM exercises.exercise WHERE name='EZ Bar Spider Curl';
        INSERT INTO exercises.exercise_variation VALUES(v_ex_id,v_var_id,0,NOW()) ON CONFLICT DO NOTHING;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Cable Spider Curl') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,
            overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Cable Spider Curl','beginner','isolation','pull',false,false,'low',false,
            NULL,'public','active',jsonb_build_object('it',jsonb_build_object('name','Spider Curl ai Cavi','description','Variante di Spider Curl - Curl per bicipiti: impugna l''attrezzo, gomiti vicini ai fianchi e spalle stabili, fletti il gomito senza oscillare il busto. Sali in controllo, poi scendi lentamente mantenendo tensione continua.'),
                                 'en',jsonb_build_object('name','Cable Spider Curl','description','Variation of Spider Curl - Biceps curl: grip the implement with elbows pinned close to your sides and shoulders stable, flex the elbow without swinging. Curl up under control, then lower slowly keeping constant tension.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='biceps_short_head'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',70,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.muscle WHERE code='brachialis'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'secondary',45,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='bodybuilding'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='dumbbell'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,true,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='incline_bench'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,false,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        FOR v_id IN SELECT id FROM exercises.tag WHERE code IN('isolation','bilateral','upper_body','hypertrophy','strength','gym_required','dumbbell_tag','beginner_safe') LOOP INSERT INTO exercises.exercise_tag VALUES(v_var_id,v_id,NOW()) ON CONFLICT DO NOTHING; END LOOP;
        INSERT INTO exercises.exercise_variation VALUES(v_ex_id,v_var_id,0,NOW()) ON CONFLICT DO NOTHING;
    ELSE
        SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Cable Spider Curl';
        INSERT INTO exercises.exercise_variation VALUES(v_ex_id,v_var_id,0,NOW()) ON CONFLICT DO NOTHING;
    END IF;

END $$;

