import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/l10n_extension.dart';
import '../../domain/entities/reading_insights.dart';

/// Yearly reading goal with a progress ring, or an invitation to set one.
class GoalCard extends StatelessWidget {
  const GoalCard({super.key, required this.insights, required this.onSetGoal});

  final ReadingInsights insights;

  /// Called with the new goal, or null to remove it.
  final ValueChanged<int?> onSetGoal;

  Future<void> _edit(BuildContext context) async {
    final result = await showDialog<_GoalResult>(
      context: context,
      builder: (_) => _GoalDialog(current: insights.goal),
    );
    if (result != null) onSetGoal(result.goal);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final goal = insights.goal;
    final read = insights.booksReadThisYear;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(
              scheme.brightness == Brightness.dark ? 90 : 28,
            ),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: goal == null
          ? Row(
              children: [
                const Icon(
                  Icons.flag_rounded,
                  color: AppColors.accent,
                  size: 32,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    l10n.statsGoalSet,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                FilledButton(
                  style:
                      FilledButton.styleFrom(minimumSize: const Size(72, 40)),
                  onPressed: () => _edit(context),
                  child: Text(l10n.statsGoalEdit),
                ),
              ],
            )
          : Row(
              children: [
                SizedBox(
                  width: 84,
                  height: 84,
                  child: CustomPaint(
                    painter: _RingPainter(
                      progress: insights.goalProgress ?? 0,
                      track: scheme.surfaceContainerHigh,
                    ),
                    child: Center(
                      child: Text(
                        '${((insights.goalProgress ?? 0) * 100).round()}%',
                        style: AppFonts.text(
                          size: 18,
                          weight: FontWeight.w800,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.statsGoalTitle(DateTime.now().year),
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.statsGoalProgress(read, goal),
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        read >= goal
                            ? l10n.statsGoalDone
                            : l10n.statsGoalLeft(goal - read),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: read >= goal
                              ? AppColors.accentDeep
                              : scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: l10n.statsGoalEdit,
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _edit(context),
                ),
              ],
            ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.track});

  final double progress;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 9.0;
    final rect = Offset.zero & size;
    final arc = rect.deflate(stroke / 2);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(arc, 0, math.pi * 2, false, base..color = track);
    if (progress > 0) {
      canvas.drawArc(
        arc,
        -math.pi / 2,
        math.pi * 2 * progress,
        false,
        base..color = AppColors.accent,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.track != track;
}

/// Wraps the chosen goal so "remove" (null) is distinguishable from cancel.
class _GoalResult {
  const _GoalResult(this.goal);

  final int? goal;
}

class _GoalDialog extends StatefulWidget {
  const _GoalDialog({required this.current});

  final int? current;

  @override
  State<_GoalDialog> createState() => _GoalDialogState();
}

class _GoalDialogState extends State<_GoalDialog> {
  late final _controller =
      TextEditingController(text: widget.current?.toString() ?? '');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int? get _value {
    final n = int.tryParse(_controller.text.trim());
    return (n != null && n >= 1 && n <= 1000) ? n : null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.statsGoalDialogTitle),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(hintText: l10n.statsGoalHint),
      ),
      actions: [
        if (widget.current != null)
          TextButton(
            onPressed: () => Navigator.pop(context, const _GoalResult(null)),
            child: Text(l10n.statsGoalRemove),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(72, 44)),
          onPressed: _value == null
              ? null
              : () => Navigator.pop(context, _GoalResult(_value)),
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
