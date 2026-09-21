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

final class BookDetailsRemoveRequested extends BookDetailsEvent {
  const BookDetailsRemoveRequested();
}
