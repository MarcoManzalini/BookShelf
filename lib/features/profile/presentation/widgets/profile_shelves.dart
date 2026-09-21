import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/l10n_extension.dart';
import '../../../library/presentation/bloc/library_bloc.dart';
import '../../../library/presentation/widgets/shelf_color.dart';

/// The reader's custom shelves as coloured bars with their book counts.
/// Tapping one opens the library narrowed to that shelf.
class ProfileShelves extends StatelessWidget {
  const ProfileShelves({super.key});

  @override
  Widget build(BuildContext context) {
    final shelves = context.select(
      (LibraryBloc bloc) => bloc.state.shelfCounts,
    );
    if (shelves.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.myShelves, style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        for (final entry in shelves.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ShelfBar(
              name: entry.key,
              count: entry.value,
              onTap: () {
                context.read<LibraryBloc>()
                  ..add(const LibraryFilterChanged(LibraryFilter.all))
                  ..add(LibraryShelfFilterChanged(entry.key));
                context.go(AppRoutes.library);
              },
            ),
          ),
      ],
    );
  }
}

class _ShelfBar extends StatelessWidget {
  const _ShelfBar({
    required this.name,
    required this.count,
    required this.onTap,
  });

  final String name;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = shelfColor(name);
    final onColor = onShelfColor(color);
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.text(
                    size: 15,
                    weight: FontWeight.w700,
                    color: onColor,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: onColor.withAlpha(46),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  style: AppFonts.text(
                    size: 13,
                    weight: FontWeight.w800,
                    color: onColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
