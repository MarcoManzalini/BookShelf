// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'BookShelf';

  @override
  String get tabLibrary => 'Shelf';

  @override
  String get tabSearch => 'Search';

  @override
  String get tabProfile => 'Profile';

  @override
  String get retry => 'Retry';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get remove => 'Remove';

  @override
  String get clear => 'Clear';

  @override
  String get offlineTitle => 'You\'re offline';

  @override
  String get errorTitle => 'Something went wrong';

  @override
  String get errorNetwork =>
      'No internet connection. Check your network and try again.';

  @override
  String get errorTimeout => 'The request took too long. Please try again.';

  @override
  String get errorServer =>
      'The service is not responding properly. Try again shortly.';

  @override
  String get errorNotFound => 'Item not found.';

  @override
  String get errorUnauthorized =>
      'Session expired or insufficient permissions. Please sign in again.';

  @override
  String get errorInvalidCredentials => 'Incorrect email or password.';

  @override
  String get errorEmailNotConfirmed =>
      'Please confirm your email address using the link we sent you.';

  @override
  String get errorUserAlreadyExists =>
      'An account with this email already exists.';

  @override
  String get errorWeakPassword => 'The password is too weak.';

  @override
  String get errorRateLimited =>
      'Too many requests. Wait a moment and try again.';

  @override
  String get errorUnknown => 'Unexpected error. Please try again.';

  @override
  String get statusWantToRead => 'Want to read';

  @override
  String get statusReading => 'Reading';

  @override
  String get statusRead => 'Read';

  @override
  String get addToLibraryAs => 'Add to library as';

  @override
  String get welcomeTagline =>
      'Your bookshelf, always with you. Keep track of every read.';

  @override
  String get welcomeTitleFind => 'Find and organize';

  @override
  String get welcomeBodyFind =>
      'Search millions of books or scan an ISBN, then put them on your shelf.';

  @override
  String get welcomeTitleTrack => 'Read and measure';

  @override
  String get welcomeBodyTrack =>
      'Log your sessions, see your stats and share your progress.';

  @override
  String get welcomeNext => 'Next';

  @override
  String get welcomeSkip => 'Skip';

  @override
  String get welcomeSignIn => 'Sign in';

  @override
  String get welcomeStart => 'Get started';

  @override
  String get welcomeHaveAccount => 'I already have an account';

  @override
  String get loginTitle => 'Welcome back';

  @override
  String get loginSubtitle => 'Sign in to find your library again.';

  @override
  String get registerTitle => 'Create your account';

  @override
  String get registerSubtitle => 'Keep track of every book you read.';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get confirmPasswordLabel => 'Confirm password';

  @override
  String get newPasswordLabel => 'New password';

  @override
  String get displayNameLabel => 'Display name';

  @override
  String get loginButton => 'Sign in';

  @override
  String get registerButton => 'Sign up';

  @override
  String get noAccountPrompt => 'Don\'t have an account?';

  @override
  String get haveAccountPrompt => 'Already have an account?';

  @override
  String get forgotPasswordLink => 'Forgot password?';

  @override
  String get forgotPasswordTitle => 'Reset password';

  @override
  String get forgotPasswordSubtitle =>
      'We\'ll email you a link to set a new password.';

  @override
  String get sendResetLink => 'Send link';

  @override
  String get resetLinkSent =>
      'If the email is registered, you\'ll receive a link to reset your password.';

  @override
  String get confirmationEmailSent =>
      'Sign-up complete. Check your email to confirm your account.';

  @override
  String get resetPasswordTitle => 'New password';

  @override
  String get resetPasswordSubtitle => 'Choose a new password for your account.';

  @override
  String get updatePasswordButton => 'Update password';

  @override
  String get passwordUpdated => 'Password updated.';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get continueWithApple => 'Continue with Apple';

  @override
  String get validationRequired => 'Required field';

  @override
  String get validationEmail => 'Enter a valid email address';

  @override
  String validationPasswordShort(int min) {
    return 'At least $min characters';
  }

  @override
  String get validationPasswordMismatch => 'Passwords don\'t match';

  @override
  String get validationPageInvalid => 'Invalid page number';

  @override
  String get libraryTitle => 'Bookshelf';

  @override
  String get filterAll => 'All';

  @override
  String get viewSwipe => 'Swipe view';

  @override
  String get viewShelf => 'Shelf view';

  @override
  String get filterTitle => 'Filter your shelf';

  @override
  String get libraryEmptyTitle => 'Your shelf is empty';

  @override
  String get libraryEmptyMessage =>
      'Search for a book and put it on the shelf: track every read from here.';

  @override
  String get libraryEmptyCta => 'Find a book';

  @override
  String get libraryFilterEmptyTitle => 'No books here';

  @override
  String get libraryFilterEmptyMessage =>
      'There are no books with this status.';

  @override
  String pagesProgress(int current, int total) {
    return '$current / $total pages';
  }

  @override
  String currentPageOnly(int current) {
    return 'Page $current';
  }

  @override
  String get searchTitle => 'Explore';

  @override
  String get searchHint => 'Title, author or ISBN';

  @override
  String get searchNoResultsTitle => 'No results';

  @override
  String searchNoResultsMessage(String query) {
    return 'No books found for “$query”. Try different words.';
  }

  @override
  String get addToLibrary => 'Add to library';

  @override
  String get added => 'Added';

  @override
  String get description => 'Description';

  @override
  String get details => 'Details';

  @override
  String get subjects => 'Subjects';

  @override
  String get showMore => 'Show more';

  @override
  String get showLess => 'Show less';

  @override
  String get publisher => 'Publisher';

  @override
  String get publishedYear => 'Year';

  @override
  String get isbn => 'ISBN';

  @override
  String get pages => 'Pages';

  @override
  String get language => 'Language';

  @override
  String get myProgress => 'My progress';

  @override
  String get currentPage => 'Current page';

  @override
  String get editCurrentPage => 'Edit current page';

  @override
  String pageOfTotal(int current, int total) {
    return 'Page $current of $total';
  }

  @override
  String get myRating => 'My rating';

  @override
  String get readingDates => 'Reading dates';

  @override
  String get startedOn => 'Started on';

  @override
  String get finishedOn => 'Finished on';

  @override
  String get notSet => 'Not set';

  @override
  String get notes => 'Personal notes';

  @override
  String get notesHint => 'Write your notes here…';

  @override
  String get removeBook => 'Remove from library';

  @override
  String get removeBookTitle => 'Remove this book?';

  @override
  String removeBookMessage(String title) {
    return '“$title” will be removed from your library, along with its rating and notes.';
  }

  @override
  String get bookRemoved => 'Book removed from library';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileUpdated => 'Profile updated';

  @override
  String get avatarUpdated => 'Profile photo updated';

  @override
  String get editDisplayName => 'Edit name';

  @override
  String get changePassword => 'Change password';

  @override
  String get theme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get statBooksRead => 'Books read';

  @override
  String get statPagesRead => 'Pages read';

  @override
  String get statBooksThisYear => 'Read this year';

  @override
  String get logout => 'Sign out';

  @override
  String get logoutTitle => 'Sign out?';

  @override
  String get logoutMessage =>
      'You\'ll need to sign in again to see your library.';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteAccountTitle => 'Delete your account?';

  @override
  String get deleteAccountMessage =>
      'Your profile, library, ratings and notes will be permanently deleted. This cannot be undone.';

  @override
  String get deleteAccountConfirm => 'Delete permanently';

  @override
  String get aboutAuthor => 'About the author';

  @override
  String moreByAuthor(String author) {
    return 'More by $author';
  }

  @override
  String get similarBooks => 'Similar books';

  @override
  String authorWorkCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count works',
      one: '1 work',
    );
    return '$_temp0';
  }

  @override
  String ratingSummary(String average, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ratings',
      one: '1 rating',
    );
    return '$average out of 5 · $_temp0';
  }

  @override
  String get exploreBestSellers => 'Best sellers';

  @override
  String get exploreNewArrivals => 'New arrivals';

  @override
  String get explorePopular => 'Popular';

  @override
  String get exploreForYou => 'Based on your latest reads';

  @override
  String get exploreForYouHint => 'Similar to the books you finished recently';

  @override
  String get exploreRankedHint => 'Ranked by rating and number of votes';

  @override
  String get exploreTopByGenre => 'Top rated by genre';

  @override
  String get genreFantasy => 'Fantasy';

  @override
  String get genreScienceFiction => 'Science fiction';

  @override
  String get genreMystery => 'Mystery';

  @override
  String get genreThriller => 'Thriller';

  @override
  String get genreRomance => 'Romance';

  @override
  String get genreHistoricalFiction => 'Historical fiction';

  @override
  String get genreHorror => 'Horror';

  @override
  String get genreClassics => 'Classics';

  @override
  String get genreBiography => 'Biography';

  @override
  String get genreYoungAdult => 'Young adult';

  @override
  String get viewAll => 'View all';

  @override
  String get scanTitle => 'Scan ISBN';

  @override
  String get scanHint =>
      'Point the camera at the barcode on the back of the book';

  @override
  String get scanLooking => 'Looking for the book…';

  @override
  String scanNotFound(String isbn) {
    return 'No book found for ISBN $isbn';
  }

  @override
  String get scanAgain => 'Scan another';

  @override
  String get scanDetails => 'Details';

  @override
  String get scanTorch => 'Torch';

  @override
  String get scanCameraDenied =>
      'Camera access is needed to scan barcodes. Enable it in your phone settings.';

  @override
  String get scanCameraError => 'The camera could not be started.';

  @override
  String get shelvesTitle => 'Shelves';

  @override
  String get addShelf => 'Add shelf';

  @override
  String get newShelfHint => 'New shelf (e.g. Gifts)';

  @override
  String get myShelves => 'My shelves';

  @override
  String shelfFilterLabel(String name) {
    return 'Shelf: $name';
  }

  @override
  String get editionTitle => 'Choose the edition';

  @override
  String get editionChange => 'Change edition';

  @override
  String get editionNone => 'No editions found for this language.';

  @override
  String pagesCount(int count) {
    return '$count pages';
  }

  @override
  String get statsTitle => 'Statistics';

  @override
  String statsGoalTitle(int year) {
    return '$year goal';
  }

  @override
  String statsGoalProgress(int read, int goal) {
    return '$read of $goal books';
  }

  @override
  String get statsGoalSet => 'Set a yearly goal';

  @override
  String get statsGoalEdit => 'Edit';

  @override
  String get statsGoalRemove => 'Remove goal';

  @override
  String get statsGoalDialogTitle =>
      'How many books do you want to read this year?';

  @override
  String get statsGoalHint => 'Number of books';

  @override
  String statsGoalLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count to go',
      one: '1 to go',
    );
    return '$_temp0';
  }

  @override
  String get statsGoalDone => 'Goal reached!';

  @override
  String get statsStreak => 'Day streak';

  @override
  String get statsPagesPerDay => 'Pages per day';

  @override
  String get statsTimeRead => 'Reading time';

  @override
  String get statsAvgRating => 'Average rating';

  @override
  String get statsBooksPerMonth => 'Books per month';

  @override
  String get statsPagesRecent => 'Pages, last 14 days';

  @override
  String get statsTopSubjects => 'Most read categories';

  @override
  String statsHours(String hours) {
    return '$hours h';
  }

  @override
  String get statsNoData => '—';

  @override
  String get statsMonthBooksFinished => 'Books finished';

  @override
  String get statsMonthPagesRead => 'Pages read';

  @override
  String get statsMonthActiveDays => 'Active days';

  @override
  String get statsMonthNoBooks => 'No book finished this month';

  @override
  String get sessionRegister => 'Log a session';

  @override
  String get sessionTitle => 'Reading session';

  @override
  String get sessionStart => 'Start';

  @override
  String get sessionPause => 'Pause';

  @override
  String get sessionMinutes => 'Minutes read';

  @override
  String get sessionEndPage => 'Page reached';

  @override
  String get sessionSaved => 'Session logged';

  @override
  String get sessionShare => 'Share';

  @override
  String get sessionShareTitle => 'Share your session';

  @override
  String get sessionShareError => 'Couldn\'t share the image.';

  @override
  String get shareSessionLabel => 'READING SESSION';

  @override
  String get shareUnitPages => 'pages';

  @override
  String get shareUnitMin => 'min';

  @override
  String get shareUnitPagesPerHour => 'p/h';

  @override
  String shareUnitDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'days',
      one: 'day',
    );
    return '$_temp0';
  }

  @override
  String get shareLabelTime => 'TIME';

  @override
  String get shareLabelPace => 'PACE';

  @override
  String get shareLabelStreak => 'STREAK';

  @override
  String get shareLabelBook => 'BOOK';

  @override
  String get shareNowReading => 'NOW READING';

  @override
  String get shareThisWeek => 'THIS WEEK';

  @override
  String shareRange(int from, int to) {
    return 'p. $from → $to';
  }

  @override
  String sharePageAt(int page) {
    return 'p. $page';
  }

  @override
  String shareOfTotal(int percent, int total) {
    return '$percent% of $total';
  }

  @override
  String get shareReadToday => 'pages read today';

  @override
  String get shareRead => 'pages read';

  @override
  String sharePillPace(int count) {
    return '$count pages/h';
  }

  @override
  String sharePillStreak(int count) {
    return '$count-day streak';
  }

  @override
  String get shareTemplateStats => 'Stats';

  @override
  String get shareTemplatePoster => 'Poster';

  @override
  String get shareTemplatePhoto => 'Photo';

  @override
  String get sessionPlace => 'Place';

  @override
  String get sessionPlaceHint => 'Where are you reading?';

  @override
  String get sessionQuote => 'Quote';

  @override
  String get sessionQuoteHint => 'A line that stuck with you';

  @override
  String get sessionPhotoTake => 'Take photo';

  @override
  String get sessionPhotoChoose => 'Gallery';

  @override
  String get sessionPhotoRemove => 'Remove photo';

  @override
  String get sessionsRecent => 'Recent sessions';

  @override
  String minutesShort(int count) {
    return '$count min';
  }

  @override
  String get offlineBanner =>
      'You are offline: showing the copy saved on this device.';

  @override
  String offlinePending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count changes',
      one: '1 change',
    );
    return '$_temp0 to sync';
  }

  @override
  String get ioTitle => 'Import and export';

  @override
  String get ioImportTitle => 'Import from Goodreads';

  @override
  String get ioImportBody =>
      'On Goodreads open “My Books” → “Import and export” → “Export Library”, then pick the downloaded .csv file here. Status, rating, dates, notes and shelves are kept.';

  @override
  String get ioPickFile => 'Choose the CSV file';

  @override
  String ioFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Found $count books',
      one: 'Found 1 book',
    );
    return '$_temp0';
  }

  @override
  String ioFoundBreakdown(int read, int reading, int wanted) {
    return '$read read · $reading reading · $wanted to read';
  }

  @override
  String ioSkippedLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lines without a title were ignored',
      one: '1 line without a title was ignored',
    );
    return '$_temp0';
  }

  @override
  String get ioStart => 'Import';

  @override
  String get ioRunning => 'Importing…';

  @override
  String get ioRunningHint =>
      'You can leave this page open: each book is looked up on Open Library.';

  @override
  String get ioCancel => 'Stop';

  @override
  String get ioImported => 'Imported';

  @override
  String get ioDuplicates => 'Already in your library';

  @override
  String get ioNotFound => 'Not found';

  @override
  String get ioFailed => 'Not saved';

  @override
  String get ioDone => 'Done';

  @override
  String get ioCancelled =>
      'Import stopped: the books already imported stay in your library.';

  @override
  String get ioAborted =>
      'Connection lost: the import stopped. Try again later; books already added are skipped.';

  @override
  String get ioInvalidFile =>
      'This file does not look like a book export (no “Title” column).';

  @override
  String get ioTryAnother => 'Choose another file';

  @override
  String get ioExportTitle => 'Export your library';

  @override
  String get ioExportBody =>
      'Creates a CSV file with all your books, compatible with Goodreads and spreadsheets.';

  @override
  String get ioExportButton => 'Export as CSV';

  @override
  String get ioExportEmpty => 'There are no books to export yet.';

  @override
  String get ioExportError => 'The file could not be created.';

  @override
  String get ioProfileEntry => 'Import and export';
}
