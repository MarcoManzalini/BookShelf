import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/cover_color.dart';

/// Big chart number standing beside a cover, half hidden behind it. Takes the
/// color of the cover it belongs to (the accent until that is known).
class RankNumber extends StatefulWidget {
  const RankNumber({super.key, required this.rank, required this.coverUrl});

  final int rank;
  final String? coverUrl;

  static const fontSize = 172.0;

  /// Empty space under the digits inside the text box, as a fraction of
  /// [fontSize] (used to seat the digits on the cover's bottom edge).
  static const descent = 0.105;

  /// Width of the number left visible before the cover starts.
  static double slotFor(int rank) => rank >= 10 ? 80 : 48;

  @override
  State<RankNumber> createState() => _RankNumberState();
}

class _RankNumberState extends State<RankNumber> {
  Color? _color;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(RankNumber oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.coverUrl != widget.coverUrl) {
      _color = null;
      _resolve();
    }
  }

  Future<void> _resolve() async {
    final url = widget.coverUrl;
    if (url == null || url.isEmpty) return;
    final color = await coverColor(url);
    if (mounted && color != null && url == widget.coverUrl) {
      setState(() => _color = color);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(end: _color ?? AppColors.accent),
      duration: const Duration(milliseconds: 300),
      builder: (context, color, _) => Text(
        '${widget.rank}',
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.visible,
        style: AppFonts.text(
          size: RankNumber.fontSize,
          weight: FontWeight.w800,
          height: 1,
          letterSpacing: -6,
          color: color,
        ),
      ),
    );
  }
}
