import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/utils/cover_color.dart';
import '../../../../core/utils/l10n_extension.dart';
import '../../../quotes/domain/entities/book_quote.dart';
import '../../../stats/domain/entities/reading_insights.dart';
import '../../../stats/domain/repositories/reading_log_repository.dart';
import 'reading_share_card.dart';

/// Preview of the session card with a button that opens the share sheet.
Future<void> showReadingShareSheet(
  BuildContext context,
  ReadingShareData data, {
  List<BookQuote> quotes = const [],
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    // Keeps the sheet below the status bar so the scrim above it stays
    // tappable even when the content is taller than the screen.
    useSafeArea: true,
    builder: (_) => _ShareSheet(data: data, quotes: quotes),
  );
}

class _ShareSheet extends StatefulWidget {
  const _ShareSheet({required this.data, required this.quotes});

  final ReadingShareData data;

  /// Quotes saved from the book, offered as ready-made card quotes.
  final List<BookQuote> quotes;

  @override
  State<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<_ShareSheet> {
  /// What fits on a card.
  static const _quoteMaxLength = 140;

  final _boundary = GlobalKey();
  final _place = TextEditingController();
  final _quote = TextEditingController();
  ImageProvider? _photo;
  ShareTemplate _template = ShareTemplate.stats;
  late ReadingShareData _data = widget.data;
  Color? _tint;
  bool _ready = false;
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
    _prepare();
    _loadHistory();
  }

  /// Streak and the past week of pages, both counted over every book from
  /// the same log fetch. Best effort: without it the cards just leave the
  /// streak and the week chart out.
  Future<void> _loadHistory() async {
    try {
      final logs = await getIt<ReadingLogRepository>().all();
      final streak = ReadingInsights.streakEndingOn(logs, widget.data.day);
      final pagesByDay = <DateTime, int>{};
      for (final log in logs) {
        final on = log.loggedOn;
        pagesByDay[DateTime(on.year, on.month, on.day)] =
            (pagesByDay[DateTime(on.year, on.month, on.day)] ?? 0) + log.pages;
      }
      final end = DateTime(
        widget.data.day.year,
        widget.data.day.month,
        widget.data.day.day,
      );
      final week = [
        for (var i = 6; i >= 0; i--)
          pagesByDay[end.subtract(Duration(days: i))] ?? 0,
      ];
      if (!mounted) return;
      setState(
        () => _data = widget.data.withStreak(streak).withWeek(week),
      );
    } catch (_) {
      // Offline or not signed in: the cards just leave that data out.
    }
  }

  @override
  void dispose() {
    _place.dispose();
    _quote.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (file == null || !mounted) return;
      final provider = MemoryImage(await file.readAsBytes());
      // Decoded before it is shown, so it is there when the card is captured.
      if (!mounted) return;
      await precacheImage(provider, context);
      if (mounted) setState(() => _photo = provider);
    } catch (_) {
      // Permission denied or picker failed: the card just stays without photo.
    }
  }

  /// The card is exported as drawn: wait for the cover (and its color) so the
  /// picture is never captured with a placeholder.
  Future<void> _prepare() async {
    final url = widget.data.coverUrl;
    final tint = (url == null || url.isEmpty) ? null : await coverColor(url);
    if (!mounted) return;
    setState(() {
      _tint = tint;
      _ready = true;
    });
  }

  Future<void> _share(BuildContext buttonContext) async {
    final messenger = ScaffoldMessenger.of(context);
    final error = context.l10n.sessionShareError;
    final box = buttonContext.findRenderObject() as RenderBox?;
    // iPad anchors the share popover to this rectangle.
    final origin =
        box == null ? null : box.localToGlobal(Offset.zero) & box.size;
    setState(() => _sharing = true);
    try {
      final render = _boundary.currentContext!.findRenderObject()!
          as RenderRepaintBoundary;
      final image = await render.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) throw StateError('empty image');
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/bookshelf-session-'
        '${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(bytes.buffer.asUint8List());
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'image/png')],
          sharePositionOrigin: origin,
        ),
      );
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(error)));
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  /// One tap puts a saved quote on the card (clipped to the field's limit).
  Widget _savedQuotes(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.shareSavedQuotes,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final quote in widget.quotes)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      avatar: const Icon(Icons.format_quote_rounded, size: 16),
                      label: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 200),
                        child: Text(
                          quote.text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      onPressed: () => _quote.text = quote.text.length >
                              _quoteMaxLength
                          ? '${quote.text.substring(0, _quoteMaxLength - 1)}…'
                          : quote.text,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final screen = MediaQuery.sizeOf(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.sessionShareTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  // The scroll view swallows the drag-to-dismiss gesture, so
                  // the sheet needs an explicit way out.
                  IconButton(
                    tooltip:
                        MaterialLocalizations.of(context).closeButtonTooltip,
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SegmentedButton<ShareTemplate>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: ShareTemplate.stats,
                    label: Text(l10n.shareTemplateStats),
                  ),
                  ButtonSegment(
                    value: ShareTemplate.poster,
                    label: Text(l10n.shareTemplatePoster),
                  ),
                  ButtonSegment(
                    value: ShareTemplate.photo,
                    label: Text(l10n.shareTemplatePhoto),
                  ),
                ],
                selected: {_template},
                onSelectionChanged: (value) =>
                    setState(() => _template = value.first),
              ),
              const SizedBox(height: 16),
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: screen.height * 0.5),
                  child: AspectRatio(
                    aspectRatio:
                        ReadingShareCard.width / ReadingShareCard.height,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: FittedBox(
                        child: RepaintBoundary(
                          key: _boundary,
                          // Rebuilds the card as the place or quote is typed.
                          child: ListenableBuilder(
                            listenable: Listenable.merge([_place, _quote]),
                            builder: (_, __) => ReadingShareCard(
                              data: _data,
                              template: _template,
                              tint: _tint,
                              photo: _photo,
                              place: _place.text,
                              quote: _quote.text,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _place,
                maxLength: 40,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: l10n.sessionPlace,
                  hintText: l10n.sessionPlaceHint,
                  prefixIcon: const Icon(Icons.place_outlined),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _quote,
                maxLength: _quoteMaxLength,
                minLines: 1,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: l10n.sessionQuote,
                  hintText: l10n.sessionQuoteHint,
                  prefixIcon: const Icon(Icons.format_quote_rounded),
                ),
              ),
              if (widget.quotes.isNotEmpty) _savedQuotes(context),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickPhoto(ImageSource.camera),
                      icon: const Icon(Icons.photo_camera_outlined, size: 18),
                      label: Text(l10n.sessionPhotoTake),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickPhoto(ImageSource.gallery),
                      icon: const Icon(Icons.photo_outlined, size: 18),
                      label: Text(l10n.sessionPhotoChoose),
                    ),
                  ),
                  if (_photo != null)
                    IconButton(
                      tooltip: l10n.sessionPhotoRemove,
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => setState(() => _photo = null),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Builder(
                builder: (buttonContext) => FilledButton.icon(
                  onPressed: (_ready && !_sharing)
                      ? () => _share(buttonContext)
                      : null,
                  icon: const Icon(Icons.ios_share_rounded, size: 18),
                  label: Text(l10n.sessionShare),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
