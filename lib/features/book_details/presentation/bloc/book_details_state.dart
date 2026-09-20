part of 'book_details_bloc.dart';

class BookDetailsState extends Equatable {
  const BookDetailsState({
    this.status = RequestStatus.initial,
    this.book,
    this.userBook,
    this.saveStatus = RequestStatus.initial,
    this.removed = false,
    this.failure,
  });

  /// Status of the initial load.
  final RequestStatus status;

  /// Always set once loaded; equals [userBook].book when saved.
  final Book? book;

  /// null while previewing a book that is not in the library.
  final UserBook? userBook;

  /// Status of the last add/edit request.
  final RequestStatus saveStatus;
  final bool removed;
  final Failure? failure;

  bool get isInLibrary => userBook != null;

  BookDetailsState copyWith({
    RequestStatus? status,
    Book? book,
    UserBook? Function()? userBook,
    RequestStatus? saveStatus,
    bool? removed,
    Failure? Function()? failure,
  }) {
    return BookDetailsState(
      status: status ?? this.status,
      book: book ?? this.book,
      userBook: userBook != null ? userBook() : this.userBook,
      saveStatus: saveStatus ?? this.saveStatus,
      removed: removed ?? this.removed,
      failure: failure != null ? failure() : this.failure,
    );
  }

  @override
  List<Object?> get props =>
      [status, book, userBook, saveStatus, removed, failure];
}
