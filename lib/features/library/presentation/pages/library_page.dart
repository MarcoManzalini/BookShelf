import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/utils/l10n_extension.dart';
import '../../../../core/widgets/bookshelf_mark.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_view.dart';
import '../bloc/library_bloc.dart';
import '../widgets/library_book_grid_item.dart';
import '../widgets/library_book_tile.dart';
import '../widgets/library_skeleton.dart';
import '../widgets/reading_status_ui.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.libraryTitle),
        actions: [
          BlocSelector<LibraryBloc, LibraryState, LibraryViewMode>(
            selector: (state) => state.viewMode,
            builder: (context, mode) => IconButton(
              tooltip:
                  mode == LibraryViewMode.list ? l10n.viewGrid : l10n.viewList,
              icon: Icon(
                mode == LibraryViewMode.list
                    ? Icons.grid_view_rounded
                    : Icons.view_list_rounded,
              ),
              onPressed: () => context
                  .read<LibraryBloc>()
                  .add(const LibraryViewModeToggled()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const _FilterBar(),
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

class _FilterBar extends StatelessWidget {
  const _FilterBar();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final selected = context.select((LibraryBloc bloc) => bloc.state.filter);
    String label(LibraryFilter filter) => switch (filter) {
          LibraryFilter.all => l10n.filterAll,
          LibraryFilter.wantToRead => l10n.statusWantToRead,
          LibraryFilter.reading => l10n.statusReading,
          LibraryFilter.read => l10n.statusRead,
        };
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: LibraryFilter.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = LibraryFilter.values[index];
          return ChoiceChip(
            label: Text(label(filter)),
            avatar: filter.status == null
                ? null
                : Icon(filter.status!.icon, size: 18),
            selected: filter == selected,
            onSelected: (_) =>
                context.read<LibraryBloc>().add(LibraryFilterChanged(filter)),
          );
        },
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

    void open(String id) => context.push(AppRoutes.bookDetails(id));

    return RefreshIndicator(
      onRefresh: () => _refresh(context),
      child: state.viewMode == LibraryViewMode.list
          ? ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              itemCount: books.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => LibraryBookTile(
                book: books[i],
                onTap: () => open(books[i].id),
              ),
            )
          : GridView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 190,
                mainAxisSpacing: 22,
                crossAxisSpacing: 0,
                childAspectRatio: 0.44,
              ),
              itemCount: books.length,
              itemBuilder: (_, i) => LibraryBookGridItem(
                book: books[i],
                onTap: () => open(books[i].id),
              ),
            ),
    );
  }
}
