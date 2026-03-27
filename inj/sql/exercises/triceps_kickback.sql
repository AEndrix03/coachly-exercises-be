-- =============================================================
-- Exercise: Triceps Kickback
-- =============================================================
DO $$
DECLARE v_ex_id UUID; v_var_id UUID; v_id UUID;
BEGIN
    IF EXISTS (SELECT 1 FROM exercises.exercise WHERE name = 'Triceps Kickback') THEN
        SELECT id INTO v_ex_id FROM exercises.exercise WHERE name = 'Triceps Kickback';
        SELECT id INTO v_id FROM exercises.category WHERE code='bodybuilding'; IF v_id IS NOT NULL AND v_ex_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_ex_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        RAISE NOTICE 'Already exists, category updated: Triceps Kickback'; RETURN;
    END IF;
    v_ex_id := gen_random_uuid();

    INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,
        overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
    VALUES (v_ex_id,'Triceps Kickback','beginner','isolation','push',
        true,false,'low',false,NULL,'public','active',
        jsonb_build_object(
            'it',jsonb_build_object('name','Kickback Tricipiti','description','Isolamento tricipiti: tieni il braccio fermo e muovi solo il gomito, portando il carico vicino alla testa e poi estendendo. Mantieni scapole stabili e controlla l''eccentrica per non irritare i gomiti.'),
            'en',jsonb_build_object('name','Triceps Kickback','description','Triceps isolation: keep the upper arm still and move only at the elbow, lowering the load near the head and then extending. Keep shoulder blades set and control the eccentric to avoid elbow irritation.')
        ), NOW(), NOW());

    -- MUSCLES
    SELECT id INTO v_id FROM exercises.muscle WHERE code='triceps_lateral_head'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'primary',80,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='triceps_medial_head'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'primary',75,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='anconeus'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'secondary',55,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- CATEGORIES
    SELECT id INTO v_id FROM exercises.category WHERE code='bodybuilding'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_ex_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- EQUIPMENT
    SELECT id INTO v_id FROM exercises.equipment WHERE code='dumbbell'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_ex_id,v_id,true,true,1,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- TAGS
    FOR v_id IN SELECT id FROM exercises.tag WHERE code IN('isolation','unilateral','upper_body','hypertrophy','strength','gym_required','dumbbell_tag','beginner_safe')
    LOOP INSERT INTO exercises.exercise_tag VALUES(v_ex_id,v_id,NOW()) ON CONFLICT DO NOTHING; END LOOP;

    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Cable Kickback') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,
            overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Cable Kickback','beginner','isolation','push',true,false,'low',false,
            NULL,'public','active',jsonb_build_object('it',jsonb_build_object('name','Kickback ai Cavi','description','Variante di Kickback Tricipiti - Esercizio: imposta una posizione stabile e lavora con ripetizioni controllate, curando ROM e tensione. Mantieni respirazione e postura per ridurre compensi.'),
                                 'en',jsonb_build_object('name','Cable Kickback','description','Variation of Triceps Kickback - Exercise: set a stable position and perform controlled reps focusing on ROM and tension. Keep breathing and posture to reduce compensations.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='triceps_lateral_head'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',70,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.muscle WHERE code='triceps_medial_head'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',70,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.muscle WHERE code='anconeus'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'secondary',45,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='bodybuilding'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='dumbbell'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,true,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        FOR v_id IN SELECT id FROM exercises.tag WHERE code IN('isolation','unilateral','upper_body','hypertrophy','strength','gym_required','dumbbell_tag','beginner_safe') LOOP INSERT INTO exercises.exercise_tag VALUES(v_var_id,v_id,NOW()) ON CONFLICT DO NOTHING; END LOOP;
        INSERT INTO exercises.exercise_variation VALUES(v_ex_id,v_var_id,0,NOW()) ON CONFLICT DO NOTHING;
    ELSE
        SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Cable Kickback';
        INSERT INTO exercises.exercise_variation VALUES(v_ex_id,v_var_id,0,NOW()) ON CONFLICT DO NOTHING;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Band Kickback') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,
            overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Band Kickback','beginner','isolation','push',true,false,'low',false,
            NULL,'public','active',jsonb_build_object('it',jsonb_build_object('name','Kickback con Elastico','description','Variante di Kickback Tricipiti - Esercizio: imposta una posizione stabile e lavora con ripetizioni controllate, curando ROM e tensione. Mantieni respirazione e postura per ridurre compensi.'),
                                 'en',jsonb_build_object('name','Band Kickback','description','Variation of Triceps Kickback - Exercise: set a stable position and perform controlled reps focusing on ROM and tension. Keep breathing and posture to reduce compensations.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='triceps_lateral_head'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',70,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.muscle WHERE code='triceps_medial_head'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',70,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.muscle WHERE code='anconeus'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'secondary',45,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='bodybuilding'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='dumbbell'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,true,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        FOR v_id IN SELECT id FROM exercises.tag WHERE code IN('isolation','unilateral','upper_body','hypertrophy','strength','gym_required','dumbbell_tag','beginner_safe') LOOP INSERT INTO exercises.exercise_tag VALUES(v_var_id,v_id,NOW()) ON CONFLICT DO NOTHING; END LOOP;
        INSERT INTO exercises.exercise_variation VALUES(v_ex_id,v_var_id,0,NOW()) ON CONFLICT DO NOTHING;
    ELSE
        SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Band Kickback';
        INSERT INTO exercises.exercise_variation VALUES(v_ex_id,v_var_id,0,NOW()) ON CONFLICT DO NOTHING;
    END IF;

END $$;

