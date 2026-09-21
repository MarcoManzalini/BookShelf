import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Slim track with a sliding thumb that follows a [PageController], one
/// thumb-width per page. Hidden when there is a single page.
class PageIndicatorBar extends StatelessWidget {
  const PageIndicatorBar({
    super.key,
    required this.controller,
    required this.count,
    this.width = 72,
  });

  final PageController controller;
  final int count;
  final double width;

  static const _height = 3.0;

  @override
  Widget build(BuildContext context) {
    if (count <= 1) return const SizedBox(height: _height);
    final track = Theme.of(context).colorScheme.outlineVariant;
    final thumbWidth = (width / count).clamp(18.0, width);
    return SizedBox(
      width: width,
      height: _height,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final page = controller.hasClients &&
                  controller.position.haveDimensions &&
                  controller.page != null
              ? controller.page!
              : controller.initialPage.toDouble();
          final progress = (page / (count - 1)).clamp(0.0, 1.0);
          return Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: track,
                    borderRadius: BorderRadius.circular(_height),
                  ),
                ),
              ),
              Positioned(
                left: (width - thumbWidth) * progress,
                width: thumbWidth,
                top: 0,
                bottom: 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(_height),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
