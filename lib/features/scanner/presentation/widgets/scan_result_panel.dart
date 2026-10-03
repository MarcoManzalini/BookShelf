import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/errors/failure_message.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/utils/l10n_extension.dart';
import '../../../../core/widgets/book_cover.dart';
import '../../../../core/widgets/book_open_target.dart';
import '../../../search/domain/entities/book.dart';
import '../../../search/presentation/widgets/add_to_library_button.dart';
import '../cubit/isbn_scan_cubit.dart';

/// What the scanner tells the reader below the viewfinder: a hint while
/// looking, then the book found (or why there is none).
class ScanResultPanel extends StatelessWidget {
  const ScanResultPanel({
    super.key,
    required this.state,
    required this.onRescan,
  });

  final IsbnScanState state;
  final VoidCallback onRescan;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final child = switch (state.status) {
      ScanStatus.scanning => _Pill(
          key: const ValueKey('scanning'),
          text: l10n.scanHint,
        ),
      ScanStatus.lookingUp => _Pill(
          key: const ValueKey('looking'),
          text: l10n.scanLooking,
          busy: true,
        ),
      ScanStatus.found => _FoundCard(
          key: const ValueKey('found'),
          book: state.book!,
          onRescan: onRescan,
        ),
      ScanStatus.notFound => _MessageCard(
          key: const ValueKey('notFound'),
          icon: Icons.search_off_rounded,
          message: l10n.scanNotFound(state.isbn!),
          onRescan: onRescan,
          action: _AddToOpenLibraryButton(isbn: state.isbn!),
        ),
      ScanStatus.failure => _MessageCard(
          key: const ValueKey('failure'),
          icon: Icons.error_outline_rounded,
          message: failureMessage(l10n, state.failure!),
          onRescan: onRescan,
        ),
    };
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.08), end: Offset.zero)
              .animate(animation),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({super.key, required this.text, this.busy = false});

  final String text;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(150),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (busy) ...[
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FoundCard extends StatelessWidget {
  const _FoundCard({super.key, required this.book, required this.onRescan});

  final Book book;
  final VoidCallback onRescan;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final subtitle = [
      if (book.authors.isNotEmpty) book.authorsLabel,
      if (book.publishedYear != null) '${book.publishedYear}',
    ].join(' · ');
    return _Sheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              BookOpenTarget(
                url: book.coverUrl,
                title: book.title,
                author: book.authorsLabel,
                child: BookCover(
                  url: book.coverUrl,
                  title: book.title,
                  author: book.authorsLabel,
                  width: 56,
                  height: 84,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AddToLibraryButton(book: book),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onRescan,
                  // One line even in narrow phones or longer translations.
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(l10n.scanAgain, maxLines: 1),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Builder(
                  builder: (cardContext) => FilledButton(
                    onPressed: () {
                      BookOpenTarget.capture(cardContext);
                      context.push(
                        AppRoutes.preview(book.externalId),
                        extra: book,
                      );
                    },
                    child: Text(l10n.scanDetails),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    super.key,
    required this.icon,
    required this.message,
    required this.onRescan,
    this.action,
  });

  final IconData icon;
  final String message;
  final VoidCallback onRescan;

  /// Extra button above "scan another".
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _Sheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 12),
              Expanded(child: Text(message, style: theme.textTheme.bodyMedium)),
            ],
          ),
          const SizedBox(height: 14),
          if (action != null) ...[
            action!,
            const SizedBox(height: 10),
          ],
          FilledButton(
            onPressed: onRescan,
            child: Text(context.l10n.scanAgain),
          ),
        ],
      ),
    );
  }
}

/// Open Library's "add a book" form can't be pre-filled, so the ISBN is
/// copied for the reader to paste. The form asks to sign in to Open Library.
class _AddToOpenLibraryButton extends StatelessWidget {
  const _AddToOpenLibraryButton({required this.isbn});

  final String isbn;

  static final _addBookUri =
      Uri.parse('${AppConfig.openLibraryBaseUrl}/books/add');

  Future<void> _open(BuildContext context) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: isbn));
    var opened = false;
    try {
      opened =
          await launchUrl(_addBookUri, mode: LaunchMode.externalApplication);
    } catch (_) {}
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(opened ? l10n.scanIsbnCopied : l10n.linkOpenFailed),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _open(context),
      icon: const Icon(Icons.library_add_outlined, size: 20),
      label: Text(context.l10n.scanAddToOpenLibrary),
    );
  }
}

class _Sheet extends StatelessWidget {
  const _Sheet({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(60),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
