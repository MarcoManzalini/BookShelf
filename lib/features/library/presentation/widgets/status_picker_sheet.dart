import 'package:flutter/material.dart';

import '../../../../core/utils/l10n_extension.dart';
import '../../domain/entities/reading_status.dart';
import 'reading_status_ui.dart';

/// Bottom sheet to choose the initial reading status when adding a book.
Future<ReadingStatus?> showStatusPickerSheet(BuildContext context) {
  return showModalBottomSheet<ReadingStatus>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      final l10n = context.l10n;
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.addToLibraryAs,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ),
            for (final status in ReadingStatus.addable)
              ListTile(
                leading: Icon(status.icon),
                title: Text(status.label(l10n)),
                onTap: () => Navigator.of(context).pop(status),
              ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}
