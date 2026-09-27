import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/errors/failure_message.dart';
import '../../../../core/utils/l10n_extension.dart';
import '../../../../core/widgets/bar_chart.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../library/domain/entities/user_book.dart';
import '../../../library/presentation/bloc/library_bloc.dart';
import '../../domain/entities/month_detail.dart';
import '../../domain/entities/reading_insights.dart';
import '../../domain/entities/reading_log.dart';
import '../cubit/stats_cubit.dart';
import '../widgets/goal_card.dart';
import '../widgets/month_detail_sheet.dart';
import '../widgets/stat_tile.dart';
import '../widgets/subject_bars.dart';

/// Reading goal, streak, pace and charts.
class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<StatsCubit>()..load(),
      child: const StatsView(),
    );
  }
}

class StatsView extends StatelessWidget {
  const StatsView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocListener<StatsCubit, StatsState>(
      listenWhen: (p, c) =>
          c.goalFailure != null && p.goalFailure != c.goalFailure,
      listener: (context, state) => ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(failureMessage(l10n, state.goalFailure!))),
        ),
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.statsTitle)),
        body: BlocBuilder<StatsCubit, StatsState>(
          builder: (context, state) {
            if (state.status.isFailure && state.failure != null) {
              return ErrorView(
                failure: state.failure!,
                onRetry: () => context.read<StatsCubit>().load(),
              );
            }
            if (!state.status.isSuccess) {
              return const Center(child: CircularProgressIndicator());
            }
            final books =
                context.select((LibraryBloc bloc) => bloc.state.books);
            return _Content(
              insights: ReadingInsights.compute(
                books: books,
                logs: state.logs,
                goal: state.goal,
              ),
              books: books,
              logs: state.logs,
            );
          },
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({
    required this.insights,
    required this.books,
    required this.logs,
  });

  final ReadingInsights insights;
  final List<UserBook> books;
  final List<ReadingLog> logs;

  void _openMonth(BuildContext context, int year, int month) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => MonthDetailSheet(
        detail: MonthDetail.compute(
          books: books,
          logs: logs,
          year: year,
          month: month,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final number = NumberFormat.decimalPattern(locale);
    final now = DateTime.now();
    final monthInitials = [
      for (var m = 1; m <= 12; m++)
        DateFormat.MMM(locale)
            .format(DateTime(now.year, m))
            .substring(0, 1)
            .toUpperCase(),
    ];
    final dayLabels = [
      for (var i = 13; i >= 0; i--) '${now.subtract(Duration(days: i)).day}',
    ];
    final hours = insights.totalMinutes / 60;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        GoalCard(
          insights: insights,
          onSetGoal: (goal) => context.read<StatsCubit>().setGoal(goal),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.7,
          children: [
            StatTile(
              icon: Icons.local_fire_department_rounded,
              value: number.format(insights.streakDays),
              label: l10n.statsStreak,
            ),
            StatTile(
              icon: Icons.auto_stories_rounded,
              value: number.format(insights.avgPagesPerDay),
              label: l10n.statsPagesPerDay,
            ),
            StatTile(
              icon: Icons.schedule_rounded,
              value: insights.totalMinutes == 0
                  ? l10n.statsNoData
                  : l10n.statsHours(hours.toStringAsFixed(1)),
              label: l10n.statsTimeRead,
            ),
            StatTile(
              icon: Icons.star_rounded,
              value: insights.avgRating == null
                  ? l10n.statsNoData
                  : insights.avgRating!.toStringAsFixed(1),
              label: l10n.statsAvgRating,
            ),
          ],
        ),
        const SizedBox(height: 28),
        Text(l10n.statsBooksPerMonth, style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        BarChart(
          values: insights.booksPerMonth,
          labels: monthInitials,
          highlight: now.month - 1,
          onBarTap: (i) => _openMonth(context, now.year, i + 1),
        ),
        const SizedBox(height: 28),
        Text(l10n.statsPagesRecent, style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        BarChart(
          values: insights.pagesLast14Days,
          labels: dayLabels,
          highlight: 13,
        ),
        if (insights.topSubjects.isNotEmpty) ...[
          const SizedBox(height: 28),
          Text(l10n.statsTopSubjects, style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          SubjectBars(subjects: insights.topSubjects),
        ],
      ],
    );
  }
}
