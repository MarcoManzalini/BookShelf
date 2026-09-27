import 'dart:io';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/cover_url.dart';
import '../../../../core/utils/l10n_extension.dart';
import '../../../../core/widgets/book_cover.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../book_details/presentation/widgets/share_cards/share_card_parts.dart';
import '../../../library/presentation/widgets/book_extras_ui.dart';
import '../../domain/reading_recap.dart';
import '../cubit/recap_cubit.dart';
import '../widgets/recap_share_card.dart';

/// "Your year (or month) in books": a few full-screen slides, ending with a
/// card to share.
class RecapPage extends StatelessWidget {
  const RecapPage({super.key, required this.period});

  final RecapPeriod period;

  /// "Il tuo 2026 in lettura" / "Il tuo settembre 2026 in lettura".
  static String titleOf(BuildContext context, RecapPeriod period) {
    final l10n = context.l10n;
    if (period.isYear) return l10n.recapTitleYear(period.year);
    final locale = Localizations.localeOf(context).toString();
    return l10n.recapTitleMonth(DateFormat.yMMMM(locale).format(period.start));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RecapCubit(getIt(), getIt(), period)..load(),
      // Always dark, like the stories it imitates.
      child: Theme(
        data: AppTheme.dark,
        child: Builder(
          builder: (context) => Scaffold(
            backgroundColor: shareInk,
            body: SafeArea(
              child: BlocBuilder<RecapCubit, RecapState>(
                builder: (context, state) {
                  final recap = state.recap;
                  if (state.status.isFailure && state.failure != null) {
                    return _Frame(
                      child: ErrorView(
                        failure: state.failure!,
                        onRetry: () => context.read<RecapCubit>().load(),
                      ),
                    );
                  }
                  if (recap == null) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (recap.isEmpty) {
                    return _Frame(
                      child: EmptyState(
                        icon: Icons.auto_stories_outlined,
                        title: context.l10n.recapEmptyTitle,
                        message: context.l10n.recapEmptyBody,
                      ),
                    );
                  }
                  return _Stories(
                    recap: recap,
                    title: titleOf(context, period),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A close button over [child], for the states without slides.
class _Frame extends StatelessWidget {
  const _Frame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: child),
        const Positioned(top: 4, right: 4, child: _CloseButton()),
      ],
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
      icon: const Icon(Icons.close_rounded, color: Colors.white),
      onPressed: () => Navigator.of(context).maybePop(),
    );
  }
}

class _Stories extends StatefulWidget {
  const _Stories({required this.recap, required this.title});

  final ReadingRecap recap;
  final String title;

  @override
  State<_Stories> createState() => _StoriesState();
}

class _StoriesState extends State<_Stories> {
  final _pages = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _go(int delta, int count) {
    final target = (_index + delta).clamp(0, count - 1);
    if (target == _index) return;
    _pages.animateToPage(
      target,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  List<Widget> _slides(BuildContext context) {
    final recap = widget.recap;
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final number = NumberFormat.decimalPattern(locale);
    final hasHabits = recap.activeDays > 0;
    final hasHighlights = recap.topRated != null ||
        recap.longest != null ||
        recap.fastest != null;
    final hasTaste = recap.topSubject != null ||
        recap.topMood != null ||
        recap.busiestMonth != null ||
        recap.formats.length > 1 ||
        recap.rereads > 0;

    return [
      _IntroSlide(recap: recap, title: widget.title),
      if (recap.finished.isNotEmpty)
        _Slide(
          accent: AppColors.accent,
          children: [
            _BigNumber(number.format(recap.finished.length)),
            _Caption(l10n.recapBooksLabel(recap.finished.length)),
            const SizedBox(height: 28),
            _CoverWall(reads: recap.finished),
          ],
        ),
      _Slide(
        accent: const Color(0xFF7DD3A8),
        children: [
          _BigNumber(number.format(recap.pagesRead)),
          _Caption(l10n.recapPagesLabel),
          if (recap.minutesRead > 0) ...[
            const SizedBox(height: 36),
            _BigNumber(
              recap.minutesRead >= 60
                  ? number.format((recap.minutesRead / 60).round())
                  : number.format(recap.minutesRead),
            ),
            _Caption(
              recap.minutesRead >= 60
                  ? l10n.recapHoursLabel
                  : l10n.recapMinutesLabel,
            ),
          ],
        ],
      ),
      if (hasHabits)
        _Slide(
          accent: const Color(0xFF8AB4F8),
          label: l10n.recapHabits,
          children: [
            _BigNumber(number.format(recap.activeDays)),
            _Caption(l10n.recapDaysLabel(recap.activeDays)),
            const SizedBox(height: 28),
            _BigNumber(number.format(recap.longestStreak), size: 56),
            _Caption(l10n.recapStreakLabel(recap.longestStreak)),
            const SizedBox(height: 28),
            if (recap.favoriteWeekday != null)
              _Line(
                l10n.recapWeekday(
                  DateFormat.EEEE(locale).format(
                    DateTime(2024, 1, recap.favoriteWeekday!),
                  ),
                ),
              ),
            if (recap.bestDay != null && recap.bestDayPages > 0)
              _Line(
                '${l10n.recapBestDay(DateFormat.MMMMd(locale).format(recap.bestDay!))}'
                ' · ${l10n.pagesCount(recap.bestDayPages)}',
              ),
          ],
        ),
      if (hasHighlights)
        _Slide(
          accent: const Color(0xFFF6C177),
          label: l10n.recapHighlights,
          children: [
            if (recap.topRated != null)
              _BookHighlight(
                label: l10n.recapTopRated,
                read: recap.topRated!,
                detail: '★' * recap.topRated!.book.rating!,
              ),
            if (recap.longest != null)
              _BookHighlight(
                label: l10n.recapLongest,
                read: recap.longest!,
                detail: l10n.pagesCount(recap.longest!.book.pageCount!),
              ),
            if (recap.fastest != null)
              _BookHighlight(
                label: l10n.recapFastest,
                read: recap.fastest!,
                detail: l10n.recapFastestDays(recap.fastest!.days!),
              ),
          ],
        ),
      if (hasTaste)
        _Slide(
          accent: const Color(0xFFE39AC5),
          label: l10n.recapTaste,
          children: [
            if (recap.topSubject != null)
              _Fact(label: l10n.recapTopGenre, value: recap.topSubject!),
            if (recap.topMood != null)
              _Fact(
                label: l10n.recapTopMood,
                value: recap.topMood!.label(l10n),
              ),
            if (recap.busiestMonth != null)
              _Fact(
                label: l10n.recapBusiestMonth,
                value: toBeginningOfSentenceCase(
                  DateFormat.MMMM(locale).format(
                    DateTime(recap.period.year, recap.busiestMonth!),
                  ),
                ),
              ),
            if (recap.formats.length > 1)
              _Fact(
                label: l10n.recapHowYouRead,
                value: [
                  for (final e in recap.formats.entries)
                    '${e.value} ${e.key.label(l10n).toLowerCase()}',
                ].join(' · '),
              ),
            if (recap.rereads > 0) _Line(l10n.recapRereads(recap.rereads)),
          ],
        ),
      _SummarySlide(recap: recap, title: widget.title),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final slides = _slides(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 4, 0),
          child: Row(
            children: [
              for (var i = 0; i < slides.length; i++)
                Expanded(
                  child: Container(
                    height: 3,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: i <= _index ? Colors.white : Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              const _CloseButton(),
            ],
          ),
        ),
        Expanded(
          child: GestureDetector(
            // Tap the left third to go back, anywhere else to go on.
            onTapUp: (details) {
              final width = MediaQuery.sizeOf(context).width;
              _go(details.localPosition.dx < width / 3 ? -1 : 1, slides.length);
            },
            child: PageView(
              controller: _pages,
              onPageChanged: (i) => setState(() => _index = i),
              children: slides,
            ),
          ),
        ),
      ],
    );
  }
}

class _Slide extends StatelessWidget {
  const _Slide({required this.accent, required this.children, this.label});

  final Color accent;
  final String? label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
      style: const TextStyle(color: Colors.white),
      child: _Accent(
        color: accent,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (label != null) ...[
                Text(
                  label!.toUpperCase(),
                  style: AppFonts.label(
                    size: 13,
                    weight: FontWeight.w700,
                    letterSpacing: 1.4,
                    color: accent,
                  ),
                ),
                const SizedBox(height: 20),
              ],
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

/// Makes the slide's accent color available to the pieces inside it.
class _Accent extends InheritedWidget {
  const _Accent({required this.color, required super.child});

  final Color color;

  static Color of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_Accent>()?.color ??
      AppColors.accent;

  @override
  bool updateShouldNotify(_Accent oldWidget) => color != oldWidget.color;
}

class _BigNumber extends StatelessWidget {
  const _BigNumber(this.value, {this.size = 88});

  final String value;
  final double size;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(
        value,
        style: AppFonts.text(
          size: size,
          weight: FontWeight.w800,
          height: 1,
          letterSpacing: -2,
          color: _Accent.of(context),
        ),
      ),
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(
          text,
          style: AppFonts.text(
            size: 20,
            weight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      );
}

class _Line extends StatelessWidget {
  const _Line(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          text,
          style: AppFonts.text(size: 16, color: Colors.white70),
        ),
      );
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppFonts.label(size: 14, color: Colors.white60)),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppFonts.text(
              size: 28,
              weight: FontWeight.w800,
              height: 1.15,
              color: _Accent.of(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _IntroSlide extends StatelessWidget {
  const _IntroSlide({required this.recap, required this.title});

  final ReadingRecap recap;
  final String title;

  @override
  Widget build(BuildContext context) {
    return _Slide(
      accent: AppColors.accent,
      children: [
        const ShareBrand(size: 26),
        const SizedBox(height: 48),
        Text(
          title,
          style: AppFonts.text(
            size: 40,
            weight: FontWeight.w800,
            height: 1.08,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 40),
        if (recap.finished.isNotEmpty) _CoverWall(reads: recap.finished),
        const SizedBox(height: 40),
        Text(
          context.l10n.recapStart,
          style: AppFonts.label(size: 14, color: Colors.white54),
        ),
      ],
    );
  }
}

/// The covers of the books finished, one per book.
class _CoverWall extends StatelessWidget {
  const _CoverWall({required this.reads});

  final List<RecapRead> reads;

  static const _max = 12;

  @override
  Widget build(BuildContext context) {
    final books = {for (final r in reads) r.book.id: r.book}.values.toList();
    return Wrap(
      spacing: 10,
      runSpacing: 12,
      children: [
        for (final book in books.take(_max))
          BookCover(
            url: book.book.coverUrl,
            title: book.book.title,
            author: book.book.authors.firstOrNull,
            width: 56,
            height: 84,
            size: CoverSize.medium,
          ),
      ],
    );
  }
}

class _BookHighlight extends StatelessWidget {
  const _BookHighlight({
    required this.label,
    required this.read,
    required this.detail,
  });

  final String label;
  final RecapRead read;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final book = read.book.book;
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Row(
        children: [
          BookCover(
            url: book.coverUrl,
            title: book.title,
            author: book.authors.firstOrNull,
            width: 52,
            height: 78,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppFonts.label(
                    size: 13,
                    weight: FontWeight.w700,
                    color: _Accent.of(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  book.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.text(
                    size: 18,
                    weight: FontWeight.w700,
                    height: 1.2,
                    color: Colors.white,
                  ),
                ),
                Text(
                  detail,
                  style: AppFonts.label(size: 13, color: Colors.white60),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummarySlide extends StatefulWidget {
  const _SummarySlide({required this.recap, required this.title});

  final ReadingRecap recap;
  final String title;

  @override
  State<_SummarySlide> createState() => _SummarySlideState();
}

class _SummarySlideState extends State<_SummarySlide> {
  final _boundary = GlobalKey();
  bool _sharing = false;

  /// Downloads the covers on the card first, so the exported picture never
  /// shows a placeholder.
  Future<void> _precacheCovers() async {
    final urls = {
      for (final r in widget.recap.finished)
        if (r.book.book.coverUrl?.isNotEmpty ?? false) r.book.book.coverUrl!,
    }.take(RecapShareCard.maxCovers);
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
    // Let the covers fade in before the picture is taken.
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  Future<void> _share(BuildContext buttonContext) async {
    final messenger = ScaffoldMessenger.of(context);
    final error = context.l10n.sessionShareError;
    final box = buttonContext.findRenderObject() as RenderBox?;
    final origin =
        box == null ? null : box.localToGlobal(Offset.zero) & box.size;
    setState(() => _sharing = true);
    try {
      await _precacheCovers();
      if (!mounted) return;
      final render = _boundary.currentContext!.findRenderObject()!
          as RenderRepaintBoundary;
      final image = await render.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) throw StateError('empty image');
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/bookshelf-recap-'
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: shareCardSize.width / shareCardSize.height,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: FittedBox(
                    child: RepaintBoundary(
                      key: _boundary,
                      child: RecapShareCard(
                        recap: widget.recap,
                        title: widget.title,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: Builder(
              builder: (buttonContext) => FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.ink,
                ),
                onPressed: _sharing ? null : () => _share(buttonContext),
                icon: _sharing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.ios_share_rounded, size: 18),
                label: Text(l10n.recapShare),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
