import 'package:bloc_test/bloc_test.dart';
import 'package:bookshelf/core/errors/failure.dart';
import 'package:bookshelf/features/scanner/presentation/cubit/isbn_scan_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/mocks.dart';

void main() {
  late MockBookSearchRepository repository;
  final dune = buildBook();
  const isbn = '9780441172719';

  setUp(() => repository = MockBookSearchRepository());

  blocTest<IsbnScanCubit, IsbnScanState>(
    'finds the book for a scanned ISBN-13',
    setUp: () =>
        when(() => repository.findByIsbn(isbn)).thenAnswer((_) async => dune),
    build: () => IsbnScanCubit(repository),
    act: (cubit) => cubit.onDetected(isbn),
    expect: () => [
      const IsbnScanState(status: ScanStatus.lookingUp, isbn: isbn),
      IsbnScanState(status: ScanStatus.found, isbn: isbn, book: dune),
    ],
  );

  blocTest<IsbnScanCubit, IsbnScanState>(
    'looks an ISBN-10 up by its ISBN-13',
    setUp: () =>
        when(() => repository.findByIsbn(isbn)).thenAnswer((_) async => dune),
    build: () => IsbnScanCubit(repository),
    act: (cubit) => cubit.onDetected('0441172717'),
    verify: (_) => verify(() => repository.findByIsbn(isbn)).called(1),
  );

  blocTest<IsbnScanCubit, IsbnScanState>(
    'ignores barcodes that are not ISBNs and keeps scanning',
    build: () => IsbnScanCubit(repository),
    act: (cubit) async {
      await cubit.onDetected(null);
      await cubit.onDetected('4006381333931');
      await cubit.onDetected('not a code');
    },
    expect: () => <IsbnScanState>[],
    verify: (_) => verifyNever(() => repository.findByIsbn(any())),
  );

  blocTest<IsbnScanCubit, IsbnScanState>(
    'reports an unknown ISBN',
    setUp: () =>
        when(() => repository.findByIsbn(any())).thenAnswer((_) async => null),
    build: () => IsbnScanCubit(repository),
    act: (cubit) => cubit.onDetected(isbn),
    expect: () => const [
      IsbnScanState(status: ScanStatus.lookingUp, isbn: isbn),
      IsbnScanState(status: ScanStatus.notFound, isbn: isbn),
    ],
  );

  blocTest<IsbnScanCubit, IsbnScanState>(
    'reports a lookup failure',
    setUp: () => when(() => repository.findByIsbn(any()))
        .thenThrow(const Failure(FailureCode.network)),
    build: () => IsbnScanCubit(repository),
    act: (cubit) => cubit.onDetected(isbn),
    expect: () => const [
      IsbnScanState(status: ScanStatus.lookingUp, isbn: isbn),
      IsbnScanState(
        status: ScanStatus.failure,
        isbn: isbn,
        failure: Failure(FailureCode.network),
      ),
    ],
  );

  blocTest<IsbnScanCubit, IsbnScanState>(
    'a code that stays in view triggers a single lookup',
    setUp: () =>
        when(() => repository.findByIsbn(isbn)).thenAnswer((_) async => dune),
    build: () => IsbnScanCubit(repository),
    act: (cubit) async {
      // The camera reports the same code on every frame.
      await Future.wait([
        cubit.onDetected(isbn),
        cubit.onDetected(isbn),
        cubit.onDetected(isbn),
      ]);
      await cubit.onDetected(isbn);
    },
    verify: (_) => verify(() => repository.findByIsbn(isbn)).called(1),
  );

  blocTest<IsbnScanCubit, IsbnScanState>(
    'rescan goes back to scanning and accepts a new code',
    setUp: () =>
        when(() => repository.findByIsbn(isbn)).thenAnswer((_) async => dune),
    build: () => IsbnScanCubit(repository),
    act: (cubit) async {
      await cubit.onDetected(isbn);
      cubit.rescan();
      await cubit.onDetected(isbn);
    },
    verify: (cubit) {
      expect(cubit.state.status, ScanStatus.found);
      verify(() => repository.findByIsbn(isbn)).called(2);
    },
  );
}
