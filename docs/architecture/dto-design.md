# DTO Design (Exercise Domain)

## Obiettivo
I DTO in `src/main/java/it/aredegalli/coachly/exercise/dto` rappresentano il payload applicativo delle entita JPA evitando campi tecnici o di persistenza.

## Regole applicate
- Campi tecnici esclusi: `createdAt`, `updatedAt`, `deletedAt`, `status`.
- Nessun riferimento JPA nei DTO (`@ManyToOne`, `@EmbeddedId`), solo valori semplici.
- Per tabelle di join sono esposte chiavi esplicite (`exerciseId`, `muscleId`, ecc.) invece di id embeddati.
- Tutti i DTO sono classi Lombok (`@Data`, `@Builder`, `@NoArgsConstructor`, `@AllArgsConstructor`) per uso pratico in service/controller.
- Gli enum di dominio usano costanti uppercase in Java; il mapping JPA converte automaticamente verso i valori lowercase del database.

## Mappatura sintetica
- `ExerciseDto`: dati funzionali dell'esercizio + ownership/visibility e `translations`.
- `MuscleDto`, `EquipmentDto`, `TagDto`, `CategoryDto`: campi di dominio, senza metadati tecnici.
- `ExerciseMuscleDto`, `ExerciseEquipmentDto`, `ExerciseTagDto`, `ExerciseCategoryDto`: relazioni many-to-many con soli dati utili al dominio.
- `ExerciseMediaDto`: metadati media funzionali per presentazione e utilizzo.
- `ExerciseVariationDto`: relazione base/variante e delta difficolta.

## Nota operativa
Con MapStruct nel `pom.xml`, i mapper Entity <-> DTO possono essere introdotti in `service`/`controller` senza leak di dettagli JPA all'esterno.

## Build note: MapStruct + Lombok
- La compilazione usa `maven-compiler-plugin` con annotation processors espliciti.
- Ordine raccomandato: `lombok`, `lombok-mapstruct-binding`, `mapstruct-processor`.
- Il binding evita errori MapStruct su getter/setter/costruttori generati da Lombok durante l'annotation processing.
