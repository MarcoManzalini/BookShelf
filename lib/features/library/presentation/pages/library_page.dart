import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/utils/l10n_extension.dart';
import '../../../../core/widgets/bookshelf_mark.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../shelf_share/presentation/widgets/shelf_share_sheet.dart';
import '../../domain/entities/shelf_names.dart';
import '../../domain/entities/user_book.dart';
import '../bloc/library_bloc.dart';
import '../widgets/book_extras_ui.dart';
import '../widgets/library_filter_sheet.dart';
import '../widgets/library_skeleton.dart';
import '../widgets/shelf_color.dart';
import '../widgets/shelf_view.dart';
import '../widgets/swipe_view.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(l10n.libraryTitle),
        leading: const _FilterButton(),
        actions: [
          BlocSelector<LibraryBloc, LibraryState, LibraryViewMode>(
            selector: (state) => state.viewMode,
            builder: (context, mode) {
              final onShelf = mode == LibraryViewMode.shelf;
              return IconButton(
                tooltip: onShelf ? l10n.viewSwipe : l10n.viewShelf,
                icon: Icon(
                  onShelf ? Icons.view_carousel_outlined : Icons.shelves,
                ),
                onPressed: () => context
                    .read<LibraryBloc>()
                    .add(const LibraryViewModeToggled()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const _OfflineBanner(),
          const _ShelfFilterChip(),
          Expanded(
            child: BlocBuilder<LibraryBloc, LibraryState>(
              builder: (context, state) => _Body(state: state),
            ),
          ),
        ],
      ),
    );
  }
}

/// Opens the status filter; a dot marks a filter that hides some books.
class _FilterButton extends StatelessWidget {
  const _FilterButton();

  @override
  Widget build(BuildContext context) {
    final filtered =
        context.select((LibraryBloc bloc) => bloc.state.hasActiveFilter);
    return IconButton(
      tooltip: context.l10n.filterTitle,
      icon: Badge(
        isLabelVisible: filtered,
        smallSize: 8,
        child: const Icon(Icons.tune_rounded),
      ),
      onPressed: () => showLibraryFilterSheet(context),
    );
  }
}

/// Tells the reader the list is the saved copy, and how many edits wait to be
/// sent. Tapping "retry" tries the server right away.
class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    final offline = context.select((LibraryBloc bloc) => bloc.state.offline);
    final pending =
        context.select((LibraryBloc bloc) => bloc.state.pendingChanges);
    if (!offline) return const SizedBox.shrink();
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: 20,
            color: theme.colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.offlineBanner,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
                if (pending > 0)
                  Text(
                    l10n.offlinePending(pending),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => context
                .read<LibraryBloc>()
                .add(const LibraryRefreshRequested()),
            child: Text(l10n.retry),
          ),
        ],
      ),
    );
  }
}

/// Shows the extra filters in use (shelf, mood, pace, loans), each with a
/// way to clear it.
class _ShelfFilterChip extends StatelessWidget {
  const _ShelfFilterChip();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bloc = context.read<LibraryBloc>();
    final (shelf, mood, pace, onLoan) = context.select(
      (LibraryBloc bloc) => (
        bloc.state.shelfFilter,
        bloc.state.moodFilter,
        bloc.state.paceFilter,
        bloc.state.onLoanOnly,
      ),
    );
    if (shelf == null && mood == null && pace == null && !onLoan) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            if (shelf != null)
              InputChip(
                avatar:
                    CircleAvatar(radius: 6, backgroundColor: shelfColor(shelf)),
                label: Text(l10n.shelfFilterLabel(shelf)),
                onDeleted: () =>
                    bloc.add(const LibraryShelfFilterChanged(null)),
              ),
            if (shelf != null)
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: l10n.shelfShareAction,
                icon: const Icon(Icons.ios_share_rounded, size: 20),
                onPressed: () => showShelfShareSheet(
                  context,
                  shelfName: shelf,
                  books: [
                    for (final b in bloc.state.books)
                      if (b.shelves.any((s) => ShelfNames.same(s, shelf)))
                        b.book,
                  ],
                ),
              ),
            if (mood != null)
              InputChip(
                avatar: const Icon(Icons.theater_comedy_outlined, size: 16),
                label: Text(mood.label(l10n)),
                onDeleted: () => bloc.add(const LibraryMoodFilterChanged(null)),
              ),
            if (pace != null)
              InputChip(
                avatar: const Icon(Icons.speed_rounded, size: 16),
                label: Text(pace.label(l10n)),
                onDeleted: () => bloc.add(const LibraryPaceFilterChanged(null)),
              ),
            if (onLoan)
              InputChip(
                avatar: const Icon(Icons.swap_horiz_rounded, size: 16),
                label: Text(l10n.filterLoans),
                onDeleted: () =>
                    bloc.add(const LibraryLoanFilterChanged(false)),
              ),
          ],
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.state});

  final LibraryState state;

  Future<void> _refresh(BuildContext context) {
    final bloc = context.read<LibraryBloc>();
    final done = bloc.stream.firstWhere((s) => !s.refreshing);
    bloc.add(const LibraryRefreshRequested());
    return done;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (state.books.isEmpty) {
      if (state.status.isFailure && state.failure != null) {
        return ErrorView(
          failure: state.failure!,
          onRetry: () =>
              context.read<LibraryBloc>().add(const LibraryStarted()),
        );
      }
      if (!state.status.isSuccess) return const LibrarySkeleton();
      return RefreshIndicator(
        onRefresh: () => _refresh(context),
        child: EmptyState(
          leading: const BookshelfMark(size: 96),
          title: l10n.libraryEmptyTitle,
          message: l10n.libraryEmptyMessage,
          actionLabel: l10n.libraryEmptyCta,
          onAction: () => context.go(AppRoutes.search),
        ),
      );
    }

    final books = state.visibleBooks;
    if (books.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _refresh(context),
        child: EmptyState(
          icon: Icons.filter_list_off_rounded,
          title: l10n.libraryFilterEmptyTitle,
          message: l10n.libraryFilterEmptyMessage,
        ),
      );
    }

    void open(UserBook book) => context.push(AppRoutes.bookDetails(book.id));

    return switch (state.viewMode) {
      LibraryViewMode.shelf => ShelfView(
          books: books,
          onOpen: open,
          onRefresh: () => _refresh(context),
        ),
      LibraryViewMode.swipe => RefreshIndicator(
          onRefresh: () => _refresh(context),
          // Pull-to-refresh needs a vertical scrollable; the carousel scrolls
          // sideways, so a bare one wraps it.
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: constraints.maxHeight,
                child: SwipeView(books: books, onOpen: open),
              ),
            ),
          ),
        ),
    };
  }
}
