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
