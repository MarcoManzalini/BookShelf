import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'BookShelf';

  @override
  String get tabLibrary => 'I miei libri';

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
  String get libraryTitle => 'I miei libri';

  @override
  String get filterAll => 'Tutti';

  @override
  String get viewList => 'Vista elenco';

  @override
  String get viewGrid => 'Vista griglia';

  @override
  String get libraryEmptyTitle => 'La tua libreria è vuota';

  @override
  String get libraryEmptyMessage =>
      'Cerca un libro e aggiungilo per iniziare a tenere traccia delle tue letture.';

  @override
  String get libraryEmptyCta => 'Cerca libri';

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
  String get searchTitle => 'Cerca';

  @override
  String get searchHint => 'Titolo, autore o ISBN';

  @override
  String get searchInitialTitle => 'Trova il tuo prossimo libro';

  @override
  String get searchInitialMessage =>
      'Cerca per titolo, autore o ISBN tra milioni di libri.';

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
}
