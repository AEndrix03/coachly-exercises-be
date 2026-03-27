-- =============================================================
-- REFERENCE DATA: Categories (Disciplines)
-- Schema: exercises
-- Run BEFORE exercise SQL files
-- =============================================================

CREATE OR REPLACE FUNCTION exercises._upsert_category(
    p_code VARCHAR, p_order INT, p_translations JSONB
) RETURNS VOID AS $$
BEGIN
    INSERT INTO exercises.category (id, code, display_order, status, translations, created_at, updated_at)
    VALUES (gen_random_uuid(), p_code, p_order, 'active', p_translations, NOW(), NOW())
    ON CONFLICT (code) DO NOTHING;
END;
$$ LANGUAGE plpgsql;

SELECT exercises._upsert_category('bodybuilding',          1,  '{"it":{"name":"Bodybuilding","description":"Allenamento per l ipertrofia muscolare e la definizione estetica"},"en":{"name":"Bodybuilding","description":"Training focused on muscle hypertrophy and aesthetic development"}}');
SELECT exercises._upsert_category('powerlifting',          2,  '{"it":{"name":"Powerlifting","description":"Sport di forza basato su squat, panca piana e stacco da terra"},"en":{"name":"Powerlifting","description":"Strength sport based on squat, bench press and deadlift"}}');
SELECT exercises._upsert_category('olympic_weightlifting', 3,  '{"it":{"name":"Sollevamento Pesi Olimpico","description":"Sport olimpico con strappo e slancio"},"en":{"name":"Olympic Weightlifting","description":"Olympic sport featuring the snatch and clean and jerk"}}');
SELECT exercises._upsert_category('strongman',             4,  '{"it":{"name":"Strongman","description":"Competizioni di forza estrema con eventi variati"},"en":{"name":"Strongman","description":"Extreme strength competitions with varied events"}}');
SELECT exercises._upsert_category('crossfit',              5,  '{"it":{"name":"CrossFit","description":"Allenamento funzionale ad alta intensità con movimenti variati"},"en":{"name":"CrossFit","description":"High-intensity functional training with varied movements"}}');
SELECT exercises._upsert_category('functional_training',   6,  '{"it":{"name":"Allenamento Funzionale","description":"Movimenti che migliorano le capacità motorie quotidiane"},"en":{"name":"Functional Training","description":"Movements that improve everyday motor capabilities"}}');
SELECT exercises._upsert_category('hiit',                  7,  '{"it":{"name":"HIIT","description":"Allenamento a intervalli ad alta intensità"},"en":{"name":"HIIT","description":"High-Intensity Interval Training"}}');
SELECT exercises._upsert_category('calisthenics',          8,  '{"it":{"name":"Calisthenics","description":"Allenamento a corpo libero con progressioni di forza"},"en":{"name":"Calisthenics","description":"Bodyweight training with strength progressions"}}');
SELECT exercises._upsert_category('gymnastics',            9,  '{"it":{"name":"Ginnastica Artistica","description":"Ginnastica artistica e movimenti di potenza su attrezzi"},"en":{"name":"Gymnastics","description":"Artistic gymnastics and power movements on apparatus"}}');
SELECT exercises._upsert_category('home_workout',          10, '{"it":{"name":"Allenamento a Casa","description":"Esercizi eseguibili a casa con attrezzatura minima o nulla"},"en":{"name":"Home Workout","description":"Exercises doable at home with minimal or no equipment"}}');
SELECT exercises._upsert_category('yoga',                  11, '{"it":{"name":"Yoga","description":"Pratica di posture, respirazione e meditazione"},"en":{"name":"Yoga","description":"Practice of postures, breathing and meditation"}}');
SELECT exercises._upsert_category('pilates',               12, '{"it":{"name":"Pilates","description":"Metodo di allenamento focalizzato sul controllo del core"},"en":{"name":"Pilates","description":"Training method focused on core control and postural alignment"}}');
SELECT exercises._upsert_category('cardio',                13, '{"it":{"name":"Cardio / Aerobico","description":"Allenamento cardiovascolare e aerobico"},"en":{"name":"Cardio / Aerobic","description":"Cardiovascular and aerobic training"}}');
SELECT exercises._upsert_category('kettlebell',            14, '{"it":{"name":"Kettlebell","description":"Allenamento con kettlebell balistici e di forza"},"en":{"name":"Kettlebell","description":"Ballistic and strength training with kettlebells"}}');
SELECT exercises._upsert_category('resistance_bands',      15, '{"it":{"name":"Elastici / Resistance Bands","description":"Allenamento con bande elastiche di resistenza"},"en":{"name":"Resistance Bands","description":"Training with elastic resistance bands"}}');
SELECT exercises._upsert_category('trx',                   16, '{"it":{"name":"TRX / Suspension Training","description":"Allenamento in sospensione con cinghie TRX"},"en":{"name":"TRX / Suspension Training","description":"Suspension training using TRX straps"}}');
SELECT exercises._upsert_category('stretching',            17, '{"it":{"name":"Stretching","description":"Esercizi di allungamento muscolare statico e dinamico"},"en":{"name":"Stretching","description":"Static and dynamic muscle lengthening exercises"}}');
SELECT exercises._upsert_category('mobility',              18, '{"it":{"name":"Mobilita Articolare","description":"Esercizi per migliorare il range of motion articolare"},"en":{"name":"Mobility","description":"Exercises to improve joint range of motion"}}');
SELECT exercises._upsert_category('foam_rolling',          19, '{"it":{"name":"Foam Rolling","description":"Tecniche di rilascio miofasciale con rullo e palla"},"en":{"name":"Foam Rolling","description":"Myofascial release techniques with roller and ball"}}');
SELECT exercises._upsert_category('warm_up',               20, '{"it":{"name":"Riscaldamento","description":"Esercizi di attivazione e preparazione pre-allenamento"},"en":{"name":"Warm Up","description":"Pre-workout activation and preparation exercises"}}');
SELECT exercises._upsert_category('core_training',         21, '{"it":{"name":"Core Training","description":"Allenamento specifico per la stabilita e forza del core"},"en":{"name":"Core Training","description":"Specific training for core stability and strength"}}');
SELECT exercises._upsert_category('boxing',                22, '{"it":{"name":"Pugilato / Boxe","description":"Allenamento condizionamento boxe e shadow boxing"},"en":{"name":"Boxing","description":"Boxing conditioning and shadow boxing training"}}');
SELECT exercises._upsert_category('martial_arts',          23, '{"it":{"name":"Arti Marziali / MMA","description":"Condizionamento per arti marziali e MMA"},"en":{"name":"Martial Arts / MMA","description":"Conditioning for martial arts and MMA"}}');
SELECT exercises._upsert_category('rehabilitation',        24, '{"it":{"name":"Riabilitazione","description":"Esercizi terapeutici e di recupero post-infortunio"},"en":{"name":"Rehabilitation","description":"Therapeutic and post-injury recovery exercises"}}');
SELECT exercises._upsert_category('balance_stability',     25, '{"it":{"name":"Equilibrio e Stabilita","description":"Allenamento per equilibrio e propriocezione"},"en":{"name":"Balance and Stability","description":"Training for balance and proprioception"}}');
SELECT exercises._upsert_category('sport_specific',        26, '{"it":{"name":"Preparazione Atletica Specifica","description":"Esercizi di condizionamento per sport specifici"},"en":{"name":"Sport-Specific Training","description":"Conditioning exercises for specific sports"}}');

DROP FUNCTION IF EXISTS exercises._upsert_category(VARCHAR, INT, JSONB);
