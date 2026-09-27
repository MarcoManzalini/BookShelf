part of 'book_details_bloc.dart';

sealed class BookDetailsEvent extends Equatable {
  const BookDetailsEvent();

  @override
  List<Object?> get props => [];
}

/// Opens a book saved in the library (`/book/:id`).
final class BookDetailsLibraryRequested extends BookDetailsEvent {
  const BookDetailsLibraryRequested(this.userBookId);

  final String userBookId;

  @override
  List<Object?> get props => [userBookId];
}

/// Opens a search result as a preview.
final class BookDetailsPreviewRequested extends BookDetailsEvent {
  const BookDetailsPreviewRequested(this.book);

  final Book book;

  @override
  List<Object?> get props => [book];
}

/// Loads the author profile and related books. Dispatched by the bloc itself
/// once the book is known.
final class BookDetailsExtrasRequested extends BookDetailsEvent {
  const BookDetailsExtrasRequested();
}

final class BookDetailsAddRequested extends BookDetailsEvent {
  const BookDetailsAddRequested(this.status);

  final ReadingStatus status;

  @override
  List<Object?> get props => [status];
}

final class BookDetailsStatusChanged extends BookDetailsEvent {
  const BookDetailsStatusChanged(this.status);

  final ReadingStatus status;

  @override
  List<Object?> get props => [status];
}

final class BookDetailsProgressChanged extends BookDetailsEvent {
  const BookDetailsProgressChanged(this.page);

  final int page;

  @override
  List<Object?> get props => [page];
}

/// The reader finished a session: where they stopped and for how long.
final class BookDetailsSessionLogged extends BookDetailsEvent {
  const BookDetailsSessionLogged({required this.endPage, this.minutes});

  final int endPage;
  final int? minutes;

  @override
  List<Object?> get props => [endPage, minutes];
}

/// Loads the reading sessions of the saved book.
final class BookDetailsLogsRequested extends BookDetailsEvent {
  const BookDetailsLogsRequested();
}

final class BookDetailsRatingChanged extends BookDetailsEvent {
  const BookDetailsRatingChanged(this.rating);

  /// null clears the rating.
  final int? rating;

  @override
  List<Object?> get props => [rating];
}

final class BookDetailsNotesChanged extends BookDetailsEvent {
  const BookDetailsNotesChanged(this.notes);

  final String notes;

  @override
  List<Object?> get props => [notes];
}

/// The reader picked another edition of the book.
final class BookDetailsEditionSelected extends BookDetailsEvent {
  const BookDetailsEditionSelected(this.edition);

  final BookEdition edition;

  @override
  List<Object?> get props => [edition];
}

final class BookDetailsShelvesChanged extends BookDetailsEvent {
  const BookDetailsShelvesChanged(this.shelves);

  final List<String> shelves;

  @override
  List<Object?> get props => [shelves];
}

enum ReadingDateField { startedAt, finishedAt }

final class BookDetailsDateChanged extends BookDetailsEvent {
  const BookDetailsDateChanged(this.field, this.date);

  final ReadingDateField field;
  final DateTime? date;

  @override
  List<Object?> get props => [field, date];
}

/// The reader starts a finished book over: the read is kept in the history.
final class BookDetailsRereadStarted extends BookDetailsEvent {
  const BookDetailsRereadStarted();
}

/// Records an earlier read the app did not know about.
final class BookDetailsPastReadAdded extends BookDetailsEvent {
  const BookDetailsPastReadAdded(this.read);

  final BookRead read;

  @override
  List<Object?> get props => [read];
}

final class BookDetailsPastReadRemoved extends BookDetailsEvent {
  const BookDetailsPastReadRemoved(this.read);

  final BookRead read;

  @override
  List<Object?> get props => [read];
}

/// Loads the quotes saved from the book.
final class BookDetailsQuotesRequested extends BookDetailsEvent {
  const BookDetailsQuotesRequested();
}

/// Saves a new quote, or edits [id] when given.
final class BookDetailsQuoteSaved extends BookDetailsEvent {
  const BookDetailsQuoteSaved({required this.text, this.page, this.id});

  final String text;
  final int? page;
  final String? id;

  @override
  List<Object?> get props => [text, page, id];
}

final class BookDetailsQuoteRemoved extends BookDetailsEvent {
  const BookDetailsQuoteRemoved(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

final class BookDetailsFormatChanged extends BookDetailsEvent {
  const BookDetailsFormatChanged(this.format);

  final BookFormat format;

  @override
  List<Object?> get props => [format];
}

/// Length of an audiobook in minutes; null clears it.
final class BookDetailsDurationChanged extends BookDetailsEvent {
  const BookDetailsDurationChanged(this.minutes);

  final int? minutes;

  @override
  List<Object?> get props => [minutes];
}

/// null takes the book out of its saga.
final class BookDetailsSeriesChanged extends BookDetailsEvent {
  const BookDetailsSeriesChanged(this.series);

  final BookSeries? series;

  @override
  List<Object?> get props => [series];
}

final class BookDetailsMoodsChanged extends BookDetailsEvent {
  const BookDetailsMoodsChanged(this.moods);

  final List<BookMood> moods;

  @override
  List<Object?> get props => [moods];
}

final class BookDetailsPaceChanged extends BookDetailsEvent {
  const BookDetailsPaceChanged(this.pace);

  final ReadingPace? pace;

  @override
  List<Object?> get props => [pace];
}

/// null marks the copy as back home.
final class BookDetailsLoanChanged extends BookDetailsEvent {
  const BookDetailsLoanChanged(this.loan);

  final BookLoan? loan;

  @override
  List<Object?> get props => [loan];
}

final class BookDetailsRemoveRequested extends BookDetailsEvent {
  const BookDetailsRemoveRequested();
}
