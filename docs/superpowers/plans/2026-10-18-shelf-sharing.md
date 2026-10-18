# Condivisione scaffali — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Un utente condivide uno scaffale (tag) con un link https; chi lo apre vede i libri sul web o nell'app e può salvarne una copia nella propria libreria.

**Architecture:** Nuova tabella `shelf_shares` (token per scaffale) + funzione `security definer` `get_shared_shelf(token)` leggibile da `anon`. Nuova feature Flutter `lib/features/shelf_share/` (data/domain/presentation) con due cubit: proprietario (crea/revoca link) e destinatario (vede/salva). Pagina statica `share_site/` su GitHub Pages che chiama la stessa RPC e rimanda all'app via `io.supabase.bookshelf://shelf/shared-shelf/<token>`.

**Tech Stack:** Flutter, flutter_bloc + bloc_test, mocktail, get_it, go_router, supabase_flutter, share_plus, Postgres/RLS, HTML+JS vanilla, GitHub Actions Pages.

**Spec:** `docs/superpowers/specs/2026-10-18-shelf-sharing-design.md`

## Global Constraints

- Ogni modifica DB va in **entrambi** `supabase/schema.sql` e `supabase/update.sql`; `update.sql` resta idempotente e non distruttivo.
- Token: 22 caratteri url-safe, `extensions.gen_random_bytes(16)`.
- La RPC espone solo `shelf_name`, `owner_name`, e per libro `external_id, title, authors, cover_url, published_year`.
- Confronto nomi scaffale sempre case-insensitive (`ShelfNames.same` / `lower()`).
- Link app: `io.supabase.bookshelf://shelf/shared-shelf/<token>`; route `/shared-shelf/:token`.
- Link web: `'${AppConfig.shelfShareBaseUrl}?t=<token>'`, `shelfShareBaseUrl = 'https://marcomanzalini.github.io/BookShelf/s/'`.
- Ogni stringa UI in `app_it.arb` + `app_en.arb` (skill `add-l10n-string`); mai editare `lib/l10n/gen/`.
- Repository: ogni eccezione → `throw mapError(e)`. Stato con `RequestStatus`.
- Nuove dipendenze DI in `lib/core/di/injection.dart` (lazySingleton per datasource/repo/use case, factory per cubit).
- `flutter analyze` pulito dopo ogni task. Lint: trailing commas, single quotes, final locals.
- **Commit:** un hook blocca `git commit`/`git push` all'agente. A fine task mostrare `git status --short` + `git diff --stat` all'utente, che committa.

## Review Focus

1. **Token assente, malformato o revocato** (link vecchio, `?t=` vuoto) → app e web mostrano "Questo scaffale non è più condiviso", mai errore generico o crash. Test in Task 3 (repo → `null`), Task 5 (cubit stato `notFound`), Task 7 (pagina web gestisce `null`).
2. **Destinatario = proprietario** (apre il proprio link) → "Salva nella mia libreria" non duplica: i libri già presenti hanno già il tag, risultato `0` aggiunti. Test in Task 2.
3. **Scaffale del destinatario con maiuscole diverse** ("letture autunnali" vs "Letture Autunnali") → i libri finiscono nello scaffale esistente con la sua grafia. Test in Task 2.
4. **Libro già sul massimo di scaffali (`ShelfNames.maxPerBook` = 20)** → il salvataggio non fallisce; quel libro viene saltato senza errore. Test in Task 2.
5. **Link aperto da non loggato** → dopo login l'utente arriva sullo scaffale condiviso, non in libreria. Test in Task 4.

---

### Task 1: Database — `shelf_shares` + `get_shared_shelf`

**Files:**
- Modify: `supabase/schema.sql` (nuova sezione dopo `book_quotes`, prima di `delete_my_account`)
- Modify: `supabase/update.sql` (nuova sezione + righe nella query di verifica finale)

**Interfaces:**
- Produces: tabella `public.shelf_shares(id, user_id, shelf_name, token, created_at)`; funzione `public.get_shared_shelf(p_token text) returns jsonb` (formato JSON della spec).

- [ ] **Step 1: Scrivere la sezione SQL in `schema.sql`**

Tabella con colonne della spec; `shelf_name text not null check (length(btrim(shelf_name)) between 1 and 30)`; `token text not null unique default substr(translate(encode(extensions.gen_random_bytes(16), 'base64'), '+/=', '-_'), 1, 22)`; `create unique index if not exists shelf_shares_user_shelf_unique on public.shelf_shares (user_id, lower(shelf_name))`. RLS on; policy `shelf_shares_select_own`, `_insert_own`, `_delete_own` con lo stesso stile `drop policy if exists` + `(select auth.uid()) = user_id` di `user_books`.

Funzione (corpo fissato perché decide la superficie dati):

```sql
create or replace function public.get_shared_shelf(p_token text)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object(
    'shelf_name', s.shelf_name,
    'owner_name', p.display_name,
    'books', coalesce((
      select jsonb_agg(jsonb_build_object(
               'external_id', b.external_id,
               'title', b.title,
               'authors', b.authors,
               'cover_url', b.cover_url,
               'published_year', b.published_year)
             order by b.created_at)
      from public.user_books b
      where b.user_id = s.user_id
        and exists (select 1 from unnest(b.shelves) t(name)
                    where lower(t.name) = lower(s.shelf_name))
    ), '[]'::jsonb))
  from public.shelf_shares s
  left join public.profiles p on p.id = s.user_id
  where s.token = p_token;
$$;

revoke all on function public.get_shared_shelf(text) from public;
grant execute on function public.get_shared_shelf(text) to anon, authenticated;
```

- [ ] **Step 2: Copiare la sezione in `update.sql`** — identica (tutto già `if not exists` / `create or replace` / `drop policy if exists`). Nella query di verifica finale aggiungere una riga `union all` per la tabella `shelf_shares` e una per la funzione `get_shared_shelf` (da `information_schema.routines`), seguendo lo stile esistente; aggiornare il commento in testa alla query.

- [ ] **Step 3: Review RLS** — lanciare l'agente `rls-reviewer` su `supabase/schema.sql` e `supabase/update.sql`. Atteso: nessun gap su `shelf_shares`; funzione con `search_path = ''` e grant solo ad `anon, authenticated`.

- [ ] **Step 4: Verifica manuale (utente)** — l'utente incolla la parte nuova di `update.sql` nel SQL Editor. Poi: `select public.get_shared_shelf('nope');` → `null`.

- [ ] **Step 5: Checkpoint commit (utente)**

---

### Task 2: Dominio — entità, repository astratto, `SaveSharedShelf`

**Files:**
- Create: `lib/features/shelf_share/domain/entities/shelf_share.dart`
- Create: `lib/features/shelf_share/domain/entities/shared_shelf.dart`
- Create: `lib/features/shelf_share/domain/repositories/shelf_share_repository.dart`
- Create: `lib/features/shelf_share/domain/usecases/save_shared_shelf.dart`
- Modify: `lib/core/config/app_config.dart` (aggiungere `shelfShareBaseUrl`, `shelfShareAppUrl`)
- Test: `test/features/shelf_share/domain/shelf_share_test.dart`
- Test: `test/features/shelf_share/domain/save_shared_shelf_test.dart`

**Interfaces:**
- Consumes: `LibraryRepository.cachedBooks`, `.findCachedByExternalId`, `.add(Book, ReadingStatus)`, `.update(UserBook)`; `ShelfNames.same`, `ShelfNames.maxPerBook`; `Book`; `UserBook.copyWith(shelves:)`.
- Produces:
  - `AppConfig.shelfShareBaseUrl = 'https://marcomanzalini.github.io/BookShelf/s/'`, `AppConfig.shelfShareAppUrl = 'io.supabase.bookshelf://shelf/shared-shelf/'`
  - `class ShelfShare extends Equatable { const ShelfShare({required String shelfName, required String token}); Uri get webUrl; Uri get appUrl; }`
  - `class SharedShelf extends Equatable { const SharedShelf({required String shelfName, String? ownerName, required List<Book> books}); }`
  - `abstract interface class ShelfShareRepository { Future<ShelfShare?> shareFor(String shelfName); Future<ShelfShare> create(String shelfName); Future<void> revoke(String shelfName); Future<SharedShelf?> fetchShared(String token); }`
  - `class SaveSharedShelf { const SaveSharedShelf(LibraryRepository library); Future<int> call(SharedShelf shelf); }` — ritorna il numero di libri **nuovi** aggiunti.

- [ ] **Step 1: Test entità**

```dart
test('webUrl and appUrl carry the token', () {
  const share = ShelfShare(shelfName: 'Letture autunnali', token: 'abc_-123');
  expect(share.webUrl.toString(),
      'https://marcomanzalini.github.io/BookShelf/s/?t=abc_-123');
  expect(share.appUrl.toString(),
      'io.supabase.bookshelf://shelf/shared-shelf/abc_-123');
});
```

- [ ] **Step 2: Test `SaveSharedShelf`** (MockLibraryRepository, fixtures `buildBook`/`buildUserBook`; `registerFallbackValue` per `Book`, `UserBook`, `ReadingStatus`)

- `adds missing books as wantToRead with the shelf tag` — libreria vuota, scaffale con 2 libri → `add(book, ReadingStatus.wantToRead)` ×2, poi `update` con `shelves: ['Letture autunnali']`; ritorna `2`.
- `only tags books already in the library` — libro già presente con `shelves: ['Preferiti']` → nessun `add`; `update` con `shelves: ['Preferiti', 'Letture autunnali']`; ritorna `0`.
- `does nothing for books already on the shelf` — libro già taggato → né `add` né `update`; ritorna `0`.
- `reuses the reader's spelling of an existing shelf` — `cachedBooks` contiene un libro con `shelves: ['letture AUTUNNALI']`; un libro nuovo viene taggato `'letture AUTUNNALI'`.
- `skips books already on maxPerBook shelves` — libro presente con 20 scaffali → nessun `update`, nessuna eccezione.

- [ ] **Step 3: Run test → FAIL** — `flutter test test/features/shelf_share/domain` → errori di compilazione (classi mancanti).

- [ ] **Step 4: Implementare entità, interfaccia e use case.** Use case: grafia = primo nome in `cachedBooks.expand((b) => b.shelves)` con `ShelfNames.same`, altrimenti `shelf.shelfName`; per ogni libro, in sequenza, `findCachedByExternalId` → se assente `add` poi `update(added.copyWith(shelves: [name]))`; se presente e già taggato salta; se a `maxPerBook` salta; altrimenti `update` con tag aggiunto.

- [ ] **Step 5: Run test → PASS** — `flutter test test/features/shelf_share/domain`

- [ ] **Step 6: Checkpoint commit (utente)**

---

### Task 3: Data — datasource, mapper, repository impl, DI, error mapping

**Files:**
- Create: `lib/features/shelf_share/data/datasources/shelf_share_remote_data_source.dart`
- Create: `lib/features/shelf_share/data/mappers/shelf_share_mapper.dart`
- Create: `lib/features/shelf_share/data/repositories/shelf_share_repository_impl.dart`
- Modify: `lib/core/errors/error_mapper.dart:89-100` (`PGRST202` → outdated)
- Modify: `lib/core/di/injection.dart` (registrazioni)
- Test: `test/features/shelf_share/data/shelf_share_mapper_test.dart`
- Test: `test/features/shelf_share/data/shelf_share_repository_impl_test.dart`
- Test: `test/core/error_mapper_test.dart` (aggiungere caso; creare se assente)

**Interfaces:**
- Consumes: Task 2 entità e `ShelfShareRepository`; `SupabaseClient`; `mapError`.
- Produces:
  - `abstract interface class ShelfShareRemoteDataSource { Future<Map<String, dynamic>?> findByShelf(String shelfName); Future<Map<String, dynamic>> insert(String shelfName); Future<void> deleteByShelf(String shelfName); Future<Map<String, dynamic>?> getShared(String token); }` — impl `SupabaseShelfShareDataSource(SupabaseClient)`, tabella `shelf_shares`, `findByShelf`/`deleteByShelf` con `.ilike('shelf_name', escaped)` (escape di `%`, `_`, `\`), `getShared` = `_client.rpc<dynamic>('get_shared_shelf', params: {'p_token': token})`.
  - `abstract final class ShelfShareMapper { static ShelfShare shareFromJson(Map<String, dynamic>); static SharedShelf sharedFromJson(Map<String, dynamic>); }`
  - `class ShelfShareRepositoryImpl implements ShelfShareRepository { ShelfShareRepositoryImpl(ShelfShareRemoteDataSource); }`
  - DI: `ShelfShareRemoteDataSource`, `ShelfShareRepository`, `SaveSharedShelf` come `registerLazySingleton`.

- [ ] **Step 1: Test mapper** — JSON della spec (con `authors` lista, `published_year` int, `owner_name` null) → `SharedShelf` con `Book(externalId: 'OL45804W', ...)`; `books: []` → lista vuota.

- [ ] **Step 2: Test repository** (mock datasource)
  - `fetchShared returns null when the rpc returns null`
  - `fetchShared returns null for an empty token` — senza chiamare il datasource.
  - `create rethrows PostgrestException as Failure` — `PostgrestException(code: 'PGRST205')` → `Failure(FailureCode.outdatedDatabase)`.
  - `revoke deletes by shelf name`.

- [ ] **Step 3: Test error mapper** — `PostgrestException(message: 'x', code: 'PGRST202')` → `FailureCode.outdatedDatabase`.

- [ ] **Step 4: Run → FAIL**: `flutter test test/features/shelf_share/data test/core/error_mapper_test.dart`

- [ ] **Step 5: Implementare** datasource, mapper, repo (`try { ... } catch (e) { throw mapError(e); }` come `QuoteRepositoryImpl`), `case 'PGRST202': // function not in the schema cache` in `_isOutdatedSchema`, registrazioni DI.

- [ ] **Step 6: Run → PASS** + `flutter analyze`

- [ ] **Step 7: Checkpoint commit (utente)**

---

### Task 4: Routing, deep link, redirect dopo login

**Files:**
- Modify: `lib/core/router/app_router.dart` (route, `AppRoutes.sharedShelf`, `authRedirect`)
- Modify: `android/app/src/main/AndroidManifest.xml:32-37`
- Modify: `test/core/auth_redirect_test.dart`

**Interfaces:**
- Consumes: `SharedShelfPage(token:)` (Task 5). Finché il Task 5 non esiste, la route punta a un `SharedShelfPage` minimo creato qui (`Scaffold` vuoto) e sostituito nel Task 5.
- Produces:
  - `static String sharedShelf(String token) => '/shared-shelf/$token';`
  - `class PendingDeepLink { String? location; }` in `app_router.dart`, istanza unica passata a `createRouter`.
  - `String? authRedirect(AuthStatus status, String location, {PendingDeepLink? pending})` — firma esistente invariata per i test vecchi.

- [ ] **Step 1: Test**
  - `unauthenticated on a shared shelf remembers it and goes to welcome` — `pending.location == '/shared-shelf/abc'`, risultato `AppRoutes.welcome`.
  - `authenticated in the auth area resumes the pending shared shelf` — con `pending.location = '/shared-shelf/abc'` → `'/shared-shelf/abc'`, poi `pending.location == null`.
  - `authenticated in the auth area without pending goes to library` — invariato.
  - `pending ignores locations other than shared shelves` — `/book/x` da non loggato non viene ricordato.

- [ ] **Step 2: Run → FAIL**: `flutter test test/core/auth_redirect_test.dart`

- [ ] **Step 3: Implementare** `PendingDeepLink`, parametro `pending`, route `GoRoute(path: '/shared-shelf/:token', builder: ... SharedShelfPage(token: state.pathParameters['token']!))` a livello root (fuori dallo shell). In `createRouter` creare `final pending = PendingDeepLink();` e passarlo.

- [ ] **Step 4: Manifest** — nello stesso intent filter del callback aggiungere `<data android:scheme="io.supabase.bookshelf" android:host="shelf"/>`; aggiornare il commento.

- [ ] **Step 5: Run → PASS** + `flutter analyze`

- [ ] **Step 6: Verifica manuale deep link** (emulatore, app installata e loggata):
  `adb shell am start -a android.intent.action.VIEW -d "io.supabase.bookshelf://shelf/shared-shelf/test123"`
  Atteso: si apre la route `/shared-shelf/test123`; nessun errore auth di `supabase_flutter` nei log.

- [ ] **Step 7: Checkpoint commit (utente)**

---

### Task 5: Destinatario — `SharedShelfCubit` + `SharedShelfPage`

**Files:**
- Create: `lib/features/shelf_share/presentation/cubit/shared_shelf_cubit.dart`
- Create: `lib/features/shelf_share/presentation/cubit/shared_shelf_state.dart`
- Create: `lib/features/shelf_share/presentation/pages/shared_shelf_page.dart` (sostituisce lo stub del Task 4)
- Modify: `lib/core/di/injection.dart` (`registerFactoryParam<SharedShelfCubit, String, void>`)
- Modify: `lib/l10n/app_it.arb`, `lib/l10n/app_en.arb`
- Modify: `test/helpers/mocks.dart` (`MockShelfShareRepository`, `MockSaveSharedShelf`)
- Test: `test/features/shelf_share/presentation/shared_shelf_cubit_test.dart`
- Test: `test/widget/shared_shelf_page_test.dart`

**Interfaces:**
- Consumes: `ShelfShareRepository.fetchShared`, `SaveSharedShelf.call`, `AppRoutes.preview(externalId)` con `extra: Book`.
- Produces:
  - `enum SharedShelfSaveStatus { idle, saving, saved, failure }`
  - `class SharedShelfState extends Equatable { RequestStatus status; SharedShelf? shelf; bool notFound; FailureCode? failure; SharedShelfSaveStatus saveStatus; int added; }`
  - `class SharedShelfCubit extends Cubit<SharedShelfState> { SharedShelfCubit(String token, ShelfShareRepository repo, SaveSharedShelf save); Future<void> load(); Future<void> saveToLibrary(); }`

- [ ] **Step 1: Test cubit** (`bloc_test`)
  - `load emits loading then success with the shelf`
  - `load emits success with notFound when the repo returns null`
  - `load emits failure with the failure code`
  - `saveToLibrary emits saving then saved with added count` (`added: 3`)
  - `saveToLibrary emits failure when save throws Failure`

- [ ] **Step 2: Run → FAIL**

- [ ] **Step 3: Implementare cubit/state.**

- [ ] **Step 4: Stringhe** (skill `add-l10n-string`), chiavi e testo IT:
  - `sharedShelfOwner`: `"Uno scaffale di {name}"`
  - `sharedShelfBookCount`: plurale `"{count, plural, =0{Nessun libro} =1{1 libro} other{{count} libri}}"`
  - `sharedShelfSave`: `"Salva nella mia libreria"`
  - `sharedShelfSaved`: `"{count, plural, =0{Era già tutto nella tua libreria} =1{1 libro aggiunto} other{{count} libri aggiunti}}"`
  - `sharedShelfNotFound`: `"Questo scaffale non è più condiviso"`
  - `sharedShelfEmpty`: `"Lo scaffale è vuoto"`

- [ ] **Step 5: Implementare `SharedShelfPage(token:)`** — `BlocProvider(create: (_) => getIt<SharedShelfCubit>(param1: token)..load())`; AppBar col nome scaffale; sottotitolo owner (se non null) + conteggio; griglia copertine (riusare il widget copertina usato in `explore_genre_page.dart`); tap → `context.push(AppRoutes.preview(b.externalId), extra: b)`; `FilledButton` "Salva" disabilitato durante `saving` e se lista vuota; `SnackBar` con `sharedShelfSaved(added)`; stati: skeleton, `failureMessage` + riprova, `sharedShelfNotFound`, `sharedShelfEmpty`.

- [ ] **Step 6: Widget test** (`tester.pumpApp`, cubit mockato via `MockCubit` o getIt override)
  - `shows title, owner and books`
  - `shows not found message`
  - `tapping save calls saveToLibrary`

- [ ] **Step 7: Run → PASS** + `flutter analyze`

- [ ] **Step 8: Checkpoint commit (utente)**

---

### Task 6: Proprietario — `ShelfShareCubit`, sheet, card, ingresso in libreria

**Files:**
- Create: `lib/features/shelf_share/presentation/cubit/shelf_share_cubit.dart`
- Create: `lib/features/shelf_share/presentation/cubit/shelf_share_state.dart`
- Create: `lib/features/shelf_share/presentation/widgets/shelf_share_sheet.dart`
- Create: `lib/features/shelf_share/presentation/widgets/shelf_share_card.dart`
- Modify: `lib/features/library/presentation/pages/library_page.dart:146-185` (`_ShelfFilterChip`: azione condividi accanto al chip scaffale)
- Modify: `lib/core/di/injection.dart` (`registerFactoryParam<ShelfShareCubit, String, void>`)
- Modify: `lib/l10n/app_it.arb`, `lib/l10n/app_en.arb`
- Test: `test/features/shelf_share/presentation/shelf_share_cubit_test.dart`
- Test: `test/widget/shelf_share_sheet_test.dart`

**Interfaces:**
- Consumes: `ShelfShareRepository.shareFor/create/revoke`; `ShelfShare.webUrl`; `LibraryBloc.state` (libri dello scaffale per la card); `share_card_parts.dart` (`shareInk`, `shareCardSize`, helpers) come `recap_share_card.dart`.
- Produces:
  - `class ShelfShareState extends Equatable { RequestStatus status; ShelfShare? share; bool busy; FailureCode? failure; }`
  - `class ShelfShareCubit extends Cubit<ShelfShareState> { ShelfShareCubit(String shelfName, ShelfShareRepository repo); Future<void> load(); Future<ShelfShare?> ensureShare(); Future<void> regenerate(); Future<void> stop(); }` — `ensureShare` crea il link se manca e lo ritorna.
  - `Future<void> showShelfShareSheet(BuildContext context, String shelfName)`
  - `class ShelfShareCard extends StatelessWidget { const ShelfShareCard({required String shelfName, required List<UserBook> books}); }`

- [ ] **Step 1: Test cubit**
  - `load emits success with existing share` / `with null when not shared`
  - `ensureShare creates when missing and returns it`
  - `ensureShare reuses existing without calling create`
  - `regenerate revokes then creates` (verifica ordine con `verifyInOrder`)
  - `stop revokes and clears share`
  - `create failure emits failure code and busy false`

- [ ] **Step 2: Run → FAIL**

- [ ] **Step 3: Implementare cubit/state.**

- [ ] **Step 4: Stringhe** (IT):
  - `shelfShareAction`: `"Condividi scaffale"`
  - `shelfShareSheetTitle`: `"Condividi «{name}»"`
  - `shelfShareSend`: `"Condividi"`
  - `shelfShareCopy`: `"Copia link"`
  - `shelfShareCopied`: `"Link copiato"`
  - `shelfShareRegenerate`: `"Nuovo link"`
  - `shelfShareRegenerateHint`: `"Il link precedente smetterà di funzionare"`
  - `shelfShareStop`: `"Interrompi condivisione"`
  - `shelfShareStopped`: `"Condivisione interrotta"`
  - `shelfShareMessage`: `"Guarda il mio scaffale «{name}» su BookShelf: {url}"`
  - `shelfShareInfo`: `"Chi ha il link vede titoli e copertine, non voti, note o progressi."`

- [ ] **Step 5: Implementare `ShelfShareCard`** (fino a 6 copertine, nome scaffale, `sharedShelfBookCount`, "via BookShelf", stile `recap_share_card.dart`) e `ShelfShareSheet`: `Condividi` → `ensureShare` → render card a PNG come `RecapPage._share` → `SharePlus.instance.share(ShareParams(files: [...], text: shelfShareMessage(name, url)))`; `Copia link` → `Clipboard.setData`; `Nuovo link` (con hint) e `Interrompi` (con conferma `AlertDialog`) visibili solo se `share != null`; `shelfShareInfo` in fondo.

- [ ] **Step 6: Ingresso** — in `_ShelfFilterChip`, quando `shelf != null`, `IconButton(icon: Icon(Icons.ios_share_rounded), tooltip: l10n.shelfShareAction, onPressed: () => showShelfShareSheet(context, shelf))` accanto al chip.

- [ ] **Step 7: Widget test sheet**
  - `shows only share and copy when not shared yet`
  - `shows regenerate and stop when shared`
  - `stop asks for confirmation before revoking`

- [ ] **Step 8: Run → PASS** + `flutter analyze`

- [ ] **Step 9: Checkpoint commit (utente)**

---

### Task 7: Pagina web + GitHub Pages

**Files:**
- Create: `share_site/index.html` (presentazione minima dell'app)
- Create: `share_site/s/index.html`
- Create: `share_site/s/config.js` (`window.BOOKSHELF = { supabaseUrl: '', anonKey: '' }`, l'utente compila con i valori pubblici del `.env`)
- Create: `share_site/.nojekyll`
- Create: `.github/workflows/pages.yml`

**Interfaces:**
- Consumes: RPC `get_shared_shelf` (Task 1), link app (Task 2 `shelfShareAppUrl`).

- [ ] **Step 1: `s/index.html`** — legge `new URLSearchParams(location.search).get('t')`; se vuoto → stato "non più condiviso"; altrimenti `fetch(`${supabaseUrl}/rest/v1/rpc/get_shared_shelf`, {method: 'POST', headers: {apikey, Authorization: `Bearer ${anonKey}`, 'Content-Type': 'application/json'}, body: JSON.stringify({p_token: t})})`; risposta `null` → "non più condiviso"; errore rete → "Impossibile caricare, riprova"; altrimenti titolo, "Uno scaffale di {owner_name}" (se presente), griglia copertine con titolo e autori, "Lo scaffale è vuoto" se `books` vuoto. Pulsante "Apri in BookShelf" → `io.supabase.bookshelf://shelf/shared-shelf/${encodeURIComponent(t)}`. Testo inserito via `textContent` (mai `innerHTML` con dati DB). Meta OG statici: titolo "Uno scaffale condiviso su BookShelf". `prefers-color-scheme` chiaro/scuro. Lingua `it`.

- [ ] **Step 2: Workflow** — trigger `push` su `master` con `paths: ['share_site/**', '.github/workflows/pages.yml']` + `workflow_dispatch`; permessi `pages: write`, `id-token: write`, `contents: read`; job con `actions/checkout@v4`, `actions/configure-pages@v5`, `actions/upload-pages-artifact@v3` (`path: share_site`), `actions/deploy-pages@v4`.

- [ ] **Step 3: Verifica locale** — `python3 -m http.server -d share_site 8080` in background; aprire `http://localhost:8080/s/?t=nope` → "non più condiviso"; con un token reale creato dall'app → lista libri. Fermare il server.

- [ ] **Step 4: Prerequisiti utente** — repo pubblico; Settings → Pages → Source "GitHub Actions"; compilare `config.js`.

- [ ] **Step 5: Checkpoint commit (utente)**

---

### Task 8: Verifica finale

- [ ] **Step 1:** `flutter analyze` → `No issues found!`
- [ ] **Step 2:** `flutter test` → tutti verdi.
- [ ] **Step 3: End-to-end manuale** (emulatore): filtra libreria su uno scaffale → icona condividi → "Condividi" crea link e apre lo share sheet con immagine + testo; apri il link web → lista; "Apri in BookShelf" → `SharedShelfPage`; "Salva nella mia libreria" con un secondo account → libri in *Da leggere* con tag; "Interrompi condivisione" → link web mostra "non più condiviso".
- [ ] **Step 4:** agente `rls-reviewer` su SQL + `shelf_share_remote_data_source.dart`.
- [ ] **Step 5:** riepilogo all'utente con `git status --short`; l'utente committa.
