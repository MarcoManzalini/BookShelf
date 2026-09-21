import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('it')
  ];

  /// No description provided for @appTitle.
  ///
  /// In it, this message translates to:
  /// **'BookShelf'**
  String get appTitle;

  /// No description provided for @tabLibrary.
  ///
  /// In it, this message translates to:
  /// **'Scaffale'**
  String get tabLibrary;

  /// No description provided for @tabSearch.
  ///
  /// In it, this message translates to:
  /// **'Cerca'**
  String get tabSearch;

  /// No description provided for @tabProfile.
  ///
  /// In it, this message translates to:
  /// **'Profilo'**
  String get tabProfile;

  /// No description provided for @retry.
  ///
  /// In it, this message translates to:
  /// **'Riprova'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In it, this message translates to:
  /// **'Annulla'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In it, this message translates to:
  /// **'Salva'**
  String get save;

  /// No description provided for @remove.
  ///
  /// In it, this message translates to:
  /// **'Rimuovi'**
  String get remove;

  /// No description provided for @clear.
  ///
  /// In it, this message translates to:
  /// **'Cancella'**
  String get clear;

  /// No description provided for @offlineTitle.
  ///
  /// In it, this message translates to:
  /// **'Sei offline'**
  String get offlineTitle;

  /// No description provided for @errorTitle.
  ///
  /// In it, this message translates to:
  /// **'Qualcosa è andato storto'**
  String get errorTitle;

  /// No description provided for @errorNetwork.
  ///
  /// In it, this message translates to:
  /// **'Nessuna connessione a internet. Controlla la rete e riprova.'**
  String get errorNetwork;

  /// No description provided for @errorTimeout.
  ///
  /// In it, this message translates to:
  /// **'La richiesta ha impiegato troppo tempo. Riprova.'**
  String get errorTimeout;

  /// No description provided for @errorServer.
  ///
  /// In it, this message translates to:
  /// **'Il servizio non risponde correttamente. Riprova tra poco.'**
  String get errorServer;

  /// No description provided for @errorNotFound.
  ///
  /// In it, this message translates to:
  /// **'Elemento non trovato.'**
  String get errorNotFound;

  /// No description provided for @errorUnauthorized.
  ///
  /// In it, this message translates to:
  /// **'Sessione scaduta o permessi insufficienti. Accedi di nuovo.'**
  String get errorUnauthorized;

  /// No description provided for @errorInvalidCredentials.
  ///
  /// In it, this message translates to:
  /// **'Email o password non corrette.'**
  String get errorInvalidCredentials;

  /// No description provided for @errorEmailNotConfirmed.
  ///
  /// In it, this message translates to:
  /// **'Conferma prima il tuo indirizzo email dal link che ti abbiamo inviato.'**
  String get errorEmailNotConfirmed;

  /// No description provided for @errorUserAlreadyExists.
  ///
  /// In it, this message translates to:
  /// **'Esiste già un account con questa email.'**
  String get errorUserAlreadyExists;

  /// No description provided for @errorWeakPassword.
  ///
  /// In it, this message translates to:
  /// **'La password è troppo debole.'**
  String get errorWeakPassword;

  /// No description provided for @errorRateLimited.
  ///
  /// In it, this message translates to:
  /// **'Troppe richieste. Attendi un momento e riprova.'**
  String get errorRateLimited;

  /// No description provided for @errorUnknown.
  ///
  /// In it, this message translates to:
  /// **'Errore imprevisto. Riprova.'**
  String get errorUnknown;

  /// No description provided for @statusWantToRead.
  ///
  /// In it, this message translates to:
  /// **'Da leggere'**
  String get statusWantToRead;

  /// No description provided for @statusReading.
  ///
  /// In it, this message translates to:
  /// **'In lettura'**
  String get statusReading;

  /// No description provided for @statusRead.
  ///
  /// In it, this message translates to:
  /// **'Letto'**
  String get statusRead;

  /// No description provided for @addToLibraryAs.
  ///
  /// In it, this message translates to:
  /// **'Aggiungi alla libreria come'**
  String get addToLibraryAs;

  /// No description provided for @loginTitle.
  ///
  /// In it, this message translates to:
  /// **'Bentornato'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Accedi per ritrovare la tua libreria.'**
  String get loginSubtitle;

  /// No description provided for @registerTitle.
  ///
  /// In it, this message translates to:
  /// **'Crea il tuo account'**
  String get registerTitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Tieni traccia di ogni libro che leggi.'**
  String get registerSubtitle;

  /// No description provided for @emailLabel.
  ///
  /// In it, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In it, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In it, this message translates to:
  /// **'Conferma password'**
  String get confirmPasswordLabel;

  /// No description provided for @newPasswordLabel.
  ///
  /// In it, this message translates to:
  /// **'Nuova password'**
  String get newPasswordLabel;

  /// No description provided for @displayNameLabel.
  ///
  /// In it, this message translates to:
  /// **'Nome visualizzato'**
  String get displayNameLabel;

  /// No description provided for @loginButton.
  ///
  /// In it, this message translates to:
  /// **'Accedi'**
  String get loginButton;

  /// No description provided for @registerButton.
  ///
  /// In it, this message translates to:
  /// **'Registrati'**
  String get registerButton;

  /// No description provided for @noAccountPrompt.
  ///
  /// In it, this message translates to:
  /// **'Non hai un account?'**
  String get noAccountPrompt;

  /// No description provided for @haveAccountPrompt.
  ///
  /// In it, this message translates to:
  /// **'Hai già un account?'**
  String get haveAccountPrompt;

  /// No description provided for @forgotPasswordLink.
  ///
  /// In it, this message translates to:
  /// **'Password dimenticata?'**
  String get forgotPasswordLink;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In it, this message translates to:
  /// **'Recupera password'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Ti invieremo un link per impostare una nuova password.'**
  String get forgotPasswordSubtitle;

  /// No description provided for @sendResetLink.
  ///
  /// In it, this message translates to:
  /// **'Invia link'**
  String get sendResetLink;

  /// No description provided for @resetLinkSent.
  ///
  /// In it, this message translates to:
  /// **'Se l\'email è registrata, riceverai un link per reimpostare la password.'**
  String get resetLinkSent;

  /// No description provided for @confirmationEmailSent.
  ///
  /// In it, this message translates to:
  /// **'Registrazione completata. Controlla la tua email per confermare l\'account.'**
  String get confirmationEmailSent;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In it, this message translates to:
  /// **'Nuova password'**
  String get resetPasswordTitle;

  /// No description provided for @resetPasswordSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Scegli una nuova password per il tuo account.'**
  String get resetPasswordSubtitle;

  /// No description provided for @updatePasswordButton.
  ///
  /// In it, this message translates to:
  /// **'Aggiorna password'**
  String get updatePasswordButton;

  /// No description provided for @passwordUpdated.
  ///
  /// In it, this message translates to:
  /// **'Password aggiornata.'**
  String get passwordUpdated;

  /// No description provided for @continueWithGoogle.
  ///
  /// In it, this message translates to:
  /// **'Continua con Google'**
  String get continueWithGoogle;

  /// No description provided for @continueWithApple.
  ///
  /// In it, this message translates to:
  /// **'Continua con Apple'**
  String get continueWithApple;

  /// No description provided for @validationRequired.
  ///
  /// In it, this message translates to:
  /// **'Campo obbligatorio'**
  String get validationRequired;

  /// No description provided for @validationEmail.
  ///
  /// In it, this message translates to:
  /// **'Inserisci un indirizzo email valido'**
  String get validationEmail;

  /// No description provided for @validationPasswordShort.
  ///
  /// In it, this message translates to:
  /// **'Almeno {min} caratteri'**
  String validationPasswordShort(int min);

  /// No description provided for @validationPasswordMismatch.
  ///
  /// In it, this message translates to:
  /// **'Le password non coincidono'**
  String get validationPasswordMismatch;

  /// No description provided for @validationPageInvalid.
  ///
  /// In it, this message translates to:
  /// **'Numero di pagina non valido'**
  String get validationPageInvalid;

  /// No description provided for @libraryTitle.
  ///
  /// In it, this message translates to:
  /// **'Bookshelf'**
  String get libraryTitle;

  /// No description provided for @filterAll.
  ///
  /// In it, this message translates to:
  /// **'Tutti'**
  String get filterAll;

  /// No description provided for @viewSwipe.
  ///
  /// In it, this message translates to:
  /// **'Vista a scorrimento'**
  String get viewSwipe;

  /// No description provided for @viewShelf.
  ///
  /// In it, this message translates to:
  /// **'Vista scaffale'**
  String get viewShelf;

  /// No description provided for @filterTitle.
  ///
  /// In it, this message translates to:
  /// **'Filtra la libreria'**
  String get filterTitle;

  /// No description provided for @libraryEmptyTitle.
  ///
  /// In it, this message translates to:
  /// **'Lo scaffale è vuoto'**
  String get libraryEmptyTitle;

  /// No description provided for @libraryEmptyMessage.
  ///
  /// In it, this message translates to:
  /// **'Cerca un libro e mettilo sullo scaffale: da qui segui ogni lettura.'**
  String get libraryEmptyMessage;

  /// No description provided for @libraryEmptyCta.
  ///
  /// In it, this message translates to:
  /// **'Cerca un libro'**
  String get libraryEmptyCta;

  /// No description provided for @libraryFilterEmptyTitle.
  ///
  /// In it, this message translates to:
  /// **'Nessun libro qui'**
  String get libraryFilterEmptyTitle;

  /// No description provided for @libraryFilterEmptyMessage.
  ///
  /// In it, this message translates to:
  /// **'Non ci sono libri con questo stato.'**
  String get libraryFilterEmptyMessage;

  /// No description provided for @pagesProgress.
  ///
  /// In it, this message translates to:
  /// **'{current} / {total} pagine'**
  String pagesProgress(int current, int total);

  /// No description provided for @currentPageOnly.
  ///
  /// In it, this message translates to:
  /// **'Pagina {current}'**
  String currentPageOnly(int current);

  /// No description provided for @searchTitle.
  ///
  /// In it, this message translates to:
  /// **'Esplora'**
  String get searchTitle;

  /// No description provided for @searchHint.
  ///
  /// In it, this message translates to:
  /// **'Titolo, autore o ISBN'**
  String get searchHint;

  /// No description provided for @searchNoResultsTitle.
  ///
  /// In it, this message translates to:
  /// **'Nessun risultato'**
  String get searchNoResultsTitle;

  /// No description provided for @searchNoResultsMessage.
  ///
  /// In it, this message translates to:
  /// **'Nessun libro trovato per «{query}». Prova con altre parole.'**
  String searchNoResultsMessage(String query);

  /// No description provided for @addToLibrary.
  ///
  /// In it, this message translates to:
  /// **'Aggiungi alla libreria'**
  String get addToLibrary;

  /// No description provided for @added.
  ///
  /// In it, this message translates to:
  /// **'Aggiunto'**
  String get added;

  /// No description provided for @description.
  ///
  /// In it, this message translates to:
  /// **'Descrizione'**
  String get description;

  /// No description provided for @details.
  ///
  /// In it, this message translates to:
  /// **'Dettagli'**
  String get details;

  /// No description provided for @subjects.
  ///
  /// In it, this message translates to:
  /// **'Categorie'**
  String get subjects;

  /// No description provided for @showMore.
  ///
  /// In it, this message translates to:
  /// **'Mostra di più'**
  String get showMore;

  /// No description provided for @showLess.
  ///
  /// In it, this message translates to:
  /// **'Mostra meno'**
  String get showLess;

  /// No description provided for @publisher.
  ///
  /// In it, this message translates to:
  /// **'Editore'**
  String get publisher;

  /// No description provided for @publishedYear.
  ///
  /// In it, this message translates to:
  /// **'Anno'**
  String get publishedYear;

  /// No description provided for @isbn.
  ///
  /// In it, this message translates to:
  /// **'ISBN'**
  String get isbn;

  /// No description provided for @pages.
  ///
  /// In it, this message translates to:
  /// **'Pagine'**
  String get pages;

  /// No description provided for @language.
  ///
  /// In it, this message translates to:
  /// **'Lingua'**
  String get language;

  /// No description provided for @myProgress.
  ///
  /// In it, this message translates to:
  /// **'Il mio progresso'**
  String get myProgress;

  /// No description provided for @currentPage.
  ///
  /// In it, this message translates to:
  /// **'Pagina corrente'**
  String get currentPage;

  /// No description provided for @editCurrentPage.
  ///
  /// In it, this message translates to:
  /// **'Modifica pagina corrente'**
  String get editCurrentPage;

  /// No description provided for @pageOfTotal.
  ///
  /// In it, this message translates to:
  /// **'Pagina {current} di {total}'**
  String pageOfTotal(int current, int total);

  /// No description provided for @myRating.
  ///
  /// In it, this message translates to:
  /// **'Il mio voto'**
  String get myRating;

  /// No description provided for @readingDates.
  ///
  /// In it, this message translates to:
  /// **'Date di lettura'**
  String get readingDates;

  /// No description provided for @startedOn.
  ///
  /// In it, this message translates to:
  /// **'Iniziato il'**
  String get startedOn;

  /// No description provided for @finishedOn.
  ///
  /// In it, this message translates to:
  /// **'Finito il'**
  String get finishedOn;

  /// No description provided for @notSet.
  ///
  /// In it, this message translates to:
  /// **'Non impostata'**
  String get notSet;

  /// No description provided for @notes.
  ///
  /// In it, this message translates to:
  /// **'Note personali'**
  String get notes;

  /// No description provided for @notesHint.
  ///
  /// In it, this message translates to:
  /// **'Scrivi qui i tuoi appunti…'**
  String get notesHint;

  /// No description provided for @removeBook.
  ///
  /// In it, this message translates to:
  /// **'Rimuovi dalla libreria'**
  String get removeBook;

  /// No description provided for @removeBookTitle.
  ///
  /// In it, this message translates to:
  /// **'Rimuovere il libro?'**
  String get removeBookTitle;

  /// No description provided for @removeBookMessage.
  ///
  /// In it, this message translates to:
  /// **'«{title}» verrà rimosso dalla tua libreria, insieme a voto e note.'**
  String removeBookMessage(String title);

  /// No description provided for @bookRemoved.
  ///
  /// In it, this message translates to:
  /// **'Libro rimosso dalla libreria'**
  String get bookRemoved;

  /// No description provided for @profileTitle.
  ///
  /// In it, this message translates to:
  /// **'Profilo'**
  String get profileTitle;

  /// No description provided for @profileUpdated.
  ///
  /// In it, this message translates to:
  /// **'Profilo aggiornato'**
  String get profileUpdated;

  /// No description provided for @avatarUpdated.
  ///
  /// In it, this message translates to:
  /// **'Foto profilo aggiornata'**
  String get avatarUpdated;

  /// No description provided for @editDisplayName.
  ///
  /// In it, this message translates to:
  /// **'Modifica nome'**
  String get editDisplayName;

  /// No description provided for @changePassword.
  ///
  /// In it, this message translates to:
  /// **'Cambia password'**
  String get changePassword;

  /// No description provided for @theme.
  ///
  /// In it, this message translates to:
  /// **'Tema'**
  String get theme;

  /// No description provided for @themeSystem.
  ///
  /// In it, this message translates to:
  /// **'Sistema'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In it, this message translates to:
  /// **'Chiaro'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In it, this message translates to:
  /// **'Scuro'**
  String get themeDark;

  /// No description provided for @statBooksRead.
  ///
  /// In it, this message translates to:
  /// **'Libri letti'**
  String get statBooksRead;

  /// No description provided for @statPagesRead.
  ///
  /// In it, this message translates to:
  /// **'Pagine lette'**
  String get statPagesRead;

  /// No description provided for @statBooksThisYear.
  ///
  /// In it, this message translates to:
  /// **'Letti quest\'anno'**
  String get statBooksThisYear;

  /// No description provided for @logout.
  ///
  /// In it, this message translates to:
  /// **'Esci'**
  String get logout;

  /// No description provided for @logoutTitle.
  ///
  /// In it, this message translates to:
  /// **'Uscire dall\'account?'**
  String get logoutTitle;

  /// No description provided for @logoutMessage.
  ///
  /// In it, this message translates to:
  /// **'Dovrai accedere di nuovo per vedere la tua libreria.'**
  String get logoutMessage;

  /// No description provided for @deleteAccount.
  ///
  /// In it, this message translates to:
  /// **'Elimina account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In it, this message translates to:
  /// **'Eliminare l\'account?'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountMessage.
  ///
  /// In it, this message translates to:
  /// **'Verranno cancellati definitivamente il tuo profilo, la tua libreria, i voti e le note. L\'operazione non può essere annullata.'**
  String get deleteAccountMessage;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In it, this message translates to:
  /// **'Elimina definitivamente'**
  String get deleteAccountConfirm;

  /// No description provided for @aboutAuthor.
  ///
  /// In it, this message translates to:
  /// **'Sull\'autore'**
  String get aboutAuthor;

  /// No description provided for @moreByAuthor.
  ///
  /// In it, this message translates to:
  /// **'Altri libri di {author}'**
  String moreByAuthor(String author);

  /// No description provided for @similarBooks.
  ///
  /// In it, this message translates to:
  /// **'Libri simili'**
  String get similarBooks;

  /// No description provided for @authorWorkCount.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, =1{1 opera} other{{count} opere}}'**
  String authorWorkCount(int count);

  /// No description provided for @ratingSummary.
  ///
  /// In it, this message translates to:
  /// **'{average} su 5 · {count, plural, =1{1 valutazione} other{{count} valutazioni}}'**
  String ratingSummary(String average, int count);

  /// No description provided for @exploreBestSellers.
  ///
  /// In it, this message translates to:
  /// **'Best seller'**
  String get exploreBestSellers;

  /// No description provided for @exploreNewArrivals.
  ///
  /// In it, this message translates to:
  /// **'Novità'**
  String get exploreNewArrivals;

  /// No description provided for @explorePopular.
  ///
  /// In it, this message translates to:
  /// **'Più apprezzati'**
  String get explorePopular;

  /// No description provided for @exploreForYou.
  ///
  /// In it, this message translates to:
  /// **'In base alle tue ultime letture'**
  String get exploreForYou;

  /// No description provided for @exploreForYouHint.
  ///
  /// In it, this message translates to:
  /// **'Simili ai libri che hai finito da poco'**
  String get exploreForYouHint;

  /// No description provided for @exploreRankedHint.
  ///
  /// In it, this message translates to:
  /// **'Classifica per voto e numero di valutazioni'**
  String get exploreRankedHint;

  /// No description provided for @exploreTopByGenre.
  ///
  /// In it, this message translates to:
  /// **'Migliori per genere'**
  String get exploreTopByGenre;

  /// No description provided for @genreFantasy.
  ///
  /// In it, this message translates to:
  /// **'Fantasy'**
  String get genreFantasy;

  /// No description provided for @genreScienceFiction.
  ///
  /// In it, this message translates to:
  /// **'Fantascienza'**
  String get genreScienceFiction;

  /// No description provided for @genreMystery.
  ///
  /// In it, this message translates to:
  /// **'Giallo'**
  String get genreMystery;

  /// No description provided for @genreThriller.
  ///
  /// In it, this message translates to:
  /// **'Thriller'**
  String get genreThriller;

  /// No description provided for @genreRomance.
  ///
  /// In it, this message translates to:
  /// **'Romance'**
  String get genreRomance;

  /// No description provided for @genreHistoricalFiction.
  ///
  /// In it, this message translates to:
  /// **'Romanzo storico'**
  String get genreHistoricalFiction;

  /// No description provided for @genreHorror.
  ///
  /// In it, this message translates to:
  /// **'Horror'**
  String get genreHorror;

  /// No description provided for @genreClassics.
  ///
  /// In it, this message translates to:
  /// **'Classici'**
  String get genreClassics;

  /// No description provided for @genreBiography.
  ///
  /// In it, this message translates to:
  /// **'Biografie'**
  String get genreBiography;

  /// No description provided for @genreYoungAdult.
  ///
  /// In it, this message translates to:
  /// **'Young adult'**
  String get genreYoungAdult;

  /// No description provided for @viewAll.
  ///
  /// In it, this message translates to:
  /// **'Vedi tutti'**
  String get viewAll;

  /// No description provided for @scanTitle.
  ///
  /// In it, this message translates to:
  /// **'Scansiona ISBN'**
  String get scanTitle;

  /// No description provided for @scanHint.
  ///
  /// In it, this message translates to:
  /// **'Inquadra il codice a barre sul retro del libro'**
  String get scanHint;

  /// No description provided for @scanLooking.
  ///
  /// In it, this message translates to:
  /// **'Cerco il libro…'**
  String get scanLooking;

  /// No description provided for @scanNotFound.
  ///
  /// In it, this message translates to:
  /// **'Nessun libro trovato per l\'ISBN {isbn}'**
  String scanNotFound(String isbn);

  /// No description provided for @scanAgain.
  ///
  /// In it, this message translates to:
  /// **'Scansiona un altro'**
  String get scanAgain;

  /// No description provided for @scanDetails.
  ///
  /// In it, this message translates to:
  /// **'Dettagli'**
  String get scanDetails;

  /// No description provided for @scanTorch.
  ///
  /// In it, this message translates to:
  /// **'Torcia'**
  String get scanTorch;

  /// No description provided for @scanCameraDenied.
  ///
  /// In it, this message translates to:
  /// **'Per scansionare i codici a barre serve l\'accesso alla fotocamera. Abilitalo dalle impostazioni del telefono.'**
  String get scanCameraDenied;

  /// No description provided for @scanCameraError.
  ///
  /// In it, this message translates to:
  /// **'Impossibile avviare la fotocamera.'**
  String get scanCameraError;

  /// No description provided for @shelvesTitle.
  ///
  /// In it, this message translates to:
  /// **'Scaffali'**
  String get shelvesTitle;

  /// No description provided for @addShelf.
  ///
  /// In it, this message translates to:
  /// **'Aggiungi scaffale'**
  String get addShelf;

  /// No description provided for @newShelfHint.
  ///
  /// In it, this message translates to:
  /// **'Nuovo scaffale (es. Regali)'**
  String get newShelfHint;

  /// No description provided for @myShelves.
  ///
  /// In it, this message translates to:
  /// **'I miei scaffali'**
  String get myShelves;

  /// No description provided for @shelfFilterLabel.
  ///
  /// In it, this message translates to:
  /// **'Scaffale: {name}'**
  String shelfFilterLabel(String name);

  /// No description provided for @editionTitle.
  ///
  /// In it, this message translates to:
  /// **'Scegli l\'edizione'**
  String get editionTitle;

  /// No description provided for @editionChange.
  ///
  /// In it, this message translates to:
  /// **'Cambia edizione'**
  String get editionChange;

  /// No description provided for @editionNone.
  ///
  /// In it, this message translates to:
  /// **'Nessuna edizione trovata per questa lingua.'**
  String get editionNone;

  /// No description provided for @pagesCount.
  ///
  /// In it, this message translates to:
  /// **'{count} pagine'**
  String pagesCount(int count);

  /// No description provided for @statsTitle.
  ///
  /// In it, this message translates to:
  /// **'Statistiche'**
  String get statsTitle;

  /// No description provided for @statsGoalTitle.
  ///
  /// In it, this message translates to:
  /// **'Obiettivo {year}'**
  String statsGoalTitle(int year);

  /// No description provided for @statsGoalProgress.
  ///
  /// In it, this message translates to:
  /// **'{read} di {goal} libri'**
  String statsGoalProgress(int read, int goal);

  /// No description provided for @statsGoalSet.
  ///
  /// In it, this message translates to:
  /// **'Imposta un obiettivo annuale'**
  String get statsGoalSet;

  /// No description provided for @statsGoalEdit.
  ///
  /// In it, this message translates to:
  /// **'Modifica'**
  String get statsGoalEdit;

  /// No description provided for @statsGoalRemove.
  ///
  /// In it, this message translates to:
  /// **'Rimuovi obiettivo'**
  String get statsGoalRemove;

  /// No description provided for @statsGoalDialogTitle.
  ///
  /// In it, this message translates to:
  /// **'Quanti libri vuoi leggere quest\'anno?'**
  String get statsGoalDialogTitle;

  /// No description provided for @statsGoalHint.
  ///
  /// In it, this message translates to:
  /// **'Numero di libri'**
  String get statsGoalHint;

  /// No description provided for @statsGoalLeft.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, =1{Ne manca 1} other{Ne mancano {count}}}'**
  String statsGoalLeft(int count);

  /// No description provided for @statsGoalDone.
  ///
  /// In it, this message translates to:
  /// **'Obiettivo raggiunto!'**
  String get statsGoalDone;

  /// No description provided for @statsStreak.
  ///
  /// In it, this message translates to:
  /// **'Giorni di fila'**
  String get statsStreak;

  /// No description provided for @statsPagesPerDay.
  ///
  /// In it, this message translates to:
  /// **'Pagine al giorno'**
  String get statsPagesPerDay;

  /// No description provided for @statsTimeRead.
  ///
  /// In it, this message translates to:
  /// **'Tempo di lettura'**
  String get statsTimeRead;

  /// No description provided for @statsAvgRating.
  ///
  /// In it, this message translates to:
  /// **'Voto medio'**
  String get statsAvgRating;

  /// No description provided for @statsBooksPerMonth.
  ///
  /// In it, this message translates to:
  /// **'Libri per mese'**
  String get statsBooksPerMonth;

  /// No description provided for @statsPagesRecent.
  ///
  /// In it, this message translates to:
  /// **'Pagine, ultimi 14 giorni'**
  String get statsPagesRecent;

  /// No description provided for @statsTopSubjects.
  ///
  /// In it, this message translates to:
  /// **'Categorie più lette'**
  String get statsTopSubjects;

  /// No description provided for @statsHours.
  ///
  /// In it, this message translates to:
  /// **'{hours} h'**
  String statsHours(String hours);

  /// No description provided for @statsNoData.
  ///
  /// In it, this message translates to:
  /// **'—'**
  String get statsNoData;

  /// No description provided for @sessionRegister.
  ///
  /// In it, this message translates to:
  /// **'Registra sessione'**
  String get sessionRegister;

  /// No description provided for @sessionTitle.
  ///
  /// In it, this message translates to:
  /// **'Sessione di lettura'**
  String get sessionTitle;

  /// No description provided for @sessionStart.
  ///
  /// In it, this message translates to:
  /// **'Avvia'**
  String get sessionStart;

  /// No description provided for @sessionPause.
  ///
  /// In it, this message translates to:
  /// **'Pausa'**
  String get sessionPause;

  /// No description provided for @sessionMinutes.
  ///
  /// In it, this message translates to:
  /// **'Minuti letti'**
  String get sessionMinutes;

  /// No description provided for @sessionEndPage.
  ///
  /// In it, this message translates to:
  /// **'Pagina raggiunta'**
  String get sessionEndPage;

  /// No description provided for @sessionsRecent.
  ///
  /// In it, this message translates to:
  /// **'Sessioni recenti'**
  String get sessionsRecent;

  /// No description provided for @minutesShort.
  ///
  /// In it, this message translates to:
  /// **'{count} min'**
  String minutesShort(int count);

  /// No description provided for @offlineBanner.
  ///
  /// In it, this message translates to:
  /// **'Sei offline: vedi la copia salvata sul dispositivo.'**
  String get offlineBanner;

  /// No description provided for @offlinePending.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, =1{1 modifica} other{{count} modifiche}} da sincronizzare'**
  String offlinePending(int count);

  /// No description provided for @ioTitle.
  ///
  /// In it, this message translates to:
  /// **'Importa ed esporta'**
  String get ioTitle;

  /// No description provided for @ioImportTitle.
  ///
  /// In it, this message translates to:
  /// **'Importa da Goodreads'**
  String get ioImportTitle;

  /// No description provided for @ioImportBody.
  ///
  /// In it, this message translates to:
  /// **'Su Goodreads apri «I miei libri» → «Importa ed esporta» → «Esporta libreria», poi scegli qui il file .csv scaricato. Stato, voto, date, note e scaffali vengono ripresi.'**
  String get ioImportBody;

  /// No description provided for @ioPickFile.
  ///
  /// In it, this message translates to:
  /// **'Scegli il file CSV'**
  String get ioPickFile;

  /// No description provided for @ioFound.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, =1{Trovato 1 libro} other{Trovati {count} libri}}'**
  String ioFound(int count);

  /// No description provided for @ioFoundBreakdown.
  ///
  /// In it, this message translates to:
  /// **'{read} letti · {reading} in lettura · {wanted} da leggere'**
  String ioFoundBreakdown(int read, int reading, int wanted);

  /// No description provided for @ioSkippedLines.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, =1{1 riga senza titolo ignorata} other{{count} righe senza titolo ignorate}}'**
  String ioSkippedLines(int count);

  /// No description provided for @ioStart.
  ///
  /// In it, this message translates to:
  /// **'Importa'**
  String get ioStart;

  /// No description provided for @ioRunning.
  ///
  /// In it, this message translates to:
  /// **'Importazione in corso…'**
  String get ioRunning;

  /// No description provided for @ioRunningHint.
  ///
  /// In it, this message translates to:
  /// **'Puoi lasciare aperta questa pagina: ogni libro viene cercato su Open Library.'**
  String get ioRunningHint;

  /// No description provided for @ioCancel.
  ///
  /// In it, this message translates to:
  /// **'Interrompi'**
  String get ioCancel;

  /// No description provided for @ioImported.
  ///
  /// In it, this message translates to:
  /// **'Importati'**
  String get ioImported;

  /// No description provided for @ioDuplicates.
  ///
  /// In it, this message translates to:
  /// **'Già nella libreria'**
  String get ioDuplicates;

  /// No description provided for @ioNotFound.
  ///
  /// In it, this message translates to:
  /// **'Non trovati'**
  String get ioNotFound;

  /// No description provided for @ioFailed.
  ///
  /// In it, this message translates to:
  /// **'Non salvati'**
  String get ioFailed;

  /// No description provided for @ioDone.
  ///
  /// In it, this message translates to:
  /// **'Fatto'**
  String get ioDone;

  /// No description provided for @ioCancelled.
  ///
  /// In it, this message translates to:
  /// **'Importazione interrotta: i libri già importati restano nella libreria.'**
  String get ioCancelled;

  /// No description provided for @ioAborted.
  ///
  /// In it, this message translates to:
  /// **'Connessione persa: importazione fermata. Riprova più tardi: i libri già presenti vengono saltati.'**
  String get ioAborted;

  /// No description provided for @ioInvalidFile.
  ///
  /// In it, this message translates to:
  /// **'Questo file non sembra un\'esportazione di libri (manca la colonna «Title»).'**
  String get ioInvalidFile;

  /// No description provided for @ioTryAnother.
  ///
  /// In it, this message translates to:
  /// **'Scegli un altro file'**
  String get ioTryAnother;

  /// No description provided for @ioExportTitle.
  ///
  /// In it, this message translates to:
  /// **'Esporta la libreria'**
  String get ioExportTitle;

  /// No description provided for @ioExportBody.
  ///
  /// In it, this message translates to:
  /// **'Crea un file CSV con tutti i tuoi libri, compatibile con Goodreads e con i fogli di calcolo.'**
  String get ioExportBody;

  /// No description provided for @ioExportButton.
  ///
  /// In it, this message translates to:
  /// **'Esporta in CSV'**
  String get ioExportButton;

  /// No description provided for @ioExportEmpty.
  ///
  /// In it, this message translates to:
  /// **'Non c\'è ancora nessun libro da esportare.'**
  String get ioExportEmpty;

  /// No description provided for @ioExportError.
  ///
  /// In it, this message translates to:
  /// **'Non è stato possibile creare il file.'**
  String get ioExportError;

  /// No description provided for @ioProfileEntry.
  ///
  /// In it, this message translates to:
  /// **'Importa ed esporta'**
  String get ioProfileEntry;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
