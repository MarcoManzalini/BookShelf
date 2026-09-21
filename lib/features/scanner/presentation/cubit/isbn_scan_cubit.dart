import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/utils/isbn.dart';
import '../../../search/domain/entities/book.dart';
import '../../../search/domain/repositories/book_search_repository.dart';

enum ScanStatus { scanning, lookingUp, found, notFound, failure }

class IsbnScanState extends Equatable {
  const IsbnScanState({
    this.status = ScanStatus.scanning,
    this.isbn,
    this.book,
    this.failure,
  });

  final ScanStatus status;

  /// The ISBN-13 being looked up or last looked up.
  final String? isbn;
  final Book? book;
  final Failure? failure;

  @override
  List<Object?> get props => [status, isbn, book, failure];
}

/// Turns barcodes seen by the camera into a book. Only the first ISBN is
/// handled: further detections are ignored until [rescan], so a code that
/// stays in front of the camera cannot trigger a request per frame.
class IsbnScanCubit extends Cubit<IsbnScanState> {
  IsbnScanCubit(this._repository) : super(const IsbnScanState());

  final BookSearchRepository _repository;

  Future<void> onDetected(String? rawValue) async {
    if (state.status != ScanStatus.scanning) return;
    final isbn = Isbn.parse(rawValue);
    // Other barcodes (shop labels, QR codes...) are not errors: keep looking.
    if (isbn == null) return;

    emit(IsbnScanState(status: ScanStatus.lookingUp, isbn: isbn));
    try {
      final book = await _repository.findByIsbn(isbn);
      emit(
        book == null
            ? IsbnScanState(status: ScanStatus.notFound, isbn: isbn)
            : IsbnScanState(status: ScanStatus.found, isbn: isbn, book: book),
      );
    } on Failure catch (failure) {
      emit(
        IsbnScanState(
          status: ScanStatus.failure,
          isbn: isbn,
          failure: failure,
        ),
      );
    }
  }

  void rescan() => emit(const IsbnScanState());
}
