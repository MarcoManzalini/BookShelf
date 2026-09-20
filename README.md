# BookShelf

App Flutter per tracciare i libri letti. Material 3, BLoC, Supabase (auth, database, storage) e Open Library come fonte dati.

- Lingue: italiano (predefinita) e inglese
- Tab: **I miei libri**, **Cerca**, **Profilo** (stato di ogni tab preservato)
- Tema chiaro / scuro / sistema

## Requisiti

- Flutter 3.47+ (stable) — testato con Flutter 3.47.5
- Un progetto Supabase (il piano gratuito basta)

## Setup

### 1. Supabase

1. Crea un progetto su [supabase.com](https://supabase.com).
2. Apri **SQL Editor → New query**, incolla **tutto** il contenuto di [`supabase/schema.sql`](supabase/schema.sql) ed esegui. Lo script è idempotente: puoi rilanciarlo.
   Crea tabelle `profiles` e `user_books`, RLS, trigger (`handle_new_user`, `updated_at`), bucket `avatars` con policy e la funzione RPC `delete_my_account`.
3. **Authentication → URL Configuration → Redirect URLs**: aggiungi `io.supabase.bookshelf://login-callback/`.
   Serve per i link di conferma email e recupero password, che riaprono l'app.
4. (Opzionale) **Authentication → Providers → Email**: disattiva "Confirm email" se in sviluppo vuoi accedere subito dopo la registrazione. Con la conferma attiva l'app mostra un avviso e chiede di confermare via email.

### 2. Credenziali

```bash
cp .env.example .env
```

Poi compila `.env` (Supabase Dashboard → **Project Settings → API**):

```
SUPABASE_URL=https://<project-ref>.supabase.co
SUPABASE_ANON_KEY=<anon / publishable key>
```

`.env` è nel `.gitignore` e non va committato. Nessun segreto è hardcoded nel codice. Non usare mai la `service_role` key nell'app.
Se `.env` manca o è vuoto, l'app mostra una schermata di configurazione mancante invece di crashare.

### 3. Avvio

```bash
flutter pub get
flutter run
```

Non serve `build_runner`: i modelli sono classi manuali con `Equatable`. Le localizzazioni (`lib/l10n/gen/`) sono generate da `flutter pub get` / `flutter gen-l10n` a partire dai file `.arb`.

### Comandi utili

```bash
flutter analyze      # analisi statica (flutter_lints + regole extra)
flutter test         # unit + widget test
flutter gen-l10n     # rigenera le localizzazioni dopo aver modificato gli .arb
```

## Architettura

Feature-first, con tre layer per feature. Le UI dipendono solo dai Bloc, i Bloc dipendono da repository astratti.

```
lib/
  core/
    config/    Env (.env), costanti (User-Agent, redirect URL, debounce)
    di/        get_it: registrazione di datasource, repository, use case, bloc
    errors/    Failure + mapError (Dio/Supabase/socket -> Failure) + messaggi localizzati
    router/    go_router, guard di autenticazione, MainShell (bottom nav)
    theme/     palette (AppColors), tipografia (AppFonts), tema Material 3 chiaro/scuro
    utils/     RequestStatus, transformer Bloc (debounce + restartable), validatori
    widgets/   BookCover/ClothCover, CatalogCard, BookshelfMark, AppRatingBar, EmptyState, ErrorView, skeleton, ExpandableText
  features/
    auth/          login, registrazione, recupero e reset password, AuthBloc
    library/       i miei libri: lista/griglia, filtri, LibraryBloc, use case AddBookToLibrary
    search/        ricerca Open Library con debounce e scroll infinito, SearchBloc
    book_details/  dettaglio libro (libreria o anteprima), BookDetailsBloc
    profile/       profilo, avatar, tema, statistiche, eliminazione account
  l10n/            app_it.arb (template), app_en.arb, codice generato in gen/
  main.dart, app.dart
supabase/schema.sql
```

Ogni feature ha `data` (datasource + repository impl + mapper), `domain` (entità + repository astratti + use case) e `presentation` (bloc/cubit, pagine, widget). `book_details` non ha `data`/`domain` propri: compone i repository di `library` e `search`.

### Flusso dati

- **Errori**: i repository intercettano qualunque eccezione e rilanciano un `Failure(code)`. I Bloc gestiscono solo `Failure`; la UI lo traduce in una stringa localizzata (`failureMessage`). Stati espliciti `initial / loading / success / failure` (`RequestStatus`).
- **Auth**: `AuthBloc` ascolta `onAuthStateChange` (tramite `AuthRepository.changes`) e parte dalla sessione persistita da `supabase_flutter`. Il router (`refreshListenable` sullo stream del bloc) reindirizza tra `/auth/*` e l'app. Un evento `passwordRecovery` porta a `/auth/reset-password`.
- **Libreria**: `LibraryRepositoryImpl` mantiene una cache in memoria ed espone uno `Stream` delle modifiche. `LibraryBloc` (singleton, caricato al login) lo segue, quindi le modifiche fatte in dettaglio o dalla ricerca compaiono subito nella lista. La ricerca sa se un libro è già aggiunto leggendo `LibraryBloc`.
- **Ricerca**: `SearchBloc` usa `debounce(400 ms) + restartable` per la digitazione e `droppable` per le pagine successive. Il footer della lista carica la pagina successiva quando diventa visibile.
- **Dettaglio**: `BookDetailsBloc` gestisce sia il libro in libreria (`/book/:id`) sia l'anteprima da ricerca (`/preview/:externalId`, con il `Book` passato come `extra`). Le modifiche sono ottimistiche con rollback in caso di errore. Le regole (es. "letto" imposta pagina finale e date) stanno in `UserBook.withStatus/withProgress`.
- **Statistiche** del profilo calcolate da `ReadingStats.fromBooks` sui libri già caricati.

## Identità visiva

Il tema è quello di una biblioteca: una sala di lettura con inchiostro verde, segnalibro bordeaux, ottone e ripiani in noce, non un'app Material generica.

| Elemento | Dove |
|---|---|
| Palette chiara (carta con leggera tinta verde) e scura ("sala di lettura", ottone acceso) | `core/theme/app_colors.dart` |
| Literata (unico font dell'app, variabile: peso e dimensione ottica) | `core/theme/app_typography.dart`, `assets/fonts/` |
| Copertina in tela con titolo e filetto oro quando manca l'immagine; il colore dipende dal titolo | `core/widgets/book_cover.dart` (`ClothCover`) |
| Segnalibro a nastro sulla copertina: bordeaux = in lettura, ottone = letto | `library/presentation/widgets/status_ribbon.dart` |
| Stato di lettura come timbro di biblioteca | `library/presentation/widgets/status_chip.dart` |
| Vista griglia: le copertine poggiano su un ripiano | `library/presentation/widgets/library_book_grid_item.dart` |
| Dati del libro come scheda di catalogo (filetto rosso, righe, foro) | `core/widgets/catalog_card.dart` |
| Marchio con tre dorsi di libri | `core/widgets/bookshelf_mark.dart` |

Per cambiare identità basta modificare `app_colors.dart` e `app_typography.dart`: i widget leggono colori e stili dal tema. I font sono distribuiti con licenza SIL OFL (testi in `assets/fonts/licenses/`).

## Open Library

Solo Open Library, nessun fallback.

- Ricerca: `/search.json` con i `fields` richiesti, 20 risultati per pagina.
- Dettagli: `/works/{id}.json` (descrizione, soggetti, altre copertine).
- Copertine: `covers.openlibrary.org/b/id/{cover_i}-{S|M|L}.jpg?default=false`. Un 404 mostra il placeholder locale di `BookCover`.
- Header `User-Agent` descrittivo (`AppConfig.userAgent`). Se pubblichi l'app, aggiungi un contatto come richiesto da Open Library.

**Costa e retro**: Open Library non li fornisce in modo affidabile, quindi `Book.extraImages` resta vuoto salvo che `works/{id}.json` restituisca altre copertine (altre edizioni), che vengono mostrate nel carosello. Il carosello (`BookImageCarousel`) è già pronto: quando avrai una fonte per costa/retro basterà popolare `extraImages`.

## Eliminazione account

Il client non può cancellare la propria riga in `auth.users`, quindi `schema.sql` definisce la RPC `public.delete_my_account()` (`security definer`, eseguibile solo da utenti autenticati). L'app rimuove prima i file avatar dal bucket, poi chiama la RPC; `on delete cascade` elimina profilo e libri. **Non serve nessuna Edge Function.**

## Login Google / Apple

Predisposto ma non attivo: `AuthRepository.signInWithProvider` e `SocialLoginSection` esistono, ma sono nascosti da `AppConfig.socialLoginEnabled = false`. Per attivarli: abilita il provider in Supabase, configura i client id nativi e imposta il flag a `true`.

## Note di piattaforma

- Android: permesso `INTERNET` e intent filter per `io.supabase.bookshelf://login-callback` in `AndroidManifest.xml`.
- iOS: URL scheme `io.supabase.bookshelf` e `NSPhotoLibraryUsageDescription` (foto profilo) in `Info.plist`.
- Il progetto è pensato per mobile (Android/iOS): usa `dart:io` nel mapping degli errori, quindi il target web non è supportato.

## Test

`flutter test` esegue:

- unit test dei Bloc con `bloc_test` + `mocktail`: `AuthBloc`, `LibraryBloc`, `SearchBloc`, `BookDetailsBloc`
- test del repository della libreria, delle regole di dominio (`UserBook`, `ReadingStats`), del mapper Open Library, del guard del router e del mapping errori
- widget test: `LoginView` (validazione, snackbar, EN/IT), `LibraryPage` (empty/error/lista/filtri), `AppRatingBar`
