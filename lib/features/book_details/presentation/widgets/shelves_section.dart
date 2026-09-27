import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/l10n_extension.dart';
import '../../../library/domain/entities/user_book.dart';
import '../../../library/presentation/bloc/library_bloc.dart';
import '../../../library/presentation/widgets/shelf_color.dart';
import '../bloc/book_details_bloc.dart';
import 'shelf_picker_sheet.dart';

/// The custom shelves a saved book is on, with a shortcut to change them.
class ShelvesSection extends StatelessWidget {
  const ShelvesSection({super.key, required this.userBook});

  final UserBook userBook;

  Future<void> _edit(BuildContext context) async {
    final bloc = context.read<BookDetailsBloc>();
    final available = context.read<LibraryBloc>().state.shelfCounts.keys;
    final chosen = await showShelfPickerSheet(
      context,
      current: userBook.shelves,
      available: available,
    );
    if (chosen == null || !context.mounted) return;
    final before = {for (final s in userBook.shelves) s.toLowerCase()};
    final after = {for (final s in chosen) s.toLowerCase()};
    if (before.length == after.length && before.containsAll(after)) return;
    bloc.add(BookDetailsShelvesChanged(chosen));

    // Say what happened; a failed save replaces this with the error.
    final l10n = context.l10n;
    final added = [
      for (final s in chosen)
        if (!before.contains(s.toLowerCase())) s,
    ];
    final message = added.isNotEmpty
        ? l10n.shelfAdded(added.length, added.join(', '))
        : chosen.isEmpty
            ? l10n.shelfRemovedAll
            : l10n.shelvesUpdated;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final shelf in userBook.shelves)
          Chip(
            avatar: CircleAvatar(
              radius: 6,
              backgroundColor: shelfColor(shelf),
            ),
            label: Text(shelf),
            visualDensity: VisualDensity.compact,
          ),
        ActionChip(
          avatar: const Icon(Icons.add_rounded, size: 18),
          label: Text(l10n.addShelf),
          visualDensity: VisualDensity.compact,
          onPressed: () => _edit(context),
        ),
      ],
    );
  }
}
