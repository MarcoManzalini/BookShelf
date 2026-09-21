import 'package:flutter/widgets.dart';

import '../utils/cover_url.dart';

/// Where a cover sits on screen when it is tapped: the starting point of the
/// "open the book" transition.
class BookOpenOrigin {
  const BookOpenOrigin({
    required this.rect,
    required this.url,
    required this.size,
    this.title,
    this.author,
  });

  final Rect rect;
  final String? url;
  final CoverSize size;
  final String? title;
  final String? author;
}

/// Marks a cover as a possible start of the open-book transition.
///
/// A tap handler calls [capture] with the context of the tapped item (any
/// ancestor of the cover); the router then takes the result with [take] when
/// it builds the details page. Going through a short-lived hand-off keeps the
/// many tap sites (shelf, swipe, search, rails, related books) free of route
/// arguments.
class BookOpenTarget extends StatefulWidget {
  const BookOpenTarget({
    super.key,
    required this.url,
    required this.child,
    this.title,
    this.author,
    this.size = CoverSize.medium,
  });

  final String? url;
  final String? title;
  final String? author;

  /// Cover size the child displays, so the flying copy reuses the image that
  /// is already in the image cache instead of flashing a placeholder.
  final CoverSize size;
  final Widget child;

  static BookOpenOrigin? _pending;
  static DateTime? _capturedAt;

  /// A capture that was never followed by a navigation must not leak into an
  /// unrelated one.
  static const _maxAge = Duration(seconds: 2);

  static void capture(BuildContext itemContext) {
    _BookOpenTargetState? found;
    void visit(Element element) {
      if (found != null) return;
      if (element is StatefulElement && element.state is _BookOpenTargetState) {
        found = element.state as _BookOpenTargetState;
        return;
      }
      element.visitChildren(visit);
    }

    itemContext.visitChildElements(visit);

    final target = found;
    final rect = target?._globalRect();
    _pending = (target == null || rect == null)
        ? null
        : BookOpenOrigin(
            rect: rect,
            url: target.widget.url,
            size: target.widget.size,
            title: target.widget.title,
            author: target.widget.author,
          );
    _capturedAt = DateTime.now();
  }

  /// Returns and clears the last capture, if it is fresh.
  static BookOpenOrigin? take({DateTime? now}) {
    final origin = _pending;
    final at = _capturedAt;
    _pending = null;
    _capturedAt = null;
    if (origin == null || at == null) return null;
    return (now ?? DateTime.now()).difference(at) <= _maxAge ? origin : null;
  }

  @override
  State<BookOpenTarget> createState() => _BookOpenTargetState();
}

class _BookOpenTargetState extends State<BookOpenTarget> {
  Rect? _globalRect() {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
