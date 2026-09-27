import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/l10n_extension.dart';
import '../bloc/library_bloc.dart';
import '../../domain/entities/book_vibe.dart';
import 'book_extras_ui.dart';
import 'reading_status_ui.dart';
import 'shelf_color.dart';

extension LibraryFilterLabel on LibraryFilter {
  String label(BuildContext context) {
    final l10n = context.l10n;
    return switch (this) {
      LibraryFilter.all => l10n.filterAll,
      LibraryFilter.wantToRead => l10n.statusWantToRead,
      LibraryFilter.reading => l10n.statusReading,
      LibraryFilter.paused => l10n.statusPaused,
      LibraryFilter.abandoned => l10n.statusAbandoned,
      LibraryFilter.read => l10n.statusRead,
    };
  }
}

/// Lets the reader narrow the library by reading status and by custom shelf.
Future<void> showLibraryFilterSheet(BuildContext context) {
  final bloc = context.read<LibraryBloc>();
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) {
      final l10n = sheetContext.l10n;
      final theme = Theme.of(sheetContext);
      final state = bloc.state;
      final shelves = state.shelfCounts;
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.8,
          ),
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child:
                    Text(l10n.filterTitle, style: theme.textTheme.titleMedium),
              ),
              for (final filter in LibraryFilter.values)
                ListTile(
                  leading: Icon(filter.status?.icon ?? Icons.layers_outlined),
                  title: Text(filter.label(sheetContext)),
                  trailing: filter == state.filter
                      ? const Icon(Icons.check_rounded)
                      : null,
                  selected: filter == state.filter,
                  onTap: () {
                    bloc.add(LibraryFilterChanged(filter));
                    Navigator.pop(sheetContext);
                  },
                ),
              if (shelves.isNotEmpty) ...[
                const Divider(height: 24),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                  child: Text(
                    l10n.shelvesTitle,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                for (final entry in shelves.entries)
                  ListTile(
                    leading: CircleAvatar(
                      radius: 8,
                      backgroundColor: shelfColor(entry.key),
                    ),
                    title: Text(entry.key),
                    trailing: Text('${entry.value}'),
                    selected: state.shelfFilter == entry.key,
                    onTap: () {
                      bloc.add(
                        LibraryShelfFilterChanged(
                          state.shelfFilter == entry.key ? null : entry.key,
                        ),
                      );
                      Navigator.pop(sheetContext);
                    },
                  ),
              ],
              const Divider(height: 24),
              _ChipsHeader(l10n.vibeTitle),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final mood in BookMood.values)
                      ChoiceChip(
                        label: Text(mood.label(l10n)),
                        selected: state.moodFilter == mood,
                        onSelected: (on) {
                          bloc.add(LibraryMoodFilterChanged(on ? mood : null));
                          Navigator.pop(sheetContext);
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _ChipsHeader(l10n.vibePace),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Wrap(
                  spacing: 8,
                  children: [
                    for (final pace in ReadingPace.values)
                      ChoiceChip(
                        label: Text(pace.label(l10n)),
                        selected: state.paceFilter == pace,
                        onSelected: (on) {
                          bloc.add(LibraryPaceFilterChanged(on ? pace : null));
                          Navigator.pop(sheetContext);
                        },
                      ),
                  ],
                ),
              ),
              if (state.hasLoans || state.onLoanOnly) ...[
                const Divider(height: 24),
                SwitchListTile(
                  secondary: const Icon(Icons.swap_horiz_rounded),
                  title: Text(l10n.filterLoans),
                  value: state.onLoanOnly,
                  onChanged: (on) {
                    bloc.add(LibraryLoanFilterChanged(on));
                    Navigator.pop(sheetContext);
                  },
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    },
  );
}

class _ChipsHeader extends StatelessWidget {
  const _ChipsHeader(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
        child: Text(text, style: Theme.of(context).textTheme.titleMedium),
      );
}
