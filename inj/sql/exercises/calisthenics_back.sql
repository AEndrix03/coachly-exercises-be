-- =============================================================
-- Calisthenics: Back Exercises
-- Disciplines: calisthenics
-- =============================================================

-- ─── Pull-Up ─────────────────────────────────────────────────
DO $$
DECLARE v_ex_id UUID; v_var_id UUID; v_id UUID;
BEGIN
    IF EXISTS (SELECT 1 FROM exercises.exercise WHERE name = 'Pull-Up') THEN
        RAISE NOTICE 'Already exists: Pull-Up'; RETURN;
    END IF;
    v_ex_id := gen_random_uuid();
    INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
    VALUES (v_ex_id,'Pull-Up','intermediate','compound','pull',false,true,'low',false,NULL,'public','active',
        jsonb_build_object('it',jsonb_build_object('name','Trazione alla Sbarra','description','Esercizio fondamentale di calistenia che sviluppa latissimo, romboidi e bicipiti. Partendo da un appeso passivo, tirare il corpo verso l''alto fino a portare il mento sopra la sbarra mantenendo le scapole depresse e retratte.'),'en',jsonb_build_object('name','Pull-Up','description','Fundamental calisthenics exercise developing the lats, rhomboids and biceps. From a dead hang, pull the body upward until the chin clears the bar while keeping the scapulae depressed and retracted.')),NOW(),NOW());
    SELECT id INTO v_id FROM exercises.muscle WHERE code='lat_dorsi'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'primary',50,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='teres_major'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'primary',25,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='rhomboid_major'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'primary',25,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='biceps_long_head'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'secondary',20,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='trap_middle'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'secondary',10,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='trap_lower'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'secondary',10,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.category WHERE code='calisthenics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_ex_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.equipment WHERE code='pull_up_bar'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_ex_id,v_id,true,false,1,NOW()) ON CONFLICT DO NOTHING; END IF;
    FOR v_id IN SELECT id FROM exercises.tag WHERE code IN('calisthenics','bodyweight','pull','back','bar') LOOP INSERT INTO exercises.exercise_tag VALUES(v_ex_id,v_id,NOW()) ON CONFLICT DO NOTHING; END LOOP;

    -- Variant: Dead Hang
    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Dead Hang') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Dead Hang','beginner','isolation','static',false,true,'low',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Appeso Passivo','description','Appendersi alla sbarra in modo passivo per sviluppare la presa e decomprimere la colonna vertebrale.'),'en',jsonb_build_object('name','Dead Hang','description','Hang passively from the bar to develop grip strength and decompress the spine.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='lat_dorsi'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',50,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='calisthenics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='pull_up_bar'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,false,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',-2,NOW()) ON CONFLICT DO NOTHING;
    ELSE SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Dead Hang'; INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',-2,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- Variant: Scapular Pull
    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Scapular Pull') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Scapular Pull','beginner','isolation','pull',false,true,'low',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Retrazione Scapolare','description','Movimento di attivazione scapolare da appeso che prepara alla trazione completa.'),'en',jsonb_build_object('name','Scapular Pull','description','Scapular activation movement from a hang that prepares for full pull-ups.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='trap_lower'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',50,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='calisthenics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='pull_up_bar'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,false,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',-2,NOW()) ON CONFLICT DO NOTHING;
    ELSE SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Scapular Pull'; INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',-2,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- Variant: Negative Pull-Up
    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Negative Pull-Up') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Negative Pull-Up','beginner','compound','pull',false,true,'low',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Trazione Negativa','description','Solo la fase eccentrica della trazione: partire dalla sbarra e abbassarsi lentamente.'),'en',jsonb_build_object('name','Negative Pull-Up','description','Only the eccentric phase of the pull-up: start at the bar and lower down slowly.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='lat_dorsi'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',50,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='calisthenics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='pull_up_bar'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,false,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',-1,NOW()) ON CONFLICT DO NOTHING;
    ELSE SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Negative Pull-Up'; INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',-1,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- Variant: Band-Assisted Pull-Up
    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Band-Assisted Pull-Up') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Band-Assisted Pull-Up','beginner','compound','pull',false,true,'low',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Trazione con Elastico','description','Trazione assistita da un elastico che riduce il carico corporeo. Ideale per imparare la tecnica.'),'en',jsonb_build_object('name','Band-Assisted Pull-Up','description','Pull-up assisted by a resistance band that reduces bodyweight load. Ideal for learning proper technique.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='lat_dorsi'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',50,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='calisthenics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='pull_up_bar'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,false,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='resistance_band'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,false,2,NOW()) ON CONFLICT DO NOTHING; END IF;
        INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',-1,NOW()) ON CONFLICT DO NOTHING;
    ELSE SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Band-Assisted Pull-Up'; INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',-1,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- Variant: Weighted Pull-Up
    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Weighted Pull-Up') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Weighted Pull-Up','advanced','compound','pull',false,true,'medium',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Trazione con Carico','description','Trazione eseguita con peso aggiuntivo (cintura, gilet zavorrato). Progressione avanzata per aumentare la forza di schiena.'),'en',jsonb_build_object('name','Weighted Pull-Up','description','Pull-up performed with added weight (belt, weighted vest). Advanced progression to increase back strength.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='lat_dorsi'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',50,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='calisthenics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='pull_up_bar'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,false,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',2,NOW()) ON CONFLICT DO NOTHING;
    ELSE SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Weighted Pull-Up'; INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',2,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- Variant: L-Sit Pull-Up
    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='L-Sit Pull-Up') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'L-Sit Pull-Up','advanced','compound','pull',false,true,'medium',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Trazione con L-Sit','description','Trazione eseguita mantenendo le gambe parallele al suolo in posizione L. Richiede forte controllo del core.'),'en',jsonb_build_object('name','L-Sit Pull-Up','description','Pull-up performed while holding the legs parallel to the floor in an L position. Requires strong core control.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='lat_dorsi'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',50,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.muscle WHERE code='rectus_abdominis'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'secondary',25,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='calisthenics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='pull_up_bar'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,false,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',2,NOW()) ON CONFLICT DO NOTHING;
    ELSE SELECT id INTO v_var_id FROM exercises.exercise WHERE name='L-Sit Pull-Up'; INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',2,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- Variant: Typewriter Pull-Up
    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Typewriter Pull-Up') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Typewriter Pull-Up','advanced','compound','pull',false,true,'medium',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Trazione Typewriter','description','Variazione avanzata della trazione in cui ci si sposta lateralmente lungo la sbarra come un carrello da macchina da scrivere.'),'en',jsonb_build_object('name','Typewriter Pull-Up','description','Advanced pull-up variation where you shift laterally along the bar like a typewriter carriage.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='lat_dorsi'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',50,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='calisthenics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='pull_up_bar'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,false,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',2,NOW()) ON CONFLICT DO NOTHING;
    ELSE SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Typewriter Pull-Up'; INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',2,NOW()) ON CONFLICT DO NOTHING; END IF;

END $$;

-- ─── Muscle-Up (Bar) ─────────────────────────────────────────
DO $$
DECLARE v_ex_id UUID; v_var_id UUID; v_id UUID;
BEGIN
    IF EXISTS (SELECT 1 FROM exercises.exercise WHERE name = 'Muscle-Up (Bar)') THEN
        RAISE NOTICE 'Already exists: Muscle-Up (Bar)'; RETURN;
    END IF;
    v_ex_id := gen_random_uuid();
    INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
    VALUES (v_ex_id,'Muscle-Up (Bar)','advanced','compound','pull',false,true,'medium',false,NULL,'public','active',
        jsonb_build_object('it',jsonb_build_object('name','Muscle-Up alla Sbarra','description','Esercizio avanzato che combina trazione e spinta: partendo da appeso, tirare sopra la sbarra e finire con le braccia tese sopra di essa.'),'en',jsonb_build_object('name','Muscle-Up (Bar)','description','Advanced exercise combining pull and push: from a hang, pull above the bar and finish with arms extended above it.')),NOW(),NOW());
    SELECT id INTO v_id FROM exercises.muscle WHERE code='lat_dorsi'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'primary',35,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='teres_major'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'primary',25,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='triceps_long_head'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'primary',25,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='rhomboid_major'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'secondary',15,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='biceps_long_head'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'secondary',15,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.category WHERE code='calisthenics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_ex_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.equipment WHERE code='pull_up_bar'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_ex_id,v_id,true,false,1,NOW()) ON CONFLICT DO NOTHING; END IF;
    FOR v_id IN SELECT id FROM exercises.tag WHERE code IN('calisthenics','bodyweight','bar','calisthenics_skill') LOOP INSERT INTO exercises.exercise_tag VALUES(v_ex_id,v_id,NOW()) ON CONFLICT DO NOTHING; END LOOP;

    -- Variant: Negative Muscle-Up
    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Negative Muscle-Up') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Negative Muscle-Up','intermediate','compound','pull',false,true,'low',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Muscle-Up Negativo','description','Solo la fase discendente del muscle-up per costruire forza e coordinazione.'),'en',jsonb_build_object('name','Negative Muscle-Up','description','Only the descending phase of the muscle-up to build strength and coordination.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='lat_dorsi'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',40,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='calisthenics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='pull_up_bar'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,false,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',-1,NOW()) ON CONFLICT DO NOTHING;
    ELSE SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Negative Muscle-Up'; INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',-1,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- Variant: Band-Assisted Muscle-Up
    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Band-Assisted Muscle-Up') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Band-Assisted Muscle-Up','intermediate','compound','pull',false,true,'low',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Muscle-Up con Elastico','description','Muscle-up assistito con elastico per apprendere il movimento prima di eseguirlo a corpo libero.'),'en',jsonb_build_object('name','Band-Assisted Muscle-Up','description','Band-assisted muscle-up to learn the movement before performing it unassisted.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='lat_dorsi'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',40,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='calisthenics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='pull_up_bar'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,false,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='resistance_band'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,false,2,NOW()) ON CONFLICT DO NOTHING; END IF;
        INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',-1,NOW()) ON CONFLICT DO NOTHING;
    ELSE SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Band-Assisted Muscle-Up'; INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',-1,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- Variant: Strict Muscle-Up
    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Strict Muscle-Up') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Strict Muscle-Up','advanced','compound','pull',false,true,'medium',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Muscle-Up Stretto','description','Versione strettamente controllata del muscle-up senza slancio delle gambe o kipping.'),'en',jsonb_build_object('name','Strict Muscle-Up','description','Strictly controlled version of the muscle-up without leg swing or kipping.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='lat_dorsi'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',40,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='calisthenics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='pull_up_bar'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,false,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',2,NOW()) ON CONFLICT DO NOTHING;
    ELSE SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Strict Muscle-Up'; INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',2,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- Variant: Ring Muscle-Up
    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Ring Muscle-Up') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Ring Muscle-Up','advanced','compound','pull',false,true,'medium',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Muscle-Up agli Anelli','description','Muscle-up eseguito agli anelli ginnici, più tecnico e instabile rispetto alla sbarra.'),'en',jsonb_build_object('name','Ring Muscle-Up','description','Muscle-up performed on gymnastic rings, more technical and unstable than the bar version.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='lat_dorsi'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',40,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='calisthenics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='gymnastic_rings'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,false,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',1,NOW()) ON CONFLICT DO NOTHING;
    ELSE SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Ring Muscle-Up'; INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',1,NOW()) ON CONFLICT DO NOTHING; END IF;

END $$;

-- ─── Front Lever ─────────────────────────────────────────────
DO $$
DECLARE v_ex_id UUID; v_var_id UUID; v_id UUID;
BEGIN
    IF EXISTS (SELECT 1 FROM exercises.exercise WHERE name = 'Front Lever') THEN
        RAISE NOTICE 'Already exists: Front Lever'; RETURN;
    END IF;
    v_ex_id := gen_random_uuid();
    INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
    VALUES (v_ex_id,'Front Lever','advanced','compound','static',false,true,'high',false,NULL,'public','active',
        jsonb_build_object('it',jsonb_build_object('name','Leva Frontale','description','Skill ginnico d''élite: tenere il corpo orizzontale davanti alla sbarra con le braccia tese. Richiede forza enorme di schiena, core e spalle.'),'en',jsonb_build_object('name','Front Lever','description','Elite gymnastics skill: hold the body horizontal in front of the bar with straight arms. Requires immense back, core and shoulder strength.')),NOW(),NOW());
    SELECT id INTO v_id FROM exercises.muscle WHERE code='lat_dorsi'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'primary',45,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='teres_major'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'primary',25,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='rhomboid_major'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'primary',20,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='rectus_abdominis'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'secondary',20,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='trap_lower'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'secondary',10,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.category WHERE code='calisthenics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_ex_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.equipment WHERE code='pull_up_bar'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_ex_id,v_id,false,false,1,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.equipment WHERE code='gymnastic_rings'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_ex_id,v_id,false,false,2,NOW()) ON CONFLICT DO NOTHING; END IF;
    FOR v_id IN SELECT id FROM exercises.tag WHERE code IN('calisthenics','bodyweight','isometric','calisthenics_skill') LOOP INSERT INTO exercises.exercise_tag VALUES(v_ex_id,v_id,NOW()) ON CONFLICT DO NOTHING; END LOOP;

    -- Variant: Tuck Front Lever
    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Tuck Front Lever') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Tuck Front Lever','intermediate','compound','static',false,true,'medium',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Leva Frontale Tuck','description','Prima progressione della leva frontale con le ginocchia piegate al petto.'),'en',jsonb_build_object('name','Tuck Front Lever','description','First progression of the front lever with knees tucked to the chest.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='lat_dorsi'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',45,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='calisthenics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='pull_up_bar'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,false,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',-2,NOW()) ON CONFLICT DO NOTHING;
    ELSE SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Tuck Front Lever'; INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',-2,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- Variant: Advanced Tuck Front Lever
    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Advanced Tuck Front Lever') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Advanced Tuck Front Lever','advanced','compound','static',false,true,'medium',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Leva Frontale Advanced Tuck','description','Progressione intermedia con schiena parallela al suolo e ginocchia piegate a 90°.'),'en',jsonb_build_object('name','Advanced Tuck Front Lever','description','Intermediate progression with back parallel to the floor and knees bent at 90 degrees.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='lat_dorsi'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',45,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='calisthenics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='pull_up_bar'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,false,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',-1,NOW()) ON CONFLICT DO NOTHING;
    ELSE SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Advanced Tuck Front Lever'; INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',-1,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- Variant: Straddle Front Lever
    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Straddle Front Lever') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Straddle Front Lever','advanced','compound','static',false,true,'high',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Leva Frontale Straddle','description','Progressione avanzata della leva frontale con le gambe divaricate per ridurre il momento di inerzia.'),'en',jsonb_build_object('name','Straddle Front Lever','description','Advanced front lever progression with legs spread apart to reduce moment of inertia.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='lat_dorsi'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',45,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='calisthenics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='pull_up_bar'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,false,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',-1,NOW()) ON CONFLICT DO NOTHING;
    ELSE SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Straddle Front Lever'; INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',-1,NOW()) ON CONFLICT DO NOTHING; END IF;

END $$;

-- ─── Back Lever ──────────────────────────────────────────────
DO $$
DECLARE v_ex_id UUID; v_var_id UUID; v_id UUID;
BEGIN
    IF EXISTS (SELECT 1 FROM exercises.exercise WHERE name = 'Back Lever') THEN
        RAISE NOTICE 'Already exists: Back Lever'; RETURN;
    END IF;
    v_ex_id := gen_random_uuid();
    INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
    VALUES (v_ex_id,'Back Lever','advanced','compound','static',false,true,'high',false,NULL,'public','active',
        jsonb_build_object('it',jsonb_build_object('name','Leva Posteriore','description','Skill ginnico avanzato: tenere il corpo orizzontale dietro la sbarra con le braccia tese. Sviluppa forza di schiena, bicipiti e glutei.'),'en',jsonb_build_object('name','Back Lever','description','Advanced gymnastics skill: hold the body horizontal behind the bar with straight arms. Develops back, biceps and glute strength.')),NOW(),NOW());
    SELECT id INTO v_id FROM exercises.muscle WHERE code='lat_dorsi'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'primary',35,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='teres_major'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'primary',25,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='erector_spinae'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'primary',25,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='biceps_long_head'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'secondary',20,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='rhomboid_major'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'secondary',15,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.category WHERE code='calisthenics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_ex_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.equipment WHERE code='pull_up_bar'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_ex_id,v_id,false,false,1,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.equipment WHERE code='gymnastic_rings'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_ex_id,v_id,false,false,2,NOW()) ON CONFLICT DO NOTHING; END IF;
    FOR v_id IN SELECT id FROM exercises.tag WHERE code IN('calisthenics','bodyweight','isometric','calisthenics_skill') LOOP INSERT INTO exercises.exercise_tag VALUES(v_ex_id,v_id,NOW()) ON CONFLICT DO NOTHING; END LOOP;

    -- Variant: Tuck Back Lever
    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Tuck Back Lever') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Tuck Back Lever','intermediate','compound','static',false,true,'medium',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Leva Posteriore Tuck','description','Prima progressione della leva posteriore con le ginocchia piegate al petto.'),'en',jsonb_build_object('name','Tuck Back Lever','description','First progression of the back lever with knees tucked to the chest.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='lat_dorsi'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',40,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='calisthenics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='pull_up_bar'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,false,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',-2,NOW()) ON CONFLICT DO NOTHING;
    ELSE SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Tuck Back Lever'; INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',-2,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- Variant: Advanced Tuck Back Lever
    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Advanced Tuck Back Lever') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Advanced Tuck Back Lever','advanced','compound','static',false,true,'medium',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Leva Posteriore Advanced Tuck','description','Progressione intermedia con schiena orizzontale e ginocchia a 90°.'),'en',jsonb_build_object('name','Advanced Tuck Back Lever','description','Intermediate progression with horizontal back and knees at 90 degrees.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='lat_dorsi'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',40,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='calisthenics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='pull_up_bar'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,false,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',-1,NOW()) ON CONFLICT DO NOTHING;
    ELSE SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Advanced Tuck Back Lever'; INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',-1,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- Variant: Full Back Lever
    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Full Back Lever') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Full Back Lever','advanced','compound','static',false,true,'high',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Leva Posteriore Completa','description','Versione completa della leva posteriore con il corpo perfettamente orizzontale e gambe unite.'),'en',jsonb_build_object('name','Full Back Lever','description','Complete version of the back lever with the body perfectly horizontal and legs together.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='lat_dorsi'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',40,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='calisthenics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='pull_up_bar'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,false,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',1,NOW()) ON CONFLICT DO NOTHING;
    ELSE SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Full Back Lever'; INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',1,NOW()) ON CONFLICT DO NOTHING; END IF;

END $$;

-- ─── Inverted Row ─────────────────────────────────────────────
DO $$
DECLARE v_ex_id UUID; v_var_id UUID; v_id UUID;
BEGIN
    IF EXISTS (SELECT 1 FROM exercises.exercise WHERE name = 'Inverted Row') THEN
        RAISE NOTICE 'Already exists: Inverted Row'; RETURN;
    END IF;
    v_ex_id := gen_random_uuid();
    INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
    VALUES (v_ex_id,'Inverted Row','beginner','compound','pull',false,true,'low',false,NULL,'public','active',
        jsonb_build_object('it',jsonb_build_object('name','Remata Invertita','description','Esercizio di tiraggio bodyweight eseguito sotto una barra o tavolo. Ottima regressione per la trazione, sviluppa latissimo, romboidi e bicipiti.'),'en',jsonb_build_object('name','Inverted Row','description','Bodyweight rowing exercise performed under a bar or table. Excellent pull-up regression developing lats, rhomboids and biceps.')),NOW(),NOW());
    SELECT id INTO v_id FROM exercises.muscle WHERE code='lat_dorsi'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'primary',35,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='rhomboid_major'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'primary',30,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='trap_middle'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'primary',25,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='biceps_long_head'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'secondary',20,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='teres_major'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'secondary',15,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.category WHERE code='calisthenics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_ex_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.equipment WHERE code='pull_up_bar'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_ex_id,v_id,false,false,1,NOW()) ON CONFLICT DO NOTHING; END IF;
    FOR v_id IN SELECT id FROM exercises.tag WHERE code IN('calisthenics','bodyweight','pull','back','beginner_safe') LOOP INSERT INTO exercises.exercise_tag VALUES(v_ex_id,v_id,NOW()) ON CONFLICT DO NOTHING; END LOOP;

    -- Variant: Feet-Elevated Inverted Row
    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Feet-Elevated Inverted Row') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Feet-Elevated Inverted Row','intermediate','compound','pull',false,true,'low',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Remata Invertita con Piedi Elevati','description','Variante più difficile con i piedi su una superficie rialzata per aumentare il carico.'),'en',jsonb_build_object('name','Feet-Elevated Inverted Row','description','Harder variant with feet elevated on a surface to increase the load.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='lat_dorsi'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',40,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='calisthenics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='pull_up_bar'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,false,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',1,NOW()) ON CONFLICT DO NOTHING;
    ELSE SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Feet-Elevated Inverted Row'; INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',1,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- Variant: Ring Inverted Row
    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Ring Inverted Row') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Ring Inverted Row','intermediate','compound','pull',false,true,'low',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Remata Invertita agli Anelli','description','Versione con gli anelli ginnici che aggiunge instabilità e richiede maggiore controllo della rotazione.'),'en',jsonb_build_object('name','Ring Inverted Row','description','Rings version adding instability and requiring greater rotational control.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='lat_dorsi'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',40,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='calisthenics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='gymnastic_rings'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,false,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',1,NOW()) ON CONFLICT DO NOTHING;
    ELSE SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Ring Inverted Row'; INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',1,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- Variant: Archer Inverted Row
    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Archer Inverted Row') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Archer Inverted Row','advanced','compound','pull',true,true,'low',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Remata Invertita Arciere','description','Versione unilaterale avanzata che lavora su un braccio alla volta allargando l''altro lateralmente.'),'en',jsonb_build_object('name','Archer Inverted Row','description','Advanced unilateral version working one arm at a time while extending the other laterally.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='lat_dorsi'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',45,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='calisthenics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='pull_up_bar'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,false,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',2,NOW()) ON CONFLICT DO NOTHING;
    ELSE SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Archer Inverted Row'; INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',2,NOW()) ON CONFLICT DO NOTHING; END IF;

END $$;

-- ─── Australian Pull-Up ──────────────────────────────────────
DO $$
DECLARE v_ex_id UUID; v_var_id UUID; v_id UUID;
BEGIN
    IF EXISTS (SELECT 1 FROM exercises.exercise WHERE name = 'Australian Pull-Up') THEN
        RAISE NOTICE 'Already exists: Australian Pull-Up'; RETURN;
    END IF;
    v_ex_id := gen_random_uuid();
    INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
    VALUES (v_ex_id,'Australian Pull-Up','beginner','compound','pull',false,true,'low',false,NULL,'public','active',
        jsonb_build_object('it',jsonb_build_object('name','Trazione Australiana','description','Simile alla remata invertita ma con il corpo più verticale. Ideale per principianti che costruiscono forza verso la trazione classica.'),'en',jsonb_build_object('name','Australian Pull-Up','description','Similar to the inverted row but with a more vertical body position. Ideal for beginners building strength toward the full pull-up.')),NOW(),NOW());
    SELECT id INTO v_id FROM exercises.muscle WHERE code='lat_dorsi'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'primary',35,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='rhomboid_major'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'primary',30,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='trap_middle'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'primary',20,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='biceps_long_head'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'secondary',20,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='teres_major'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'secondary',15,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.category WHERE code='calisthenics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_ex_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.equipment WHERE code='pull_up_bar'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_ex_id,v_id,false,false,1,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.equipment WHERE code='gymnastic_rings'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_ex_id,v_id,false,false,2,NOW()) ON CONFLICT DO NOTHING; END IF;
    FOR v_id IN SELECT id FROM exercises.tag WHERE code IN('calisthenics','bodyweight','pull','back','beginner_safe') LOOP INSERT INTO exercises.exercise_tag VALUES(v_ex_id,v_id,NOW()) ON CONFLICT DO NOTHING; END LOOP;

    -- Variant: Supinated Australian Pull-Up
    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Supinated Australian Pull-Up') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Supinated Australian Pull-Up','beginner','compound','pull',false,true,'low',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Trazione Australiana Supinata','description','Versione con presa supinata che coinvolge maggiormente i bicipiti.'),'en',jsonb_build_object('name','Supinated Australian Pull-Up','description','Underhand grip version that engages the biceps more.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='lat_dorsi'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',30,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.muscle WHERE code='biceps_long_head'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',35,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='calisthenics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='pull_up_bar'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,false,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',0,NOW()) ON CONFLICT DO NOTHING;
    ELSE SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Supinated Australian Pull-Up'; INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',0,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- Variant: Archer Australian Pull-Up
    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Archer Australian Pull-Up') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Archer Australian Pull-Up','intermediate','compound','pull',true,true,'low',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Trazione Australiana Arciere','description','Versione unilaterale con uno delle braccia estesa lateralmente per un carico maggiore su un lato.'),'en',jsonb_build_object('name','Archer Australian Pull-Up','description','Unilateral version with one arm extended to the side for increased load on one side.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='lat_dorsi'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',40,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='calisthenics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='pull_up_bar'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,false,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',1,NOW()) ON CONFLICT DO NOTHING;
    ELSE SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Archer Australian Pull-Up'; INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',1,NOW()) ON CONFLICT DO NOTHING; END IF;

END $$;

-- ─── Scapular Pull-Up ────────────────────────────────────────
DO $$
DECLARE v_ex_id UUID; v_var_id UUID; v_id UUID;
BEGIN
    IF EXISTS (SELECT 1 FROM exercises.exercise WHERE name = 'Scapular Pull-Up') THEN
        RAISE NOTICE 'Already exists: Scapular Pull-Up'; RETURN;
    END IF;
    v_ex_id := gen_random_uuid();
    INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
    VALUES (v_ex_id,'Scapular Pull-Up','beginner','isolation','pull',false,true,'low',false,NULL,'public','active',
        jsonb_build_object('it',jsonb_build_object('name','Trazione Scapolare','description','Esercizio di isolamento scapolare eseguito dalla posizione di appeso alla sbarra. Attiva e rinforza i depressori della scapola come il trapezio inferiore e il dentato anteriore.'),'en',jsonb_build_object('name','Scapular Pull-Up','description','Scapular isolation exercise performed from a bar hang. Activates and strengthens scapular depressors like the lower trapezius and serratus anterior.')),NOW(),NOW());
    SELECT id INTO v_id FROM exercises.muscle WHERE code='trap_lower'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'primary',40,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='trap_middle'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'primary',30,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='serratus_anterior'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'primary',20,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='rhomboid_major'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'secondary',15,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='infraspinatus'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'secondary',10,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.category WHERE code='calisthenics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_ex_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.equipment WHERE code='pull_up_bar'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_ex_id,v_id,true,false,1,NOW()) ON CONFLICT DO NOTHING; END IF;
    FOR v_id IN SELECT id FROM exercises.tag WHERE code IN('calisthenics','bodyweight','back','beginner_safe','prehab') LOOP INSERT INTO exercises.exercise_tag VALUES(v_ex_id,v_id,NOW()) ON CONFLICT DO NOTHING; END LOOP;

    -- Variant: Scapular Push-Up
    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Scapular Push-Up') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Scapular Push-Up','beginner','isolation','push',false,true,'low',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Push-Up Scapolare','description','Versione antagonista che protrae le scapole dalla posizione di plank per attivare il dentato anteriore.'),'en',jsonb_build_object('name','Scapular Push-Up','description','Antagonist version that protracts scapulae from plank position to activate the serratus anterior.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='serratus_anterior'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',50,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='calisthenics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='none_bodyweight'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,true,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',0,NOW()) ON CONFLICT DO NOTHING;
    ELSE SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Scapular Push-Up'; INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',0,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- Variant: Ring Scapular Retraction
    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Ring Scapular Retraction') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Ring Scapular Retraction','beginner','isolation','pull',false,true,'low',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Retrazione Scapolare agli Anelli','description','Retrazione scapolare eseguita agli anelli ginnici in posizione invertita.'),'en',jsonb_build_object('name','Ring Scapular Retraction','description','Scapular retraction performed on gymnastic rings in an inverted position.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='rhomboid_major'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',45,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='calisthenics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='gymnastic_rings'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,false,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',0,NOW()) ON CONFLICT DO NOTHING;
    ELSE SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Ring Scapular Retraction'; INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',0,NOW()) ON CONFLICT DO NOTHING; END IF;

END $$;

-- ─── Superman Hold ───────────────────────────────────────────
DO $$
DECLARE v_ex_id UUID; v_var_id UUID; v_id UUID;
BEGIN
    IF EXISTS (SELECT 1 FROM exercises.exercise WHERE name = 'Superman Hold') THEN
        RAISE NOTICE 'Already exists: Superman Hold'; RETURN;
    END IF;
    v_ex_id := gen_random_uuid();
    INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
    VALUES (v_ex_id,'Superman Hold','beginner','compound','static',false,true,'low',false,NULL,'public','active',
        jsonb_build_object('it',jsonb_build_object('name','Superman','description','Esercizio prono in cui braccia e gambe vengono sollevate simultaneamente da terra, isometricamente. Rinforza l''intera catena posteriore e i muscoli estensori della colonna.'),'en',jsonb_build_object('name','Superman Hold','description','Prone exercise where arms and legs are simultaneously lifted from the ground, held isometrically. Strengthens the entire posterior chain and spinal extensors.')),NOW(),NOW());
    SELECT id INTO v_id FROM exercises.muscle WHERE code='erector_spinae'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'primary',40,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='multifidus'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'primary',25,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='glute_max'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'primary',20,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='trap_lower'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'secondary',15,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='rhomboid_major'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'secondary',10,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.category WHERE code='calisthenics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_ex_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.equipment WHERE code='none_bodyweight'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_ex_id,v_id,true,true,1,NOW()) ON CONFLICT DO NOTHING; END IF;
    FOR v_id IN SELECT id FROM exercises.tag WHERE code IN('calisthenics','bodyweight','no_equipment','home_friendly','beginner_safe') LOOP INSERT INTO exercises.exercise_tag VALUES(v_ex_id,v_id,NOW()) ON CONFLICT DO NOTHING; END LOOP;

    -- Variant: Alternating Superman
    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Alternating Superman') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Alternating Superman','beginner','compound','static',true,true,'low',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Superman Alternato','description','Versione alternata del superman in cui si solleva un braccio e la gamba opposta per volta.'),'en',jsonb_build_object('name','Alternating Superman','description','Alternating version where one arm and the opposite leg are lifted at a time.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='erector_spinae'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',40,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='calisthenics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='none_bodyweight'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,true,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',-1,NOW()) ON CONFLICT DO NOTHING;
    ELSE SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Alternating Superman'; INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',-1,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- Variant: Superman Rock
    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Superman Rock') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Superman Rock','beginner','compound','static',false,true,'low',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Superman con Dondolo','description','Variante del superman con un dondolo avanti/indietro per aumentare l''intensità e la mobilità spinale.'),'en',jsonb_build_object('name','Superman Rock','description','Superman variant with a forward/backward rocking motion to increase intensity and spinal mobility.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='erector_spinae'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',40,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='calisthenics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='none_bodyweight'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,true,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',0,NOW()) ON CONFLICT DO NOTHING;
    ELSE SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Superman Rock'; INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',0,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- Variant: Weighted Superman
    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Weighted Superman') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Weighted Superman','intermediate','compound','static',false,true,'low',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Superman con Carico','description','Superman eseguito con un peso aggiuntivo per aumentare l''intensità dell''esercizio.'),'en',jsonb_build_object('name','Weighted Superman','description','Superman performed with added weight to increase exercise intensity.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='erector_spinae'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',40,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='calisthenics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='none_bodyweight'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,true,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',1,NOW()) ON CONFLICT DO NOTHING;
    ELSE SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Weighted Superman'; INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',1,NOW()) ON CONFLICT DO NOTHING; END IF;

END $$;

-- ─── Archer Pull-Up ──────────────────────────────────────────
DO $$
DECLARE v_ex_id UUID; v_var_id UUID; v_id UUID;
BEGIN
    IF EXISTS (SELECT 1 FROM exercises.exercise WHERE name = 'Archer Pull-Up') THEN
        RAISE NOTICE 'Already exists: Archer Pull-Up'; RETURN;
    END IF;
    v_ex_id := gen_random_uuid();
    INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
    VALUES (v_ex_id,'Archer Pull-Up','advanced','compound','pull',true,true,'medium',false,NULL,'public','active',
        jsonb_build_object('it',jsonb_build_object('name','Trazione Arciere','description','Variante avanzata della trazione in cui si tira con un braccio mentre l''altro rimane esteso lateralmente. Precursore della trazione a un braccio.'),'en',jsonb_build_object('name','Archer Pull-Up','description','Advanced pull-up variant where you pull with one arm while the other remains extended laterally. Precursor to the one-arm pull-up.')),NOW(),NOW());
    SELECT id INTO v_id FROM exercises.muscle WHERE code='lat_dorsi'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'primary',50,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='teres_major'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'primary',25,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='rhomboid_major'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'primary',15,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='biceps_long_head'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'secondary',20,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='trap_middle'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'secondary',10,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.category WHERE code='calisthenics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_ex_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.equipment WHERE code='pull_up_bar'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_ex_id,v_id,true,false,1,NOW()) ON CONFLICT DO NOTHING; END IF;
    FOR v_id IN SELECT id FROM exercises.tag WHERE code IN('calisthenics','bodyweight','pull','back','unilateral') LOOP INSERT INTO exercises.exercise_tag VALUES(v_ex_id,v_id,NOW()) ON CONFLICT DO NOTHING; END LOOP;

    -- Variant: Assisted Archer Pull-Up
    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Assisted Archer Pull-Up') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Assisted Archer Pull-Up','intermediate','compound','pull',true,true,'low',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Trazione Arciere Assistita','description','Versione della trazione arciere con assistenza da un elastico o aiuto parziale dell''altro braccio.'),'en',jsonb_build_object('name','Assisted Archer Pull-Up','description','Archer pull-up with assistance from a band or partial help from the other arm.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='lat_dorsi'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',50,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='calisthenics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='pull_up_bar'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,false,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',-1,NOW()) ON CONFLICT DO NOTHING;
    ELSE SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Assisted Archer Pull-Up'; INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',-1,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- Variant: Weighted Archer Pull-Up
    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Weighted Archer Pull-Up') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Weighted Archer Pull-Up','advanced','compound','pull',true,true,'medium',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Trazione Arciere con Carico','description','Trazione arciere eseguita con peso aggiuntivo per incrementare ulteriormente la difficoltà.'),'en',jsonb_build_object('name','Weighted Archer Pull-Up','description','Archer pull-up performed with added weight to further increase difficulty.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='lat_dorsi'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',50,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='calisthenics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='pull_up_bar'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,false,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',2,NOW()) ON CONFLICT DO NOTHING;
    ELSE SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Weighted Archer Pull-Up'; INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',2,NOW()) ON CONFLICT DO NOTHING; END IF;

END $$;

-- ─── One-Arm Pull-Up ─────────────────────────────────────────
DO $$
DECLARE v_ex_id UUID; v_var_id UUID; v_id UUID;
BEGIN
    IF EXISTS (SELECT 1 FROM exercises.exercise WHERE name = 'One-Arm Pull-Up') THEN
        RAISE NOTICE 'Already exists: One-Arm Pull-Up'; RETURN;
    END IF;
    v_ex_id := gen_random_uuid();
    INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
    VALUES (v_ex_id,'One-Arm Pull-Up','advanced','compound','pull',true,true,'high',false,NULL,'public','active',
        jsonb_build_object('it',jsonb_build_object('name','Trazione a un Braccio','description','Il pinnacolo della calistenia di tiraggio: trazione eseguita con un solo braccio. Richiede forza e coordinazione eccezionali di schiena, bicipiti e avambracci.'),'en',jsonb_build_object('name','One-Arm Pull-Up','description','The pinnacle of pulling calisthenics: a pull-up performed with a single arm. Requires exceptional strength and coordination in the back, biceps and forearms.')),NOW(),NOW());
    SELECT id INTO v_id FROM exercises.muscle WHERE code='lat_dorsi'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'primary',50,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='teres_major'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'primary',20,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='biceps_long_head'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'primary',20,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='rhomboid_major'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'secondary',15,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='trap_middle'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'secondary',10,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.category WHERE code='calisthenics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_ex_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.equipment WHERE code='pull_up_bar'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_ex_id,v_id,true,false,1,NOW()) ON CONFLICT DO NOTHING; END IF;
    FOR v_id IN SELECT id FROM exercises.tag WHERE code IN('calisthenics','bodyweight','pull','calisthenics_skill','unilateral') LOOP INSERT INTO exercises.exercise_tag VALUES(v_ex_id,v_id,NOW()) ON CONFLICT DO NOTHING; END LOOP;

    -- Variant: Assisted One-Arm Pull-Up
    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Assisted One-Arm Pull-Up') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Assisted One-Arm Pull-Up','advanced','compound','pull',true,true,'medium',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Trazione a un Braccio Assistita','description','Versione assistita della trazione a un braccio usando l''altro braccio su una corda o elastico.'),'en',jsonb_build_object('name','Assisted One-Arm Pull-Up','description','Assisted version of the one-arm pull-up using the other arm on a rope or band.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='lat_dorsi'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',50,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='calisthenics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='pull_up_bar'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,false,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',-2,NOW()) ON CONFLICT DO NOTHING;
    ELSE SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Assisted One-Arm Pull-Up'; INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',-2,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- Variant: Band-Assisted One-Arm Pull-Up
    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Band-Assisted One-Arm Pull-Up') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Band-Assisted One-Arm Pull-Up','advanced','compound','pull',true,true,'medium',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Trazione un Braccio con Elastico','description','Trazione a un braccio con elastico per ridurre il carico e imparare il movimento.'),'en',jsonb_build_object('name','Band-Assisted One-Arm Pull-Up','description','One-arm pull-up with a band to reduce load and learn the movement pattern.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='lat_dorsi'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',50,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='calisthenics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='pull_up_bar'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,false,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='resistance_band'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,false,2,NOW()) ON CONFLICT DO NOTHING; END IF;
        INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',-1,NOW()) ON CONFLICT DO NOTHING;
    ELSE SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Band-Assisted One-Arm Pull-Up'; INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',-1,NOW()) ON CONFLICT DO NOTHING; END IF;

END $$;

-- ─── Dragon Flag ─────────────────────────────────────────────
DO $$
DECLARE v_ex_id UUID; v_var_id UUID; v_id UUID;
BEGIN
    IF EXISTS (SELECT 1 FROM exercises.exercise WHERE name = 'Dragon Flag') THEN
        RAISE NOTICE 'Already exists: Dragon Flag'; RETURN;
    END IF;
    v_ex_id := gen_random_uuid();
    INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
    VALUES (v_ex_id,'Dragon Flag','advanced','compound','static',false,true,'medium',false,NULL,'public','active',
        jsonb_build_object('it',jsonb_build_object('name','Dragon Flag','description','Esercizio avanzato reso famoso da Bruce Lee: sdraiati su una panca, tenere il corpo rigido in posizione inclinata usando solo la forza del core e della schiena bassa.'),'en',jsonb_build_object('name','Dragon Flag','description','Advanced exercise made famous by Bruce Lee: lying on a bench, hold the body rigid in an inclined position using only core and lower back strength.')),NOW(),NOW());
    SELECT id INTO v_id FROM exercises.muscle WHERE code='erector_spinae'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'primary',35,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='multifidus'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'primary',25,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='rectus_abdominis'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'primary',25,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='glute_max'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'secondary',15,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='trap_lower'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'secondary',10,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.category WHERE code='calisthenics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_ex_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.equipment WHERE code='pull_up_bar'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_ex_id,v_id,false,false,1,NOW()) ON CONFLICT DO NOTHING; END IF;
    FOR v_id IN SELECT id FROM exercises.tag WHERE code IN('calisthenics','bodyweight','core','calisthenics_skill') LOOP INSERT INTO exercises.exercise_tag VALUES(v_ex_id,v_id,NOW()) ON CONFLICT DO NOTHING; END LOOP;

    -- Variant: Tuck Dragon Flag
    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Tuck Dragon Flag') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Tuck Dragon Flag','intermediate','compound','static',false,true,'low',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Dragon Flag Tuck','description','Prima progressione del dragon flag con le ginocchia piegate al petto per ridurre il momento di inerzia.'),'en',jsonb_build_object('name','Tuck Dragon Flag','description','First progression of the dragon flag with knees tucked to the chest to reduce moment of inertia.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='erector_spinae'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',35,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='calisthenics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='pull_up_bar'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,false,false,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',-2,NOW()) ON CONFLICT DO NOTHING;
    ELSE SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Tuck Dragon Flag'; INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',-2,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- Variant: Negative Dragon Flag
    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Negative Dragon Flag') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Negative Dragon Flag','intermediate','compound','static',false,true,'low',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Dragon Flag Negativo','description','Solo la fase eccentrica del dragon flag: partire in alto e abbassarsi lentamente.'),'en',jsonb_build_object('name','Negative Dragon Flag','description','Only the eccentric phase of the dragon flag: start at the top and lower down slowly.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='erector_spinae'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',35,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='calisthenics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='pull_up_bar'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,false,false,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',-1,NOW()) ON CONFLICT DO NOTHING;
    ELSE SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Negative Dragon Flag'; INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',-1,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- Variant: Full Dragon Flag
    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Full Dragon Flag') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Full Dragon Flag','advanced','compound','static',false,true,'medium',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Dragon Flag Completo','description','Versione completa del dragon flag con le gambe tese in posizione orizzontale.'),'en',jsonb_build_object('name','Full Dragon Flag','description','Complete version of the dragon flag with legs straight in the horizontal position.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='erector_spinae'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',35,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='calisthenics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='pull_up_bar'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,false,false,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',1,NOW()) ON CONFLICT DO NOTHING;
    ELSE SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Full Dragon Flag'; INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',1,NOW()) ON CONFLICT DO NOTHING; END IF;

END $$;

-- ─── Skin the Cat ────────────────────────────────────────────
DO $$
DECLARE v_ex_id UUID; v_var_id UUID; v_id UUID;
BEGIN
    IF EXISTS (SELECT 1 FROM exercises.exercise WHERE name = 'Skin the Cat') THEN
        RAISE NOTICE 'Already exists: Skin the Cat'; RETURN;
    END IF;
    v_ex_id := gen_random_uuid();
    INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
    VALUES (v_ex_id,'Skin the Cat','intermediate','compound','pull',false,true,'medium',false,NULL,'public','active',
        jsonb_build_object('it',jsonb_build_object('name','Skin the Cat','description','Esercizio ginnico alla sbarra o agli anelli in cui si ruota il corpo in avanti e indietro passando sotto l''attrezzo. Eccellente per la salute delle spalle e la forza del core.'),'en',jsonb_build_object('name','Skin the Cat','description','Gymnastics exercise on the bar or rings where the body rotates forward and backward passing under the equipment. Excellent for shoulder health and core strength.')),NOW(),NOW());
    SELECT id INTO v_id FROM exercises.muscle WHERE code='lat_dorsi'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'primary',35,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='teres_major'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'primary',25,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='serratus_anterior'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'primary',20,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='rhomboid_major'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'secondary',15,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='erector_spinae'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'secondary',15,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.category WHERE code='calisthenics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_ex_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.equipment WHERE code='pull_up_bar'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_ex_id,v_id,false,false,1,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.equipment WHERE code='gymnastic_rings'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_ex_id,v_id,false,false,2,NOW()) ON CONFLICT DO NOTHING; END IF;
    FOR v_id IN SELECT id FROM exercises.tag WHERE code IN('calisthenics','bodyweight','back','calisthenics_skill') LOOP INSERT INTO exercises.exercise_tag VALUES(v_ex_id,v_id,NOW()) ON CONFLICT DO NOTHING; END LOOP;

    -- Variant: Tuck Skin the Cat
    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Tuck Skin the Cat') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Tuck Skin the Cat','beginner','compound','pull',false,true,'low',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Skin the Cat Tuck','description','Versione facilitata con le ginocchia piegate per apprendere il movimento rotazionale.'),'en',jsonb_build_object('name','Tuck Skin the Cat','description','Easier version with bent knees to learn the rotational movement.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='lat_dorsi'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',35,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='calisthenics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='pull_up_bar'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,false,false,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',-2,NOW()) ON CONFLICT DO NOTHING;
    ELSE SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Tuck Skin the Cat'; INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',-2,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- Variant: Slow Skin the Cat
    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Slow Skin the Cat') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Slow Skin the Cat','intermediate','compound','pull',false,true,'medium',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Skin the Cat Lento','description','Versione eseguita lentamente per massimizzare il controllo e il lavoro muscolare.'),'en',jsonb_build_object('name','Slow Skin the Cat','description','Version performed slowly to maximize control and muscular work.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='lat_dorsi'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',35,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='calisthenics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='pull_up_bar'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,false,false,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',0,NOW()) ON CONFLICT DO NOTHING;
    ELSE SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Slow Skin the Cat'; INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',0,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- Variant: Ring Skin the Cat
    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Ring Skin the Cat') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Ring Skin the Cat','intermediate','compound','pull',false,true,'medium',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Skin the Cat agli Anelli','description','Versione agli anelli ginnici che richiede maggiore stabilità e controllo della rotazione.'),'en',jsonb_build_object('name','Ring Skin the Cat','description','Gymnastic rings version requiring greater stability and rotational control.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='lat_dorsi'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',35,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='calisthenics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='gymnastic_rings'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,false,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',1,NOW()) ON CONFLICT DO NOTHING;
    ELSE SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Ring Skin the Cat'; INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',1,NOW()) ON CONFLICT DO NOTHING; END IF;

END $$;
