-- =============================================================
-- Exercise: Suitcase Carry
-- =============================================================
DO $$
DECLARE v_ex_id UUID; v_var_id UUID; v_id UUID;
BEGIN
    IF EXISTS (SELECT 1 FROM exercises.exercise WHERE name = 'Suitcase Carry') THEN
        SELECT id INTO v_ex_id FROM exercises.exercise WHERE name = 'Suitcase Carry';
        SELECT id INTO v_id FROM exercises.category WHERE code='bodybuilding'; IF v_id IS NOT NULL AND v_ex_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_ex_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        RAISE NOTICE 'Already exists, category updated: Suitcase Carry'; RETURN;
    END IF;
    v_ex_id := gen_random_uuid();

    INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,
        overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
    VALUES (v_ex_id,'Suitcase Carry','beginner','compound','static',
        true,false,'low',false,NULL,'public','active',
        jsonb_build_object(
            'it',jsonb_build_object('name','Cammino con Valigia','description','Trasporto carichi: postura alta, spalle basse e addome in brace, cammina con passi corti mantenendo il carico stabile. Non inclinarti: bacino livellato e respirazione regolare.'),
            'en',jsonb_build_object('name','Suitcase Carry','description','Loaded carry: stay tall with shoulders down and abs braced, walk with short steps keeping the load stable. Do not lean: keep the pelvis level and breathe steadily.')
        ), NOW(), NOW());

    -- MUSCLES
    SELECT id INTO v_id FROM exercises.muscle WHERE code='external_oblique'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'primary',80,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='internal_oblique'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'primary',75,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='transversus_abdom'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'primary',70,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='quadratus_lumborum'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'secondary',55,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='trap_upper'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'secondary',50,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='erector_spinae'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'secondary',45,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- CATEGORIES
    SELECT id INTO v_id FROM exercises.category WHERE code='bodybuilding'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_ex_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- EQUIPMENT
    SELECT id INTO v_id FROM exercises.equipment WHERE code='dumbbell'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_ex_id,v_id,true,true,1,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- TAGS
    FOR v_id IN SELECT id FROM exercises.tag WHERE code IN('compound','isometric','carry','anti_lateral','unilateral','core_focus','strength','gym_required')
    LOOP INSERT INTO exercises.exercise_tag VALUES(v_ex_id,v_id,NOW()) ON CONFLICT DO NOTHING; END LOOP;

END $$;

