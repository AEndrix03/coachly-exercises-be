-- =============================================================
-- Exercise: Standing Calf Raise
-- Disciplines: home_workout
-- =============================================================
DO $$
DECLARE v_ex_id UUID; v_var_id UUID; v_id UUID;
BEGIN
    IF EXISTS (SELECT 1 FROM exercises.exercise WHERE name = 'Standing Calf Raise') THEN
        RAISE NOTICE 'Already exists: Standing Calf Raise'; RETURN;
    END IF;
    v_ex_id := gen_random_uuid();

    INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
    VALUES (v_ex_id,'Standing Calf Raise','beginner','isolation','push',false,true,'low',false,NULL,'public','active',
        jsonb_build_object('it',jsonb_build_object('name','Alzata del Polpaccio in Piedi','description','Imposta una posizione stabile e metti in brace il core prima di iniziare. Muoviti in un ROM controllato, mantieni l''allineamento articolare e chiudi ogni ripetizione con tensione totale.'),
                           'en',jsonb_build_object('name','Standing Calf Raise','description','Set up in a stable position and brace the core before starting the movement. Move through a controlled range of motion, keep joint alignment clean, and finish each rep with full-body tension.')),NOW(),NOW());

    -- MUSCLES
    SELECT id INTO v_id FROM exercises.muscle WHERE code='soleus'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'secondary',55,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='tibialis_posterior'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'secondary',45,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='fibularis_longus'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'secondary',35,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- CATEGORIES
    SELECT id INTO v_id FROM exercises.category WHERE code='home_workout'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_ex_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- EQUIPMENT
    SELECT id INTO v_id FROM exercises.equipment WHERE code='none_bodyweight'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_ex_id,v_id,true,true,1,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- TAGS
    FOR v_id IN SELECT id FROM exercises.tag WHERE code IN('isolation','horizontal_push','bilateral','upper_body','no_equipment','home_friendly') LOOP INSERT INTO exercises.exercise_tag VALUES(v_ex_id,v_id,NOW()) ON CONFLICT DO NOTHING; END LOOP;

    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Single-Leg Calf Raise') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Single-Leg Calf Raise','intermediate','isolation','push',false,true,'low',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Alzata del Polpaccio su una Gamba','description','Variante di Standing Calf Raise che modifica leva o tempo per lavorare lo stesso schema. Mantieni un setup solido e muoviti in controllo senza perdere posizione.'),
                               'en',jsonb_build_object('name','Single-Leg Calf Raise','description','Variation of Standing Calf Raise that changes leverage or tempo to target the same pattern. Keep the same tight setup and move under control without losing position.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.category WHERE code='home_workout'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='none_bodyweight'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,true,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        INSERT INTO exercises.exercise_variation VALUES(v_ex_id,v_var_id,1,NOW()) ON CONFLICT DO NOTHING;
    ELSE
        SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Single-Leg Calf Raise';
        INSERT INTO exercises.exercise_variation VALUES(v_ex_id,v_var_id,1,NOW()) ON CONFLICT DO NOTHING;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Weighted Calf Raise') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Weighted Calf Raise','beginner','isolation','push',false,false,'low',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Alzata del Polpaccio con Peso','description','Variante di Standing Calf Raise che modifica leva o tempo per lavorare lo stesso schema. Mantieni un setup solido e muoviti in controllo senza perdere posizione.'),
                               'en',jsonb_build_object('name','Weighted Calf Raise','description','Variation of Standing Calf Raise that changes leverage or tempo to target the same pattern. Keep the same tight setup and move under control without losing position.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.category WHERE code='home_workout'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='none_bodyweight'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,true,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='weight_vest'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,false,false,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        INSERT INTO exercises.exercise_variation VALUES(v_ex_id,v_var_id,2,NOW()) ON CONFLICT DO NOTHING;
    ELSE
        SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Weighted Calf Raise';
        INSERT INTO exercises.exercise_variation VALUES(v_ex_id,v_var_id,2,NOW()) ON CONFLICT DO NOTHING;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Donkey Calf Raise') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Donkey Calf Raise','intermediate','isolation','push',false,true,'low',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Alzata del Polpaccio da Asino','description','Variante di Standing Calf Raise che modifica leva o tempo per lavorare lo stesso schema. Mantieni un setup solido e muoviti in controllo senza perdere posizione.'),
                               'en',jsonb_build_object('name','Donkey Calf Raise','description','Variation of Standing Calf Raise that changes leverage or tempo to target the same pattern. Keep the same tight setup and move under control without losing position.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.category WHERE code='home_workout'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='none_bodyweight'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,true,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        INSERT INTO exercises.exercise_variation VALUES(v_ex_id,v_var_id,1,NOW()) ON CONFLICT DO NOTHING;
    ELSE
        SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Donkey Calf Raise';
        INSERT INTO exercises.exercise_variation VALUES(v_ex_id,v_var_id,1,NOW()) ON CONFLICT DO NOTHING;
    END IF;
END $$;

