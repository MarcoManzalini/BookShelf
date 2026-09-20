import 'package:flutter/material.dart';

import '../../../../core/theme/app_typography.dart';

/// Typed section label followed by a hairline, like a catalogue divider.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 28, bottom: 12),
      child: Row(
        children: [
          Text(
            text.toUpperCase(),
            style: AppFonts.mono(
              size: 12.5,
              weight: FontWeight.w700,
              letterSpacing: 1.8,
              color: scheme.tertiary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Divider(color: scheme.outlineVariant)),
        ],
      ),
    );
  }
}
