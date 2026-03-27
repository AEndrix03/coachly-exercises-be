-- =============================================================
-- REFERENCE DATA: Muscles
-- Schema: exercises
-- Run this BEFORE any exercise SQL files
-- =============================================================

-- Helper: insert muscle only if code not already present
CREATE OR REPLACE FUNCTION exercises._upsert_muscle(
    p_code VARCHAR, p_group_code VARCHAR, p_translations JSONB
) RETURNS VOID AS $$
BEGIN
    INSERT INTO exercises.muscle (id, code, group_code, status, translations, created_at, updated_at)
    VALUES (gen_random_uuid(), p_code, p_group_code, 'active', p_translations, NOW(), NOW())
    ON CONFLICT (code) DO NOTHING;
END;
$$ LANGUAGE plpgsql;

-- ── CHEST ─────────────────────────────────────────────────────
SELECT exercises._upsert_muscle('pec_major_upper',  'chest', '{"it":{"name":"Pettorale Maggiore - Superiore (Capo Clavicolare)"},"en":{"name":"Pectoralis Major - Upper (Clavicular Head)"}}');
SELECT exercises._upsert_muscle('pec_major_mid',    'chest', '{"it":{"name":"Pettorale Maggiore - Medio (Capo Sternale)"},"en":{"name":"Pectoralis Major - Mid (Sternal Head)"}}');
SELECT exercises._upsert_muscle('pec_major_lower',  'chest', '{"it":{"name":"Pettorale Maggiore - Inferiore (Capo Costale)"},"en":{"name":"Pectoralis Major - Lower (Costal Head)"}}');
SELECT exercises._upsert_muscle('pec_minor',        'chest', '{"it":{"name":"Pettorale Minore"},"en":{"name":"Pectoralis Minor"}}');
SELECT exercises._upsert_muscle('serratus_anterior','chest', '{"it":{"name":"Dentato Anteriore"},"en":{"name":"Serratus Anterior"}}');

-- ── BACK ──────────────────────────────────────────────────────
SELECT exercises._upsert_muscle('lat_dorsi',           'back', '{"it":{"name":"Gran Dorsale"},"en":{"name":"Latissimus Dorsi"}}');
SELECT exercises._upsert_muscle('trap_upper',          'back', '{"it":{"name":"Trapezio - Superiore"},"en":{"name":"Trapezius - Upper"}}');
SELECT exercises._upsert_muscle('trap_mid',            'back', '{"it":{"name":"Trapezio - Medio"},"en":{"name":"Trapezius - Middle"}}');
SELECT exercises._upsert_muscle('trap_lower',          'back', '{"it":{"name":"Trapezio - Inferiore"},"en":{"name":"Trapezius - Lower"}}');
SELECT exercises._upsert_muscle('rhomboid_major',      'back', '{"it":{"name":"Romboide Maggiore"},"en":{"name":"Rhomboid Major"}}');
SELECT exercises._upsert_muscle('rhomboid_minor',      'back', '{"it":{"name":"Romboide Minore"},"en":{"name":"Rhomboid Minor"}}');
SELECT exercises._upsert_muscle('teres_major',         'back', '{"it":{"name":"Teres Maggiore"},"en":{"name":"Teres Major"}}');
SELECT exercises._upsert_muscle('erector_spinae',      'back', '{"it":{"name":"Erettori della Colonna (Ileo-costale, Lunghissimo, Spinale)"},"en":{"name":"Erector Spinae (Iliocostalis, Longissimus, Spinalis)"}}');
SELECT exercises._upsert_muscle('multifidus',          'back', '{"it":{"name":"Multifido"},"en":{"name":"Multifidus"}}');
SELECT exercises._upsert_muscle('quadratus_lumborum',  'back', '{"it":{"name":"Quadrato dei Lombi"},"en":{"name":"Quadratus Lumborum"}}');
SELECT exercises._upsert_muscle('levator_scapulae',    'back', '{"it":{"name":"Elevatore della Scapola"},"en":{"name":"Levator Scapulae"}}');

-- ── SHOULDERS ─────────────────────────────────────────────────
SELECT exercises._upsert_muscle('deltoid_anterior',  'shoulders', '{"it":{"name":"Deltoide Anteriore"},"en":{"name":"Deltoid - Anterior"}}');
SELECT exercises._upsert_muscle('deltoid_lateral',   'shoulders', '{"it":{"name":"Deltoide Laterale"},"en":{"name":"Deltoid - Lateral"}}');
SELECT exercises._upsert_muscle('deltoid_posterior', 'shoulders', '{"it":{"name":"Deltoide Posteriore"},"en":{"name":"Deltoid - Posterior"}}');
SELECT exercises._upsert_muscle('supraspinatus',     'shoulders', '{"it":{"name":"Sopraspinoso"},"en":{"name":"Supraspinatus"}}');
SELECT exercises._upsert_muscle('infraspinatus',     'shoulders', '{"it":{"name":"Infraspinoso"},"en":{"name":"Infraspinatus"}}');
SELECT exercises._upsert_muscle('teres_minor',       'shoulders', '{"it":{"name":"Teres Minore"},"en":{"name":"Teres Minor"}}');
SELECT exercises._upsert_muscle('subscapularis',     'shoulders', '{"it":{"name":"Sottoscapolare"},"en":{"name":"Subscapularis"}}');

-- ── BICEPS ────────────────────────────────────────────────────
SELECT exercises._upsert_muscle('biceps_long_head',    'biceps', '{"it":{"name":"Bicipite Brachiale - Capo Lungo"},"en":{"name":"Biceps Brachii - Long Head"}}');
SELECT exercises._upsert_muscle('biceps_short_head',   'biceps', '{"it":{"name":"Bicipite Brachiale - Capo Corto"},"en":{"name":"Biceps Brachii - Short Head"}}');
SELECT exercises._upsert_muscle('brachialis',          'biceps', '{"it":{"name":"Brachiale"},"en":{"name":"Brachialis"}}');
SELECT exercises._upsert_muscle('brachioradialis',     'biceps', '{"it":{"name":"Brachioradiale"},"en":{"name":"Brachioradialis"}}');
SELECT exercises._upsert_muscle('coracobrachialis',    'biceps', '{"it":{"name":"Coracobrachiale"},"en":{"name":"Coracobrachialis"}}');

-- ── TRICEPS ───────────────────────────────────────────────────
SELECT exercises._upsert_muscle('triceps_long_head',    'triceps', '{"it":{"name":"Tricipite Brachiale - Capo Lungo"},"en":{"name":"Triceps Brachii - Long Head"}}');
SELECT exercises._upsert_muscle('triceps_lateral_head', 'triceps', '{"it":{"name":"Tricipite Brachiale - Capo Laterale"},"en":{"name":"Triceps Brachii - Lateral Head"}}');
SELECT exercises._upsert_muscle('triceps_medial_head',  'triceps', '{"it":{"name":"Tricipite Brachiale - Capo Mediale"},"en":{"name":"Triceps Brachii - Medial Head"}}');
SELECT exercises._upsert_muscle('anconeus',             'triceps', '{"it":{"name":"Anconeo"},"en":{"name":"Anconeus"}}');

-- ── FOREARMS ──────────────────────────────────────────────────
SELECT exercises._upsert_muscle('flexor_carpi_radialis',        'forearms', '{"it":{"name":"Flessore Radiale del Carpo"},"en":{"name":"Flexor Carpi Radialis"}}');
SELECT exercises._upsert_muscle('flexor_carpi_ulnaris',         'forearms', '{"it":{"name":"Flessore Ulnare del Carpo"},"en":{"name":"Flexor Carpi Ulnaris"}}');
SELECT exercises._upsert_muscle('extensor_carpi_radialis_long', 'forearms', '{"it":{"name":"Estensore Radiale Lungo del Carpo"},"en":{"name":"Extensor Carpi Radialis Longus"}}');
SELECT exercises._upsert_muscle('extensor_carpi_radialis_brev', 'forearms', '{"it":{"name":"Estensore Radiale Breve del Carpo"},"en":{"name":"Extensor Carpi Radialis Brevis"}}');
SELECT exercises._upsert_muscle('extensor_carpi_ulnaris',       'forearms', '{"it":{"name":"Estensore Ulnare del Carpo"},"en":{"name":"Extensor Carpi Ulnaris"}}');
SELECT exercises._upsert_muscle('pronator_teres',               'forearms', '{"it":{"name":"Pronatore Rotondo"},"en":{"name":"Pronator Teres"}}');
SELECT exercises._upsert_muscle('supinator',                    'forearms', '{"it":{"name":"Supinatore"},"en":{"name":"Supinator"}}');
SELECT exercises._upsert_muscle('flexor_digitorum_superfic',    'forearms', '{"it":{"name":"Flessore Superficiale delle Dita"},"en":{"name":"Flexor Digitorum Superficialis"}}');
SELECT exercises._upsert_muscle('extensor_digitorum',           'forearms', '{"it":{"name":"Estensore delle Dita"},"en":{"name":"Extensor Digitorum"}}');

-- ── CORE ──────────────────────────────────────────────────────
SELECT exercises._upsert_muscle('rectus_abdominis',  'core', '{"it":{"name":"Retto dell Addome"},"en":{"name":"Rectus Abdominis"}}');
SELECT exercises._upsert_muscle('external_oblique',  'core', '{"it":{"name":"Obliquo Esterno"},"en":{"name":"External Oblique"}}');
SELECT exercises._upsert_muscle('internal_oblique',  'core', '{"it":{"name":"Obliquo Interno"},"en":{"name":"Internal Oblique"}}');
SELECT exercises._upsert_muscle('transversus_abdom', 'core', '{"it":{"name":"Trasverso dell Addome"},"en":{"name":"Transversus Abdominis"}}');
SELECT exercises._upsert_muscle('diaphragm',         'core', '{"it":{"name":"Diaframma"},"en":{"name":"Diaphragm"}}');
SELECT exercises._upsert_muscle('pelvic_floor',      'core', '{"it":{"name":"Pavimento Pelvico"},"en":{"name":"Pelvic Floor"}}');

-- ── QUADRICEPS ────────────────────────────────────────────────
SELECT exercises._upsert_muscle('rectus_femoris',    'quads', '{"it":{"name":"Retto Femorale"},"en":{"name":"Rectus Femoris"}}');
SELECT exercises._upsert_muscle('vastus_lateralis',  'quads', '{"it":{"name":"Vasto Laterale"},"en":{"name":"Vastus Lateralis"}}');
SELECT exercises._upsert_muscle('vastus_medialis',   'quads', '{"it":{"name":"Vasto Mediale"},"en":{"name":"Vastus Medialis"}}');
SELECT exercises._upsert_muscle('vastus_intermedius','quads', '{"it":{"name":"Vasto Intermedio"},"en":{"name":"Vastus Intermedius"}}');
SELECT exercises._upsert_muscle('tensor_fasciae_lat','quads', '{"it":{"name":"Tensore della Fascia Lata"},"en":{"name":"Tensor Fasciae Latae"}}');

-- ── HAMSTRINGS ────────────────────────────────────────────────
SELECT exercises._upsert_muscle('biceps_femoris_long', 'hamstrings', '{"it":{"name":"Bicipite Femorale - Capo Lungo"},"en":{"name":"Biceps Femoris - Long Head"}}');
SELECT exercises._upsert_muscle('biceps_femoris_short','hamstrings', '{"it":{"name":"Bicipite Femorale - Capo Corto"},"en":{"name":"Biceps Femoris - Short Head"}}');
SELECT exercises._upsert_muscle('semitendinosus',      'hamstrings', '{"it":{"name":"Semitendinoso"},"en":{"name":"Semitendinosus"}}');
SELECT exercises._upsert_muscle('semimembranosus',     'hamstrings', '{"it":{"name":"Semimembranoso"},"en":{"name":"Semimembranosus"}}');

-- ── GLUTES ────────────────────────────────────────────────────
SELECT exercises._upsert_muscle('gluteus_maximus',  'glutes', '{"it":{"name":"Grande Gluteo"},"en":{"name":"Gluteus Maximus"}}');
SELECT exercises._upsert_muscle('gluteus_medius',   'glutes', '{"it":{"name":"Medio Gluteo"},"en":{"name":"Gluteus Medius"}}');
SELECT exercises._upsert_muscle('gluteus_minimus',  'glutes', '{"it":{"name":"Piccolo Gluteo"},"en":{"name":"Gluteus Minimus"}}');
SELECT exercises._upsert_muscle('piriformis',       'glutes', '{"it":{"name":"Piriforme"},"en":{"name":"Piriformis"}}');
SELECT exercises._upsert_muscle('obturator_internus','glutes','{"it":{"name":"Otturatore Interno"},"en":{"name":"Obturator Internus"}}');
SELECT exercises._upsert_muscle('gemellus_superior','glutes', '{"it":{"name":"Gemello Superiore"},"en":{"name":"Gemellus Superior"}}');
SELECT exercises._upsert_muscle('gemellus_inferior','glutes', '{"it":{"name":"Gemello Inferiore"},"en":{"name":"Gemellus Inferior"}}');

-- ── CALVES ────────────────────────────────────────────────────
SELECT exercises._upsert_muscle('gastrocnemius_medial', 'calves', '{"it":{"name":"Gastrocnemio - Capo Mediale"},"en":{"name":"Gastrocnemius - Medial Head"}}');
SELECT exercises._upsert_muscle('gastrocnemius_lateral','calves', '{"it":{"name":"Gastrocnemio - Capo Laterale"},"en":{"name":"Gastrocnemius - Lateral Head"}}');
SELECT exercises._upsert_muscle('soleus',               'calves', '{"it":{"name":"Soleo"},"en":{"name":"Soleus"}}');
SELECT exercises._upsert_muscle('tibialis_anterior',    'calves', '{"it":{"name":"Tibiale Anteriore"},"en":{"name":"Tibialis Anterior"}}');
SELECT exercises._upsert_muscle('tibialis_posterior',   'calves', '{"it":{"name":"Tibiale Posteriore"},"en":{"name":"Tibialis Posterior"}}');
SELECT exercises._upsert_muscle('fibularis_longus',     'calves', '{"it":{"name":"Fibulare Lungo (Peroniero Lungo)"},"en":{"name":"Fibularis (Peroneus) Longus"}}');
SELECT exercises._upsert_muscle('fibularis_brevis',     'calves', '{"it":{"name":"Fibulare Breve (Peroniero Breve)"},"en":{"name":"Fibularis (Peroneus) Brevis"}}');
SELECT exercises._upsert_muscle('flexor_hallucis_long', 'calves', '{"it":{"name":"Flessore Lungo dell Alluce"},"en":{"name":"Flexor Hallucis Longus"}}');

-- ── ADDUCTORS ─────────────────────────────────────────────────
SELECT exercises._upsert_muscle('adductor_longus', 'adductors', '{"it":{"name":"Adduttore Lungo"},"en":{"name":"Adductor Longus"}}');
SELECT exercises._upsert_muscle('adductor_brevis', 'adductors', '{"it":{"name":"Adduttore Breve"},"en":{"name":"Adductor Brevis"}}');
SELECT exercises._upsert_muscle('adductor_magnus', 'adductors', '{"it":{"name":"Grande Adduttore"},"en":{"name":"Adductor Magnus"}}');
SELECT exercises._upsert_muscle('gracilis',        'adductors', '{"it":{"name":"Gracile"},"en":{"name":"Gracilis"}}');
SELECT exercises._upsert_muscle('pectineus',       'adductors', '{"it":{"name":"Pettineo"},"en":{"name":"Pectineus"}}');

-- ── HIP FLEXORS ───────────────────────────────────────────────
SELECT exercises._upsert_muscle('psoas_major', 'hip_flexors', '{"it":{"name":"Psoas Maggiore"},"en":{"name":"Psoas Major"}}');
SELECT exercises._upsert_muscle('iliacus',     'hip_flexors', '{"it":{"name":"Iliaco"},"en":{"name":"Iliacus"}}');
SELECT exercises._upsert_muscle('sartorius',   'hip_flexors', '{"it":{"name":"Sartorio"},"en":{"name":"Sartorius"}}');

-- ── NECK ──────────────────────────────────────────────────────
SELECT exercises._upsert_muscle('sternocleidomastoid', 'neck', '{"it":{"name":"Sternocleidomastoideo"},"en":{"name":"Sternocleidomastoid"}}');
SELECT exercises._upsert_muscle('splenius_capitis',    'neck', '{"it":{"name":"Splenio della Testa"},"en":{"name":"Splenius Capitis"}}');
SELECT exercises._upsert_muscle('splenius_cervicis',   'neck', '{"it":{"name":"Splenio del Collo"},"en":{"name":"Splenius Cervicis"}}');
SELECT exercises._upsert_muscle('scalene_anterior',    'neck', '{"it":{"name":"Scaleno Anteriore"},"en":{"name":"Scalene Anterior"}}');
SELECT exercises._upsert_muscle('scalene_mid',         'neck', '{"it":{"name":"Scaleno Medio"},"en":{"name":"Scalene Middle"}}');
SELECT exercises._upsert_muscle('scalene_posterior',   'neck', '{"it":{"name":"Scaleno Posteriore"},"en":{"name":"Scalene Posterior"}}');

-- ── THORACIC (Mobility) ───────────────────────────────────────
SELECT exercises._upsert_muscle('thoracic_erector',       'thoracic', '{"it":{"name":"Erettori Toracici"},"en":{"name":"Thoracic Erector Spinae"}}');
SELECT exercises._upsert_muscle('multifidus_thoracic',    'thoracic', '{"it":{"name":"Multifido Toracico"},"en":{"name":"Multifidus (Thoracic)"}}');
SELECT exercises._upsert_muscle('intercostals_internal',  'thoracic', '{"it":{"name":"Intercostali Interni"},"en":{"name":"Intercostals - Internal"}}');
SELECT exercises._upsert_muscle('intercostals_external',  'thoracic', '{"it":{"name":"Intercostali Esterni"},"en":{"name":"Intercostals - External"}}');

DROP FUNCTION IF EXISTS exercises._upsert_muscle(VARCHAR, VARCHAR, JSONB);
