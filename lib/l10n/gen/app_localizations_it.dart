// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'BookShelf';

  @override
  String get tabLibrary => 'Scaffale';

  @override
  String get tabSearch => 'Cerca';

  @override
  String get tabProfile => 'Profilo';

  @override
  String get retry => 'Riprova';

  @override
  String get cancel => 'Annulla';

  @override
  String get save => 'Salva';

  @override
  String get remove => 'Rimuovi';

  @override
  String get clear => 'Cancella';

  @override
  String get offlineTitle => 'Sei offline';

  @override
  String get errorTitle => 'Qualcosa è andato storto';

  @override
  String get errorNetwork =>
      'Nessuna connessione a internet. Controlla la rete e riprova.';

  @override
  String get errorTimeout => 'La richiesta ha impiegato troppo tempo. Riprova.';

  @override
  String get errorServer =>
      'Il servizio non risponde correttamente. Riprova tra poco.';

  @override
  String get errorNotFound => 'Elemento non trovato.';

  @override
  String get errorUnauthorized =>
      'Sessione scaduta o permessi insufficienti. Accedi di nuovo.';

  @override
  String get errorInvalidCredentials => 'Email o password non corrette.';

  @override
  String get errorEmailNotConfirmed =>
      'Conferma prima il tuo indirizzo email dal link che ti abbiamo inviato.';

  @override
  String get errorUserAlreadyExists =>
      'Esiste già un account con questa email.';

  @override
  String get errorWeakPassword => 'La password è troppo debole.';

  @override
  String get errorRateLimited =>
      'Troppe richieste. Attendi un momento e riprova.';

  @override
  String get errorUnknown => 'Errore imprevisto. Riprova.';

  @override
  String get statusWantToRead => 'Da leggere';

  @override
  String get statusReading => 'In lettura';

  @override
  String get statusRead => 'Letto';

  @override
  String get addToLibraryAs => 'Aggiungi alla libreria come';

  @override
  String get loginTitle => 'Bentornato';

  @override
  String get loginSubtitle => 'Accedi per ritrovare la tua libreria.';

  @override
  String get registerTitle => 'Crea il tuo account';

  @override
  String get registerSubtitle => 'Tieni traccia di ogni libro che leggi.';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get confirmPasswordLabel => 'Conferma password';

  @override
  String get newPasswordLabel => 'Nuova password';

  @override
  String get displayNameLabel => 'Nome visualizzato';

  @override
  String get loginButton => 'Accedi';

  @override
  String get registerButton => 'Registrati';

  @override
  String get noAccountPrompt => 'Non hai un account?';

  @override
  String get haveAccountPrompt => 'Hai già un account?';

  @override
  String get forgotPasswordLink => 'Password dimenticata?';

  @override
  String get forgotPasswordTitle => 'Recupera password';

  @override
  String get forgotPasswordSubtitle =>
      'Ti invieremo un link per impostare una nuova password.';

  @override
  String get sendResetLink => 'Invia link';

  @override
  String get resetLinkSent =>
      'Se l\'email è registrata, riceverai un link per reimpostare la password.';

  @override
  String get confirmationEmailSent =>
      'Registrazione completata. Controlla la tua email per confermare l\'account.';

  @override
  String get resetPasswordTitle => 'Nuova password';

  @override
  String get resetPasswordSubtitle =>
      'Scegli una nuova password per il tuo account.';

  @override
  String get updatePasswordButton => 'Aggiorna password';

  @override
  String get passwordUpdated => 'Password aggiornata.';

  @override
  String get continueWithGoogle => 'Continua con Google';

  @override
  String get continueWithApple => 'Continua con Apple';

  @override
  String get validationRequired => 'Campo obbligatorio';

  @override
  String get validationEmail => 'Inserisci un indirizzo email valido';

  @override
  String validationPasswordShort(int min) {
    return 'Almeno $min caratteri';
  }

  @override
  String get validationPasswordMismatch => 'Le password non coincidono';

  @override
  String get validationPageInvalid => 'Numero di pagina non valido';

  @override
  String get libraryTitle => 'Bookshelf';

  @override
  String get filterAll => 'Tutti';

  @override
  String get viewSwipe => 'Vista a scorrimento';

  @override
  String get viewShelf => 'Vista scaffale';

  @override
  String get filterTitle => 'Filtra la libreria';

  @override
  String get libraryEmptyTitle => 'Lo scaffale è vuoto';

  @override
  String get libraryEmptyMessage =>
      'Cerca un libro e mettilo sullo scaffale: da qui segui ogni lettura.';

  @override
  String get libraryEmptyCta => 'Cerca un libro';

  @override
  String get libraryFilterEmptyTitle => 'Nessun libro qui';

  @override
  String get libraryFilterEmptyMessage => 'Non ci sono libri con questo stato.';

  @override
  String pagesProgress(int current, int total) {
    return '$current / $total pagine';
  }

  @override
  String currentPageOnly(int current) {
    return 'Pagina $current';
  }

  @override
  String get searchTitle => 'Esplora';

  @override
  String get searchHint => 'Titolo, autore o ISBN';

  @override
  String get searchNoResultsTitle => 'Nessun risultato';

  @override
  String searchNoResultsMessage(String query) {
    return 'Nessun libro trovato per «$query». Prova con altre parole.';
  }

  @override
  String get addToLibrary => 'Aggiungi alla libreria';

  @override
  String get added => 'Aggiunto';

  @override
  String get description => 'Descrizione';

  @override
  String get details => 'Dettagli';

  @override
  String get subjects => 'Categorie';

  @override
  String get showMore => 'Mostra di più';

  @override
  String get showLess => 'Mostra meno';

  @override
  String get publisher => 'Editore';

  @override
  String get publishedYear => 'Anno';

  @override
  String get isbn => 'ISBN';

  @override
  String get pages => 'Pagine';

  @override
  String get language => 'Lingua';

  @override
  String get myProgress => 'Il mio progresso';

  @override
  String get currentPage => 'Pagina corrente';

  @override
  String get editCurrentPage => 'Modifica pagina corrente';

  @override
  String pageOfTotal(int current, int total) {
    return 'Pagina $current di $total';
  }

  @override
  String get myRating => 'Il mio voto';

  @override
  String get readingDates => 'Date di lettura';

  @override
  String get startedOn => 'Iniziato il';

  @override
  String get finishedOn => 'Finito il';

  @override
  String get notSet => 'Non impostata';

  @override
  String get notes => 'Note personali';

  @override
  String get notesHint => 'Scrivi qui i tuoi appunti…';

  @override
  String get removeBook => 'Rimuovi dalla libreria';

  @override
  String get removeBookTitle => 'Rimuovere il libro?';

  @override
  String removeBookMessage(String title) {
    return '«$title» verrà rimosso dalla tua libreria, insieme a voto e note.';
  }

  @override
  String get bookRemoved => 'Libro rimosso dalla libreria';

  @override
  String get profileTitle => 'Profilo';

  @override
  String get profileUpdated => 'Profilo aggiornato';

  @override
  String get avatarUpdated => 'Foto profilo aggiornata';

  @override
  String get editDisplayName => 'Modifica nome';

  @override
  String get changePassword => 'Cambia password';

  @override
  String get theme => 'Tema';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Chiaro';

  @override
  String get themeDark => 'Scuro';

  @override
  String get statBooksRead => 'Libri letti';

  @override
  String get statPagesRead => 'Pagine lette';

  @override
  String get statBooksThisYear => 'Letti quest\'anno';

  @override
  String get logout => 'Esci';

  @override
  String get logoutTitle => 'Uscire dall\'account?';

  @override
  String get logoutMessage =>
      'Dovrai accedere di nuovo per vedere la tua libreria.';

  @override
  String get deleteAccount => 'Elimina account';

  @override
  String get deleteAccountTitle => 'Eliminare l\'account?';

  @override
  String get deleteAccountMessage =>
      'Verranno cancellati definitivamente il tuo profilo, la tua libreria, i voti e le note. L\'operazione non può essere annullata.';

  @override
  String get deleteAccountConfirm => 'Elimina definitivamente';

  @override
  String get aboutAuthor => 'Sull\'autore';

  @override
  String moreByAuthor(String author) {
    return 'Altri libri di $author';
  }

  @override
  String get similarBooks => 'Libri simili';

  @override
  String authorWorkCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count opere',
      one: '1 opera',
    );
    return '$_temp0';
  }

  @override
  String ratingSummary(String average, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count valutazioni',
      one: '1 valutazione',
    );
    return '$average su 5 · $_temp0';
  }

  @override
  String get exploreBestSellers => 'Best seller';

  @override
  String get exploreNewArrivals => 'Novità';

  @override
  String get explorePopular => 'Più apprezzati';

  @override
  String get exploreForYou => 'In base alle tue ultime letture';

  @override
  String get exploreForYouHint => 'Simili ai libri che hai finito da poco';

  @override
  String get exploreRankedHint => 'Classifica per voto e numero di valutazioni';

  @override
  String get exploreTopByGenre => 'Migliori per genere';

  @override
  String get genreFantasy => 'Fantasy';

  @override
  String get genreScienceFiction => 'Fantascienza';

  @override
  String get genreMystery => 'Giallo';

  @override
  String get genreThriller => 'Thriller';

  @override
  String get genreRomance => 'Romance';

  @override
  String get genreHistoricalFiction => 'Romanzo storico';

  @override
  String get genreHorror => 'Horror';

  @override
  String get genreClassics => 'Classici';

  @override
  String get genreBiography => 'Biografie';

  @override
  String get genreYoungAdult => 'Young adult';

  @override
  String get viewAll => 'Vedi tutti';

  @override
  String get scanTitle => 'Scansiona ISBN';

  @override
  String get scanHint => 'Inquadra il codice a barre sul retro del libro';

  @override
  String get scanLooking => 'Cerco il libro…';

  @override
  String scanNotFound(String isbn) {
    return 'Nessun libro trovato per l\'ISBN $isbn';
  }

  @override
  String get scanAgain => 'Scansiona un altro';

  @override
  String get scanDetails => 'Dettagli';

  @override
  String get scanTorch => 'Torcia';

  @override
  String get scanCameraDenied =>
      'Per scansionare i codici a barre serve l\'accesso alla fotocamera. Abilitalo dalle impostazioni del telefono.';

  @override
  String get scanCameraError => 'Impossibile avviare la fotocamera.';

  @override
  String get shelvesTitle => 'Scaffali';

  @override
  String get addShelf => 'Aggiungi scaffale';

  @override
  String get newShelfHint => 'Nuovo scaffale (es. Regali)';

  @override
  String get myShelves => 'I miei scaffali';

  @override
  String shelfFilterLabel(String name) {
    return 'Scaffale: $name';
  }

  @override
  String get editionTitle => 'Scegli l\'edizione';

  @override
  String get editionChange => 'Cambia edizione';

  @override
  String get editionNone => 'Nessuna edizione trovata per questa lingua.';

  @override
  String pagesCount(int count) {
    return '$count pagine';
  }

  @override
  String get statsTitle => 'Statistiche';

  @override
  String statsGoalTitle(int year) {
    return 'Obiettivo $year';
  }

  @override
  String statsGoalProgress(int read, int goal) {
    return '$read di $goal libri';
  }

  @override
  String get statsGoalSet => 'Imposta un obiettivo annuale';

  @override
  String get statsGoalEdit => 'Modifica';

  @override
  String get statsGoalRemove => 'Rimuovi obiettivo';

  @override
  String get statsGoalDialogTitle => 'Quanti libri vuoi leggere quest\'anno?';

  @override
  String get statsGoalHint => 'Numero di libri';

  @override
  String statsGoalLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ne mancano $count',
      one: 'Ne manca 1',
    );
    return '$_temp0';
  }

  @override
  String get statsGoalDone => 'Obiettivo raggiunto!';

  @override
  String get statsStreak => 'Giorni di fila';

  @override
  String get statsPagesPerDay => 'Pagine al giorno';

  @override
  String get statsTimeRead => 'Tempo di lettura';

  @override
  String get statsAvgRating => 'Voto medio';

  @override
  String get statsBooksPerMonth => 'Libri per mese';

  @override
  String get statsPagesRecent => 'Pagine, ultimi 14 giorni';

  @override
  String get statsTopSubjects => 'Categorie più lette';

  @override
  String statsHours(String hours) {
    return '$hours h';
  }

  @override
  String get statsNoData => '—';

  @override
  String get sessionRegister => 'Registra sessione';

  @override
  String get sessionTitle => 'Sessione di lettura';

  @override
  String get sessionStart => 'Avvia';

  @override
  String get sessionPause => 'Pausa';

  @override
  String get sessionMinutes => 'Minuti letti';

  @override
  String get sessionEndPage => 'Pagina raggiunta';

  @override
  String get sessionsRecent => 'Sessioni recenti';

  @override
  String minutesShort(int count) {
    return '$count min';
  }

  @override
  String get offlineBanner =>
      'Sei offline: vedi la copia salvata sul dispositivo.';

  @override
  String offlinePending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count modifiche',
      one: '1 modifica',
    );
    return '$_temp0 da sincronizzare';
  }

  @override
  String get ioTitle => 'Importa ed esporta';

  @override
  String get ioImportTitle => 'Importa da Goodreads';

  @override
  String get ioImportBody =>
      'Su Goodreads apri «I miei libri» → «Importa ed esporta» → «Esporta libreria», poi scegli qui il file .csv scaricato. Stato, voto, date, note e scaffali vengono ripresi.';

  @override
  String get ioPickFile => 'Scegli il file CSV';

  @override
  String ioFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Trovati $count libri',
      one: 'Trovato 1 libro',
    );
    return '$_temp0';
  }

  @override
  String ioFoundBreakdown(int read, int reading, int wanted) {
    return '$read letti · $reading in lettura · $wanted da leggere';
  }

  @override
  String ioSkippedLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count righe senza titolo ignorate',
      one: '1 riga senza titolo ignorata',
    );
    return '$_temp0';
  }

  @override
  String get ioStart => 'Importa';

  @override
  String get ioRunning => 'Importazione in corso…';

  @override
  String get ioRunningHint =>
      'Puoi lasciare aperta questa pagina: ogni libro viene cercato su Open Library.';

  @override
  String get ioCancel => 'Interrompi';

  @override
  String get ioImported => 'Importati';

  @override
  String get ioDuplicates => 'Già nella libreria';

  @override
  String get ioNotFound => 'Non trovati';

  @override
  String get ioFailed => 'Non salvati';

  @override
  String get ioDone => 'Fatto';

  @override
  String get ioCancelled =>
      'Importazione interrotta: i libri già importati restano nella libreria.';

  @override
  String get ioAborted =>
      'Connessione persa: importazione fermata. Riprova più tardi: i libri già presenti vengono saltati.';

  @override
  String get ioInvalidFile =>
      'Questo file non sembra un\'esportazione di libri (manca la colonna «Title»).';

  @override
  String get ioTryAnother => 'Scegli un altro file';

  @override
  String get ioExportTitle => 'Esporta la libreria';

  @override
  String get ioExportBody =>
      'Crea un file CSV con tutti i tuoi libri, compatibile con Goodreads e con i fogli di calcolo.';

  @override
  String get ioExportButton => 'Esporta in CSV';

  @override
  String get ioExportEmpty => 'Non c\'è ancora nessun libro da esportare.';

  @override
  String get ioExportError => 'Non è stato possibile creare il file.';

  @override
  String get ioProfileEntry => 'Importa ed esporta';
}
