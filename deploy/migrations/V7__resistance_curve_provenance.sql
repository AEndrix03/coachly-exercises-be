-- Provenienza della curva, separata da quella della riga.
--
-- `exercise_biomechanics.confidence` ed `evidence_basis` descrivono la riga
-- intera: sorgente di resistenza, domanda di stabilita', carico spinale. La
-- curva ha una provenienza propria e molto piu' forte -- e' calcolata da una
-- geometria dichiarata in `movement_archetype`, contestabile un angolo alla
-- volta. Scriverla dentro i campi di riga confonderebbe due affermazioni
-- diverse e farebbe sembrare verificato cio' che non lo e'.
ALTER TABLE exercises.exercise_biomechanics
  ADD COLUMN IF NOT EXISTS resistance_curve_basis exercises.evidence_basis,
  ADD COLUMN IF NOT EXISTS resistance_curve_confidence exercises.confidence_level,
  ADD COLUMN IF NOT EXISTS resistance_curve_archetype varchar(80)
      REFERENCES exercises.movement_archetype(code);

COMMENT ON COLUMN exercises.exercise_biomechanics.resistance_curve_archetype IS
  'L''archetipo da cui la curva e'' stata generata. E'' il puntatore che rende la '
  'revisione possibile: si corregge un angolo in movement_archetype e si '
  'rigenerano tutte le curve che ne dipendono.';

COMMENT ON COLUMN exercises.exercise_biomechanics.resistance_curve_confidence IS
  '"high" si guadagna con la fisica, non con la sicurezza di chi scrive: lo '
  'prende una curva calcolata da un''articolazione e un arco angolare dichiarati. '
  'Una curva ereditata dall''archetipo non puo'' prenderlo a nessun livello, '
  'perche'' su quel movimento la geometria non e'' stata applicata.';
