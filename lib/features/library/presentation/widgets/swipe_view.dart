import 'package:flutter/material.dart';

import '../../../../core/utils/cover_url.dart';
import '../../../../core/widgets/book_cover.dart';
import '../../../../core/widgets/book_open_target.dart';
import '../../../../core/widgets/page_indicator_bar.dart';
import '../../domain/entities/reading_status.dart';
import '../../domain/entities/user_book.dart';
import 'book_progress.dart';
import 'status_chip.dart';

/// One large cover at a time: swipe sideways through the library, with the
/// neighbours peeking in at the edges.
class SwipeView extends StatefulWidget {
  const SwipeView({super.key, required this.books, required this.onOpen});

  final List<UserBook> books;
  final ValueChanged<UserBook> onOpen;

  @override
  State<SwipeView> createState() => _SwipeViewState();
}

class _SwipeViewState extends State<SwipeView> {
  static const _viewportFraction = 0.66;

  final _controller = PageController(viewportFraction: _viewportFraction);
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get _page => _controller.hasClients &&
          _controller.position.haveDimensions &&
          _controller.page != null
      ? _controller.page!
      : _index.toDouble();

  @override
  Widget build(BuildContext context) {
    final books = widget.books;
    // Books may disappear (filter, removal) while the page is on the last one.
    final current = books[_index.clamp(0, books.length - 1)];

    return LayoutBuilder(
      builder: (context, constraints) {
        const captionHeight = 156.0;
        const indicatorHeight = 28.0;
        const gaps = 16.0;
        final pageWidth = constraints.maxWidth * _viewportFraction;
        // Poster proportions, but never taller than the space left over.
        final room =
            constraints.maxHeight - captionHeight - indicatorHeight - gaps - 24;
        final coverHeight = room.clamp(0.0, (pageWidth - 16) * 1.5);

        // Cover, caption and indicator form one group, centred on screen.
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: coverHeight + 24,
                child: PageView.builder(
                  controller: _controller,
                  itemCount: books.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) => _SwipeCover(
                    book: books[i],
                    height: coverHeight,
                    animation: _controller,
                    pageOf: () => _page,
                    index: i,
                    onTap: () => i == _index
                        ? widget.onOpen(books[i])
                        : _controller.animateToPage(
                            i,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                          ),
                  ),
                ),
              ),
              _Caption(book: current),
              const SizedBox(height: gaps),
              SizedBox(
                height: indicatorHeight,
                child: Center(
                  child: PageIndicatorBar(
                    controller: _controller,
                    count: books.length,
                    width: 96,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SwipeCover extends StatelessWidget {
  const _SwipeCover({
    required this.book,
    required this.height,
    required this.animation,
    required this.pageOf,
    required this.index,
    required this.onTap,
  });

  final UserBook book;
  final double height;
  final Listenable animation;
  final double Function() pageOf;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final distance = (pageOf() - index).abs().clamp(0.0, 1.0);
        return Opacity(
          opacity: 1 - 0.4 * distance,
          child: Transform.scale(scale: 1 - 0.18 * distance, child: child),
        );
      },
      child: Center(
        child: GestureDetector(
          onTap: () {
            BookOpenTarget.capture(context);
            onTap();
          },
          child: BookOpenTarget(
            url: book.book.coverUrl,
            title: book.book.title,
            author: book.book.authorsLabel,
            size: CoverSize.large,
            child: NaturalBookCover(
              url: book.book.coverUrl,
              title: book.book.title,
              author: book.book.authorsLabel,
              height: height,
              borderRadius: 6,
            ),
          ),
        ),
      ),
    );
  }
}

/// Title, author, status and progress of the focused book.
class _Caption extends StatelessWidget {
  const _Caption({required this.book});

  final UserBook book;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Fixed height: the cover area above must not resize between books.
    return SizedBox(
      height: 156,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          layoutBuilder: (current, previous) => Stack(
            alignment: Alignment.topCenter,
            children: [...previous, if (current != null) current],
          ),
          child: Column(
            key: ValueKey(book.id),
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                book.book.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge,
              ),
              if (book.book.authors.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  book.book.authorsLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              StatusChip(status: book.status),
              if (book.status == ReadingStatus.reading) ...[
                const SizedBox(height: 10),
                SizedBox(width: 180, child: BookProgress(book: book)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
