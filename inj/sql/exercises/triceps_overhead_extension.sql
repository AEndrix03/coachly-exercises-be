-- =============================================================
-- Exercise: Triceps Overhead Extension
-- =============================================================
DO $$
DECLARE v_ex_id UUID; v_var_id UUID; v_id UUID;
BEGIN
    IF EXISTS (SELECT 1 FROM exercises.exercise WHERE name = 'Triceps Overhead Extension') THEN
        SELECT id INTO v_ex_id FROM exercises.exercise WHERE name = 'Triceps Overhead Extension';
        SELECT id INTO v_id FROM exercises.category WHERE code='bodybuilding'; IF v_id IS NOT NULL AND v_ex_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_ex_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        RAISE NOTICE 'Already exists, category updated: Triceps Overhead Extension'; RETURN;
    END IF;
    v_ex_id := gen_random_uuid();

    INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,
        overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
    VALUES (v_ex_id,'Triceps Overhead Extension','beginner','isolation','push',
        false,false,'low',false,NULL,'public','active',
        jsonb_build_object(
            'it',jsonb_build_object('name','Estensione Tricipiti Sopra la Testa','description','Isolamento tricipiti: tieni il braccio fermo e muovi solo il gomito, portando il carico vicino alla testa e poi estendendo. Mantieni scapole stabili e controlla l''eccentrica per non irritare i gomiti.'),
            'en',jsonb_build_object('name','Triceps Overhead Extension','description','Triceps isolation: keep the upper arm still and move only at the elbow, lowering the load near the head and then extending. Keep shoulder blades set and control the eccentric to avoid elbow irritation.')
        ), NOW(), NOW());

    -- MUSCLES
    SELECT id INTO v_id FROM exercises.muscle WHERE code='triceps_long_head'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'primary',80,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='triceps_lateral_head'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'secondary',55,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='triceps_medial_head'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'secondary',50,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- CATEGORIES
    SELECT id INTO v_id FROM exercises.category WHERE code='bodybuilding'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_ex_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- EQUIPMENT
    SELECT id INTO v_id FROM exercises.equipment WHERE code='ez_bar'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_ex_id,v_id,true,true,1,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- TAGS
    FOR v_id IN SELECT id FROM exercises.tag WHERE code IN('isolation','bilateral','upper_body','hypertrophy','strength','gym_required','beginner_safe')
    LOOP INSERT INTO exercises.exercise_tag VALUES(v_ex_id,v_id,NOW()) ON CONFLICT DO NOTHING; END LOOP;

    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Single Arm Overhead Extension') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,
            overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Single Arm Overhead Extension','beginner','isolation','push',true,false,'low',false,
            NULL,'public','active',jsonb_build_object('it',jsonb_build_object('name','Estensione Monobraccia Sopra Testa','description','Variante di Estensione Tricipiti Sopra la Testa - Isolamento tricipiti: tieni il braccio fermo e muovi solo il gomito, portando il carico vicino alla testa e poi estendendo. Mantieni scapole stabili e controlla l''eccentrica per non irritare i gomiti.'),
                                 'en',jsonb_build_object('name','Single Arm Overhead Extension','description','Variation of Triceps Overhead Extension - Triceps isolation: keep the upper arm still and move only at the elbow, lowering the load near the head and then extending. Keep shoulder blades set and control the eccentric to avoid elbow irritation.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='triceps_long_head'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',70,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.muscle WHERE code='triceps_lateral_head'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'secondary',45,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.muscle WHERE code='triceps_medial_head'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'secondary',45,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='bodybuilding'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='ez_bar'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,true,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        FOR v_id IN SELECT id FROM exercises.tag WHERE code IN('isolation','bilateral','upper_body','hypertrophy','strength','gym_required','beginner_safe') LOOP INSERT INTO exercises.exercise_tag VALUES(v_var_id,v_id,NOW()) ON CONFLICT DO NOTHING; END LOOP;
        INSERT INTO exercises.exercise_variation VALUES(v_ex_id,v_var_id,0,NOW()) ON CONFLICT DO NOTHING;
    ELSE
        SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Single Arm Overhead Extension';
        INSERT INTO exercises.exercise_variation VALUES(v_ex_id,v_var_id,0,NOW()) ON CONFLICT DO NOTHING;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Barbell Overhead Extension') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,
            overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Barbell Overhead Extension','intermediate','isolation','push',false,false,'low',false,
            NULL,'public','active',jsonb_build_object('it',jsonb_build_object('name','Estensione Bilanciere Sopra Testa','description','Variante di Estensione Tricipiti Sopra la Testa - Isolamento tricipiti: tieni il braccio fermo e muovi solo il gomito, portando il carico vicino alla testa e poi estendendo. Mantieni scapole stabili e controlla l''eccentrica per non irritare i gomiti.'),
                                 'en',jsonb_build_object('name','Barbell Overhead Extension','description','Variation of Triceps Overhead Extension - Triceps isolation: keep the upper arm still and move only at the elbow, lowering the load near the head and then extending. Keep shoulder blades set and control the eccentric to avoid elbow irritation.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='triceps_long_head'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',70,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.muscle WHERE code='triceps_lateral_head'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'secondary',45,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.muscle WHERE code='triceps_medial_head'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'secondary',45,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='bodybuilding'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='ez_bar'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,true,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        FOR v_id IN SELECT id FROM exercises.tag WHERE code IN('isolation','bilateral','upper_body','hypertrophy','strength','gym_required','beginner_safe') LOOP INSERT INTO exercises.exercise_tag VALUES(v_var_id,v_id,NOW()) ON CONFLICT DO NOTHING; END LOOP;
        INSERT INTO exercises.exercise_variation VALUES(v_ex_id,v_var_id,1,NOW()) ON CONFLICT DO NOTHING;
    ELSE
        SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Barbell Overhead Extension';
        INSERT INTO exercises.exercise_variation VALUES(v_ex_id,v_var_id,1,NOW()) ON CONFLICT DO NOTHING;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Cable Overhead Extension') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,
            overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Cable Overhead Extension','beginner','isolation','push',false,false,'low',false,
            NULL,'public','active',jsonb_build_object('it',jsonb_build_object('name','Estensione ai Cavi Sopra Testa','description','Variante di Estensione Tricipiti Sopra la Testa - Isolamento tricipiti: tieni il braccio fermo e muovi solo il gomito, portando il carico vicino alla testa e poi estendendo. Mantieni scapole stabili e controlla l''eccentrica per non irritare i gomiti.'),
                                 'en',jsonb_build_object('name','Cable Overhead Extension','description','Variation of Triceps Overhead Extension - Triceps isolation: keep the upper arm still and move only at the elbow, lowering the load near the head and then extending. Keep shoulder blades set and control the eccentric to avoid elbow irritation.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='triceps_long_head'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',70,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.muscle WHERE code='triceps_lateral_head'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'secondary',45,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.muscle WHERE code='triceps_medial_head'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'secondary',45,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='bodybuilding'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='ez_bar'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,true,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        FOR v_id IN SELECT id FROM exercises.tag WHERE code IN('isolation','bilateral','upper_body','hypertrophy','strength','gym_required','beginner_safe') LOOP INSERT INTO exercises.exercise_tag VALUES(v_var_id,v_id,NOW()) ON CONFLICT DO NOTHING; END LOOP;
        INSERT INTO exercises.exercise_variation VALUES(v_ex_id,v_var_id,0,NOW()) ON CONFLICT DO NOTHING;
    ELSE
        SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Cable Overhead Extension';
        INSERT INTO exercises.exercise_variation VALUES(v_ex_id,v_var_id,0,NOW()) ON CONFLICT DO NOTHING;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Seated Overhead Extension') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,
            overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Seated Overhead Extension','beginner','isolation','push',false,false,'low',false,
            NULL,'public','active',jsonb_build_object('it',jsonb_build_object('name','Estensione Seduto Sopra Testa','description','Variante di Estensione Tricipiti Sopra la Testa - Isolamento tricipiti: tieni il braccio fermo e muovi solo il gomito, portando il carico vicino alla testa e poi estendendo. Mantieni scapole stabili e controlla l''eccentrica per non irritare i gomiti.'),
                                 'en',jsonb_build_object('name','Seated Overhead Extension','description','Variation of Triceps Overhead Extension - Triceps isolation: keep the upper arm still and move only at the elbow, lowering the load near the head and then extending. Keep shoulder blades set and control the eccentric to avoid elbow irritation.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='triceps_long_head'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',70,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.muscle WHERE code='triceps_lateral_head'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'secondary',45,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.muscle WHERE code='triceps_medial_head'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'secondary',45,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='bodybuilding'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='ez_bar'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,true,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        FOR v_id IN SELECT id FROM exercises.tag WHERE code IN('isolation','bilateral','upper_body','hypertrophy','strength','gym_required','beginner_safe') LOOP INSERT INTO exercises.exercise_tag VALUES(v_var_id,v_id,NOW()) ON CONFLICT DO NOTHING; END LOOP;
        INSERT INTO exercises.exercise_variation VALUES(v_ex_id,v_var_id,0,NOW()) ON CONFLICT DO NOTHING;
    ELSE
        SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Seated Overhead Extension';
        INSERT INTO exercises.exercise_variation VALUES(v_ex_id,v_var_id,0,NOW()) ON CONFLICT DO NOTHING;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='EZ Bar Overhead Extension') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,
            overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'EZ Bar Overhead Extension','beginner','isolation','push',false,false,'low',false,
            NULL,'public','active',jsonb_build_object('it',jsonb_build_object('name','Estensione EZ Bar Sopra Testa','description','Variante di Estensione Tricipiti Sopra la Testa - Isolamento tricipiti: tieni il braccio fermo e muovi solo il gomito, portando il carico vicino alla testa e poi estendendo. Mantieni scapole stabili e controlla l''eccentrica per non irritare i gomiti.'),
                                 'en',jsonb_build_object('name','EZ Bar Overhead Extension','description','Variation of Triceps Overhead Extension - Triceps isolation: keep the upper arm still and move only at the elbow, lowering the load near the head and then extending. Keep shoulder blades set and control the eccentric to avoid elbow irritation.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='triceps_long_head'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',70,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.muscle WHERE code='triceps_lateral_head'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'secondary',45,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.muscle WHERE code='triceps_medial_head'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'secondary',45,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='bodybuilding'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='ez_bar'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,true,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        FOR v_id IN SELECT id FROM exercises.tag WHERE code IN('isolation','bilateral','upper_body','hypertrophy','strength','gym_required','beginner_safe') LOOP INSERT INTO exercises.exercise_tag VALUES(v_var_id,v_id,NOW()) ON CONFLICT DO NOTHING; END LOOP;
        INSERT INTO exercises.exercise_variation VALUES(v_ex_id,v_var_id,0,NOW()) ON CONFLICT DO NOTHING;
    ELSE
        SELECT id INTO v_var_id FROM exercises.exercise WHERE name='EZ Bar Overhead Extension';
        INSERT INTO exercises.exercise_variation VALUES(v_ex_id,v_var_id,0,NOW()) ON CONFLICT DO NOTHING;
    END IF;

END $$;

