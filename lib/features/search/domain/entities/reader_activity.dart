import 'package:equatable/equatable.dart';

/// How a work can be read online on Open Library.
enum EbookAccess {
  /// Public domain scan: free to read, no account needed.
  public,

  /// Lent one copy at a time; needs an Open Library account.
  borrowable,

  /// Nothing readable online.
  none,
}

/// What Open Library readers do with a work: how many shelved it and
/// whether it can be read online. Not stored in the library.
class ReaderActivity extends Equatable {
  const ReaderActivity({
    this.wantToRead = 0,
    this.reading = 0,
    this.read = 0,
    this.ebookAccess = EbookAccess.none,
  });

  final int wantToRead;
  final int reading;
  final int read;
  final EbookAccess ebookAccess;

  bool get hasReaders => wantToRead + reading + read > 0;

  @override
  List<Object?> get props => [wantToRead, reading, read, ebookAccess];
}
