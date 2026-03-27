-- =============================================================
-- Exercise: Board Press
-- Disciplines: powerlifting
-- =============================================================
DO $$
DECLARE v_ex_id UUID; v_var_id UUID; v_id UUID;
BEGIN
    IF EXISTS (SELECT 1 FROM exercises.exercise WHERE name = 'Board Press') THEN
        RAISE NOTICE 'Already exists: Board Press'; RETURN;
    END IF;
    v_ex_id := gen_random_uuid();

    INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
    VALUES (v_ex_id,'Board Press','intermediate','compound','push',false,false,'medium',true,NULL,'public','active',
        jsonb_build_object(
            'it',jsonb_build_object('name','Panca con Assi','description','Accessorio powerlifting in cui uno o piu assi di legno sono posizionati sul petto per limitare il range of motion. Permette di lavorare con carichi sopramassimali nella fase di lockout e mette in enfasi il lavoro dei tricipiti. Usato per superare sticking point nella fase alta della panca.'),
            'en',jsonb_build_object('name','Board Press','description','Powerlifting accessory where wooden boards are placed on the chest to limit range of motion. Allows supramaximal loads in the lockout phase and emphasizes triceps work. Used to break through sticking points in the upper bench press range.')),
        NOW(),NOW());

    -- MUSCLES
    SELECT id INTO v_id FROM exercises.muscle WHERE code='pec_major_mid'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'primary',60,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='triceps_lateral_head'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'primary',65,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='deltoid_anterior'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'secondary',35,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='triceps_long_head'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'secondary',45,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- CATEGORIES
    SELECT id INTO v_id FROM exercises.category WHERE code='powerlifting'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_ex_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- EQUIPMENT
    SELECT id INTO v_id FROM exercises.equipment WHERE code='barbell'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_ex_id,v_id,true,true,1,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.equipment WHERE code='flat_bench'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_ex_id,v_id,true,true,2,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- TAGS
    FOR v_id IN SELECT id FROM exercises.tag WHERE code IN('powerlifting','accessory','compound','strength','gym_required') LOOP INSERT INTO exercises.exercise_tag VALUES(v_ex_id,v_id,NOW()) ON CONFLICT DO NOTHING; END LOOP;

    -- VARIANT: 1-Board Press
    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='1-Board Press') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'1-Board Press','intermediate','compound','push',false,false,'medium',true,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Panca con 1 Asse','description','Board press con 1 asse sul petto, riduce il ROM di circa 3-5 cm, lavoro enfatizzato sulla fase di lockout.'),'en',jsonb_build_object('name','1-Board Press','description','Board press with 1 board on the chest, reducing ROM by ~3-5 cm, emphasizing lockout phase work.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='pec_major_mid'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',60,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='powerlifting'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='barbell'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,true,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        INSERT INTO exercises.exercise_variation VALUES(v_ex_id,v_var_id,1,NOW()) ON CONFLICT DO NOTHING;
    ELSE
        SELECT id INTO v_var_id FROM exercises.exercise WHERE name='1-Board Press';
        INSERT INTO exercises.exercise_variation VALUES(v_ex_id,v_var_id,1,NOW()) ON CONFLICT DO NOTHING;
    END IF;

    -- VARIANT: 2-Board Press
    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='2-Board Press') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'2-Board Press','intermediate','compound','push',false,false,'medium',true,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Panca con 2 Assi','description','Board press con 2 assi, ROM ridotto a meta percorso, massimizza il lavoro di lockout dei tricipiti.'),'en',jsonb_build_object('name','2-Board Press','description','Board press with 2 boards, ROM reduced to mid-range, maximizing triceps lockout work.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='triceps_lateral_head'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',65,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='powerlifting'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='barbell'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,true,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        INSERT INTO exercises.exercise_variation VALUES(v_ex_id,v_var_id,2,NOW()) ON CONFLICT DO NOTHING;
    ELSE
        SELECT id INTO v_var_id FROM exercises.exercise WHERE name='2-Board Press';
        INSERT INTO exercises.exercise_variation VALUES(v_ex_id,v_var_id,2,NOW()) ON CONFLICT DO NOTHING;
    END IF;

    -- VARIANT: 3-Board Press
    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='3-Board Press') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'3-Board Press','intermediate','compound','push',false,false,'medium',true,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Panca con 3 Assi','description','Board press con 3 assi, range of motion molto corto, permette carichi elevati per adattamenti neurali nel lockout.'),'en',jsonb_build_object('name','3-Board Press','description','Board press with 3 boards, very short ROM, allows heavy loads for neural adaptations in the lockout.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='triceps_lateral_head'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',70,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='powerlifting'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='barbell'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,true,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        INSERT INTO exercises.exercise_variation VALUES(v_ex_id,v_var_id,3,NOW()) ON CONFLICT DO NOTHING;
    ELSE
        SELECT id INTO v_var_id FROM exercises.exercise WHERE name='3-Board Press';
        INSERT INTO exercises.exercise_variation VALUES(v_ex_id,v_var_id,3,NOW()) ON CONFLICT DO NOTHING;
    END IF;

    -- VARIANT: 4-Board Press
    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='4-Board Press') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'4-Board Press','intermediate','compound','push',false,false,'medium',true,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Panca con 4 Assi','description','Board press con 4 assi, quasi solo lockout, permette carichi molto elevati per adattamenti di forza nella fase terminale del press.'),'en',jsonb_build_object('name','4-Board Press','description','Board press with 4 boards, almost pure lockout work, allows very heavy loads for strength adaptations in the terminal press phase.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='triceps_lateral_head'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',75,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='powerlifting'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='barbell'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,true,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        INSERT INTO exercises.exercise_variation VALUES(v_ex_id,v_var_id,4,NOW()) ON CONFLICT DO NOTHING;
    ELSE
        SELECT id INTO v_var_id FROM exercises.exercise WHERE name='4-Board Press';
        INSERT INTO exercises.exercise_variation VALUES(v_ex_id,v_var_id,4,NOW()) ON CONFLICT DO NOTHING;
    END IF;

END $$;
