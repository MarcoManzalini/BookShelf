import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/l10n_extension.dart';
import '../../../library/presentation/bloc/library_bloc.dart';
import '../../../library/presentation/widgets/status_picker_sheet.dart';
import '../../domain/entities/book.dart';

/// Quick action on a search result: pick a status and add, or show "added".
class AddToLibraryButton extends StatelessWidget {
  const AddToLibraryButton({super.key, required this.book});

  final Book book;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final added = context.select(
      (LibraryBloc bloc) => bloc.state.containsExternalId(book.externalId),
    );
    final adding = context.select(
      (LibraryBloc bloc) => bloc.state.addingIds.contains(book.externalId),
    );

    if (adding) {
      return const SizedBox(
        width: 40,
        height: 40,
        child: Padding(
          padding: EdgeInsets.all(10),
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      );
    }
    if (added) {
      return Chip(
        avatar: Icon(
          Icons.check_circle_rounded,
          size: 18,
          color: Theme.of(context).colorScheme.primary,
        ),
        label: Text(l10n.added),
        visualDensity: VisualDensity.compact,
        side: BorderSide.none,
      );
    }
    return IconButton.filledTonal(
      tooltip: l10n.addToLibrary,
      icon: const Icon(Icons.add_rounded),
      onPressed: () async {
        final bloc = context.read<LibraryBloc>();
        final status = await showStatusPickerSheet(context);
        if (status != null) bloc.add(LibraryBookAdded(book, status));
      },
    );
  }
}
