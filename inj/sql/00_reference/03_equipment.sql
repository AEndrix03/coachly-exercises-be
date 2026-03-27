-- =============================================================
-- REFERENCE DATA: Equipment
-- Schema: exercises
-- Run BEFORE exercise SQL files
-- =============================================================

CREATE OR REPLACE FUNCTION exercises._upsert_equipment(
    p_code VARCHAR, p_category VARCHAR, p_translations JSONB
) RETURNS VOID AS $$
BEGIN
    INSERT INTO exercises.equipment (id, code, category, status, translations, created_at, updated_at)
    VALUES (gen_random_uuid(), p_code, p_category, 'active', p_translations, NOW(), NOW())
    ON CONFLICT (code) DO NOTHING;
END;
$$ LANGUAGE plpgsql;

-- ── BARBELL ───────────────────────────────────────────────────
SELECT exercises._upsert_equipment('barbell',          'barbell', '{"it":{"name":"Bilanciere"},"en":{"name":"Barbell"}}');
SELECT exercises._upsert_equipment('ez_bar',           'barbell', '{"it":{"name":"Bilanciere EZ (Curl Bar)"},"en":{"name":"EZ Bar (Curl Bar)"}}');
SELECT exercises._upsert_equipment('axle_bar',         'barbell', '{"it":{"name":"Bilanciere Axle (Strongman)"},"en":{"name":"Axle Bar (Strongman)"}}');
SELECT exercises._upsert_equipment('log_bar',          'barbell', '{"it":{"name":"Log Bar (Strongman)"},"en":{"name":"Log Bar (Strongman)"}}');
SELECT exercises._upsert_equipment('safety_squat_bar', 'barbell', '{"it":{"name":"Safety Squat Bar (SSB)"},"en":{"name":"Safety Squat Bar (SSB)"}}');
SELECT exercises._upsert_equipment('cambered_bar',     'barbell', '{"it":{"name":"Cambered Bar"},"en":{"name":"Cambered Bar"}}');
SELECT exercises._upsert_equipment('trap_bar',         'barbell', '{"it":{"name":"Trap Bar / Hex Bar"},"en":{"name":"Trap Bar / Hex Bar"}}');

-- ── DUMBBELLS ─────────────────────────────────────────────────
SELECT exercises._upsert_equipment('dumbbell', 'dumbbell', '{"it":{"name":"Manubri"},"en":{"name":"Dumbbell"}}');

-- ── KETTLEBELL ────────────────────────────────────────────────
SELECT exercises._upsert_equipment('kettlebell', 'kettlebell', '{"it":{"name":"Kettlebell"},"en":{"name":"Kettlebell"}}');

-- ── BENCHES ───────────────────────────────────────────────────
SELECT exercises._upsert_equipment('flat_bench',       'bench', '{"it":{"name":"Panca Piana"},"en":{"name":"Flat Bench"}}');
SELECT exercises._upsert_equipment('incline_bench',    'bench', '{"it":{"name":"Panca Inclinata"},"en":{"name":"Incline Bench"}}');
SELECT exercises._upsert_equipment('decline_bench',    'bench', '{"it":{"name":"Panca Declinata"},"en":{"name":"Decline Bench"}}');
SELECT exercises._upsert_equipment('adjustable_bench', 'bench', '{"it":{"name":"Panca Regolabile"},"en":{"name":"Adjustable Bench"}}');
SELECT exercises._upsert_equipment('preacher_bench',   'bench', '{"it":{"name":"Panca per Curl (Preacher)"},"en":{"name":"Preacher Bench"}}');

-- ── RACKS / PULL-UP STRUCTURES ────────────────────────────────
SELECT exercises._upsert_equipment('power_rack',     'rack', '{"it":{"name":"Power Rack / Cage"},"en":{"name":"Power Rack / Cage"}}');
SELECT exercises._upsert_equipment('squat_rack',     'rack', '{"it":{"name":"Squat Rack / Half Rack"},"en":{"name":"Squat Rack / Half Rack"}}');
SELECT exercises._upsert_equipment('pull_up_bar',    'rack', '{"it":{"name":"Sbarra Trazioni"},"en":{"name":"Pull-Up Bar"}}');
SELECT exercises._upsert_equipment('dip_bars',       'rack', '{"it":{"name":"Parallele per Dip"},"en":{"name":"Dip Bars / Parallel Bars"}}');
SELECT exercises._upsert_equipment('gymnastic_rings','rack', '{"it":{"name":"Anelli Ginnastici"},"en":{"name":"Gymnastic Rings"}}');
SELECT exercises._upsert_equipment('landmine',       'rack', '{"it":{"name":"Landmine (Barra Incastrata)"},"en":{"name":"Landmine Attachment"}}');

-- ── MACHINES ──────────────────────────────────────────────────
SELECT exercises._upsert_equipment('cable_machine',         'machine', '{"it":{"name":"Cavo / Pulley"},"en":{"name":"Cable Machine"}}');
SELECT exercises._upsert_equipment('smith_machine',         'machine', '{"it":{"name":"Smith Machine"},"en":{"name":"Smith Machine"}}');
SELECT exercises._upsert_equipment('leg_press_machine',     'machine', '{"it":{"name":"Leg Press"},"en":{"name":"Leg Press Machine"}}');
SELECT exercises._upsert_equipment('lat_pulldown_machine',  'machine', '{"it":{"name":"Lat Machine / Pulldown"},"en":{"name":"Lat Pulldown Machine"}}');
SELECT exercises._upsert_equipment('seated_row_machine',    'machine', '{"it":{"name":"Rematore Seduto (Macchina)"},"en":{"name":"Seated Row Machine"}}');
SELECT exercises._upsert_equipment('chest_press_machine',   'machine', '{"it":{"name":"Chest Press (Macchina)"},"en":{"name":"Chest Press Machine"}}');
SELECT exercises._upsert_equipment('shoulder_press_machine','machine', '{"it":{"name":"Shoulder Press (Macchina)"},"en":{"name":"Shoulder Press Machine"}}');
SELECT exercises._upsert_equipment('leg_extension_machine', 'machine', '{"it":{"name":"Leg Extension"},"en":{"name":"Leg Extension Machine"}}');
SELECT exercises._upsert_equipment('leg_curl_machine',      'machine', '{"it":{"name":"Leg Curl"},"en":{"name":"Leg Curl Machine"}}');
SELECT exercises._upsert_equipment('calf_raise_machine',    'machine', '{"it":{"name":"Calf Raise (Macchina)"},"en":{"name":"Calf Raise Machine"}}');
SELECT exercises._upsert_equipment('pec_deck_machine',      'machine', '{"it":{"name":"Pec Deck / Butterfly"},"en":{"name":"Pec Deck Machine"}}');
SELECT exercises._upsert_equipment('adductor_machine',      'machine', '{"it":{"name":"Adduttori (Macchina)"},"en":{"name":"Adductor Machine"}}');
SELECT exercises._upsert_equipment('abductor_machine',      'machine', '{"it":{"name":"Abduttori (Macchina)"},"en":{"name":"Abductor Machine"}}');
SELECT exercises._upsert_equipment('glute_kickback_machine','machine', '{"it":{"name":"Kickback Glutei (Macchina)"},"en":{"name":"Glute Kickback Machine"}}');
SELECT exercises._upsert_equipment('neck_machine',          'machine', '{"it":{"name":"Macchina per il Collo"},"en":{"name":"4-Way Neck Machine"}}');
SELECT exercises._upsert_equipment('ghd_machine',           'machine', '{"it":{"name":"GHD (Glute Ham Developer)"},"en":{"name":"GHD (Glute Ham Developer)"}}');
SELECT exercises._upsert_equipment('reverse_hyper_machine', 'machine', '{"it":{"name":"Reverse Hyperextension"},"en":{"name":"Reverse Hyperextension Machine"}}');
SELECT exercises._upsert_equipment('hack_squat_machine',    'machine', '{"it":{"name":"Hack Squat (Macchina)"},"en":{"name":"Hack Squat Machine"}}');
SELECT exercises._upsert_equipment('ab_crunch_machine',     'machine', '{"it":{"name":"Crunch (Macchina)"},"en":{"name":"Ab Crunch Machine"}}');

-- ── CARDIO ────────────────────────────────────────────────────
SELECT exercises._upsert_equipment('treadmill',       'cardio', '{"it":{"name":"Tapis Roulant"},"en":{"name":"Treadmill"}}');
SELECT exercises._upsert_equipment('stationary_bike', 'cardio', '{"it":{"name":"Cyclette / Bici Stazionaria"},"en":{"name":"Stationary Bike"}}');
SELECT exercises._upsert_equipment('rowing_machine',  'cardio', '{"it":{"name":"Vogatore"},"en":{"name":"Rowing Machine"}}');
SELECT exercises._upsert_equipment('assault_bike',    'cardio', '{"it":{"name":"Assault Bike / Air Bike"},"en":{"name":"Assault Bike / Air Bike"}}');
SELECT exercises._upsert_equipment('ski_erg',         'cardio', '{"it":{"name":"Ski Erg"},"en":{"name":"Ski Erg"}}');
SELECT exercises._upsert_equipment('jump_rope',       'cardio', '{"it":{"name":"Corda per Saltare"},"en":{"name":"Jump Rope"}}');
SELECT exercises._upsert_equipment('battle_ropes',    'cardio', '{"it":{"name":"Battle Ropes"},"en":{"name":"Battle Ropes"}}');
SELECT exercises._upsert_equipment('stair_climber',   'cardio', '{"it":{"name":"Scalatore / Stair Climber"},"en":{"name":"Stair Climber"}}');

-- ── BANDS ─────────────────────────────────────────────────────
SELECT exercises._upsert_equipment('resistance_band',     'band', '{"it":{"name":"Elastico di Resistenza"},"en":{"name":"Resistance Band"}}');
SELECT exercises._upsert_equipment('mini_band',           'band', '{"it":{"name":"Mini Band / Loop Band"},"en":{"name":"Mini Band / Loop Band"}}');
SELECT exercises._upsert_equipment('pull_up_assist_band', 'band', '{"it":{"name":"Elastico Assistenza Trazioni"},"en":{"name":"Pull-Up Assist Band"}}');

-- ── SUSPENSION ────────────────────────────────────────────────
SELECT exercises._upsert_equipment('trx_straps',       'suspension', '{"it":{"name":"TRX / Sling Trainer"},"en":{"name":"TRX / Suspension Straps"}}');

-- ── ACCESSORIES ───────────────────────────────────────────────
SELECT exercises._upsert_equipment('foam_roller',      'accessory', '{"it":{"name":"Foam Roller"},"en":{"name":"Foam Roller"}}');
SELECT exercises._upsert_equipment('lacrosse_ball',    'accessory', '{"it":{"name":"Pallina Lacrosse / Trigger Point"},"en":{"name":"Lacrosse Ball / Trigger Point Ball"}}');
SELECT exercises._upsert_equipment('yoga_mat',         'accessory', '{"it":{"name":"Tappetino Yoga"},"en":{"name":"Yoga Mat"}}');
SELECT exercises._upsert_equipment('yoga_block',       'accessory', '{"it":{"name":"Mattoncino Yoga"},"en":{"name":"Yoga Block"}}');
SELECT exercises._upsert_equipment('yoga_strap',       'accessory', '{"it":{"name":"Cintura Yoga"},"en":{"name":"Yoga Strap"}}');
SELECT exercises._upsert_equipment('bosu_ball',        'accessory', '{"it":{"name":"BOSU Ball"},"en":{"name":"BOSU Ball"}}');
SELECT exercises._upsert_equipment('stability_ball',   'accessory', '{"it":{"name":"Palla Svizzera / Swiss Ball"},"en":{"name":"Swiss / Stability Ball"}}');
SELECT exercises._upsert_equipment('ab_wheel',         'accessory', '{"it":{"name":"Ruota Addominali"},"en":{"name":"Ab Wheel"}}');
SELECT exercises._upsert_equipment('medicine_ball',    'accessory', '{"it":{"name":"Palla Medica"},"en":{"name":"Medicine Ball"}}');
SELECT exercises._upsert_equipment('wall_ball',        'accessory', '{"it":{"name":"Wall Ball"},"en":{"name":"Wall Ball"}}');
SELECT exercises._upsert_equipment('heavy_bag',        'accessory', '{"it":{"name":"Sacco da Boxe"},"en":{"name":"Heavy Bag"}}');
SELECT exercises._upsert_equipment('speed_bag',        'accessory', '{"it":{"name":"Speed Bag"},"en":{"name":"Speed Bag"}}');
SELECT exercises._upsert_equipment('box_platform',     'accessory', '{"it":{"name":"Box / Pedana Pliometrica"},"en":{"name":"Plyometric Box / Platform"}}');
SELECT exercises._upsert_equipment('dip_belt',         'accessory', '{"it":{"name":"Cintura con Catena per Zavorra"},"en":{"name":"Dip Belt"}}');
SELECT exercises._upsert_equipment('weight_vest',      'accessory', '{"it":{"name":"Gilet Zavorrato"},"en":{"name":"Weighted Vest"}}');
SELECT exercises._upsert_equipment('ankle_weights',    'accessory', '{"it":{"name":"Cavigliere Zavorrate"},"en":{"name":"Ankle Weights"}}');
SELECT exercises._upsert_equipment('hip_thrust_pad',   'accessory', '{"it":{"name":"Pad per Hip Thrust"},"en":{"name":"Hip Thrust Pad"}}');
SELECT exercises._upsert_equipment('wrist_wraps',      'accessory', '{"it":{"name":"Fascette Polsi"},"en":{"name":"Wrist Wraps"}}');
SELECT exercises._upsert_equipment('lifting_straps',   'accessory', '{"it":{"name":"Cinghie Sollevamento"},"en":{"name":"Lifting Straps"}}');
SELECT exercises._upsert_equipment('chalk',            'accessory', '{"it":{"name":"Magnesio"},"en":{"name":"Chalk"}}');
SELECT exercises._upsert_equipment('sandbag',          'accessory', '{"it":{"name":"Sacca di Sabbia"},"en":{"name":"Sandbag"}}');
SELECT exercises._upsert_equipment('tire',             'accessory', '{"it":{"name":"Copertone (Strongman)"},"en":{"name":"Tire (Strongman)"}}');
SELECT exercises._upsert_equipment('atlas_stone',      'accessory', '{"it":{"name":"Atlas Stone (Strongman)"},"en":{"name":"Atlas Stone (Strongman)"}}');
SELECT exercises._upsert_equipment('yoke',             'accessory', '{"it":{"name":"Giogo (Strongman)"},"en":{"name":"Yoke (Strongman)"}}');
SELECT exercises._upsert_equipment('t_bar_attachment', 'accessory', '{"it":{"name":"Attacco T-Bar Row"},"en":{"name":"T-Bar Row Attachment"}}');
SELECT exercises._upsert_equipment('wobble_board',     'accessory', '{"it":{"name":"Tavoletta Propriocettiva / Wobble Board"},"en":{"name":"Wobble Board / Balance Board"}}');
SELECT exercises._upsert_equipment('parallettes',      'accessory', '{"it":{"name":"Parallettes"},"en":{"name":"Parallettes"}}');
SELECT exercises._upsert_equipment('none_bodyweight',  'bodyweight','{"it":{"name":"Nessuna Attrezzatura (Corpo Libero)"},"en":{"name":"None (Bodyweight)"}}');

DROP FUNCTION IF EXISTS exercises._upsert_equipment(VARCHAR, VARCHAR, JSONB);
