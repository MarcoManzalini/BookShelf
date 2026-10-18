import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/utils/request_status.dart';
import '../../domain/entities/shared_shelf.dart';
import '../../domain/repositories/shelf_share_repository.dart';
import '../../domain/usecases/save_shared_shelf.dart';

/// A shelf someone shared, opened from its link: read-only, with the option
/// of copying it into the reader's own library.
class SharedShelfCubit extends Cubit<SharedShelfState> {
  SharedShelfCubit(this._token, this._repository, this._save)
      : super(const SharedShelfState());

  final String _token;
  final ShelfShareRepository _repository;
  final SaveSharedShelf _save;

  Future<void> load() async {
    emit(const SharedShelfState(status: RequestStatus.loading));
    try {
      final shelf = await _repository.fetchShared(_token);
      emit(
        SharedShelfState(
          status: RequestStatus.success,
          shelf: shelf,
          notFound: shelf == null,
        ),
      );
    } on Failure catch (failure) {
      emit(SharedShelfState(status: RequestStatus.failure, failure: failure));
    }
  }

  Future<void> saveToLibrary() async {
    final shelf = state.shelf;
    if (shelf == null || state.saveStatus == SharedShelfSaveStatus.saving) {
      return;
    }
    emit(state.copyWith(saveStatus: SharedShelfSaveStatus.saving));
    try {
      final added = await _save(shelf);
      emit(
        state.copyWith(saveStatus: SharedShelfSaveStatus.saved, added: added),
      );
    } on Failure catch (failure) {
      emit(
        state.copyWith(
          saveStatus: SharedShelfSaveStatus.failure,
          saveFailure: failure,
        ),
      );
    }
  }
}

enum SharedShelfSaveStatus { idle, saving, saved, failure }

class SharedShelfState extends Equatable {
  const SharedShelfState({
    this.status = RequestStatus.initial,
    this.shelf,
    this.notFound = false,
    this.failure,
    this.saveStatus = SharedShelfSaveStatus.idle,
    this.added = 0,
    this.saveFailure,
  });

  final RequestStatus status;
  final SharedShelf? shelf;

  /// The link is unknown or no longer shared.
  final bool notFound;
  final Failure? failure;
  final SharedShelfSaveStatus saveStatus;

  /// Books new to the library after the last save.
  final int added;
  final Failure? saveFailure;

  SharedShelfState copyWith({
    SharedShelfSaveStatus? saveStatus,
    int? added,
    Failure? saveFailure,
  }) {
    return SharedShelfState(
      status: status,
      shelf: shelf,
      notFound: notFound,
      failure: failure,
      saveStatus: saveStatus ?? this.saveStatus,
      added: added ?? this.added,
      saveFailure: saveFailure,
    );
  }

  @override
  List<Object?> get props =>
      [status, shelf, notFound, failure, saveStatus, added, saveFailure];
}
