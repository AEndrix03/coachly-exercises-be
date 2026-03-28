-- =============================================================
-- Calisthenics: Chest Exercises
-- Disciplines: calisthenics
-- =============================================================

-- ─── Push-Up ────────────────────────────────────────────────
DO $$
DECLARE v_ex_id UUID; v_var_id UUID; v_id UUID;
BEGIN
    IF EXISTS (SELECT 1 FROM exercises.exercise WHERE name = 'Push-Up') THEN
        RAISE NOTICE 'Already exists: Push-Up'; RETURN;
    END IF;
    v_ex_id := gen_random_uuid();
    INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
    VALUES (v_ex_id,'Push-Up','beginner','compound','push',false,true,'low',false,NULL,'public','active',
        jsonb_build_object('it',jsonb_build_object('name','Flessione sulle Braccia','description','Esercizio fondamentale a corpo libero che sviluppa pettorali, tricipiti e deltoide anteriore. Partendo dalla posizione di plank, abbassare il petto a terra mantenendo il core compatto, poi spingere fino all''estensione completa delle braccia.'),'en',jsonb_build_object('name','Push-Up','description','Foundational bodyweight exercise developing chest, triceps and anterior deltoid. From a plank position, lower your chest to the ground keeping the core tight, then press back to full arm extension.')),NOW(),NOW());
    SELECT id INTO v_id FROM exercises.muscle WHERE code='pec_major_mid'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'primary',50,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='pec_major_upper'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'primary',30,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='deltoid_anterior'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'secondary',10,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='triceps_long_head'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'secondary',10,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.category WHERE code='calisthenics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_ex_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.equipment WHERE code='none_bodyweight'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_ex_id,v_id,true,true,1,NOW()) ON CONFLICT DO NOTHING; END IF;
    FOR v_id IN SELECT id FROM exercises.tag WHERE code IN('calisthenics','bodyweight','no_equipment','home_friendly') LOOP INSERT INTO exercises.exercise_tag VALUES(v_ex_id,v_id,NOW()) ON CONFLICT DO NOTHING; END LOOP;

    -- Variant: Wall Push-Up
    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Wall Push-Up') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Wall Push-Up','beginner','compound','push',false,true,'low',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Flessione al Muro','description','Versione facilitata della flessione eseguita in piedi contro un muro. Ideale per principianti o riabilitazione.'),'en',jsonb_build_object('name','Wall Push-Up','description','Easiest push-up regression performed standing against a wall. Ideal for beginners or rehabilitation purposes.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='pec_major_mid'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',50,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='calisthenics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='none_bodyweight'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,true,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',-2,NOW()) ON CONFLICT DO NOTHING;
    ELSE SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Wall Push-Up'; INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',-2,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- Variant: Incline Push-Up
    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Incline Push-Up') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Incline Push-Up','beginner','compound','push',false,true,'low',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Flessione Inclinata','description','Flessione con le mani su una superficie rialzata (panca o gradino) che riduce il carico sul petto superiore. Ottima regressione per costruire forza progressivamente.'),'en',jsonb_build_object('name','Incline Push-Up','description','Push-up with hands elevated on a bench or step, reducing load and emphasizing the upper chest. Great regression to build progressive strength.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='pec_major_mid'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',50,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='calisthenics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='none_bodyweight'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,true,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',-1,NOW()) ON CONFLICT DO NOTHING;
    ELSE SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Incline Push-Up'; INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',-1,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- Variant: Knee Push-Up
    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Knee Push-Up') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Knee Push-Up','beginner','compound','push',false,true,'low',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Flessione sulle Ginocchia','description','Flessione eseguita con le ginocchia a terra per ridurre il carico corporeo. Utile come regressione per chi non riesce ancora a fare la flessione standard.'),'en',jsonb_build_object('name','Knee Push-Up','description','Push-up performed with knees on the ground to reduce bodyweight load. Useful regression for those not yet able to perform a full push-up.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='pec_major_mid'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',50,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='calisthenics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='none_bodyweight'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,true,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',-1,NOW()) ON CONFLICT DO NOTHING;
    ELSE SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Knee Push-Up'; INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',-1,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- Variant: Wide Push-Up
    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Wide Push-Up') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Wide Push-Up','beginner','compound','push',false,true,'low',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Flessione Presa Larga','description','Flessione con presa più larga della spalla per aumentare l''attivazione del pettorale mediale. Riduce il coinvolgimento dei tricipiti rispetto alla presa standard.'),'en',jsonb_build_object('name','Wide Push-Up','description','Push-up with a wider than shoulder-width grip to increase mid-chest activation. Reduces tricep involvement compared to standard grip.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='pec_major_mid'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',60,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='calisthenics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='none_bodyweight'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,true,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',0,NOW()) ON CONFLICT DO NOTHING;
    ELSE SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Wide Push-Up'; INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',0,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- Variant: Close-Grip Push-Up
    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Close-Grip Push-Up') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Close-Grip Push-Up','intermediate','compound','push',false,true,'low',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Flessione Presa Stretta','description','Flessione con le mani ravvicinate che aumenta il coinvolgimento dei tricipiti e del pettorale interno. Richiede maggiore stabilità del polso rispetto alla versione standard.'),'en',jsonb_build_object('name','Close-Grip Push-Up','description','Push-up with hands close together increasing tricep and inner chest engagement. Requires more wrist stability than standard grip.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='pec_major_mid'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',40,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.muscle WHERE code='triceps_long_head'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',40,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='calisthenics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='none_bodyweight'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,true,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',1,NOW()) ON CONFLICT DO NOTHING;
    ELSE SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Close-Grip Push-Up'; INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',1,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- Variant: Decline Push-Up
    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Decline Push-Up') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Decline Push-Up','intermediate','compound','push',false,true,'low',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Flessione Declinata','description','Flessione con i piedi rialzati per aumentare il coinvolgimento del pettorale superiore e del deltoide anteriore. La posizione declinata sposta il carico verso la parte alta del petto.'),'en',jsonb_build_object('name','Decline Push-Up','description','Push-up with feet elevated to increase upper chest and anterior deltoid activation. The decline position shifts the load to the upper chest region.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='pec_major_upper'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',50,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='calisthenics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='none_bodyweight'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,true,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',1,NOW()) ON CONFLICT DO NOTHING;
    ELSE SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Decline Push-Up'; INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',1,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- Variant: Ring Push-Up
    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Ring Push-Up') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Ring Push-Up','intermediate','compound','push',false,true,'low',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Flessione agli Anelli','description','Flessione eseguita su anelli ginnici che aumenta l''instabilità e richiede maggiore stabilizzazione scapolare e core. Gli anelli aggiungono un piano di movimento extra rispetto al pavimento.'),'en',jsonb_build_object('name','Ring Push-Up','description','Push-up on gymnastic rings adding instability and requiring greater scapular and core stabilization. Rings add an extra plane of motion compared to floor push-ups.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='pec_major_mid'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',50,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='calisthenics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='gymnastic_rings'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,true,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',1,NOW()) ON CONFLICT DO NOTHING;
    ELSE SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Ring Push-Up'; INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',1,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- Variant: Plyometric Push-Up
    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Plyometric Push-Up') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Plyometric Push-Up','intermediate','compound','push',false,true,'medium',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Flessione Pliometrica','description','Flessione esplosiva dove si spinge con tale forza da sollevare le mani da terra. Sviluppa la potenza muscolare del petto e la velocità di contrazione.'),'en',jsonb_build_object('name','Plyometric Push-Up','description','Explosive push-up where you push so hard your hands leave the ground. Develops chest muscular power and rate of force development.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='pec_major_mid'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',50,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='calisthenics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='none_bodyweight'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,true,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',1,NOW()) ON CONFLICT DO NOTHING;
    ELSE SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Plyometric Push-Up'; INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',1,NOW()) ON CONFLICT DO NOTHING; END IF;
END $$;

-- ─── Archer Push-Up ─────────────────────────────────────────
DO $$
DECLARE v_ex_id UUID; v_var_id UUID; v_id UUID;
BEGIN
    IF EXISTS (SELECT 1 FROM exercises.exercise WHERE name = 'Archer Push-Up') THEN
        RAISE NOTICE 'Already exists: Archer Push-Up'; RETURN;
    END IF;
    v_ex_id := gen_random_uuid();
    INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
    VALUES (v_ex_id,'Archer Push-Up','intermediate','compound','push',true,true,'low',false,NULL,'public','active',
        jsonb_build_object('it',jsonb_build_object('name','Flessione Arciere','description','Variante unilaterale della flessione dove un braccio lavora in piena estensione mentre l''altro esegue la flessione. Ottima progressione verso la flessione a un braccio, sviluppa forza asimmetrica del petto.'),'en',jsonb_build_object('name','Archer Push-Up','description','Unilateral push-up variation where one arm stays extended while the other performs the pressing motion. Excellent progression toward one-arm push-up, building asymmetric chest strength.')),NOW(),NOW());
    SELECT id INTO v_id FROM exercises.muscle WHERE code='pec_major_mid'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'primary',55,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='pec_major_upper'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'primary',25,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.category WHERE code='calisthenics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_ex_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.equipment WHERE code='none_bodyweight'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_ex_id,v_id,true,true,1,NOW()) ON CONFLICT DO NOTHING; END IF;
    FOR v_id IN SELECT id FROM exercises.tag WHERE code IN('calisthenics','bodyweight','no_equipment','calisthenics_skill') LOOP INSERT INTO exercises.exercise_tag VALUES(v_ex_id,v_id,NOW()) ON CONFLICT DO NOTHING; END LOOP;

    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Assisted Archer Push-Up') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Assisted Archer Push-Up','beginner','compound','push',true,true,'low',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Flessione Arciere Assistita','description','Versione assistita della flessione arciere con supporto sul braccio esteso. Permette di apprendere il pattern di movimento con carico ridotto.'),'en',jsonb_build_object('name','Assisted Archer Push-Up','description','Assisted version of the archer push-up with support on the extended arm. Allows learning the movement pattern with reduced load.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='pec_major_mid'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',55,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='calisthenics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='none_bodyweight'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,true,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',-1,NOW()) ON CONFLICT DO NOTHING;
    ELSE SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Assisted Archer Push-Up'; INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',-1,NOW()) ON CONFLICT DO NOTHING; END IF;

    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Weighted Archer Push-Up') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Weighted Archer Push-Up','advanced','compound','push',true,true,'medium',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Flessione Arciere con Carico','description','Flessione arciere con peso aggiuntivo sul dorso per aumentare la resistenza e la difficoltà del movimento.'),'en',jsonb_build_object('name','Weighted Archer Push-Up','description','Archer push-up with added weight on the back to increase resistance and difficulty of the movement.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='pec_major_mid'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',55,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='calisthenics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='none_bodyweight'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,true,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',1,NOW()) ON CONFLICT DO NOTHING;
    ELSE SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Weighted Archer Push-Up'; INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',1,NOW()) ON CONFLICT DO NOTHING; END IF;

    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Ring Archer Push-Up') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Ring Archer Push-Up','advanced','compound','push',true,true,'medium',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Flessione Arciere agli Anelli','description','Flessione arciere su anelli ginnici che aggiunge instabilità e aumenta la richiesta di stabilizzazione delle spalle e del core.'),'en',jsonb_build_object('name','Ring Archer Push-Up','description','Archer push-up on gymnastic rings adding instability and increasing shoulder and core stabilization demands.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='pec_major_mid'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',55,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='calisthenics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='gymnastic_rings'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,true,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',2,NOW()) ON CONFLICT DO NOTHING;
    ELSE SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Ring Archer Push-Up'; INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',2,NOW()) ON CONFLICT DO NOTHING; END IF;
END $$;

-- ─── Pseudo Planche Push-Up ──────────────────────────────────
DO $$
DECLARE v_ex_id UUID; v_var_id UUID; v_id UUID;
BEGIN
    IF EXISTS (SELECT 1 FROM exercises.exercise WHERE name = 'Pseudo Planche Push-Up') THEN
        RAISE NOTICE 'Already exists: Pseudo Planche Push-Up'; RETURN;
    END IF;
    v_ex_id := gen_random_uuid();
    INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
    VALUES (v_ex_id,'Pseudo Planche Push-Up','intermediate','compound','push',false,true,'medium',false,NULL,'public','active',
        jsonb_build_object('it',jsonb_build_object('name','Flessione Pseudo Plancha','description','Flessione con le mani orientate verso i fianchi e il busto inclinato in avanti per simulare la posizione di planche. Sviluppa la forza delle spalle anteriori, del pettorale inferiore e del serratus anterior necessaria per la planche.'),'en',jsonb_build_object('name','Pseudo Planche Push-Up','description','Push-up with hands rotated toward hips and torso leaning forward to simulate planche position. Develops anterior shoulder, lower chest and serratus anterior strength required for the planche.')),NOW(),NOW());
    SELECT id INTO v_id FROM exercises.muscle WHERE code='pec_major_lower'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'primary',45,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='pec_minor'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'primary',25,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='serratus_anterior'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'primary',20,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.category WHERE code='calisthenics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_ex_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.equipment WHERE code='none_bodyweight'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_ex_id,v_id,true,true,1,NOW()) ON CONFLICT DO NOTHING; END IF;
    FOR v_id IN SELECT id FROM exercises.tag WHERE code IN('calisthenics','bodyweight','calisthenics_skill','no_equipment') LOOP INSERT INTO exercises.exercise_tag VALUES(v_ex_id,v_id,NOW()) ON CONFLICT DO NOTHING; END LOOP;

    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Elevated Pseudo Planche Push-Up') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Elevated Pseudo Planche Push-Up','beginner','compound','push',false,true,'low',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Flessione Pseudo Plancha Elevata','description','Versione facilitata con le mani su una superficie rialzata per ridurre il carico e apprendere il posizionamento delle mani.'),'en',jsonb_build_object('name','Elevated Pseudo Planche Push-Up','description','Easier version with hands on an elevated surface to reduce load and learn hand positioning.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='pec_major_lower'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',45,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='calisthenics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='none_bodyweight'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,true,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',-1,NOW()) ON CONFLICT DO NOTHING;
    ELSE SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Elevated Pseudo Planche Push-Up'; INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',-1,NOW()) ON CONFLICT DO NOTHING; END IF;

    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Pseudo Planche Lean') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Pseudo Planche Lean','beginner','compound','static',false,true,'low',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Inclinazione Pseudo Plancha','description','Tenuta isometrica della posizione pseudo planche senza eseguire la flessione. Costruisce la forza e la resistenza necessarie per le flessioni in planche.'),'en',jsonb_build_object('name','Pseudo Planche Lean','description','Isometric hold of the pseudo planche position without performing the push-up movement. Builds the strength and endurance needed for planche push-ups.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='pec_major_lower'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',40,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='calisthenics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='none_bodyweight'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,true,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',-1,NOW()) ON CONFLICT DO NOTHING;
    ELSE SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Pseudo Planche Lean'; INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',-1,NOW()) ON CONFLICT DO NOTHING; END IF;

    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Advanced Pseudo Planche Push-Up') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Advanced Pseudo Planche Push-Up','advanced','compound','push',false,true,'medium',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Flessione Pseudo Plancha Avanzata','description','Versione avanzata con inclinazione maggiore del corpo in avanti e mani posizionate ancora più verso i fianchi. Avvicina ulteriormente alla planche vera e propria.'),'en',jsonb_build_object('name','Advanced Pseudo Planche Push-Up','description','Advanced version with greater forward body lean and hands positioned even further back. Moves closer to the true planche position.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='pec_major_lower'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',45,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='calisthenics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='none_bodyweight'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,true,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',1,NOW()) ON CONFLICT DO NOTHING;
    ELSE SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Advanced Pseudo Planche Push-Up'; INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',1,NOW()) ON CONFLICT DO NOTHING; END IF;
END $$;

-- ─── Planche Push-Up ─────────────────────────────────────────
DO $$
DECLARE v_ex_id UUID; v_var_id UUID; v_id UUID;
BEGIN
    IF EXISTS (SELECT 1 FROM exercises.exercise WHERE name = 'Planche Push-Up') THEN
        RAISE NOTICE 'Already exists: Planche Push-Up'; RETURN;
    END IF;
    v_ex_id := gen_random_uuid();
    INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
    VALUES (v_ex_id,'Planche Push-Up','advanced','compound','push',false,true,'high',true,NULL,'public','active',
        jsonb_build_object('it',jsonb_build_object('name','Flessione alla Plancha','description','L''apice delle flessioni a corpo libero: spingere in su e in giù mantenendo il corpo completamente parallelo al suolo. Richiede anni di training specifico e forza straordinaria di spalle e pettorale inferiore.'),'en',jsonb_build_object('name','Planche Push-Up','description','The pinnacle of bodyweight pressing: pushing up and down while keeping the body fully parallel to the ground. Requires years of specific training and extraordinary shoulder and lower chest strength.')),NOW(),NOW());
    SELECT id INTO v_id FROM exercises.muscle WHERE code='pec_major_lower'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'primary',40,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='pec_minor'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'primary',25,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='serratus_anterior'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'primary',20,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.category WHERE code='calisthenics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_ex_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.equipment WHERE code='parallettes'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_ex_id,v_id,true,false,1,NOW()) ON CONFLICT DO NOTHING; END IF;
    FOR v_id IN SELECT id FROM exercises.tag WHERE code IN('calisthenics','bodyweight','calisthenics_skill') LOOP INSERT INTO exercises.exercise_tag VALUES(v_ex_id,v_id,NOW()) ON CONFLICT DO NOTHING; END LOOP;

    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Tuck Planche Push-Up') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Tuck Planche Push-Up','advanced','compound','push',false,true,'high',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Flessione Tuck Plancha','description','Flessione in posizione tuck planche con ginocchia piegate verso il petto. Prima progressione verso le flessioni in planche completa.'),'en',jsonb_build_object('name','Tuck Planche Push-Up','description','Push-up in tuck planche position with knees pulled to the chest. First progression toward full planche push-ups.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='pec_major_lower'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',40,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='calisthenics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='parallettes'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,false,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',-2,NOW()) ON CONFLICT DO NOTHING;
    ELSE SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Tuck Planche Push-Up'; INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',-2,NOW()) ON CONFLICT DO NOTHING; END IF;

    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Straddle Planche Push-Up') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Straddle Planche Push-Up','advanced','compound','push',false,true,'high',true,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Flessione Straddle Plancha','description','Flessione in posizione straddle planche con gambe divaricate. Riduce leggermente il momento di forza rispetto alla planche completa.'),'en',jsonb_build_object('name','Straddle Planche Push-Up','description','Push-up in straddle planche with legs spread apart. Slightly reduces the moment arm compared to full planche.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='pec_major_lower'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',40,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='calisthenics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='parallettes'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,false,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',-1,NOW()) ON CONFLICT DO NOTHING;
    ELSE SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Straddle Planche Push-Up'; INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',-1,NOW()) ON CONFLICT DO NOTHING; END IF;
END $$;

-- ─── Dip (Parallel Bar) ──────────────────────────────────────
DO $$
DECLARE v_ex_id UUID; v_var_id UUID; v_id UUID;
BEGIN
    IF EXISTS (SELECT 1 FROM exercises.exercise WHERE name = 'Dip (Parallel Bar)') THEN
        RAISE NOTICE 'Already exists: Dip (Parallel Bar)'; RETURN;
    END IF;
    v_ex_id := gen_random_uuid();
    INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
    VALUES (v_ex_id,'Dip (Parallel Bar)','intermediate','compound','push',false,true,'medium',false,NULL,'public','active',
        jsonb_build_object('it',jsonb_build_object('name','Dip alle Parallele','description','Esercizio fondamentale a corpo libero sulle parallele che sviluppa pettorale inferiore, tricipiti e deltoide anteriore. Abbassarsi finché le spalle sono sotto i gomiti, poi spingere fino all''estensione completa.'),'en',jsonb_build_object('name','Dip (Parallel Bar)','description','Fundamental bodyweight exercise on parallel bars developing lower chest, triceps and anterior deltoid. Lower until shoulders are below elbows, then press to full extension.')),NOW(),NOW());
    SELECT id INTO v_id FROM exercises.muscle WHERE code='pec_major_lower'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'primary',45,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='pec_major_mid'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'primary',25,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='triceps_long_head'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'secondary',20,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.category WHERE code='calisthenics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_ex_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.equipment WHERE code='dip_bars'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_ex_id,v_id,true,true,1,NOW()) ON CONFLICT DO NOTHING; END IF;
    FOR v_id IN SELECT id FROM exercises.tag WHERE code IN('calisthenics','bodyweight','calisthenics_skill') LOOP INSERT INTO exercises.exercise_tag VALUES(v_ex_id,v_id,NOW()) ON CONFLICT DO NOTHING; END LOOP;

    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Bench Dip') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Bench Dip','beginner','compound','push',false,true,'low',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Dip alla Panca','description','Dip eseguito con le mani su una panca e i piedi a terra. Regressione ideale per costruire la forza di base necessaria per i dip alle parallele.'),'en',jsonb_build_object('name','Bench Dip','description','Dip performed with hands on a bench and feet on the floor. Ideal regression for building base strength needed for parallel bar dips.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='pec_major_lower'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',40,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='calisthenics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='none_bodyweight'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,true,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',-1,NOW()) ON CONFLICT DO NOTHING;
    ELSE SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Bench Dip'; INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',-1,NOW()) ON CONFLICT DO NOTHING; END IF;

    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Ring Dip') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Ring Dip','advanced','compound','push',false,true,'medium',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Dip agli Anelli','description','Dip eseguito su anelli ginnici che aggiunge instabilità e richiede maggiore controllo delle spalle. Gli anelli ruotano verso l''interno nella salita, aumentando l''attivazione pettorale.'),'en',jsonb_build_object('name','Ring Dip','description','Dip on gymnastic rings adding instability requiring greater shoulder control. Rings rotate inward on the way up, increasing chest activation.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='pec_major_lower'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',45,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='calisthenics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='gymnastic_rings'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,true,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',1,NOW()) ON CONFLICT DO NOTHING;
    ELSE SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Ring Dip'; INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',1,NOW()) ON CONFLICT DO NOTHING; END IF;

    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Weighted Dip') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Weighted Dip','advanced','compound','push',false,true,'medium',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Dip con Carico','description','Dip alle parallele con peso aggiuntivo tramite cintura o gilet zavorrato. Aumenta la resistenza per costruire maggiore forza assoluta.'),'en',jsonb_build_object('name','Weighted Dip','description','Parallel bar dip with added weight via belt or weighted vest. Increases resistance for greater absolute strength development.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='pec_major_lower'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',45,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='calisthenics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='dip_bars'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,true,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',1,NOW()) ON CONFLICT DO NOTHING;
    ELSE SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Weighted Dip'; INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',1,NOW()) ON CONFLICT DO NOTHING; END IF;
END $$;

-- ─── Diamond Push-Up ─────────────────────────────────────────
DO $$
DECLARE v_ex_id UUID; v_var_id UUID; v_id UUID;
BEGIN
    IF EXISTS (SELECT 1 FROM exercises.exercise WHERE name = 'Diamond Push-Up') THEN
        RAISE NOTICE 'Already exists: Diamond Push-Up'; RETURN;
    END IF;
    v_ex_id := gen_random_uuid();
    INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
    VALUES (v_ex_id,'Diamond Push-Up','intermediate','compound','push',false,true,'low',false,NULL,'public','active',
        jsonb_build_object('it',jsonb_build_object('name','Flessione a Diamante','description','Flessione con le mani ravvicinate a formare un rombo tra pollici e indici. Massimizza il coinvolgimento dei tricipiti e del pettorale interno.'),'en',jsonb_build_object('name','Diamond Push-Up','description','Push-up with hands close together forming a diamond shape between thumbs and index fingers. Maximizes tricep and inner chest engagement.')),NOW(),NOW());
    SELECT id INTO v_id FROM exercises.muscle WHERE code='pec_major_mid'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'primary',40,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='triceps_long_head'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'primary',40,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.category WHERE code='calisthenics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_ex_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.equipment WHERE code='none_bodyweight'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_ex_id,v_id,true,true,1,NOW()) ON CONFLICT DO NOTHING; END IF;
    FOR v_id IN SELECT id FROM exercises.tag WHERE code IN('calisthenics','bodyweight','no_equipment','home_friendly') LOOP INSERT INTO exercises.exercise_tag VALUES(v_ex_id,v_id,NOW()) ON CONFLICT DO NOTHING; END LOOP;

    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Elevated Diamond Push-Up') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Elevated Diamond Push-Up','beginner','compound','push',false,true,'low',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Flessione a Diamante Elevata','description','Versione facilitata del diamond push-up con le mani su una superficie rialzata.'),'en',jsonb_build_object('name','Elevated Diamond Push-Up','description','Easier version of the diamond push-up with hands on an elevated surface.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='pec_major_mid'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',40,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='calisthenics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='none_bodyweight'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,true,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',-1,NOW()) ON CONFLICT DO NOTHING;
    ELSE SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Elevated Diamond Push-Up'; INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',-1,NOW()) ON CONFLICT DO NOTHING; END IF;
END $$;

-- ─── Muscle-Up ───────────────────────────────────────────────
DO $$
DECLARE v_ex_id UUID; v_var_id UUID; v_id UUID;
BEGIN
    IF EXISTS (SELECT 1 FROM exercises.exercise WHERE name = 'Muscle-Up') THEN
        RAISE NOTICE 'Already exists: Muscle-Up'; RETURN;
    END IF;
    v_ex_id := gen_random_uuid();
    INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
    VALUES (v_ex_id,'Muscle-Up','advanced','compound','pull',false,true,'medium',false,NULL,'public','active',
        jsonb_build_object('it',jsonb_build_object('name','Muscle-Up','description','Movimento composito che combina una trazione esplosiva con una transizione e una pressata sopra la sbarra. Richiede forza di trazione, coordinazione e potenza. Coinvolge dorsali, pettorale inferiore e tricipiti.'),'en',jsonb_build_object('name','Muscle-Up','description','Composite movement combining an explosive pull with a transition and push above the bar. Requires pulling strength, coordination and power. Engages lats, lower chest and triceps.')),NOW(),NOW());
    SELECT id INTO v_id FROM exercises.muscle WHERE code='pec_major_lower'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'primary',30,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='lat_dorsi'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'primary',35,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='triceps_long_head'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'primary',25,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.category WHERE code='calisthenics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_ex_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.equipment WHERE code='pull_up_bar'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_ex_id,v_id,true,true,1,NOW()) ON CONFLICT DO NOTHING; END IF;
    FOR v_id IN SELECT id FROM exercises.tag WHERE code IN('calisthenics','bodyweight','calisthenics_skill') LOOP INSERT INTO exercises.exercise_tag VALUES(v_ex_id,v_id,NOW()) ON CONFLICT DO NOTHING; END LOOP;

    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Band-Assisted Muscle-Up') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Band-Assisted Muscle-Up','intermediate','compound','pull',false,true,'low',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Muscle-Up con Elastico','description','Muscle-up assistito da un elastico per ridurre il carico e apprendere la tecnica di transizione.'),'en',jsonb_build_object('name','Band-Assisted Muscle-Up','description','Muscle-up assisted by a resistance band to reduce load and learn the transition technique.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='pec_major_lower'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',30,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='calisthenics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='pull_up_bar'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,true,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',-1,NOW()) ON CONFLICT DO NOTHING;
    ELSE SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Band-Assisted Muscle-Up'; INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',-1,NOW()) ON CONFLICT DO NOTHING; END IF;

    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Strict Bar Muscle-Up') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Strict Bar Muscle-Up','advanced','compound','pull',false,true,'medium',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Muscle-Up Stretto','description','Muscle-up eseguito senza kipping, con forza pura e controllo assoluto del movimento.'),'en',jsonb_build_object('name','Strict Bar Muscle-Up','description','Muscle-up performed without kipping, using pure strength and absolute movement control.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='pec_major_lower'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',30,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='calisthenics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='pull_up_bar'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,true,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',1,NOW()) ON CONFLICT DO NOTHING;
    ELSE SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Strict Bar Muscle-Up'; INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',1,NOW()) ON CONFLICT DO NOTHING; END IF;
END $$;

-- ─── Planche Lean ────────────────────────────────────────────
DO $$
DECLARE v_ex_id UUID; v_var_id UUID; v_id UUID;
BEGIN
    IF EXISTS (SELECT 1 FROM exercises.exercise WHERE name = 'Planche Lean') THEN
        RAISE NOTICE 'Already exists: Planche Lean'; RETURN;
    END IF;
    v_ex_id := gen_random_uuid();
    INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
    VALUES (v_ex_id,'Planche Lean','intermediate','compound','static',false,true,'medium',false,NULL,'public','active',
        jsonb_build_object('it',jsonb_build_object('name','Inclinazione Plancha','description','Tenuta isometrica in posizione planche lean dove il corpo è inclinato in avanti con le braccia tese. Costruisce la tensione necessaria nelle spalle anteriori e nel pettorale inferiore per progressioni verso la planche.'),'en',jsonb_build_object('name','Planche Lean','description','Isometric hold in the planche lean position with the body tilted forward on straight arms. Builds the required tension in anterior shoulders and lower chest for planche progressions.')),NOW(),NOW());
    SELECT id INTO v_id FROM exercises.muscle WHERE code='pec_minor'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'primary',35,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='serratus_anterior'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'primary',30,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='deltoid_anterior'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'secondary',25,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.category WHERE code='calisthenics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_ex_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.equipment WHERE code='parallettes'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_ex_id,v_id,true,false,1,NOW()) ON CONFLICT DO NOTHING; END IF;
    FOR v_id IN SELECT id FROM exercises.tag WHERE code IN('calisthenics','bodyweight','calisthenics_skill') LOOP INSERT INTO exercises.exercise_tag VALUES(v_ex_id,v_id,NOW()) ON CONFLICT DO NOTHING; END LOOP;

    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Tuck Planche Hold') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Tuck Planche Hold','intermediate','compound','static',false,true,'low',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Tenuta Tuck Plancha','description','Prima vera posizione di planche con ginocchia piegate verso il petto. Primo step per imparare la planche completa.'),'en',jsonb_build_object('name','Tuck Planche Hold','description','First real planche position with knees tucked to the chest. First step toward learning the full planche.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='pec_minor'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',35,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='calisthenics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='parallettes'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,false,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',1,NOW()) ON CONFLICT DO NOTHING;
    ELSE SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Tuck Planche Hold'; INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',1,NOW()) ON CONFLICT DO NOTHING; END IF;

    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Straddle Planche Hold') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Straddle Planche Hold','advanced','compound','static',false,true,'high',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Tenuta Straddle Plancha','description','Planche con le gambe divaricate che riduce il braccio di leva rispetto alla versione completa.'),'en',jsonb_build_object('name','Straddle Planche Hold','description','Planche with legs spread apart reducing the lever arm compared to full planche.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='pec_minor'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',35,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='calisthenics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='parallettes'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,false,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',2,NOW()) ON CONFLICT DO NOTHING;
    ELSE SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Straddle Planche Hold'; INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',2,NOW()) ON CONFLICT DO NOTHING; END IF;
END $$;

-- ─── Ring Fly ─────────────────────────────────────────────────
DO $$
DECLARE v_ex_id UUID; v_var_id UUID; v_id UUID;
BEGIN
    IF EXISTS (SELECT 1 FROM exercises.exercise WHERE name = 'Ring Fly') THEN
        RAISE NOTICE 'Already exists: Ring Fly'; RETURN;
    END IF;
    v_ex_id := gen_random_uuid();
    INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
    VALUES (v_ex_id,'Ring Fly','advanced','isolation','push',false,true,'high',false,NULL,'public','active',
        jsonb_build_object('it',jsonb_build_object('name','Aperture agli Anelli','description','Esercizio di isolamento del pettorale su anelli ginnici. Partendo con le braccia tese, aprirle controllando la discesa e poi chiuderle con forza. Richiede grande mobilità e forza stabilizzatrice delle spalle.'),'en',jsonb_build_object('name','Ring Fly','description','Chest isolation exercise on gymnastic rings. Starting with arms extended, lower them with control then squeeze them together. Requires great shoulder mobility and stabilizing strength.')),NOW(),NOW());
    SELECT id INTO v_id FROM exercises.muscle WHERE code='pec_major_mid'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'primary',50,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='pec_major_upper'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'primary',30,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.category WHERE code='calisthenics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_ex_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.equipment WHERE code='gymnastic_rings'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_ex_id,v_id,true,true,1,NOW()) ON CONFLICT DO NOTHING; END IF;
    FOR v_id IN SELECT id FROM exercises.tag WHERE code IN('calisthenics','bodyweight','calisthenics_skill') LOOP INSERT INTO exercises.exercise_tag VALUES(v_ex_id,v_id,NOW()) ON CONFLICT DO NOTHING; END LOOP;

    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Assisted Ring Fly') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Assisted Ring Fly','intermediate','isolation','push',false,true,'medium',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Aperture agli Anelli Assistite','description','Versione assistita delle aperture agli anelli con i piedi a terra o su una superficie di supporto per ridurre il carico.'),'en',jsonb_build_object('name','Assisted Ring Fly','description','Assisted version of ring flies with feet on the ground or on a support surface to reduce load.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='pec_major_mid'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',50,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='calisthenics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='gymnastic_rings'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,true,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',-1,NOW()) ON CONFLICT DO NOTHING;
    ELSE SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Assisted Ring Fly'; INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',-1,NOW()) ON CONFLICT DO NOTHING; END IF;
END $$;

-- ─── Hindu Push-Up ───────────────────────────────────────────
DO $$
DECLARE v_ex_id UUID; v_var_id UUID; v_id UUID;
BEGIN
    IF EXISTS (SELECT 1 FROM exercises.exercise WHERE name = 'Hindu Push-Up') THEN
        RAISE NOTICE 'Already exists: Hindu Push-Up'; RETURN;
    END IF;
    v_ex_id := gen_random_uuid();
    INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
    VALUES (v_ex_id,'Hindu Push-Up','intermediate','compound','push',false,true,'low',false,NULL,'public','active',
        jsonb_build_object('it',jsonb_build_object('name','Flessione Hindu','description','Flessione circolare che parte dalla posizione a V, scende con il petto verso il basso in un arco e termina in cobra. Combina forza, mobilità della colonna e fluidità del movimento.'),'en',jsonb_build_object('name','Hindu Push-Up','description','Circular push-up starting from a V position, sweeping the chest down in an arc and finishing in cobra. Combines strength, spinal mobility and movement fluidity.')),NOW(),NOW());
    SELECT id INTO v_id FROM exercises.muscle WHERE code='pec_major_mid'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'primary',40,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='pec_major_upper'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'primary',25,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='deltoid_anterior'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'secondary',20,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.category WHERE code='calisthenics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_ex_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.equipment WHERE code='none_bodyweight'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_ex_id,v_id,true,true,1,NOW()) ON CONFLICT DO NOTHING; END IF;
    FOR v_id IN SELECT id FROM exercises.tag WHERE code IN('calisthenics','bodyweight','no_equipment','home_friendly') LOOP INSERT INTO exercises.exercise_tag VALUES(v_ex_id,v_id,NOW()) ON CONFLICT DO NOTHING; END LOOP;

    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Divebomber Push-Up') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Divebomber Push-Up','intermediate','compound','push',false,true,'low',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Flessione Divebomber','description','Simile alla flessione hindu ma con il movimento inverso nella fase di ritorno. Il corpo disegna un ampio arco bidirezionale.'),'en',jsonb_build_object('name','Divebomber Push-Up','description','Similar to the Hindu push-up but with the reverse movement on the return. The body traces a wide bidirectional arc.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='pec_major_mid'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',40,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='calisthenics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='none_bodyweight'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,true,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',0,NOW()) ON CONFLICT DO NOTHING;
    ELSE SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Divebomber Push-Up'; INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',0,NOW()) ON CONFLICT DO NOTHING; END IF;
END $$;

-- ─── Clapping Push-Up ────────────────────────────────────────
DO $$
DECLARE v_ex_id UUID; v_var_id UUID; v_id UUID;
BEGIN
    IF EXISTS (SELECT 1 FROM exercises.exercise WHERE name = 'Clapping Push-Up') THEN
        RAISE NOTICE 'Already exists: Clapping Push-Up'; RETURN;
    END IF;
    v_ex_id := gen_random_uuid();
    INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
    VALUES (v_ex_id,'Clapping Push-Up','intermediate','compound','push',false,true,'medium',false,NULL,'public','active',
        jsonb_build_object('it',jsonb_build_object('name','Flessione con Applauso','description','Flessione pliometrica con battuta di mani in aria. Sviluppa la potenza esplosiva del petto e la velocità di contrazione muscolare.'),'en',jsonb_build_object('name','Clapping Push-Up','description','Plyometric push-up with a hand clap in the air. Develops explosive chest power and rate of muscular contraction.')),NOW(),NOW());
    SELECT id INTO v_id FROM exercises.muscle WHERE code='pec_major_mid'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'primary',45,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code='deltoid_anterior'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'primary',25,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.category WHERE code='calisthenics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_ex_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.equipment WHERE code='none_bodyweight'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_ex_id,v_id,true,true,1,NOW()) ON CONFLICT DO NOTHING; END IF;
    FOR v_id IN SELECT id FROM exercises.tag WHERE code IN('calisthenics','bodyweight','no_equipment') LOOP INSERT INTO exercises.exercise_tag VALUES(v_ex_id,v_id,NOW()) ON CONFLICT DO NOTHING; END LOOP;

    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='Double Clapping Push-Up') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES(v_var_id,'Double Clapping Push-Up','advanced','compound','push',false,true,'medium',false,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Flessione con Doppio Applauso','description','Versione avanzata con due battute di mani durante la fase aerea. Richiede maggiore potenza esplosiva.'),'en',jsonb_build_object('name','Double Clapping Push-Up','description','Advanced version with two hand claps during the airborne phase. Requires greater explosive power.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='pec_major_mid'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',45,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='calisthenics'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='none_bodyweight'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,true,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',1,NOW()) ON CONFLICT DO NOTHING;
    ELSE SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Double Clapping Push-Up'; INSERT INTO exercises.exercise_variation (base_exercise_id, variant_exercise_id, variation_type, difficulty_delta, created_at) VALUES(v_ex_id,v_var_id,'default',1,NOW()) ON CONFLICT DO NOTHING; END IF;
END $$;
