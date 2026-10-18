import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/utils/request_status.dart';
import '../../domain/entities/shelf_share.dart';
import '../../domain/repositories/shelf_share_repository.dart';

/// The owner's side of sharing one shelf: its link, created on first share,
/// replaced or revoked on request.
class ShelfShareCubit extends Cubit<ShelfShareState> {
  ShelfShareCubit(this._shelfName, this._repository)
      : super(const ShelfShareState());

  final String _shelfName;
  final ShelfShareRepository _repository;

  Future<void> load() async {
    emit(const ShelfShareState(status: RequestStatus.loading));
    try {
      final share = await _repository.shareFor(_shelfName);
      emit(ShelfShareState(status: RequestStatus.success, share: share));
    } on Failure catch (failure) {
      emit(ShelfShareState(status: RequestStatus.failure, failure: failure));
    }
  }

  /// The current link, creating it the first time; null if that failed.
  Future<ShelfShare?> ensureShare() async {
    final current = state.share;
    if (current != null) return current;
    // The first load failed (e.g. offline): the shelf may already be shared,
    // and creating again would hit the one-link-per-shelf index.
    if (!state.status.isSuccess) {
      await load();
      if (state.share != null || state.status.isFailure) return state.share;
    }
    await _change(() => _repository.create(_shelfName));
    return state.share;
  }

  /// Replaces the link: the old one stops working.
  Future<void> regenerate() async {
    var revoked = false;
    await _change(
      () async {
        await _repository.revoke(_shelfName);
        revoked = true;
        return _repository.create(_shelfName);
      },
      // Once revoked, the old link is dead: never hand it out again.
      keepShareOnFailure: () => !revoked,
    );
  }

  Future<void> stop() => _change(() async {
        await _repository.revoke(_shelfName);
        return null;
      });

  Future<void> _change(
    Future<ShelfShare?> Function() action, {
    bool Function()? keepShareOnFailure,
  }) async {
    if (state.busy) return;
    emit(
      ShelfShareState(status: state.status, share: state.share, busy: true),
    );
    try {
      final share = await action();
      emit(ShelfShareState(status: RequestStatus.success, share: share));
    } on Failure catch (failure) {
      final keep = keepShareOnFailure?.call() ?? true;
      emit(
        ShelfShareState(
          status: state.status,
          share: keep ? state.share : null,
          failure: failure,
        ),
      );
    }
  }
}

class ShelfShareState extends Equatable {
  const ShelfShareState({
    this.status = RequestStatus.initial,
    this.share,
    this.busy = false,
    this.failure,
  });

  final RequestStatus status;

  /// Null while the shelf is not shared.
  final ShelfShare? share;

  /// A create/regenerate/stop request is running.
  final bool busy;
  final Failure? failure;

  @override
  List<Object?> get props => [status, share, busy, failure];
}
