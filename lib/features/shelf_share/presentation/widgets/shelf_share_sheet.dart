import 'dart:io';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/errors/failure_message.dart';
import '../../../../core/utils/cover_url.dart';
import '../../../../core/utils/l10n_extension.dart';
import '../../../book_details/presentation/widgets/share_cards/share_card_parts.dart';
import '../../../search/domain/entities/book.dart';
import '../cubit/shelf_share_cubit.dart';
import 'shelf_share_card.dart';

/// Lets the owner share [shelfName] (picture + link), copy the link, replace
/// it or stop sharing.
Future<void> showShelfShareSheet(
  BuildContext context, {
  required String shelfName,
  required List<Book> books,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => BlocProvider(
      create: (_) => getIt<ShelfShareCubit>(param1: shelfName)..load(),
      child: ShelfShareSheet(shelfName: shelfName, books: books),
    ),
  );
}

class ShelfShareSheet extends StatefulWidget {
  const ShelfShareSheet({
    super.key,
    required this.shelfName,
    required this.books,
  });

  final String shelfName;
  final List<Book> books;

  @override
  State<ShelfShareSheet> createState() => _ShelfShareSheetState();
}

class _ShelfShareSheetState extends State<ShelfShareSheet> {
  final _boundary = GlobalKey();
  bool _sharing = false;

  /// Feedback shown inside the sheet: a snackbar would sit under it.
  String? _notice;
  bool _noticeIsError = false;

  void _toast(String message, {bool error = false}) {
    setState(() {
      _notice = message;
      _noticeIsError = error;
    });
  }

  /// Downloads the covers on the card first, so the picture never shows a
  /// placeholder.
  Future<void> _precacheCovers() async {
    final urls = {
      for (final b in widget.books.take(ShelfShareCard.maxCovers))
        if (b.coverUrl?.isNotEmpty ?? false) b.coverUrl!,
    };
    await Future.wait([
      for (final url in urls)
        precacheImage(
          CachedNetworkImageProvider(
            resizeCoverUrl(url, CoverSize.large),
            headers: const {'User-Agent': AppConfig.userAgent},
          ),
          context,
          onError: (_, __) {},
        ),
    ]);
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  Future<void> _share(BuildContext buttonContext) async {
    final l10n = context.l10n;
    final cubit = context.read<ShelfShareCubit>();
    final box = buttonContext.findRenderObject() as RenderBox?;
    final origin =
        box == null ? null : box.localToGlobal(Offset.zero) & box.size;
    setState(() => _sharing = true);
    try {
      final share = await cubit.ensureShare();
      if (share == null || !mounted) return;
      await _precacheCovers();
      if (!mounted) return;
      final render = _boundary.currentContext!.findRenderObject()!
          as RenderRepaintBoundary;
      final image = await render.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) throw StateError('empty image');
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/bookshelf-shelf-'
        '${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(bytes.buffer.asUint8List());
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'image/png')],
          text: l10n.shelfShareMessage(
            widget.shelfName,
            share.webUrl.toString(),
          ),
          sharePositionOrigin: origin,
        ),
      );
    } catch (_) {
      if (mounted) _toast(l10n.shelfShareError, error: true);
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Future<void> _copy() async {
    final l10n = context.l10n;
    final share = await context.read<ShelfShareCubit>().ensureShare();
    if (share == null) return;
    await Clipboard.setData(ClipboardData(text: share.webUrl.toString()));
    if (mounted) _toast(l10n.shelfShareCopied);
  }

  Future<void> _confirmStop() async {
    final l10n = context.l10n;
    final cubit = context.read<ShelfShareCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.shelfShareStop),
        content: Text(l10n.shelfShareStopConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(88, 44)),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.shelfShareStop),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false)) return;
    await cubit.stop();
    if (mounted && cubit.state.failure == null) _toast(l10n.shelfShareStopped);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return BlocConsumer<ShelfShareCubit, ShelfShareState>(
      listenWhen: (a, b) => b.failure != null && a.failure != b.failure,
      listener: (context, state) =>
          _toast(failureMessage(l10n, state.failure!), error: true),
      builder: (context, state) {
        final busy = state.busy || _sharing || state.status.isLoading;
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.shelfShareSheetTitle(widget.shelfName),
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Center(
                  child: SizedBox(
                    height: 260,
                    child: AspectRatio(
                      aspectRatio: shareCardSize.width / shareCardSize.height,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: FittedBox(
                          child: RepaintBoundary(
                            key: _boundary,
                            child: ShelfShareCard(
                              shelfName: widget.shelfName,
                              books: widget.books,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Builder(
                  builder: (buttonContext) => FilledButton.icon(
                    onPressed: busy ? null : () => _share(buttonContext),
                    icon: _sharing
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.ios_share_rounded, size: 18),
                    label: Text(l10n.shelfShareSend),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: busy ? null : _copy,
                  icon: const Icon(Icons.link_rounded, size: 18),
                  label: Text(l10n.shelfShareCopy),
                ),
                if (state.share != null) ...[
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.autorenew_rounded),
                    title: Text(l10n.shelfShareRegenerate),
                    subtitle: Text(l10n.shelfShareRegenerateHint),
                    enabled: !busy,
                    onTap: context.read<ShelfShareCubit>().regenerate,
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.link_off_rounded,
                      color: theme.colorScheme.error,
                    ),
                    title: Text(
                      l10n.shelfShareStop,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                    enabled: !busy,
                    onTap: _confirmStop,
                  ),
                ],
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _notice == null
                      ? const SizedBox.shrink()
                      : Padding(
                          key: ValueKey(_notice),
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            _notice!,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: _noticeIsError
                                  ? theme.colorScheme.error
                                  : theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.shelfShareInfo,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
