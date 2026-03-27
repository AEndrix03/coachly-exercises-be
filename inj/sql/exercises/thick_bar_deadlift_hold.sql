-- =============================================================
-- Exercise: Thick Bar Deadlift Hold
-- Disciplines: powerlifting
-- =============================================================
DO $$
DECLARE v_ex_id UUID; v_var_id UUID; v_id UUID;
BEGIN
    IF EXISTS (SELECT 1 FROM exercises.exercise WHERE name = 'Thick Bar Deadlift Hold') THEN
        RAISE NOTICE 'Already exists: Thick Bar Deadlift Hold'; RETURN;
    END IF;
    v_ex_id := gen_random_uuid();

    INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
    VALUES (v_ex_id,'Thick Bar Deadlift Hold','intermediate','compound','static',false,false,'medium',false,NULL,'public','active',
        jsonb_build_object(
            'it',jsonb_build_object('name','Tenuta da Stacco con Barra Spessa','description','Tenuta isometrica al lockout con barra spessa (fat bar/axle) per aumentare la richiesta di presa. Arriva a lockout completo, spalle stabili e polsi neutri, poi mantieni il carico senza perdere postura.'),
            'en',jsonb_build_object('name','Thick Bar Deadlift Hold','description','Isometric lockout hold with a thick bar (fat bar/axle) to increase grip demand. Reach full lockout with stable shoulders and neutral wrists, then hold the load without losing posture.')
        ), NOW(), NOW());

    -- MUSCLES
    SELECT id INTO v_id FROM exercises.muscle WHERE code='flexor_digitorum_superfic'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'primary',75,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='flexor_carpi_radialis'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'primary',65,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='flexor_carpi_ulnaris'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'primary',65,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='brachioradialis'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'secondary',45,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='lat_dorsi'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'tertiary',25,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- CATEGORIES
    SELECT id INTO v_id FROM exercises.category WHERE code='powerlifting'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_ex_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- EQUIPMENT
    SELECT id INTO v_id FROM exercises.equipment WHERE code='axle_bar'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_ex_id,v_id,true,true,1,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- TAGS
    FOR v_id IN SELECT id FROM exercises.tag WHERE code IN('compound','isometric','upper_body','bilateral','strength','barbell_tag','gym_required')
    LOOP INSERT INTO exercises.exercise_tag VALUES(v_ex_id,v_id,NOW()) ON CONFLICT DO NOTHING; END LOOP;

    -- VARIANTS
    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Weighted Thick Bar Deadlift Hold') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Weighted Thick Bar Deadlift Hold','intermediate','compound','static',false,false,'medium',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Tenuta Barra Spessa Zavorrata','description','Progressione della tenuta su barra spessa aumentando il carico mantenendo lockout e presa puliti.'),
                               'en',jsonb_build_object('name','Weighted Thick Bar Deadlift Hold','description','Progression increasing the load while keeping a clean lockout and grip on a thick bar.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='flexor_digitorum_superfic'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',75,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='powerlifting'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='axle_bar'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,true,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        INSERT INTO exercises.exercise_variation VALUES(v_ex_id,v_var_id,0,NOW()) ON CONFLICT DO NOTHING;
    ELSE
        SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Weighted Thick Bar Deadlift Hold';
        INSERT INTO exercises.exercise_variation VALUES(v_ex_id,v_var_id,0,NOW()) ON CONFLICT DO NOTHING;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Single-Arm Thick Bar Deadlift Hold') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Single-Arm Thick Bar Deadlift Hold','advanced','compound','static',true,false,'medium',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Tenuta Barra Spessa a Un Braccio','description','Variante unilaterale per aumentare richiesta di presa e anti-rotazione; usa carichi ridotti e controllo totale.'),
                               'en',jsonb_build_object('name','Single-Arm Thick Bar Deadlift Hold','description','Unilateral variation increasing grip and anti-rotation demands; use reduced loads and strict control.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='flexor_digitorum_superfic'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',75,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='powerlifting'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='axle_bar'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,true,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        INSERT INTO exercises.exercise_variation VALUES(v_ex_id,v_var_id,1,NOW()) ON CONFLICT DO NOTHING;
    ELSE
        SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Single-Arm Thick Bar Deadlift Hold';
        INSERT INTO exercises.exercise_variation VALUES(v_ex_id,v_var_id,1,NOW()) ON CONFLICT DO NOTHING;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Offset Thick Bar Deadlift Hold') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Offset Thick Bar Deadlift Hold','advanced','compound','static',false,false,'medium',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Tenuta Barra Spessa Decentrata','description','Tenuta con carico decentrato (asimmetrico) per aumentare richiesta di stabilita e presa mantenendo lockout pulito.'),
                               'en',jsonb_build_object('name','Offset Thick Bar Deadlift Hold','description','Offset/asymmetric loading to increase stability and grip demands while holding a clean lockout.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='flexor_digitorum_superfic'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',75,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='powerlifting'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='axle_bar'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,true,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        INSERT INTO exercises.exercise_variation VALUES(v_ex_id,v_var_id,1,NOW()) ON CONFLICT DO NOTHING;
    ELSE
        SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Offset Thick Bar Deadlift Hold';
        INSERT INTO exercises.exercise_variation VALUES(v_ex_id,v_var_id,1,NOW()) ON CONFLICT DO NOTHING;
    END IF;

END $$;

