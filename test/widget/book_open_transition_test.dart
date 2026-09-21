import 'package:bookshelf/core/router/book_open_page.dart';
import 'package:bookshelf/core/utils/cover_url.dart';
import 'package:bookshelf/core/widgets/book_open_target.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';

void main() {
  group('BookOpenTarget', () {
    Widget list(void Function(BuildContext) onTapItem) => Scaffold(
          body: Column(
            children: [
              for (final i in [0, 1])
                Builder(
                  builder: (itemContext) => GestureDetector(
                    key: ValueKey('item_$i'),
                    onTap: () => onTapItem(itemContext),
                    child: Padding(
                      padding: EdgeInsets.only(left: 10.0 * (i + 1)),
                      child: BookOpenTarget(
                        url: 'u$i',
                        title: 'Book $i',
                        size: CoverSize.large,
                        child:
                            SizedBox(width: 50, height: 75, child: Text('$i')),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );

    testWidgets('captures the cover inside the tapped item, not another one',
        (tester) async {
      await tester.pumpApp(list(BookOpenTarget.capture));

      await tester.tap(find.byKey(const ValueKey('item_1')));
      final origin = BookOpenTarget.take();

      expect(origin, isNotNull);
      expect(origin!.url, 'u1');
      expect(origin.title, 'Book 1');
      expect(origin.size, CoverSize.large);
      expect(origin.rect.size, const Size(50, 75));
      expect(origin.rect.left, 20);
    });

    testWidgets('a capture is consumed once', (tester) async {
      await tester.pumpApp(list(BookOpenTarget.capture));

      await tester.tap(find.byKey(const ValueKey('item_0')));
      expect(BookOpenTarget.take(), isNotNull);
      expect(BookOpenTarget.take(), isNull);
    });

    testWidgets('a stale capture is ignored', (tester) async {
      await tester.pumpApp(list(BookOpenTarget.capture));

      await tester.tap(find.byKey(const ValueKey('item_0')));

      expect(
        BookOpenTarget.take(
          now: DateTime.now().add(const Duration(seconds: 5)),
        ),
        isNull,
      );
    });

    testWidgets('an item without a cover yields no origin', (tester) async {
      await tester.pumpApp(
        Builder(
          builder: (context) => GestureDetector(
            onTap: () => BookOpenTarget.capture(context),
            child: const SizedBox(width: 40, height: 40),
          ),
        ),
      );

      await tester.tap(find.byType(SizedBox));
      expect(BookOpenTarget.take(), isNull);
    });
  });

  group('BookOpenTransition', () {
    const origin = BookOpenOrigin(
      rect: Rect.fromLTWH(20, 300, 90, 135),
      url: null,
      size: CoverSize.medium,
      title: 'Dune',
    );

    testWidgets('reveals the page at the end and blocks touches meanwhile',
        (tester) async {
      final controller = AnimationController(
        vsync: const TestVSync(),
        duration: BookOpenTransition.duration,
      );
      addTearDown(controller.dispose);
      var taps = 0;
      await tester.pumpApp(
        BookOpenTransition(
          animation: controller,
          origin: origin,
          child: Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => taps++,
                child: const Text('details'),
              ),
            ),
          ),
        ),
      );

      double contentOpacity() => tester
          .widget<Opacity>(
            find
                .ancestor(
                  of: find.text('details'),
                  matching: find.byType(Opacity),
                )
                .first,
          )
          .opacity;

      // Cover in flight: details hidden and untouchable.
      controller.value = 0.2;
      await tester.pump();
      expect(contentOpacity(), 0);
      await tester.tap(find.text('details'), warnIfMissed: false);
      expect(taps, 0);

      // Cover open, page growing.
      controller.value = 0.6;
      await tester.pump();
      expect(tester.takeException(), isNull);

      // Done: page visible and interactive.
      controller.value = 1;
      await tester.pumpAndSettle();
      expect(contentOpacity(), 1);
      await tester.tap(find.text('details'));
      expect(taps, 1);
    });

    testWidgets('survives every frame of the animation', (tester) async {
      final controller = AnimationController(
        vsync: const TestVSync(),
        duration: BookOpenTransition.duration,
      );
      addTearDown(controller.dispose);
      await tester.pumpApp(
        BookOpenTransition(
          animation: controller,
          origin: origin,
          child: const Scaffold(body: Text('details')),
        ),
      );

      for (var t = 0.0; t <= 1.0; t += 0.02) {
        controller.value = t;
        await tester.pump();
        expect(tester.takeException(), isNull, reason: 'at t=$t');
      }
    });
  });
}
