part of 'book_details_bloc.dart';

class BookDetailsState extends Equatable {
  const BookDetailsState({
    this.status = RequestStatus.initial,
    this.book,
    this.userBook,
    this.saveStatus = RequestStatus.initial,
    this.removed = false,
    this.failure,
    this.author,
    this.moreByAuthor = const [],
    this.similarBooks = const [],
    this.logs = const [],
    this.quotes = const [],
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

  /// Profile of the first author; null until loaded (or when unavailable).
  final AuthorInfo? author;
  final List<Book> moreByAuthor;
  final List<Book> similarBooks;

  /// Reading sessions of this book, newest first (saved books only).
  final List<ReadingLog> logs;

  /// Quotes saved from this book, newest first (saved books only).
  final List<BookQuote> quotes;

  bool get isInLibrary => userBook != null;

  BookDetailsState copyWith({
    RequestStatus? status,
    Book? book,
    UserBook? Function()? userBook,
    RequestStatus? saveStatus,
    bool? removed,
    Failure? Function()? failure,
    AuthorInfo? author,
    List<Book>? moreByAuthor,
    List<Book>? similarBooks,
    List<ReadingLog>? logs,
    List<BookQuote>? quotes,
  }) {
    return BookDetailsState(
      status: status ?? this.status,
      book: book ?? this.book,
      userBook: userBook != null ? userBook() : this.userBook,
      saveStatus: saveStatus ?? this.saveStatus,
      removed: removed ?? this.removed,
      failure: failure != null ? failure() : this.failure,
      author: author ?? this.author,
      moreByAuthor: moreByAuthor ?? this.moreByAuthor,
      similarBooks: similarBooks ?? this.similarBooks,
      logs: logs ?? this.logs,
      quotes: quotes ?? this.quotes,
    );
  }

  @override
  List<Object?> get props => [
        status,
        book,
        userBook,
        saveStatus,
        removed,
        failure,
        author,
        moreByAuthor,
        similarBooks,
        logs,
        quotes,
      ];
}
