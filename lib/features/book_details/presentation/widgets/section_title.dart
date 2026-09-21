import 'package:flutter/material.dart';

/// Bold section heading, left-aligned, in the style of the "Best Sellers" rows.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 28, bottom: 12),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}
