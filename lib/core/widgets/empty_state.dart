import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    this.icon,
    this.leading,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  }) : assert(icon != null || leading != null);

  final IconData? icon;

  /// Replaces the default icon medallion (e.g. with the brand mark).
  final Widget? leading;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            leading ?? _Medallion(icon: icon!),
            const SizedBox(height: 24),
            Text(
              title,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null) ...[
              const SizedBox(height: 24),
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(minimumSize: const Size(180, 48)),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Soft round plate behind the illustration icon.
class _Medallion extends StatelessWidget {
  const _Medallion({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: scheme.surfaceContainer,
      ),
      child: Icon(icon, size: 40, color: scheme.onSurfaceVariant),
    );
  }
}
