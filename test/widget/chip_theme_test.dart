import 'package:bookshelf/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Light: resting light fill + dark label, selected dark fill + light label.
  // Dark mode is the mirror image. What matters is label vs. fill contrast.
  for (final (name, theme) in [
    ('light', AppTheme.light),
    ('dark', AppTheme.dark),
  ]) {
    for (final selected in [false, true]) {
      testWidgets(
          'chip label contrasts with its fill ($name, '
          '${selected ? 'selected' : 'resting'})', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: Scaffold(
              body: ChoiceChip(
                label: const Text('Fantasy'),
                selected: selected,
                onSelected: (_) {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final scheme = theme.colorScheme;
        final label = tester
            .renderObject<RenderParagraph>(find.text('Fantasy'))
            .text
            .style!
            .color;
        expect(label, selected ? scheme.onPrimary : scheme.onSurface);

        final fill =
            selected ? scheme.primary : theme.chipTheme.backgroundColor;
        expect(
          (fill!.computeLuminance() - label!.computeLuminance()).abs(),
          greaterThan(0.5),
          reason: 'label must stand out from the chip fill',
        );
      });
    }
  }
}
