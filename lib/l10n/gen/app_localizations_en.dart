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
  String get libraryTitle => 'My shelf';

  @override
  String get filterAll => 'All';

  @override
  String get viewList => 'List view';

  @override
  String get viewGrid => 'Grid view';

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
  String get searchTitle => 'Search';

  @override
  String get searchHint => 'Title, author or ISBN';

  @override
  String get searchInitialTitle => 'Find your next book';

  @override
  String get searchInitialMessage =>
      'Search by title, author or ISBN among millions of books.';

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
}
