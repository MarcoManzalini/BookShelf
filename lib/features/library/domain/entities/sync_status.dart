import 'package:equatable/equatable.dart';

/// Whether the library is talking to the server, and how many local edits
/// are still waiting to be sent.
class SyncStatus extends Equatable {
  const SyncStatus({this.offline = false, this.pending = 0});

  final bool offline;
  final int pending;

  @override
  List<Object?> get props => [offline, pending];
}
