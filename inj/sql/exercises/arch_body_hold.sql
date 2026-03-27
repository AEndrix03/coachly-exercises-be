-- =============================================================
-- Exercise: Arch Body Hold
-- Disciplines: gymnastics
-- =============================================================
DO $$
DECLARE v_ex_id UUID; v_var_id UUID; v_id UUID;
BEGIN
    IF EXISTS (SELECT 1 FROM exercises.exercise WHERE name = 'Arch Body Hold') THEN
        RAISE NOTICE 'Already exists: Arch Body Hold'; RETURN;
    END IF;
    v_ex_id := gen_random_uuid();

    INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
    VALUES (v_ex_id,'Arch Body Hold','','','',false,false,'',false,NULL,'public','active',
        jsonb_build_object('it',jsonb_build_object('name','Posizione Arch','description','Imposta una posizione stabile e metti in brace il core prima di iniziare. Muoviti in un ROM controllato, mantieni l''allineamento articolare e chiudi ogni ripetizione con tensione totale.'),
                           'en',jsonb_build_object('name','Arch Body Hold','description','Set up in a stable position and brace the core before starting the movement. Move through a controlled range of motion, keep joint alignment clean, and finish each rep with full-body tension.')),NOW(),NOW());

    -- MUSCLES
    SELECT id INTO v_id FROM exercises.muscle WHERE code='rectus_abdominis'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'primary',80,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='transversus_abdom'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'primary',70,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='external_oblique'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'secondary',55,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='internal_oblique'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'secondary',45,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='serratus_anterior'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'secondary',35,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- CATEGORIES
    SELECT id INTO v_id FROM exercises.category WHERE code='gymnastics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_ex_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- EQUIPMENT
    SELECT id INTO v_id FROM exercises.equipment WHERE code='pull_up_bar'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_ex_id,v_id,true,true,1,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.equipment WHERE code='dip_bars'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_ex_id,v_id,false,false,1,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- TAGS
    FOR v_id IN SELECT id FROM exercises.tag WHERE code IN('','bilateral','core_focus','home_friendly','calisthenics_skill') LOOP INSERT INTO exercises.exercise_tag VALUES(v_ex_id,v_id,NOW()) ON CONFLICT DO NOTHING; END LOOP;

    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Rock Arch Body Hold') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Rock Arch Body Hold','intermediate','isolation','static',false,false,'',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Posizione Arch Rock','description','Variante di Arch Body Hold che modifica leva o tempo per lavorare lo stesso schema. Mantieni un setup solido e muoviti in controllo senza perdere posizione.'),
                               'en',jsonb_build_object('name','Rock Arch Body Hold','description','Variation of Arch Body Hold that changes leverage or tempo to target the same pattern. Keep the same tight setup and move under control without losing position.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='rectus_abdominis'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',75,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='gymnastics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='pull_up_bar'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,true,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='dip_bars'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,false,false,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        INSERT INTO exercises.exercise_variation VALUES(v_ex_id,v_var_id,2,NOW()) ON CONFLICT DO NOTHING;
    ELSE
        SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Rock Arch Body Hold';
        INSERT INTO exercises.exercise_variation VALUES(v_ex_id,v_var_id,2,NOW()) ON CONFLICT DO NOTHING;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Weighted Arch Body Hold') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Weighted Arch Body Hold','intermediate','isolation','static',false,false,'',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Posizione Arch con Sovraccarico','description','Variante di Arch Body Hold che modifica leva o tempo per lavorare lo stesso schema. Mantieni un setup solido e muoviti in controllo senza perdere posizione.'),
                               'en',jsonb_build_object('name','Weighted Arch Body Hold','description','Variation of Arch Body Hold that changes leverage or tempo to target the same pattern. Keep the same tight setup and move under control without losing position.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='rectus_abdominis'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',75,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='gymnastics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='pull_up_bar'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,true,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='weight_vest'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,false,false,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        INSERT INTO exercises.exercise_variation VALUES(v_ex_id,v_var_id,3,NOW()) ON CONFLICT DO NOTHING;
    ELSE
        SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Weighted Arch Body Hold';
        INSERT INTO exercises.exercise_variation VALUES(v_ex_id,v_var_id,3,NOW()) ON CONFLICT DO NOTHING;
    END IF;
END $$;
