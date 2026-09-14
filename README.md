# coachly-exercises-be

## Import alias esercizi

Gli alias editoriali si importano per `exercise.code`, mai per nome. Il file
`deploy/aliases/aliases.seed.csv` documenta il formato minimo. Validare e
generare SQL idempotente con:

```bash
python deploy/aliases/import_aliases.py deploy/aliases/aliases.seed.csv --output aliases.sql
psql "$DATABASE_URL" --set ON_ERROR_STOP=1 --file aliases.sql
```

Il validatore blocca locale, tipo, peso e duplicati normalizzati; le ambiguita
tra esercizi sono warning deliberati. Lo SQL blocca codici inesistenti prima di
scrivere.
