import 'package:flutter/material.dart';

import '../../../../core/widgets/error_view.dart';
import '../../../library/presentation/widgets/library_skeleton.dart';
import '../bloc/explore_section_cubit.dart';
import 'explore_home.dart';
import 'search_result_tile.dart';

/// The full list behind a shelf's "View all": skeleton while loading, retry on
/// failure, then one tile per book.
class ExploreBookList extends StatelessWidget {
  const ExploreBookList({
    super.key,
    required this.state,
    required this.onRetry,
  });

  final ExploreSectionState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (state.status.isFailure) {
      return ErrorView(failure: state.failure!, onRetry: onRetry);
    }
    if (!state.status.isSuccess) return const LibrarySkeleton();
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: state.books.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final book = state.books[index];
        return SearchResultTile(
          book: book,
          onTap: () => openBookPreview(context, book),
        );
      },
    );
  }
}
