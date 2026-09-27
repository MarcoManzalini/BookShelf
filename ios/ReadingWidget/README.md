# Widget iOS (non ancora attivo)

Il codice del widget è pronto (`ReadingWidget.swift`) ma **non è collegato al
progetto Xcode**. Su iOS il widget è un'estensione separata che legge i dati
dell'app da un **App Group**, e gli App Group richiedono un account Apple
Developer a pagamento. Con il Personal Team gratuito l'app non si
installerebbe più sul telefono.

Con un account a pagamento:

1. Apri `ios/Runner.xcworkspace` in Xcode.
2. File → New → Target… → **Widget Extension**. Nome `ReadingWidget`, togli
   "Include Configuration App Intent" e "Include Live Activity". Quando Xcode
   chiede di attivare lo schema, rispondi Cancel.
3. Sostituisci il file Swift generato con `ios/ReadingWidget/ReadingWidget.swift`
   (cancella gli altri file `.swift` generati nel target).
4. Imposta il **deployment target** del widget a iOS 17 (usa
   `containerBackground`).
5. Target **Runner** → Signing & Capabilities → + Capability → **App Groups** →
   aggiungi `group.com.marcomanzalini.bookshelf`. Ripeti sul target
   **ReadingWidget** con lo stesso gruppo.
6. In `ios/Runner/Info.plist` non serve altro: l'app scrive già i dati nel
   gruppo (`ReadingWidgetSync.iOSAppGroup`) e chiede l'aggiornamento del
   widget `ReadingWidget`.
7. `flutter run` sul telefono, poi aggiungi il widget dalla schermata Home.
