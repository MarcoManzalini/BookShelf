import 'package:flutter/material.dart';

import '../../../../core/widgets/book_cover.dart';

/// Swipeable images. Today it holds the cover only; it is ready for spine and
/// back-cover images once a source provides them.
class BookImageCarousel extends StatefulWidget {
  const BookImageCarousel({
    super.key,
    required this.images,
    this.title,
    this.author,
    this.height = 300,
  });

  final List<String> images;
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
              final cover = NaturalBookCover(
                url: images[index],
                title: widget.title,
                author: widget.author,
                height: widget.height - 24,
              );
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: Center(child: cover),
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
