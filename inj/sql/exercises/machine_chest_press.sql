-- =============================================================
-- Exercise: Machine Chest Press
-- Disciplines: bodybuilding
-- =============================================================
DO $$
DECLARE
    v_ex_id  UUID;
    v_var_id UUID;
    v_id     UUID;
BEGIN
    IF EXISTS (SELECT 1 FROM exercises.exercise WHERE name = 'Machine Chest Press') THEN
        RAISE NOTICE 'Already exists: Machine Chest Press'; RETURN;
    END IF;
    v_ex_id := gen_random_uuid();

    INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
    VALUES (
        v_ex_id, 'Machine Chest Press', 'beginner', 'compound', 'push',
        false, false, 'low', false, NULL, 'public', 'active',
        jsonb_build_object(
            'it', jsonb_build_object('name','Chest Press alla Macchina','description','Press per il petto eseguito su macchina guidata che elimina la necessità di equilibrio e stabilizzazione. Ideale per principianti o per aumentare il volume con affaticamento elevato; la macchina garantisce una traiettoria sicura e controllata permettendo di focalizzarsi sulla contrazione pettorale.'),
            'en', jsonb_build_object('name','Machine Chest Press','description','Chest press performed on a guided machine that eliminates the need for balance and stabilization. Ideal for beginners or for adding volume under high fatigue; the machine provides a safe, controlled path allowing full focus on the pectoral contraction.')
        ),
        NOW(), NOW()
    );

    -- MUSCLES
    SELECT id INTO v_id FROM exercises.muscle WHERE code='pec_major_mid'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'primary',70,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='pec_major_upper'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'secondary',35,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='deltoid_anterior'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'secondary',30,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='triceps_lateral_head'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'secondary',30,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- CATEGORIES
    SELECT id INTO v_id FROM exercises.category WHERE code='bodybuilding'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_ex_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- EQUIPMENT
    SELECT id INTO v_id FROM exercises.equipment WHERE code='chest_press_machine'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_ex_id,v_id,true,true,1,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- TAGS
    FOR v_id IN SELECT id FROM exercises.tag WHERE code IN('compound','horizontal_push','upper_body','bilateral','hypertrophy','machine_tag','gym_required') LOOP INSERT INTO exercises.exercise_tag VALUES(v_ex_id,v_id,NOW()) ON CONFLICT DO NOTHING; END LOOP;

    -- VARIANTS
    -- Incline Machine Chest Press
    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Incline Machine Chest Press') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Incline Machine Chest Press','beginner','compound','push',false,false,'low',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Chest Press Inclinata alla Macchina','description','Versione inclinata della chest press machine che enfatizza la porzione clavicolare del pettorale. Sicura e guidata, ideale per chi inizia a lavorare il petto alto senza il rischio di caduta del bilanciere.'),'en',jsonb_build_object('name','Incline Machine Chest Press','description','Inclined version of the machine chest press emphasizing the clavicular pectoral head. Safe and guided, ideal for beginners targeting the upper chest without barbell drop risk.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='pec_major_upper'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',68,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.muscle WHERE code='deltoid_anterior'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'secondary',38,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.muscle WHERE code='triceps_lateral_head'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'secondary',25,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='bodybuilding'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='chest_press_machine'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,true,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        FOR v_id IN SELECT id FROM exercises.tag WHERE code IN('compound','horizontal_push','upper_body','bilateral','hypertrophy','machine_tag','gym_required') LOOP INSERT INTO exercises.exercise_tag VALUES(v_var_id,v_id,NOW()) ON CONFLICT DO NOTHING; END LOOP;
        INSERT INTO exercises.exercise_variation VALUES(v_ex_id,v_var_id,0,NOW()) ON CONFLICT DO NOTHING;
    ELSE
        SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Incline Machine Chest Press';
        INSERT INTO exercises.exercise_variation VALUES(v_ex_id,v_var_id,0,NOW()) ON CONFLICT DO NOTHING;
    END IF;

    -- Decline Machine Chest Press
    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Decline Machine Chest Press') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Decline Machine Chest Press','beginner','compound','push',false,false,'low',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Chest Press Declinata alla Macchina','description','Versione declinata della chest press machine che isola la porzione inferiore del pettorale. La macchina rende sicuro l''angolo declinato senza richiedere il bloccaggio dei piedi come sulla panca declinata libera.'),'en',jsonb_build_object('name','Decline Machine Chest Press','description','Declined version of the machine chest press isolating the lower pectoral. The machine makes the declined angle safe without requiring foot restraints like a free decline bench.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='pec_major_lower'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',68,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.muscle WHERE code='pec_major_mid'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'secondary',38,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.muscle WHERE code='triceps_lateral_head'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'secondary',28,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='bodybuilding'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='chest_press_machine'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,true,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        FOR v_id IN SELECT id FROM exercises.tag WHERE code IN('compound','horizontal_push','upper_body','bilateral','hypertrophy','machine_tag','gym_required') LOOP INSERT INTO exercises.exercise_tag VALUES(v_var_id,v_id,NOW()) ON CONFLICT DO NOTHING; END LOOP;
        INSERT INTO exercises.exercise_variation VALUES(v_ex_id,v_var_id,0,NOW()) ON CONFLICT DO NOTHING;
    ELSE
        SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Decline Machine Chest Press';
        INSERT INTO exercises.exercise_variation VALUES(v_ex_id,v_var_id,0,NOW()) ON CONFLICT DO NOTHING;
    END IF;

    -- Single Arm Machine Chest Press
    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Single Arm Machine Chest Press') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Single Arm Machine Chest Press','beginner','compound','push',true,false,'low',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Chest Press Monobraccia','description','Press unilaterale alla macchina che consente di focalizzarsi su un lato alla volta. Permette la correzione di squilibri di forza e ipertrofia tra i due lati del petto in sicurezza e con guida meccanica.'),'en',jsonb_build_object('name','Single Arm Machine Chest Press','description','Unilateral machine press allowing focus on one side at a time. Enables correction of strength and hypertrophy imbalances between the two pectoral sides safely with mechanical guidance.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='pec_major_mid'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',70,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.muscle WHERE code='deltoid_anterior'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'secondary',30,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='bodybuilding'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='chest_press_machine'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,true,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        FOR v_id IN SELECT id FROM exercises.tag WHERE code IN('compound','horizontal_push','upper_body','unilateral','hypertrophy','machine_tag','gym_required') LOOP INSERT INTO exercises.exercise_tag VALUES(v_var_id,v_id,NOW()) ON CONFLICT DO NOTHING; END LOOP;
        INSERT INTO exercises.exercise_variation VALUES(v_ex_id,v_var_id,0,NOW()) ON CONFLICT DO NOTHING;
    ELSE
        SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Single Arm Machine Chest Press';
        INSERT INTO exercises.exercise_variation VALUES(v_ex_id,v_var_id,0,NOW()) ON CONFLICT DO NOTHING;
    END IF;

    -- Converging Machine Chest Press
    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Converging Machine Chest Press') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Converging Machine Chest Press','beginner','compound','push',false,false,'low',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Chest Press Convergente','description','Macchina chest press con bracci convergenti che si avvicinano seguendo un arco naturale durante la pressione. Simula meglio il movimento naturale del grande pettorale rispetto alle macchine con traiettoria lineare, combinando elementi di fly e press.'),'en',jsonb_build_object('name','Converging Machine Chest Press','description','Chest press machine with converging arms that come together in a natural arc during the press. Better simulates the natural movement of the pectoralis major compared to linear machines, combining elements of fly and press.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='pec_major_mid'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',75,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.muscle WHERE code='pec_major_upper'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'secondary',35,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.muscle WHERE code='deltoid_anterior'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'secondary',28,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='bodybuilding'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='chest_press_machine'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,true,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        FOR v_id IN SELECT id FROM exercises.tag WHERE code IN('compound','horizontal_push','upper_body','bilateral','hypertrophy','machine_tag','gym_required') LOOP INSERT INTO exercises.exercise_tag VALUES(v_var_id,v_id,NOW()) ON CONFLICT DO NOTHING; END LOOP;
        INSERT INTO exercises.exercise_variation VALUES(v_ex_id,v_var_id,0,NOW()) ON CONFLICT DO NOTHING;
    ELSE
        SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Converging Machine Chest Press';
        INSERT INTO exercises.exercise_variation VALUES(v_ex_id,v_var_id,0,NOW()) ON CONFLICT DO NOTHING;
    END IF;

END $$;
