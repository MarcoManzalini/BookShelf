import 'package:flutter/material.dart';

import '../errors/failure.dart';
import '../errors/failure_message.dart';
import '../utils/l10n_extension.dart';
import 'empty_state.dart';

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.failure, this.onRetry});

  final Failure failure;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final offline = failure.code == FailureCode.network;
    return EmptyState(
      icon: offline ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
      title: offline ? l10n.offlineTitle : l10n.errorTitle,
      message: failureMessage(l10n, failure),
      actionLabel: onRetry == null ? null : l10n.retry,
      onAction: onRetry,
    );
  }
}
