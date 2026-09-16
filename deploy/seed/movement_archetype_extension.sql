-- Estensione della tabella degli archetipi: i movimenti che il primo giro
-- aveva lasciato ambigui e che hanno invece una geometria difendibile.
--
-- CONVENZIONE (ripetuta qui perche' ogni riga sotto la usa):
--   angolo = inclinazione del segmento rispetto all'ORIZZONTALE, con segno.
--   0 = orizzontale = braccio di leva massimo. +-90 = verticale = leva ~0.
--   Un cambio di segno fra start ed end = il segmento attraversa
--   l'orizzontale = picco interno alla ROM.
--   Campionamento sulla CONCENTRICA: start = 0%, end = 100%.
--
-- Si applica SOLO alle righe con resistance_source 'gravity' o
-- 'bodyweight_leverage'. Le righe a cavo degli stessi archetipi restano
-- ambigue finche' il catalogo non registra l'altezza della puleggia.

INSERT INTO exercises.movement_archetype (code, model, geometry, confidence, rationale) VALUES

-- =========================================================================
-- CAVIGLIA
-- =========================================================================
('calf_raise_standing', 'lever', '{"joint":"ankle","start":10,"end":55}', 'high',
 'Il piede ruota sulle teste metatarsali. Il momento esterno alla caviglia e'' il peso per la distanza orizzontale fra avampiede e articolazione: massima in dorsiflessione, quando il segmento e'' quasi orizzontale, e decrescente man mano che il tallone sale. Curva discendente, il punto piu'' duro e'' in allungamento.'),

('calf_raise_seated', 'lever', '{"joint":"ankle","start":10,"end":55}', 'high',
 'Identica geometria alla caviglia rispetto alla versione in piedi. La flessione del ginocchio cambia quale muscolo lavora (soleo invece di gastrocnemio, che e'' biarticolare) ma non il braccio di leva del piede.'),

('tibialis_raise', 'lever', '{"joint":"ankle","start":45,"end":5}', 'medium',
 'Dorsiflessione: arco inverso del calf raise. Si parte con il piede plantarflesso, segmento inclinato e leva ridotta, e si finisce vicino all''orizzontale dove il momento e'' massimo. Curva crescente.'),

-- =========================================================================
-- TIRATE ORIZZONTALI -- l''omero ruota dalla verticale verso il tronco
-- =========================================================================
('row_barbell', 'lever', '{"joint":"shoulder","start":-85,"end":-10}', 'medium-high',
 'Tronco flesso, bilanciere appeso in verticale. L''omero parte quasi verticale verso il basso (braccio di leva prossimo a zero rispetto alla spalla) e arriva quasi parallelo al tronco, dove la distanza orizzontale dalla spalla e'' massima. Curva crescente: il punto duro e'' in chiusura, non allo stacco.'),

('row_dumbbell', 'lever', '{"joint":"shoulder","start":-85,"end":-5}', 'medium-high',
 'Stessa geometria del rematore con bilanciere. Il manubrio consente qualche grado in piu'' di chiusura perche'' non incontra il tronco.'),

('row_chest_supported', 'lever', '{"joint":"shoulder","start":-85,"end":-5}', 'high',
 'Stesso arco dell''omero, con il vantaggio che l''appoggio al petto fissa il tronco: sparisce la variabile che rende medium-high le altre versioni del rematore, cioe'' di quanto l''atleta accompagna con la schiena.'),

('row_landmine', 'lever', '{"joint":"shoulder","start":-80,"end":-15}', 'low-medium',
 'Il landmine impone una traiettoria ad arco invece che verticale, quindi la linea della resistenza cambia durante il movimento e il modello a leva singola la approssima soltanto. Forma coerente con gli altri rematori, incertezza dichiarata piu'' alta.'),

('row_inverted', 'lever', '{"joint":"shoulder","start":-85,"end":-10}', 'medium',
 'Corpo sospeso sotto la barra: il carico e'' il peso corporeo ma l''arco dell''omero e'' quello del rematore. L''inclinazione del corpo cambia la frazione di peso sollevata, non la forma della curva.'),

-- =========================================================================
-- TRAZIONI VERTICALI -- picco decentrato, non campana simmetrica
-- =========================================================================
('pullup', 'control_points', '{"joint":"elbow","points":[[0,80],[0.6,15],[1,55]]}', 'medium',
 'In sospensione l''avambraccio e'' quasi verticale e il momento al gomito e'' piccolo; ruota verso l''orizzontale e il punto critico cade oltre meta'' trazione, non al centro. Non e'' una campana simmetrica: il tratto finale resta piu'' impegnativo dell''iniziale, ed e'' il motivo per cui si cede sotto il mento e non allo stacco.'),

('chinup', 'control_points', '{"joint":"elbow","points":[[0,80],[0.55,12],[1,50]]}', 'medium',
 'Stesso arco sagittale della trazione prona. La presa supina anticipa di poco il punto critico perche'' il bicipite contribuisce prima, ma la geometria del braccio non cambia.'),

-- =========================================================================
-- GOMITO E POLSO
-- =========================================================================
('curl_wrist', 'lever', '{"joint":"wrist","start":-70,"end":40}', 'medium-high',
 'Avambraccio appoggiato, mano oltre il bordo. La mano parte pendente verso il basso, attraversa l''orizzontale dove il braccio di leva e'' massimo e finisce in flessione. Il cambio di segno produce un picco interno: stessa struttura di un curl, scala ridotta.'),

-- =========================================================================
-- SPALLA
-- =========================================================================
('fly_dumbbell', 'lever', '{"joint":"shoulder","start":0,"end":85}', 'high',
 'Da supini, braccia aperte: all''inizio l''omero e'' orizzontale, cioe'' esattamente dove la distanza orizzontale dalla spalla e'' massima, e finisce verticale sopra il petto dove il momento e'' prossimo a zero. E'' il caso da manuale della curva discendente, con tutto il carico nella posizione allungata.'),

('rear_delt_cable', 'lever', '{"joint":"shoulder","start":-85,"end":-5}', 'high',
 'Solo per le righe a gravita'' di questo archetipo (bent-over reverse fly): le braccia pendono verticali e si aprono fino all''orizzontale, dove il momento e'' massimo. Curva crescente. Le righe a cavo dello stesso archetipo restano fuori.'),

('upright_row', 'lever', '{"joint":"shoulder","start":-85,"end":-15}', 'medium',
 'Abduzione dell''omero dalla verticale verso l''orizzontale, con il carico che resta aderente al corpo. Curva crescente. Il gomito flette in parallelo e il modello a leva singola non lo rappresenta: da qui il medium.'),

('pullover_db', 'lever', '{"joint":"shoulder","start":-25,"end":75}', 'medium-high',
 'Da supini, il braccio parte dietro la testa sotto il livello della spalla, attraversa l''orizzontale e arriva verticale sopra il petto. Il passaggio per lo zero cade presto nella concentrica: picco decentrato verso l''inizio, coerente con il fatto che il pullover pesa nella posizione allungata.'),

('cuff_rotation', 'lever', '{"joint":"shoulder_rotation","start":0,"end":80}', 'medium',
 'Rotazione esterna da decubito laterale. L''avambraccio ruota attorno all''asse dell''omero: parte con il peso alla stessa altezza dell''asse, cioe'' alla massima distanza orizzontale, e finisce con il peso sopra l''asse dove la distanza e'' nulla. Curva discendente.'),

-- =========================================================================
-- ANCA
-- =========================================================================
('hip_thrust', 'lever', '{"joint":"hip","start":-55,"end":0}', 'high',
 'Il momento all''anca segue la proiezione orizzontale del femore: minima quando il femore e'' inclinato in basso, massima al lockout quando e'' orizzontale. Curva crescente, il punto duro e'' in chiusura. E'' il complemento speculare dello squat, che invece pesa in buca.'),

('glute_bridge', 'lever', '{"joint":"hip","start":-45,"end":0}', 'high',
 'Stessa geometria dell''hip thrust con arco ridotto, perche'' partendo da terra invece che da un rialzo il femore parte meno inclinato.'),

('hip_abduction', 'lever', '{"joint":"hip","start":0,"end":45}', 'medium',
 'Da decubito laterale la gamba parte allineata al tronco, cioe'' orizzontale e alla massima distanza dall''anca, e sale riducendo la proiezione orizzontale. Curva discendente. Vale per le righe a gravita''; le macchine a camma seguono la loro regola.'),

('hip_adduction', 'lever', '{"joint":"hip","start":0,"end":40}', 'medium',
 'Stessa costruzione dell''abduzione, gamba che risale verso la linea mediana. Curva discendente.'),

-- =========================================================================
-- GINOCCHIO
-- =========================================================================
('slider_leg_curl', 'lever', '{"joint":"knee","start":0,"end":70}', 'medium',
 'Flessione del ginocchio con i talloni che scivolano e il bacino sollevato. La tibia parte orizzontale, dove la leva e'' massima, e flette verso la verticale. Curva discendente: il tratto duro e'' a gambe distese. L''anca contribuisce e non e'' modellata, da cui il medium.'),

-- =========================================================================
-- TRONCO
-- =========================================================================
('side_bend', 'lever', '{"joint":"spine_lateral","start":65,"end":88}', 'medium',
 'Il carico pende lateralmente: il momento sulla colonna e'' la sua distanza orizzontale dall''asse, massima a tronco flesso e quasi nulla a tronco eretto. Curva discendente. La geometria reale dipende da quanto l''atleta si flette, quindi l''ampiezza e'' indicativa.'),

-- =========================================================================
-- NESSUNA LEVA CHE RUOTA
-- =========================================================================
('shrug', 'constant', '{"reason":"translation"}', 'medium-high',
 'L''elevazione scapolare e'' una traslazione quasi verticale, non la rotazione di un segmento attorno a un''articolazione. Non esiste un braccio di leva che cambi lungo il movimento: la domanda esterna e'' sostanzialmente il peso, costante. Curva piatta per ragioni fisiche, non per mancanza di dati.')

ON CONFLICT (code) DO UPDATE SET
  model = excluded.model,
  geometry = excluded.geometry,
  confidence = excluded.confidence,
  rationale = excluded.rationale,
  updated_at = now();
