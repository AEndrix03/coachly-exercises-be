# Codex Agent Prompt — SQL Generation per Esercizi

> Copia l'intero contenuto come prompt per Codex / GPT-4o agent.

---

## CONTESTO

Stai generando file `.sql` di seeding per un database PostgreSQL di una app fitness (Coachly).
Schema: `exercises`. I dati di riferimento (muscoli, categorie, equipment, tag) sono già stati
inseriti dai file in `inj/sql/00_reference/`.

I file `.md` in `inj/<disciplina>/<gruppo_muscolare>.md` contengono già tutti gli esercizi
con i loro metadati. Il tuo compito è leggere questi file e generare **un file `.sql` per ogni
esercizio principale** (NON per le varianti — le varianti vengono inserite nello stesso file
del padre tramite `exercise_variation`).

---

## STRUTTURA DB (schema: `exercises`)

### Tabelle principali

```sql
-- Esercizio
exercises.exercise (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,             -- nome canonico INGLESE
    difficulty VARCHAR                       -- beginner | intermediate | advanced | elite
        CHECK (difficulty IN ('beginner','intermediate','advanced','elite')),
    mechanics VARCHAR                        -- compound | isolation
        CHECK (mechanics IN ('compound','isolation')),
    force VARCHAR                            -- push | pull | static | dynamic
        CHECK (force IN ('push','pull','static','dynamic')),
    unilateral BOOLEAN NOT NULL DEFAULT false,
    bodyweight BOOLEAN NOT NULL DEFAULT false,
    overall_risk VARCHAR                     -- low | medium | high | very_high
        CHECK (overall_risk IN ('low','medium','high','very_high')),
    spotter_required BOOLEAN NOT NULL DEFAULT false,
    owner_user_id UUID,                      -- NULL per esercizi di sistema
    visibility VARCHAR NOT NULL DEFAULT 'public',
    status VARCHAR NOT NULL DEFAULT 'active',
    translations JSONB NOT NULL,             -- {"it":{...},"en":{...}}
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
)

-- Relazione esercizio-muscolo
exercises.exercise_muscle (
    exercise_id UUID REFERENCES exercises.exercise(id),
    muscle_id UUID REFERENCES exercises.muscle(id),
    involvement_level VARCHAR                -- primary | secondary | tertiary
        CHECK (involvement_level IN ('primary','secondary','tertiary')),
    activation_percentage INT,               -- 0-100, stima % attivazione
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (exercise_id, muscle_id)
)

-- Relazione esercizio-categoria (disciplina)
exercises.exercise_category (
    exercise_id UUID REFERENCES exercises.exercise(id),
    category_id UUID REFERENCES exercises.category(id),
    is_primary BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (exercise_id, category_id)
)

-- Relazione esercizio-equipment
exercises.exercise_equipment (
    exercise_id UUID REFERENCES exercises.exercise(id),
    equipment_id UUID REFERENCES exercises.equipment(id),
    required BOOLEAN NOT NULL DEFAULT true,  -- true = obbligatorio
    is_primary BOOLEAN NOT NULL DEFAULT true,-- true = equipment principale
    quantity_needed INT NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (exercise_id, equipment_id)
)

-- Relazione esercizio-tag
exercises.exercise_tag (
    exercise_id UUID REFERENCES exercises.exercise(id),
    tag_id UUID REFERENCES exercises.tag(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (exercise_id, tag_id)
)

-- Varianti esercizi
exercises.exercise_variation (
    base_exercise_id UUID REFERENCES exercises.exercise(id),
    variant_exercise_id UUID REFERENCES exercises.exercise(id),
    difficulty_delta INT,   -- differenza di difficolta vs padre (negativo=piu facile, positivo=piu difficile)
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (base_exercise_id, variant_exercise_id)
)
```

### Codici muscoli disponibili (da 01_muscles.sql)

**GROUP: chest** → pec_major_upper, pec_major_mid, pec_major_lower, pec_minor, serratus_anterior
**GROUP: back** → lat_dorsi, trap_upper, trap_mid, trap_lower, rhomboid_major, rhomboid_minor, teres_major, erector_spinae, multifidus, quadratus_lumborum, levator_scapulae
**GROUP: shoulders** → deltoid_anterior, deltoid_lateral, deltoid_posterior, supraspinatus, infraspinatus, teres_minor, subscapularis
**GROUP: biceps** → biceps_long_head, biceps_short_head, brachialis, brachioradialis, coracobrachialis
**GROUP: triceps** → triceps_long_head, triceps_lateral_head, triceps_medial_head, anconeus
**GROUP: forearms** → flexor_carpi_radialis, flexor_carpi_ulnaris, extensor_carpi_radialis_long, extensor_carpi_radialis_brev, extensor_carpi_ulnaris, pronator_teres, supinator, flexor_digitorum_superfic, extensor_digitorum
**GROUP: core** → rectus_abdominis, external_oblique, internal_oblique, transversus_abdom, diaphragm, pelvic_floor
**GROUP: quads** → rectus_femoris, vastus_lateralis, vastus_medialis, vastus_intermedius, tensor_fasciae_lat
**GROUP: hamstrings** → biceps_femoris_long, biceps_femoris_short, semitendinosus, semimembranosus
**GROUP: glutes** → gluteus_maximus, gluteus_medius, gluteus_minimus, piriformis, obturator_internus, gemellus_superior, gemellus_inferior
**GROUP: calves** → gastrocnemius_medial, gastrocnemius_lateral, soleus, tibialis_anterior, tibialis_posterior, fibularis_longus, fibularis_brevis, flexor_hallucis_long
**GROUP: adductors** → adductor_longus, adductor_brevis, adductor_magnus, gracilis, pectineus
**GROUP: hip_flexors** → psoas_major, iliacus, sartorius (+ rectus_femoris, tensor_fasciae_lat from quads)
**GROUP: neck** → sternocleidomastoid, splenius_capitis, splenius_cervicis, scalene_anterior, scalene_mid, scalene_posterior (+ trap_upper, levator_scapulae from back)
**GROUP: thoracic** → thoracic_erector, multifidus_thoracic, intercostals_internal, intercostals_external

### Codici categorie (da 02_categories.sql)
bodybuilding, powerlifting, olympic_weightlifting, strongman, crossfit, functional_training,
hiit, calisthenics, gymnastics, home_workout, yoga, pilates, cardio, kettlebell,
resistance_bands, trx, stretching, mobility, foam_rolling, warm_up, core_training,
boxing, martial_arts, rehabilitation, balance_stability, sport_specific

### Codici equipment principali (da 03_equipment.sql)
barbell, ez_bar, axle_bar, log_bar, safety_squat_bar, cambered_bar, trap_bar,
dumbbell, kettlebell, flat_bench, incline_bench, decline_bench, adjustable_bench,
preacher_bench, power_rack, squat_rack, pull_up_bar, dip_bars, gymnastic_rings,
landmine, cable_machine, smith_machine, leg_press_machine, lat_pulldown_machine,
seated_row_machine, chest_press_machine, shoulder_press_machine, leg_extension_machine,
leg_curl_machine, calf_raise_machine, pec_deck_machine, adductor_machine, abductor_machine,
glute_kickback_machine, neck_machine, ghd_machine, reverse_hyper_machine, hack_squat_machine,
ab_crunch_machine, treadmill, stationary_bike, rowing_machine, assault_bike, ski_erg,
jump_rope, battle_ropes, stair_climber, resistance_band, mini_band, pull_up_assist_band,
trx_straps, foam_roller, lacrosse_ball, yoga_mat, yoga_block, yoga_strap, bosu_ball,
stability_ball, ab_wheel, medicine_ball, wall_ball, heavy_bag, speed_bag, box_platform,
dip_belt, weight_vest, ankle_weights, hip_thrust_pad, wrist_wraps, lifting_straps, chalk,
sandbag, tire, atlas_stone, yoke, t_bar_attachment, wobble_board, parallettes, none_bodyweight

### Codici tag principali (da 04_tags.sql)
**mechanics:** compound, isolation, isometric, explosive, eccentric, plyometric, ballistic
**pattern:** horizontal_push, vertical_push, horizontal_pull, vertical_pull, hip_hinge, knee_dominant, carry, rotation, anti_rotation, anti_extension, anti_lateral
**body_area:** upper_body, lower_body, full_body, core_focus, bilateral, unilateral
**goal:** strength, hypertrophy, endurance, power, flexibility, mobility, balance, coordination, fat_loss, rehabilitation, activation, prehab, sport_perf
**equipment:** no_equipment, home_friendly, gym_required, barbell_tag, dumbbell_tag, cable_tag, machine_tag, kettlebell_tag, band_tag, rings_tag
**safety:** spotter_needed, high_risk, beginner_safe, advanced_only, low_back_risk, shoulder_risk, knee_risk
**style:** pause_rep, tempo_training, max_effort, dynamic_effort, time_under_tension, amrap, emom, for_time
**sport:** powerlifting_comp, olympic_lift, strongman_event, crossfit_movement, calisthenics_skill, yoga_pose, pilates_exercise, martial_arts_cond, boxing_cond, physiotherapy

---

## TEMPLATE SQL — UN FILE PER ESERCIZIO

Crea ogni file in: `inj/sql/exercises/<nome_file>.sql`
dove `<nome_file>` = nome inglese lowercase con underscore (es. `barbell_bench_press.sql`)

```sql
-- =============================================================
-- Exercise: <English Name>
-- File: <filename>.sql
-- Disciplines: <discipline1>, <discipline2>
-- =============================================================

DO $$
DECLARE
    v_ex_id    UUID;
    v_var_id   UUID;
    v_id       UUID;
BEGIN
    -- ── SKIP IF ALREADY INSERTED ──────────────────────────────
    IF EXISTS (SELECT 1 FROM exercises.exercise WHERE name = '<English Name>') THEN
        RAISE NOTICE 'Exercise already exists: <English Name>';
        RETURN;
    END IF;

    v_ex_id := gen_random_uuid();

    -- ── MAIN EXERCISE ─────────────────────────────────────────
    INSERT INTO exercises.exercise (
        id, name, difficulty, mechanics, force,
        unilateral, bodyweight, overall_risk, spotter_required,
        owner_user_id, visibility, status, translations, created_at, updated_at
    ) VALUES (
        v_ex_id,
        '<English Name>',
        '<difficulty>',
        '<mechanics>',
        '<force>',
        <unilateral>,
        <bodyweight>,
        '<risk>',
        <spotter>,
        NULL,
        'public',
        'active',
        jsonb_build_object(
            'it', jsonb_build_object(
                'name',        '<Nome Italiano>',
                'description', '<Descrizione italiana dettagliata, 2-4 frasi>'
            ),
            'en', jsonb_build_object(
                'name',        '<English Name>',
                'description', '<Detailed English description, 2-4 sentences>'
            )
        ),
        NOW(), NOW()
    );

    -- ── MUSCLES ───────────────────────────────────────────────
    -- Primary (involvement_level = 'primary', activation ~60-100%)
    SELECT id INTO v_id FROM exercises.muscle WHERE code = '<muscle_code>';
    IF v_id IS NOT NULL THEN
        INSERT INTO exercises.exercise_muscle VALUES (v_ex_id, v_id, 'primary', <activation_pct>, NOW()) ON CONFLICT DO NOTHING;
    END IF;

    -- Secondary (involvement_level = 'secondary', activation ~30-60%)
    SELECT id INTO v_id FROM exercises.muscle WHERE code = '<muscle_code>';
    IF v_id IS NOT NULL THEN
        INSERT INTO exercises.exercise_muscle VALUES (v_ex_id, v_id, 'secondary', <activation_pct>, NOW()) ON CONFLICT DO NOTHING;
    END IF;

    -- Tertiary (involvement_level = 'tertiary', activation ~10-30%)
    SELECT id INTO v_id FROM exercises.muscle WHERE code = '<muscle_code>';
    IF v_id IS NOT NULL THEN
        INSERT INTO exercises.exercise_muscle VALUES (v_ex_id, v_id, 'tertiary', <activation_pct>, NOW()) ON CONFLICT DO NOTHING;
    END IF;

    -- ── CATEGORIES ────────────────────────────────────────────
    -- is_primary = true per la disciplina principale
    SELECT id INTO v_id FROM exercises.category WHERE code = '<category_code>';
    IF v_id IS NOT NULL THEN
        INSERT INTO exercises.exercise_category VALUES (v_ex_id, v_id, true, NOW()) ON CONFLICT DO NOTHING;
    END IF;

    SELECT id INTO v_id FROM exercises.category WHERE code = '<other_category_code>';
    IF v_id IS NOT NULL THEN
        INSERT INTO exercises.exercise_category VALUES (v_ex_id, v_id, false, NOW()) ON CONFLICT DO NOTHING;
    END IF;

    -- ── EQUIPMENT ─────────────────────────────────────────────
    -- required=true, is_primary=true per equipment principale
    SELECT id INTO v_id FROM exercises.equipment WHERE code = '<equipment_code>';
    IF v_id IS NOT NULL THEN
        INSERT INTO exercises.exercise_equipment VALUES (v_ex_id, v_id, true, true, 1, NOW()) ON CONFLICT DO NOTHING;
    END IF;

    -- ── TAGS ──────────────────────────────────────────────────
    SELECT id INTO v_id FROM exercises.tag WHERE code = '<tag_code>';
    IF v_id IS NOT NULL THEN
        INSERT INTO exercises.exercise_tag VALUES (v_ex_id, v_id, NOW()) ON CONFLICT DO NOTHING;
    END IF;

    -- ── VARIANTS (insert each variant, then link to parent) ───
    -- Repeat this block for EACH variant listed in the .md file
    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name = '<Variant Name EN>') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (
            id, name, difficulty, mechanics, force,
            unilateral, bodyweight, overall_risk, spotter_required,
            owner_user_id, visibility, status, translations, created_at, updated_at
        ) VALUES (
            v_var_id, '<Variant Name EN>', '<variant_difficulty>', '<mechanics>', '<force>',
            <unilateral>, <bodyweight>, '<risk>', <spotter>, NULL, 'public', 'active',
            jsonb_build_object(
                'it', jsonb_build_object('name','<Nome Variante IT>','description','<Descrizione variante IT>'),
                'en', jsonb_build_object('name','<Variant Name EN>','description','<Variant description EN>')
            ),
            NOW(), NOW()
        );
        -- Add muscles to variant (same as parent or adjusted)
        -- Add categories to variant
        -- Link variant to parent
        INSERT INTO exercises.exercise_variation VALUES (v_ex_id, v_var_id, <difficulty_delta>, NOW()) ON CONFLICT DO NOTHING;
    ELSE
        SELECT id INTO v_var_id FROM exercises.exercise WHERE name = '<Variant Name EN>';
        INSERT INTO exercises.exercise_variation VALUES (v_ex_id, v_var_id, <difficulty_delta>, NOW()) ON CONFLICT DO NOTHING;
    END IF;

END $$;
```

### Regole per difficulty_delta in exercise_variation
- Variante più semplice del padre: -1 (es. knee push-up vs push-up)
- Stessa difficoltà ma diversa: 0 (es. incline vs flat bench)
- Più difficile: +1 (es. weighted push-up)
- Molto più difficile: +2 o +3 (es. planche push-up vs push-up)

---

## DONE REGISTRY — come aggiornarlo

Dopo ogni esercizio inserito (padre + varianti), aggiungi una riga in:
`inj/sql/_done/done_registry.md`

Formato:
```
| Exercise Name (EN) | SQL File | Variants Included | Done By |
|---|---|---|---|
| Barbell Bench Press | barbell_bench_press.sql | 12 | codex_agent_a |
```

**IMPORTANTE:** Prima di iniziare ogni esercizio, controlla se è già nel done_registry.
Se è presente, SALTA e passa al successivo.

---

## DOVE TROVARE GLI ESERCIZI

Leggi i file .md nelle cartelle disciplina. Ogni file ha la forma:

```
inj/<disciplina>/<gruppo_muscolare>.md
```

Esempio: `inj/bodybuilding/chest.md` contiene tutti gli esercizi per il petto nel bodybuilding.

### Priorità di lavorazione consigliata

1. **bodybuilding/** (tutti i file) — massima priorità
2. **powerlifting/** — molti condivisi con bodybuilding, usa ON CONFLICT DO NOTHING
3. **crossfit/** — include movimenti olimpici e ginnastica
4. **calisthenics/** — solo bodyweight
5. **olympic_weightlifting/** — movimenti tecnici
6. Tutti gli altri

---

## ESEMPIO COMPLETO: barbell_bench_press.sql

```sql
-- =============================================================
-- Exercise: Barbell Bench Press
-- File: barbell_bench_press.sql
-- Disciplines: bodybuilding (primary), powerlifting, crossfit
-- =============================================================

DO $$
DECLARE
    v_ex_id  UUID;
    v_var_id UUID;
    v_id     UUID;
BEGIN
    IF EXISTS (SELECT 1 FROM exercises.exercise WHERE name = 'Barbell Bench Press') THEN
        RAISE NOTICE 'Exercise already exists: Barbell Bench Press';
        RETURN;
    END IF;

    v_ex_id := gen_random_uuid();

    INSERT INTO exercises.exercise (
        id, name, difficulty, mechanics, force,
        unilateral, bodyweight, overall_risk, spotter_required,
        owner_user_id, visibility, status, translations, created_at, updated_at
    ) VALUES (
        v_ex_id, 'Barbell Bench Press', 'intermediate', 'compound', 'push',
        false, false, 'medium', true, NULL, 'public', 'active',
        jsonb_build_object(
            'it', jsonb_build_object(
                'name',        'Distensioni su Panca Piana con Bilanciere',
                'description', 'Esercizio fondamentale per lo sviluppo del petto. Sdraiato su una panca piana, impugna il bilanciere con una presa leggermente piu larga delle spalle. Abbassa il bilanciere controllato fino al petto, poi spingilo verso l alto fino all estensione completa delle braccia. Mantieni i piedi ben piantati a terra e la schiena in posizione neutra.'
            ),
            'en', jsonb_build_object(
                'name',        'Barbell Bench Press',
                'description', 'The foundational chest exercise. Lying on a flat bench, grip the barbell slightly wider than shoulder-width. Lower the bar under control to the chest, then press it back up to full arm extension. Keep feet flat on the floor and maintain a natural arch in the lower back.'
            )
        ),
        NOW(), NOW()
    );

    -- Primary muscles
    SELECT id INTO v_id FROM exercises.muscle WHERE code = 'pec_major_mid';
    IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES (v_ex_id,v_id,'primary',75,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code = 'pec_major_lower';
    IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES (v_ex_id,v_id,'primary',65,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code = 'pec_major_upper';
    IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES (v_ex_id,v_id,'secondary',40,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code = 'deltoid_anterior';
    IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES (v_ex_id,v_id,'secondary',45,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code = 'triceps_lateral_head';
    IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES (v_ex_id,v_id,'secondary',50,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code = 'triceps_medial_head';
    IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES (v_ex_id,v_id,'secondary',40,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.muscle WHERE code = 'serratus_anterior';
    IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES (v_ex_id,v_id,'tertiary',20,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- Categories
    SELECT id INTO v_id FROM exercises.category WHERE code = 'bodybuilding';
    IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES (v_ex_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.category WHERE code = 'powerlifting';
    IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES (v_ex_id,v_id,false,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.category WHERE code = 'crossfit';
    IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES (v_ex_id,v_id,false,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- Equipment
    SELECT id INTO v_id FROM exercises.equipment WHERE code = 'barbell';
    IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES (v_ex_id,v_id,true,true,1,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.equipment WHERE code = 'flat_bench';
    IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES (v_ex_id,v_id,true,false,1,NOW()) ON CONFLICT DO NOTHING; END IF;
    SELECT id INTO v_id FROM exercises.equipment WHERE code = 'power_rack';
    IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES (v_ex_id,v_id,false,false,1,NOW()) ON CONFLICT DO NOTHING; END IF;

    -- Tags
    FOR v_id IN SELECT id FROM exercises.tag WHERE code IN (
        'compound','horizontal_push','upper_body','bilateral','strength','hypertrophy',
        'barbell_tag','gym_required','spotter_needed'
    ) LOOP INSERT INTO exercises.exercise_tag VALUES (v_ex_id,v_id,NOW()) ON CONFLICT DO NOTHING; END LOOP;

    -- ── VARIANT: Pause Bench Press ─────────────────────────────
    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name = 'Pause Bench Press') THEN
        v_var_id := gen_random_uuid();
        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)
        VALUES (v_var_id,'Pause Bench Press','intermediate','compound','push',false,false,'medium',true,NULL,'public','active',
            jsonb_build_object('it',jsonb_build_object('name','Panca con Pausa','description','Variante della panca piana con una pausa di 1-3 secondi a petto prima di spingere. Elimina il rimbalzo e aumenta la difficolta della fase concentrica.'),
                               'en',jsonb_build_object('name','Pause Bench Press','description','Bench press variation with a 1-3 second pause at the chest before pressing. Eliminates stretch reflex and increases concentric difficulty.')),NOW(),NOW());
        SELECT id INTO v_id FROM exercises.muscle WHERE code='pec_major_mid'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',75,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.muscle WHERE code='triceps_lateral_head'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'secondary',55,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='bodybuilding'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.category WHERE code='powerlifting'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,false,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='barbell'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,true,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        SELECT id INTO v_id FROM exercises.equipment WHERE code='flat_bench'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,false,1,NOW()) ON CONFLICT DO NOTHING; END IF;
        FOR v_id IN SELECT id FROM exercises.tag WHERE code IN('compound','horizontal_push','strength','pause_rep','powerlifting_comp','spotter_needed') LOOP INSERT INTO exercises.exercise_tag VALUES(v_var_id,v_id,NOW()) ON CONFLICT DO NOTHING; END LOOP;
        INSERT INTO exercises.exercise_variation VALUES(v_ex_id,v_var_id,0,NOW()) ON CONFLICT DO NOTHING;
    ELSE
        SELECT id INTO v_var_id FROM exercises.exercise WHERE name='Pause Bench Press';
        INSERT INTO exercises.exercise_variation VALUES(v_ex_id,v_var_id,0,NOW()) ON CONFLICT DO NOTHING;
    END IF;

    -- (continua con le altre varianti nello stesso pattern...)

END $$;
```

---

## STRATEGIA PER AGENTI IN PARALLELO

Dividi le discipline tra i tuoi agenti. Ogni agente:

1. Legge i file .md assegnati
2. Controlla il `done_registry.md` per non duplicare
3. Genera i `.sql` nella cartella `inj/sql/exercises/`
4. Aggiorna il `done_registry.md` con ogni file completato

**NESSUN CONFLITTO:** ogni agente lavora su discipline diverse, ma gli esercizi condivisi
(es. Deadlift sia in bodybuilding che in powerlifting) vengono gestiti via `ON CONFLICT DO NOTHING`
sulla tabella `exercise`. Il primo agente che inserisce l'esercizio "vince", gli altri saltano.

### Batch consigliati

| Batch | Discipline da leggere | ~Esercizi |
|---|---|---|
| A | bodybuilding (chest, back, shoulders) | ~80 |
| B | bodybuilding (biceps, triceps, forearms, core, neck) | ~70 |
| C | bodybuilding (quads, hamstrings, glutes, calves, adductors) | ~70 |
| D | powerlifting (tutti i file) | ~80 |
| E | olympic_weightlifting + strongman | ~90 |
| F | crossfit + functional_training | ~80 |
| G | hiit + calisthenics | ~80 |
| H | gymnastics + home_workout | ~70 |
| I | yoga + pilates + cardio | ~80 |
| J | kettlebell + resistance_bands + trx | ~80 |
| K | stretching + mobility | ~80 |
| L | foam_rolling + warm_up + core_training | ~70 |
| M | boxing + martial_arts | ~70 |
| N | rehabilitation + balance_stability + sport_specific | ~80 |

---

## NOTE IMPORTANTI

- **Descrizioni**: scrivi descrizioni REALI e utili (tecnica, setup, cueing), non solo il nome. Min 2 frasi per lingua.
- **Activation %**: usa stime realistiche basate su EMG/letteratura:
  - Bench press: pec_major_mid ~75%, triceps ~50%, deltoid_ant ~45%
  - Squat: quads ~70-80%, glutes ~50-60%, hamstrings ~30%
  - Deadlift: erector_spinae ~70%, glutes ~60%, hamstrings ~55%, quads ~40%
- **ON CONFLICT DO NOTHING**: sempre su tutte le insert per sicurezza
- **Varianti**: ogni variante è un esercizio a sé nella tabella `exercise`, collegato al padre via `exercise_variation`
- **difficulty_delta**: 0 = stessa difficoltà, -1 = più facile, +1 = più difficile, +2/+3 = molto più difficile
- **is_primary in exercise_category**: true per la disciplina principale, false per le altre
- **is_primary in exercise_equipment**: true per l'equipment principale dell'esercizio
