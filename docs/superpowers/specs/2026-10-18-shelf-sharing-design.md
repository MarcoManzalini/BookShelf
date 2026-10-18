# Condivisione scaffali — design

Data: 2026-10-18

## Obiettivo

Un utente condivide uno scaffale personale (es. "Letture autunnali") con
chiunque. Chi riceve vede l'elenco dei libri, anche senza app, e dall'app può
salvarsi una copia dello scaffale o aggiungere singoli libri alla propria
libreria.

## Decisioni

- **Condivisione = card statica + link live.** Il proprietario condivide
  un'immagine (copertine + titoli) e un link `https`. Il link mostra sempre lo
  stato attuale dello scaffale.
- **Revocabile.** Il proprietario può interrompere la condivisione; il link
  smette di funzionare. "Nuovo link" = revoca + nuovo token.
- **Sola lettura per chi riceve.** Vede titolo, autori, copertina, anno. Mai
  stato di lettura, voti, note, progressi, prestiti, date.
- **Duplica, non sincronizza.** "Salva nella mia libreria" copia i libri nel
  proprio account come *Da leggere* con il tag dello scaffale; libri già
  presenti ricevono solo il tag. La copia è indipendente dall'originale.
- **Link web su GitHub Pages, senza App Links/Universal Links.** La pagina
  web mostra lo scaffale e un pulsante "Apri in BookShelf" che usa lo schema
  custom già registrato `io.supabase.bookshelf`. Un dominio custom con
  `.well-known` può essere aggiunto più avanti senza cambiare il database.
- **Nell'app serve il login** per vedere lo scaffale condiviso (l'app è tutta
  dietro login). Dopo il login l'utente torna allo scaffale condiviso.

## Database

Modifiche identiche in `supabase/schema.sql` e `supabase/update.sql`
(idempotenti, non distruttive; la query di verifica finale di `update.sql`
include la nuova tabella e la funzione).

### Tabella `shelf_shares`

| colonna      | tipo        | note                                                    |
|--------------|-------------|---------------------------------------------------------|
| `id`         | uuid pk     | `gen_random_uuid()`                                     |
| `user_id`    | uuid        | default `auth.uid()`, fk `auth.users` on delete cascade |
| `shelf_name` | text        | not null, trim non vuoto; nome del tag come scritto     |
| `token`      | text        | not null, unique; 22 caratteri url-safe casuali         |
| `created_at` | timestamptz | default `now()`                                         |

- Indice unico su `(user_id, lower(shelf_name))`: un link per scaffale.
- Token generato lato DB: default
  `translate(encode(extensions.gen_random_bytes(16), 'base64'), '+/=', '-_')` troncato a
  22 caratteri (pgcrypto, schema `extensions` su Supabase).
- RLS attiva. Policy `select`, `insert`, `delete` per `authenticated` con
  `(select auth.uid()) = user_id`. Nessuna policy `update` (si revoca e si
  ricrea).

### Funzione `get_shared_shelf(p_token text)`

- `security definer`, `set search_path = ''`, `stable`.
- `grant execute` ad `anon` e `authenticated`; `revoke` da `public`.
- Restituisce `jsonb`, oppure `null` se il token non esiste:

```json
{
  "shelf_name": "Letture autunnali",
  "owner_name": "Marco",
  "books": [
    {"external_id": "OL45804W", "title": "...", "authors": ["..."],
     "cover_url": "...", "published_year": 1954}
  ]
}
```

- `books` = righe `user_books` del proprietario il cui array `shelves`
  contiene il nome (confronto case-insensitive, come `shelf_names.dart`),
  ordinate per `created_at`. Lista vuota se lo scaffale non ha più libri.
- `owner_name` = `profiles.display_name`, può essere `null`.
- Nessun'altra colonna esce dalla funzione.

## App Flutter

### Feature `lib/features/shelf_share/`

- `domain/entities/shelf_share.dart` — `ShelfShare` (shelfName, token) con
  getter `webUrl` e `appUrl`.
- `domain/entities/shared_shelf.dart` — `SharedShelf` (shelfName, ownerName,
  books: `List<Book>` riusando l'entità `Book` di search).
- `domain/repositories/shelf_share_repository.dart`:
  - `Future<ShelfShare?> shareFor(String shelfName)`
  - `Future<ShelfShare> create(String shelfName)`
  - `Future<void> revoke(String shelfName)`
  - `Future<SharedShelf?> fetchShared(String token)`
- `data/` — datasource Supabase (tabella + `rpc('get_shared_shelf')`),
  mapper, repository impl con `mapError`.
- `presentation/`:
  - `ShelfShareCubit` (proprietario): carica share esistente, crea, revoca,
    rigenera. Stato con `RequestStatus`.
  - `SharedShelfCubit` (destinatario): carica scaffale per token, azione
    "salva nella mia libreria" con stato separato (idle/saving/saved/failure)
    e numero di libri aggiunti.
  - `ShelfShareSheet` — bottom sheet: *Condividi* (immagine + testo con link
    via `share_plus`), *Copia link*, *Nuovo link*, *Interrompi condivisione*.
  - `ShelfShareCard` — widget renderizzato a immagine come
    `recap_share_card.dart`: nome scaffale, fino a 6 copertine, numero libri,
    "via BookShelf".
  - `SharedShelfPage` — griglia copertine in sola lettura, nome scaffale e
    proprietario, pulsante "Salva nella mia libreria". Tap su libro →
    `AppRoutes.preview(externalId)` con `extra: Book`. Stati: caricamento,
    errore con riprova, link non valido/revocato, scaffale vuoto.
- Registrazioni in `lib/core/di/injection.dart`: datasource e repository
  `registerLazySingleton`, cubit `registerFactory` /
  `registerFactoryParam` (token).

### Salva nella mia libreria

Logica di dominio (non nel cubit): per ogni libro condiviso, se è già in
libreria (stesso `external_id`) aggiunge il tag se manca, altrimenti lo
aggiunge come *Da leggere* con quel tag. Passa da `LibraryRepository`, quindi
usa cache e coda offline esistenti e aggiorna `LibraryBloc` via stream. Se
l'utente ha già uno scaffale con lo stesso nome (case-insensitive) i libri
confluiscono lì.

### Punto di ingresso proprietario

In `library_page.dart`, quando il filtro scaffale è attivo
(`LibraryShelfFilterChanged`), compare un'azione "Condividi scaffale" che apre
`ShelfShareSheet` per quello scaffale. Gli scaffali sono tag: nessuna
gestione di rinomina/cancellazione esiste oggi, quindi nessun hook extra. Se
lo scaffale si svuota, il link resta valido e mostra uno scaffale vuoto.

### Deep link

- Link app: `io.supabase.bookshelf://shelf/shared-shelf/<token>`. Gli URI con
  schema custom arrivano a go_router con il solo path, quindi la route è
  `/shared-shelf/:token` (`AppRoutes.sharedShelf(token)`).
- Android: aggiungere `<data android:host="shelf"/>` all'intent filter dello
  schema `io.supabase.bookshelf` in `AndroidManifest.xml`. iOS: lo schema è
  già in `Info.plist`, nessuna modifica.
- Login: `authRedirect` oggi perde la destinazione. Se l'utente non loggato
  apre `/shared-shelf/...`, il redirect verso welcome conserva la
  destinazione (`?from=`) e dopo il login si torna lì.
- Da verificare in implementazione: `supabase_flutter` non deve trattare
  questo URI come callback di autenticazione (non contiene `code` né
  `access_token`, quindi atteso ok).

### Configurazione

`AppConfig.shelfShareBaseUrl =
'https://marcomanzalini.github.io/BookShelf/s/'`. Link web =
`'$shelfShareBaseUrl?t=<token>'`.

### Localizzazione

Tutte le nuove stringhe in `app_it.arb` e `app_en.arb` (skill
`add-l10n-string`).

### Errori

Nuovi casi passano da `mapError`. Tabella/funzione assenti → codici
`42P01`/`PGRST202`/`PGRST205` → `FailureCode.outdatedDatabase`
(aggiungere `42P01` e `PGRST202` se non già mappati).

## Pagina web `share_site/`

- `share_site/s/index.html` — HTML + CSS + JS vanilla, nessuna build, in
  italiano. Legge `t` dalla query string, chiama
  `POST {SUPABASE_URL}/rest/v1/rpc/get_shared_shelf` con header `apikey`
  (chiave anon, già pubblica nell'app). Mostra nome scaffale, "di
  {owner_name}", griglia copertine con titolo e autori, pulsante "Apri in
  BookShelf" (link app). Stati: caricamento, link non valido, errore rete,
  scaffale vuoto. Rispetta tema chiaro/scuro.
- `share_site/index.html` — pagina minima che presenta l'app.
- Meta Open Graph statici ("Uno scaffale condiviso su BookShelf").
- `.github/workflows/pages.yml` — pubblica `share_site/` con
  `actions/upload-pages-artifact` + `actions/deploy-pages` a ogni push su
  `master` che tocca `share_site/**`.
- URL Supabase e chiave anon scritti nell'HTML (file statico, nessun `.env`).

### Prerequisiti manuali (utente)

1. Repo `MarcoManzalini/BookShelf` pubblico (o account GitHub Pro).
2. Settings → Pages → Source: "GitHub Actions".
3. Eseguire la parte nuova di `update.sql` nel SQL Editor Supabase.

## Test

- Entità e mapper `shelf_share` / `shared_shelf`.
- Regola "salva nella mia libreria" (libro nuovo, libro già presente con e
  senza tag, scaffale omonimo con maiuscole diverse).
- `ShelfShareCubit` e `SharedShelfCubit` con `bloc_test`.
- `authRedirect` conserva la destinazione per `/shared-shelf/...`.
- Widget test `SharedShelfPage` (stati principali) e `ShelfShareSheet`.

## Fuori scope

Notifiche al proprietario, statistiche di apertura, condivisione di più
scaffali insieme, scadenza dei link, App Links / Universal Links, anteprime
Open Graph dinamiche, versione web dell'app.
