import 'package:flutter/material.dart';

import '../../../../core/utils/cover_url.dart';
import '../../../../core/widgets/book_cover.dart';

/// Swipeable images. Today it holds the cover only; it is ready for spine and
/// back-cover images once a source provides them.
class BookImageCarousel extends StatefulWidget {
  const BookImageCarousel({
    super.key,
    required this.images,
    required this.heroTag,
    this.title,
    this.author,
    this.height = 300,
  });

  final List<String> images;
  final Object heroTag;
  final String? title;
  final String? author;
  final double height;

  @override
  State<BookImageCarousel> createState() => _BookImageCarouselState();
}

class _BookImageCarouselState extends State<BookImageCarousel> {
  final _controller = PageController(viewportFraction: 0.72);
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.images.isEmpty ? <String?>[null] : widget.images;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        SizedBox(
          height: widget.height,
          child: PageView.builder(
            controller: _controller,
            itemCount: images.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, index) {
              final cover = Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(46),
                        blurRadius: 20,
                        offset: const Offset(4, 10),
                      ),
                    ],
                  ),
                  child: BookCover(
                    url: images[index],
                    title: widget.title,
                    author: widget.author,
                    size: CoverSize.large,
                    borderRadius: 4,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              );
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: index == 0
                    ? Hero(tag: widget.heroTag, child: cover)
                    : cover,
              );
            },
          ),
        ),
        if (images.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < images.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _page ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color:
                          i == _page ? scheme.primary : scheme.outlineVariant,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
