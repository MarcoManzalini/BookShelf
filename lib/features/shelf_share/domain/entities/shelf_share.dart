import 'package:equatable/equatable.dart';

import '../../../../core/config/app_config.dart';

/// The link that shares one of the user's shelves.
class ShelfShare extends Equatable {
  const ShelfShare({required this.shelfName, required this.token});

  final String shelfName;
  final String token;

  /// Web page anyone can open, with or without the app.
  Uri get webUrl => Uri.parse(
        '${AppConfig.shelfShareBaseUrl}?t=${Uri.encodeQueryComponent(token)}',
      );

  /// Opens the shelf directly in the app.
  Uri get appUrl =>
      Uri.parse('${AppConfig.shelfShareAppUrl}${Uri.encodeComponent(token)}');

  @override
  List<Object?> get props => [shelfName, token];
}
