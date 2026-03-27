-- =============================================================
-- Exercise: Pec Deck / Chest Fly Machine
-- Disciplines: bodybuilding
-- =============================================================
DO $$
DECLARE
    v_ex_id  UUID;
    v_var_id UUID;
    v_id     UUID;
BEGIN
    IF EXISTS (SELECT 1 FROM exercises.exercise WHERE name = 'Pec Deck / Chest Fly Machine') THEN
        RAISE NOTICE 'Already exists: Pec Deck / Chest Fly Machine'; RETURN;
    END IF;
    v_ex_id := gen_random_uuid();

    INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
    VALUES (
        v_ex_id, 'Pec Deck / Chest Fly Machine', 'beginner', 'isolation', 'push',
        false, false, 'low', false, NULL, 'public', 'active',
        jsonb_build_object(
            'it', jsonb_build_object('name','Pec Deck / Butterfly','description','Esercizio di isolamento pettorale su macchina butterfly dove i gomiti vengono posizionati sui supporti imbottiti e portati insieme davanti al petto. La macchina guida il movimento in totale sicurezza permettendo un picco di contrazione isometrica elevato; ideale per allenamento ad alto volume o come pump finale.'),
            'en', jsonb_build_object('name','Pec Deck / Butterfly','description','Pectoral isolation exercise on a butterfly machine where the elbows are placed on padded supports and brought together in front of the chest. The machine guides the movement in complete safety, allowing a high isometric contraction peak; ideal for high-volume training or as a final pump exercise.')
        ),
        NOW(), NOW()
    );

    -- MUSCLES
    SELECT id INTO v_id FROM exercises.muscle WHERE code='pec_major_mid'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'primary',80,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='pec_major_upper'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'secondary',30,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='deltoid_anterior'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'secondary',20,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- CATEGORIES
    SELECT id INTO v_id FROM exercises.category WHERE code='bodybuilding'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_ex_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- EQUIPMENT
    SELECT id INTO v_id FROM exercises.equipment WHERE code='pec_deck_machine'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_ex_id,v_id,true,true,1,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- TAGS
    FOR v_id IN SELECT id FROM exercises.tag WHERE code IN('isolation','horizontal_push','upper_body','bilateral','hypertrophy','machine_tag','gym_required') LOOP INSERT INTO exercises.exercise_tag VALUES(v_ex_id,v_id,NOW()) ON CONFLICT DO NOTHING; END LOOP;

    -- VARIANTS
    -- Reverse Pec Deck
    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Reverse Pec Deck') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES (v_var_id,'Reverse Pec Deck','beginner','compound','static',false,false,'medium',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Pec Deck Inverso','description','Variante inversa del pec deck eseguita girandosi verso la macchina e aprendo le braccia verso l''esterno. Isola il deltoide posteriore e i muscoli della cuffia dei rotatori; esercizio fondamentale per la salute della spalla e l''equilibrio muscolare del cingolo scapolare.'),'en',jsonb_build_object('name','Reverse Pec Deck','description','Reverse pec deck variation performed facing the machine and opening the arms outward. Isolates the posterior deltoid and rotator cuff muscles; a key exercise for shoulder health and scapular girdle muscular balance.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='deltoid_posterior'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',75,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.muscle WHERE code='infraspinatus'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'secondary',40,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.muscle WHERE code='teres_minor'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'secondary',35,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.muscle WHERE code='rhomboid_major'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'secondary',30,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='bodybuilding'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='pec_deck_machine'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,true,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        FOR v_id IN SELECT id FROM exercises.tag WHERE code IN('isolation','upper_body','bilateral','hypertrophy','machine_tag','gym_required') LOOP INSERT INTO exercises.exercise_tag VALUES(v_var_id,v_id,NOW()) ON CONFLICT DO NOTHING; END LOOP;
        INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,0,NOW()) ON CONFLICT DO NOTHING;
    ELSE
        SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Reverse Pec Deck';
        INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,0,NOW()) ON CONFLICT DO NOTHING;
    END IF;

END $$;
