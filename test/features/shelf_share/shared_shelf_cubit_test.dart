import 'package:bloc_test/bloc_test.dart';
import 'package:bookshelf/core/errors/failure.dart';
import 'package:bookshelf/core/utils/request_status.dart';
import 'package:bookshelf/features/shelf_share/domain/entities/shared_shelf.dart';
import 'package:bookshelf/features/shelf_share/presentation/cubit/shared_shelf_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/mocks.dart';

void main() {
  late MockShelfShareRepository repository;
  late MockSaveSharedShelf save;

  final shelf = SharedShelf(
    shelfName: 'Letture autunnali',
    ownerName: 'Marco',
    books: [buildBook()],
  );
  const failure = Failure(FailureCode.network);

  setUpAll(() => registerFallbackValue(shelf));

  setUp(() {
    repository = MockShelfShareRepository();
    save = MockSaveSharedShelf();
  });

  SharedShelfCubit build() => SharedShelfCubit('tok', repository, save);

  blocTest<SharedShelfCubit, SharedShelfState>(
    'load emits loading then success with the shelf',
    setUp: () => when(() => repository.fetchShared('tok'))
        .thenAnswer((_) async => shelf),
    build: build,
    act: (cubit) => cubit.load(),
    expect: () => [
      const SharedShelfState(status: RequestStatus.loading),
      SharedShelfState(status: RequestStatus.success, shelf: shelf),
    ],
  );

  blocTest<SharedShelfCubit, SharedShelfState>(
    'load emits success with notFound when the repo returns null',
    setUp: () =>
        when(() => repository.fetchShared('tok')).thenAnswer((_) async => null),
    build: build,
    act: (cubit) => cubit.load(),
    expect: () => [
      const SharedShelfState(status: RequestStatus.loading),
      const SharedShelfState(status: RequestStatus.success, notFound: true),
    ],
  );

  blocTest<SharedShelfCubit, SharedShelfState>(
    'load emits failure with the failure',
    setUp: () => when(() => repository.fetchShared('tok')).thenThrow(failure),
    build: build,
    act: (cubit) => cubit.load(),
    expect: () => [
      const SharedShelfState(status: RequestStatus.loading),
      const SharedShelfState(status: RequestStatus.failure, failure: failure),
    ],
  );

  blocTest<SharedShelfCubit, SharedShelfState>(
    'saveToLibrary emits saving then saved with added count',
    setUp: () => when(() => save(shelf)).thenAnswer((_) async => 3),
    build: build,
    seed: () => SharedShelfState(status: RequestStatus.success, shelf: shelf),
    act: (cubit) => cubit.saveToLibrary(),
    expect: () => [
      SharedShelfState(
        status: RequestStatus.success,
        shelf: shelf,
        saveStatus: SharedShelfSaveStatus.saving,
      ),
      SharedShelfState(
        status: RequestStatus.success,
        shelf: shelf,
        saveStatus: SharedShelfSaveStatus.saved,
        added: 3,
      ),
    ],
  );

  blocTest<SharedShelfCubit, SharedShelfState>(
    'saveToLibrary emits failure when save throws Failure',
    setUp: () => when(() => save(shelf)).thenThrow(failure),
    build: build,
    seed: () => SharedShelfState(status: RequestStatus.success, shelf: shelf),
    act: (cubit) => cubit.saveToLibrary(),
    expect: () => [
      SharedShelfState(
        status: RequestStatus.success,
        shelf: shelf,
        saveStatus: SharedShelfSaveStatus.saving,
      ),
      SharedShelfState(
        status: RequestStatus.success,
        shelf: shelf,
        saveStatus: SharedShelfSaveStatus.failure,
        saveFailure: failure,
      ),
    ],
  );
}
