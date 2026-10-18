import 'package:bloc_test/bloc_test.dart';
import 'package:bookshelf/core/errors/failure.dart';
import 'package:bookshelf/core/utils/request_status.dart';
import 'package:bookshelf/features/shelf_share/domain/entities/shelf_share.dart';
import 'package:bookshelf/features/shelf_share/presentation/cubit/shelf_share_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';

void main() {
  late MockShelfShareRepository repository;

  const name = 'Regali';
  const share = ShelfShare(shelfName: name, token: 'old');
  const fresh = ShelfShare(shelfName: name, token: 'new');
  const failure = Failure(FailureCode.network);
  const shared = ShelfShareState(status: RequestStatus.success, share: share);

  setUp(() => repository = MockShelfShareRepository());

  ShelfShareCubit build() => ShelfShareCubit(name, repository);

  blocTest<ShelfShareCubit, ShelfShareState>(
    'load emits success with existing share',
    setUp: () =>
        when(() => repository.shareFor(name)).thenAnswer((_) async => share),
    build: build,
    act: (cubit) => cubit.load(),
    expect: () => [
      const ShelfShareState(status: RequestStatus.loading),
      shared,
    ],
  );

  blocTest<ShelfShareCubit, ShelfShareState>(
    'load emits success with null when not shared',
    setUp: () =>
        when(() => repository.shareFor(name)).thenAnswer((_) async => null),
    build: build,
    act: (cubit) => cubit.load(),
    expect: () => [
      const ShelfShareState(status: RequestStatus.loading),
      const ShelfShareState(status: RequestStatus.success),
    ],
  );

  test('ensureShare creates when missing and returns it', () async {
    when(() => repository.create(name)).thenAnswer((_) async => fresh);
    final cubit = build()
      ..emit(const ShelfShareState(status: RequestStatus.success));

    expect(await cubit.ensureShare(), fresh);
    expect(cubit.state.share, fresh);
    expect(cubit.state.busy, isFalse);
  });

  test('ensureShare reloads after a failed first load instead of creating',
      () async {
    when(() => repository.shareFor(name)).thenAnswer((_) async => share);
    final cubit = build()
      ..emit(
        const ShelfShareState(status: RequestStatus.failure, failure: failure),
      );

    expect(await cubit.ensureShare(), share);
    verifyNever(() => repository.create(any()));
  });

  test('ensureShare reuses existing without calling create', () async {
    final cubit = build()..emit(shared);

    expect(await cubit.ensureShare(), share);
    verifyNever(() => repository.create(any()));
  });

  blocTest<ShelfShareCubit, ShelfShareState>(
    'regenerate revokes then creates',
    setUp: () {
      when(() => repository.revoke(name)).thenAnswer((_) async {});
      when(() => repository.create(name)).thenAnswer((_) async => fresh);
    },
    build: build,
    seed: () => shared,
    act: (cubit) => cubit.regenerate(),
    expect: () => [
      const ShelfShareState(
        status: RequestStatus.success,
        share: share,
        busy: true,
      ),
      const ShelfShareState(status: RequestStatus.success, share: fresh),
    ],
    verify: (_) => verifyInOrder([
      () => repository.revoke(name),
      () => repository.create(name),
    ]),
  );

  blocTest<ShelfShareCubit, ShelfShareState>(
    'regenerate failing after the revoke drops the dead link',
    setUp: () {
      when(() => repository.revoke(name)).thenAnswer((_) async {});
      when(() => repository.create(name)).thenThrow(failure);
    },
    build: build,
    seed: () => shared,
    act: (cubit) => cubit.regenerate(),
    expect: () => [
      const ShelfShareState(
        status: RequestStatus.success,
        share: share,
        busy: true,
      ),
      const ShelfShareState(status: RequestStatus.success, failure: failure),
    ],
  );

  blocTest<ShelfShareCubit, ShelfShareState>(
    'stop revokes and clears share',
    setUp: () => when(() => repository.revoke(name)).thenAnswer((_) async {}),
    build: build,
    seed: () => shared,
    act: (cubit) => cubit.stop(),
    expect: () => [
      const ShelfShareState(
        status: RequestStatus.success,
        share: share,
        busy: true,
      ),
      const ShelfShareState(status: RequestStatus.success),
    ],
  );

  blocTest<ShelfShareCubit, ShelfShareState>(
    'create failure emits failure and busy false',
    setUp: () => when(() => repository.create(name)).thenThrow(failure),
    build: build,
    seed: () => const ShelfShareState(status: RequestStatus.success),
    act: (cubit) => cubit.ensureShare(),
    expect: () => [
      const ShelfShareState(status: RequestStatus.success, busy: true),
      const ShelfShareState(status: RequestStatus.success, failure: failure),
    ],
  );
}
