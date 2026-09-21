import 'package:flutter/material.dart';

import '../../../../core/utils/cover_url.dart';
import '../../../../core/widgets/book_cover.dart';
import '../../../../core/widgets/book_open_target.dart';
import '../../../../core/widgets/page_indicator_bar.dart';
import '../../domain/entities/user_book.dart';

/// Covers standing on shelves, three to a row. Rows are as many as fit the
/// screen; further books go on the next swipeable page of shelves.
class ShelfView extends StatefulWidget {
  const ShelfView({
    super.key,
    required this.books,
    required this.onOpen,
    required this.onRefresh,
  });

  final List<UserBook> books;
  final ValueChanged<UserBook> onOpen;
  final Future<void> Function() onRefresh;

  static const columns = 3;

  @override
  State<ShelfView> createState() => _ShelfViewState();
}

const _sideGutter = 22.0;
const _coverGap = 18.0;

/// Shelf board seen from slightly above: a top surface (depth) that the books
/// stand on and a front edge (lip). Books sit [_bookRest] above the row's
/// bottom, i.e. part-way into the top surface.
const _shelfDepth = 18.0;
const _shelfLip = 8.0;
const _shelfHeight = _shelfDepth + _shelfLip;
const _bookRest = _shelfLip + _shelfDepth * 0.45 + 4;
const _minTopGap = 8.0;
const _indicatorArea = 44.0;

class _ShelfViewState extends State<ShelfView> {
  final _controller = PageController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final coverWidth =
            (width - 2 * _sideGutter - (ShelfView.columns - 1) * _coverGap) /
                ShelfView.columns;
        final coverHeight = coverWidth * 1.5;
        final rowMin = _minTopGap + coverHeight + _bookRest;
        final shelvesHeight = constraints.maxHeight - _indicatorArea;
        final rows = (shelvesHeight / rowMin).floor().clamp(1, 99);
        final perPage = rows * ShelfView.columns;
        final pageCount = (widget.books.length / perPage).ceil();

        return Column(
          children: [
            Expanded(
              child: PageView.builder(
                // A new page size (rotation) or shorter list must not leave the
                // controller on a page that no longer exists.
                key: ValueKey(perPage),
                controller: _controller,
                itemCount: pageCount,
                itemBuilder: (context, page) {
                  final start = page * perPage;
                  final slice = widget.books.skip(start).take(perPage).toList();
                  return RefreshIndicator(
                    onRefresh: widget.onRefresh,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: shelvesHeight,
                        child: Column(
                          children: [
                            for (var r = 0; r < rows; r++)
                              Expanded(
                                child: _ShelfRow(
                                  books: slice
                                      .skip(r * ShelfView.columns)
                                      .take(ShelfView.columns)
                                      .toList(),
                                  coverWidth: coverWidth,
                                  coverHeight: coverHeight,
                                  onOpen: widget.onOpen,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              height: _indicatorArea,
              child: Center(
                child: PageIndicatorBar(
                  controller: _controller,
                  count: pageCount,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ShelfRow extends StatelessWidget {
  const _ShelfRow({
    required this.books,
    required this.coverWidth,
    required this.coverHeight,
    required this.onOpen,
  });

  final List<UserBook> books;
  final double coverWidth;
  final double coverHeight;
  final ValueChanged<UserBook> onOpen;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned(
          left: 0,
          right: 0,
          bottom: 4,
          height: _shelfHeight,
          child: _Shelf(),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          bottom: _bookRest,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: _sideGutter),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < books.length; i++) ...[
                    if (i > 0) const SizedBox(width: _coverGap),
                    _ShelfBook(
                      book: books[i],
                      width: coverWidth,
                      height: coverHeight,
                      onTap: () => onOpen(books[i]),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ShelfBook extends StatelessWidget {
  const _ShelfBook({
    required this.book,
    required this.width,
    required this.height,
    required this.onTap,
  });

  final UserBook book;
  final double width;
  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: book.book.title,
      child: GestureDetector(
        onTap: () {
          BookOpenTarget.capture(context);
          onTap();
        },
        child: SizedBox(
          width: width,
          height: height,
          child: BookOpenTarget(
            url: book.book.coverUrl,
            title: book.book.title,
            author: book.book.authorsLabel,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(70),
                    blurRadius: 7,
                    offset: const Offset(1, 5),
                  ),
                ],
              ),
              child: BookCover(
                url: book.book.coverUrl,
                title: book.book.title,
                author: book.book.authorsLabel,
                size: CoverSize.medium,
                width: width,
                height: height,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A shelf board in perspective: the top surface narrows towards the back, a
/// slightly darker front edge closes it, and a soft shadow falls below.
class _Shelf extends StatelessWidget {
  const _Shelf();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: CustomPaint(
        size: Size.infinite,
        painter: _ShelfPainter(
          top: scheme.surfaceContainerHighest,
          back: scheme.surfaceContainerHigh,
          front: Color.lerp(
            scheme.surfaceContainerHighest,
            scheme.outline,
            0.4,
          )!,
          highlight: scheme.surfaceContainerLowest,
          shadow: Colors.black.withAlpha(
            scheme.brightness == Brightness.dark ? 150 : 46,
          ),
        ),
      ),
    );
  }
}

class _ShelfPainter extends CustomPainter {
  _ShelfPainter({
    required this.top,
    required this.back,
    required this.front,
    required this.highlight,
    required this.shadow,
  });

  final Color top;
  final Color back;
  final Color front;
  final Color highlight;
  final Color shadow;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final backInset = w * 0.045;

    final surface = Path()
      ..moveTo(backInset, 0)
      ..lineTo(w - backInset, 0)
      ..lineTo(w, _shelfDepth)
      ..lineTo(0, _shelfDepth)
      ..close();
    final lip = RRect.fromLTRBAndCorners(
      0,
      _shelfDepth,
      w,
      _shelfHeight,
      bottomLeft: const Radius.circular(2),
      bottomRight: const Radius.circular(2),
    );

    canvas.drawShadow(
      Path()
        ..addPath(surface, Offset.zero)
        ..addRRect(lip),
      shadow,
      6,
      false,
    );

    // Top surface: lighter towards the viewer, fading into the wall behind.
    canvas.drawPath(
      surface,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [back, top],
        ).createShader(Rect.fromLTWH(0, 0, w, _shelfDepth)),
    );
    canvas.drawRRect(lip, Paint()..color = front);
    // Bright edge where the surface turns into the front face.
    canvas.drawLine(
      const Offset(0, _shelfDepth),
      Offset(w, _shelfDepth),
      Paint()
        ..color = highlight.withAlpha(200)
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_ShelfPainter old) =>
      old.top != top ||
      old.back != back ||
      old.front != front ||
      old.highlight != highlight ||
      old.shadow != shadow;
}
