-- =============================================================
-- REFERENCE DATA: Tags
-- Schema: exercises
-- Run BEFORE exercise SQL files
-- =============================================================

CREATE OR REPLACE FUNCTION exercises._upsert_tag(
    p_code VARCHAR, p_type VARCHAR, p_translations JSONB
) RETURNS VOID AS $$
BEGIN
    INSERT INTO exercises.tag (id, code, tag_type, status, translations, created_at, updated_at)
    VALUES (gen_random_uuid(), p_code, p_type, 'active', p_translations, NOW(), NOW())
    ON CONFLICT (code) DO NOTHING;
END;
$$ LANGUAGE plpgsql;

-- ── MECHANICS ─────────────────────────────────────────────────
SELECT exercises._upsert_tag('compound',     'mechanics', '{"it":{"name":"Multiarticolare"},"en":{"name":"Compound"}}');
SELECT exercises._upsert_tag('isolation',    'mechanics', '{"it":{"name":"Monoarticolare"},"en":{"name":"Isolation"}}');
SELECT exercises._upsert_tag('isometric',    'mechanics', '{"it":{"name":"Isometrico"},"en":{"name":"Isometric"}}');
SELECT exercises._upsert_tag('explosive',    'mechanics', '{"it":{"name":"Esplosivo"},"en":{"name":"Explosive"}}');
SELECT exercises._upsert_tag('eccentric',    'mechanics', '{"it":{"name":"Eccentrico"},"en":{"name":"Eccentric"}}');
SELECT exercises._upsert_tag('plyometric',   'mechanics', '{"it":{"name":"Pliometrico"},"en":{"name":"Plyometric"}}');
SELECT exercises._upsert_tag('ballistic',    'mechanics', '{"it":{"name":"Balistico"},"en":{"name":"Ballistic"}}');

-- ── MOVEMENT PATTERN ──────────────────────────────────────────
SELECT exercises._upsert_tag('horizontal_push',  'pattern', '{"it":{"name":"Spinta Orizzontale"},"en":{"name":"Horizontal Push"}}');
SELECT exercises._upsert_tag('vertical_push',    'pattern', '{"it":{"name":"Spinta Verticale"},"en":{"name":"Vertical Push"}}');
SELECT exercises._upsert_tag('horizontal_pull',  'pattern', '{"it":{"name":"Tirata Orizzontale"},"en":{"name":"Horizontal Pull"}}');
SELECT exercises._upsert_tag('vertical_pull',    'pattern', '{"it":{"name":"Tirata Verticale"},"en":{"name":"Vertical Pull"}}');
SELECT exercises._upsert_tag('hip_hinge',        'pattern', '{"it":{"name":"Cerniera Anca"},"en":{"name":"Hip Hinge"}}');
SELECT exercises._upsert_tag('knee_dominant',    'pattern', '{"it":{"name":"Dominante al Ginocchio"},"en":{"name":"Knee Dominant"}}');
SELECT exercises._upsert_tag('carry',            'pattern', '{"it":{"name":"Portare"},"en":{"name":"Carry"}}');
SELECT exercises._upsert_tag('rotation',         'pattern', '{"it":{"name":"Rotazione"},"en":{"name":"Rotation"}}');
SELECT exercises._upsert_tag('anti_rotation',    'pattern', '{"it":{"name":"Anti-Rotazione"},"en":{"name":"Anti-Rotation"}}');
SELECT exercises._upsert_tag('anti_extension',   'pattern', '{"it":{"name":"Anti-Estensione"},"en":{"name":"Anti-Extension"}}');
SELECT exercises._upsert_tag('anti_lateral',     'pattern', '{"it":{"name":"Anti-Flessione Laterale"},"en":{"name":"Anti-Lateral Flexion"}}');

-- ── BODY AREA ─────────────────────────────────────────────────
SELECT exercises._upsert_tag('upper_body', 'body_area', '{"it":{"name":"Parte Superiore"},"en":{"name":"Upper Body"}}');
SELECT exercises._upsert_tag('lower_body', 'body_area', '{"it":{"name":"Parte Inferiore"},"en":{"name":"Lower Body"}}');
SELECT exercises._upsert_tag('full_body',  'body_area', '{"it":{"name":"Corpo Intero"},"en":{"name":"Full Body"}}');
SELECT exercises._upsert_tag('core_focus', 'body_area', '{"it":{"name":"Focus Core"},"en":{"name":"Core Focus"}}');
SELECT exercises._upsert_tag('bilateral',  'body_area', '{"it":{"name":"Bilaterale"},"en":{"name":"Bilateral"}}');
SELECT exercises._upsert_tag('unilateral', 'body_area', '{"it":{"name":"Unilaterale"},"en":{"name":"Unilateral"}}');

-- ── GOAL ──────────────────────────────────────────────────────
SELECT exercises._upsert_tag('strength',      'goal', '{"it":{"name":"Forza"},"en":{"name":"Strength"}}');
SELECT exercises._upsert_tag('hypertrophy',   'goal', '{"it":{"name":"Ipertrofia"},"en":{"name":"Hypertrophy"}}');
SELECT exercises._upsert_tag('endurance',     'goal', '{"it":{"name":"Resistenza"},"en":{"name":"Endurance"}}');
SELECT exercises._upsert_tag('power',         'goal', '{"it":{"name":"Potenza"},"en":{"name":"Power"}}');
SELECT exercises._upsert_tag('flexibility',   'goal', '{"it":{"name":"Flessibilita"},"en":{"name":"Flexibility"}}');
SELECT exercises._upsert_tag('mobility',      'goal', '{"it":{"name":"Mobilita"},"en":{"name":"Mobility"}}');
SELECT exercises._upsert_tag('balance',       'goal', '{"it":{"name":"Equilibrio"},"en":{"name":"Balance"}}');
SELECT exercises._upsert_tag('coordination',  'goal', '{"it":{"name":"Coordinazione"},"en":{"name":"Coordination"}}');
SELECT exercises._upsert_tag('fat_loss',      'goal', '{"it":{"name":"Dimagrimento"},"en":{"name":"Fat Loss"}}');
SELECT exercises._upsert_tag('rehabilitation','goal', '{"it":{"name":"Riabilitazione"},"en":{"name":"Rehabilitation"}}');
SELECT exercises._upsert_tag('activation',    'goal', '{"it":{"name":"Attivazione Muscolare"},"en":{"name":"Muscle Activation"}}');
SELECT exercises._upsert_tag('prehab',        'goal', '{"it":{"name":"Prevenzione Infortuni"},"en":{"name":"Injury Prevention"}}');
SELECT exercises._upsert_tag('sport_perf',    'goal', '{"it":{"name":"Performance Sportiva"},"en":{"name":"Sport Performance"}}');

-- ── EQUIPMENT TAG ─────────────────────────────────────────────
SELECT exercises._upsert_tag('no_equipment',    'equipment', '{"it":{"name":"Senza Attrezzatura"},"en":{"name":"No Equipment"}}');
SELECT exercises._upsert_tag('home_friendly',   'equipment', '{"it":{"name":"A Casa"},"en":{"name":"Home Friendly"}}');
SELECT exercises._upsert_tag('gym_required',    'equipment', '{"it":{"name":"Richiede Palestra"},"en":{"name":"Gym Required"}}');
SELECT exercises._upsert_tag('barbell_tag',     'equipment', '{"it":{"name":"Con Bilanciere"},"en":{"name":"Barbell"}}');
SELECT exercises._upsert_tag('dumbbell_tag',    'equipment', '{"it":{"name":"Con Manubri"},"en":{"name":"Dumbbell"}}');
SELECT exercises._upsert_tag('cable_tag',       'equipment', '{"it":{"name":"Cavo"},"en":{"name":"Cable"}}');
SELECT exercises._upsert_tag('machine_tag',     'equipment', '{"it":{"name":"Macchina"},"en":{"name":"Machine"}}');
SELECT exercises._upsert_tag('kettlebell_tag',  'equipment', '{"it":{"name":"Kettlebell"},"en":{"name":"Kettlebell"}}');
SELECT exercises._upsert_tag('band_tag',        'equipment', '{"it":{"name":"Con Elastico"},"en":{"name":"Band"}}');
SELECT exercises._upsert_tag('rings_tag',       'equipment', '{"it":{"name":"Agli Anelli"},"en":{"name":"Rings"}}');

-- ── SAFETY / RISK ─────────────────────────────────────────────
SELECT exercises._upsert_tag('spotter_needed',   'safety', '{"it":{"name":"Richiede Spotter"},"en":{"name":"Spotter Required"}}');
SELECT exercises._upsert_tag('high_risk',        'safety', '{"it":{"name":"Alto Rischio"},"en":{"name":"High Risk"}}');
SELECT exercises._upsert_tag('beginner_safe',    'safety', '{"it":{"name":"Sicuro per Principianti"},"en":{"name":"Beginner Safe"}}');
SELECT exercises._upsert_tag('advanced_only',    'safety', '{"it":{"name":"Solo Avanzati"},"en":{"name":"Advanced Only"}}');
SELECT exercises._upsert_tag('low_back_risk',    'safety', '{"it":{"name":"Rischio Schiena"},"en":{"name":"Lower Back Risk"}}');
SELECT exercises._upsert_tag('shoulder_risk',    'safety', '{"it":{"name":"Rischio Spalla"},"en":{"name":"Shoulder Risk"}}');
SELECT exercises._upsert_tag('knee_risk',        'safety', '{"it":{"name":"Rischio Ginocchio"},"en":{"name":"Knee Risk"}}');

-- ── TEMPO / STYLE ─────────────────────────────────────────────
SELECT exercises._upsert_tag('pause_rep',      'style', '{"it":{"name":"Ripetizione con Pausa"},"en":{"name":"Pause Rep"}}');
SELECT exercises._upsert_tag('tempo_training', 'style', '{"it":{"name":"Allenamento Tempo"},"en":{"name":"Tempo Training"}}');
SELECT exercises._upsert_tag('max_effort',     'style', '{"it":{"name":"Massimo Sforzo"},"en":{"name":"Max Effort"}}');
SELECT exercises._upsert_tag('dynamic_effort', 'style', '{"it":{"name":"Sforzo Dinamico"},"en":{"name":"Dynamic Effort"}}');
SELECT exercises._upsert_tag('time_under_tension','style','{"it":{"name":"Tempo sotto Tensione"},"en":{"name":"Time Under Tension"}}');
SELECT exercises._upsert_tag('amrap',          'style', '{"it":{"name":"AMRAP"},"en":{"name":"As Many Reps As Possible"}}');
SELECT exercises._upsert_tag('emom',           'style', '{"it":{"name":"EMOM"},"en":{"name":"Every Minute on the Minute"}}');
SELECT exercises._upsert_tag('for_time',       'style', '{"it":{"name":"A Tempo"},"en":{"name":"For Time"}}');

-- ── SPORT ─────────────────────────────────────────────────────
SELECT exercises._upsert_tag('powerlifting_comp',  'sport', '{"it":{"name":"Gara Powerlifting"},"en":{"name":"Powerlifting Competition"}}');
SELECT exercises._upsert_tag('olympic_lift',       'sport', '{"it":{"name":"Sollevamento Olimpico"},"en":{"name":"Olympic Lift"}}');
SELECT exercises._upsert_tag('strongman_event',    'sport', '{"it":{"name":"Evento Strongman"},"en":{"name":"Strongman Event"}}');
SELECT exercises._upsert_tag('crossfit_movement',  'sport', '{"it":{"name":"Movimento CrossFit"},"en":{"name":"CrossFit Movement"}}');
SELECT exercises._upsert_tag('calisthenics_skill', 'sport', '{"it":{"name":"Skill Calisthenics"},"en":{"name":"Calisthenics Skill"}}');
SELECT exercises._upsert_tag('yoga_pose',          'sport', '{"it":{"name":"Postura Yoga"},"en":{"name":"Yoga Pose"}}');
SELECT exercises._upsert_tag('pilates_exercise',   'sport', '{"it":{"name":"Esercizio Pilates"},"en":{"name":"Pilates Exercise"}}');
SELECT exercises._upsert_tag('martial_arts_cond',  'sport', '{"it":{"name":"Condizionamento Arti Marziali"},"en":{"name":"Martial Arts Conditioning"}}');
SELECT exercises._upsert_tag('boxing_cond',        'sport', '{"it":{"name":"Condizionamento Boxe"},"en":{"name":"Boxing Conditioning"}}');
SELECT exercises._upsert_tag('physiotherapy',      'sport', '{"it":{"name":"Fisioterapia"},"en":{"name":"Physiotherapy"}}');

DROP FUNCTION IF EXISTS exercises._upsert_tag(VARCHAR, VARCHAR, JSONB);
