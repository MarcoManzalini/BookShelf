import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/failure_message.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/utils/l10n_extension.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../domain/entities/book.dart';
import '../../domain/entities/explore_genre.dart';
import '../../domain/entities/explore_section.dart';
import '../bloc/explore_bloc.dart';
import '../bloc/genre_shelf_cubit.dart';
import '../bloc/recommendations_cubit.dart';
import 'book_rail.dart';
import 'explore_section_header.dart';
import 'new_arrivals_rail.dart';

extension ExploreSectionTitle on ExploreSection {
  String title(BuildContext context) {
    final l10n = context.l10n;
    return switch (this) {
      ExploreSection.bestSellers => l10n.exploreBestSellers,
      ExploreSection.newArrivals => l10n.exploreNewArrivals,
      ExploreSection.popular => l10n.explorePopular,
    };
  }
}

extension ExploreGenreLabel on ExploreGenre {
  String label(BuildContext context) {
    final l10n = context.l10n;
    return switch (this) {
      ExploreGenre.fantasy => l10n.genreFantasy,
      ExploreGenre.scienceFiction => l10n.genreScienceFiction,
      ExploreGenre.mystery => l10n.genreMystery,
      ExploreGenre.thriller => l10n.genreThriller,
      ExploreGenre.romance => l10n.genreRomance,
      ExploreGenre.historicalFiction => l10n.genreHistoricalFiction,
      ExploreGenre.horror => l10n.genreHorror,
      ExploreGenre.classics => l10n.genreClassics,
      ExploreGenre.biography => l10n.genreBiography,
      ExploreGenre.youngAdult => l10n.genreYoungAdult,
    };
  }
}

void openBookPreview(BuildContext context, Book book) =>
    context.push(AppRoutes.preview(book.externalId), extra: book);

/// Best sellers, new arrivals and popular books: what the page shows until
/// the reader starts typing.
class ExploreHome extends StatelessWidget {
  const ExploreHome({super.key});

  Future<void> _refresh(BuildContext context) {
    final bloc = context.read<ExploreBloc>();
    final done = bloc.stream.firstWhere((s) => !s.refreshing);
    bloc.add(const ExploreRefreshRequested());
    return Future.wait([
      done,
      context.read<GenreShelfCubit>().load(refresh: true),
      context.read<RecommendationsCubit>().load(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => _refresh(context),
      child: BlocBuilder<ExploreBloc, ExploreState>(
        builder: (context, state) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.only(top: 0, bottom: 40),
          children: [
            const _ForYou(),
            _Shelf(
              section: ExploreSection.bestSellers,
              shelf: state.of(ExploreSection.bestSellers),
            ),
            _Shelf(
              section: ExploreSection.popular,
              shelf: state.of(ExploreSection.popular),
            ),
            const _GenreShelf(),
            _Shelf(
              section: ExploreSection.newArrivals,
              shelf: state.of(ExploreSection.newArrivals),
            ),
          ],
        ),
      ),
    );
  }
}

/// One rail of suggestions drawn from the books the reader finished last.
/// Hidden until there is something to show.
class _ForYou extends StatelessWidget {
  const _ForYou();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RecommendationsCubit, RecommendationsState>(
      builder: (context, state) {
        if (state.books.isEmpty && !state.status.isLoading) {
          return const SizedBox.shrink();
        }
        final l10n = context.l10n;
        return _ShelfFrame(
          header: ExploreSectionHeader(
            title: l10n.exploreForYou,
            subtitle: l10n.exploreForYouHint,
          ),
          child: state.books.isEmpty
              ? const _ShelfSkeleton(wide: false)
              : BookRail(
                  books: state.books,
                  onTap: (book) => openBookPreview(context, book),
                ),
        );
      },
    );
  }
}

/// Same rhythm for every block of the page: header, gap, content.
class _ShelfFrame extends StatelessWidget {
  const _ShelfFrame({required this.header, required this.child, this.chips});

  final Widget header;
  final Widget child;

  /// Optional strip between header and content (the genre chips).
  final Widget? chips;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: header,
          ),
          if (chips != null) ...[const SizedBox(height: 12), chips!],
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _Shelf extends StatelessWidget {
  const _Shelf({required this.section, required this.shelf});

  final ExploreSection section;
  final ExploreShelf shelf;

  @override
  Widget build(BuildContext context) {
    if (shelf.status.isSuccess && shelf.books.isEmpty) {
      return const SizedBox.shrink();
    }
    final Widget content;
    if (shelf.status.isFailure) {
      content = _ShelfError(
        message: failureMessage(context.l10n, shelf.failure!),
        onRetry: () =>
            context.read<ExploreBloc>().add(const ExploreRefreshRequested()),
      );
    } else if (!shelf.status.isSuccess) {
      content = _ShelfSkeleton(
        wide: section == ExploreSection.newArrivals,
        withRating: section == ExploreSection.popular,
      );
    } else {
      void open(Book book) => openBookPreview(context, book);
      content = switch (section) {
        ExploreSection.newArrivals =>
          NewArrivalsRail(books: shelf.books, onTap: open),
        ExploreSection.bestSellers =>
          BookRail(books: shelf.books, onTap: open, ranked: true),
        ExploreSection.popular => BookRail(
            books: shelf.books,
            onTap: open,
            ranked: true,
            showRating: true,
          ),
      };
    }

    return _ShelfFrame(
      header: ExploreSectionHeader(
        title: section.title(context),
        subtitle: section == ExploreSection.popular
            ? context.l10n.exploreRankedHint
            : null,
        onViewAll: () => context.push(AppRoutes.exploreSection(section.name)),
      ),
      child: content,
    );
  }
}

/// Top rated books of one genre, picked with chips.
class _GenreShelf extends StatelessWidget {
  const _GenreShelf();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GenreShelfCubit, GenreShelfState>(
      builder: (context, state) {
        final Widget content;
        if (state.status.isFailure) {
          content = _ShelfError(
            message: failureMessage(context.l10n, state.failure!),
            onRetry: () => context.read<GenreShelfCubit>().load(),
          );
        } else if (!state.status.isSuccess) {
          content = const _ShelfSkeleton(wide: false, withRating: true);
        } else if (state.books.isEmpty) {
          content = const SizedBox(height: 8);
        } else {
          content = BookRail(
            books: state.books,
            onTap: (book) => openBookPreview(context, book),
            ranked: true,
            showRating: true,
          );
        }
        return _ShelfFrame(
          header: ExploreSectionHeader(
            title: context.l10n.exploreTopByGenre,
            subtitle: context.l10n.exploreRankedHint,
            onViewAll: () =>
                context.push(AppRoutes.exploreGenre(state.genre.name)),
          ),
          chips: SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: ExploreGenre.values.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final genre = ExploreGenre.values[index];
                return ChoiceChip(
                  label: Text(genre.label(context)),
                  selected: genre == state.genre,
                  onSelected: (_) =>
                      context.read<GenreShelfCubit>().select(genre),
                );
              },
            ),
          ),
          child: content,
        );
      },
    );
  }
}

class _ShelfSkeleton extends StatelessWidget {
  const _ShelfSkeleton({required this.wide, this.withRating = false});

  final bool wide;
  final bool withRating;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: wide
          ? NewArrivalsRail.height
          : (withRating ? BookRail.heightWithRating : BookRail.height),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, __) => wide
            ? const SkeletonBox(width: 268, height: 100, radius: 14)
            : const SkeletonBox(
                width: BookRail.coverWidth,
                height: BookRail.coverWidth * 1.5,
                radius: 4,
              ),
      ),
    );
  }
}

class _ShelfError extends StatelessWidget {
  const _ShelfError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(message, style: Theme.of(context).textTheme.bodySmall),
          ),
          TextButton(onPressed: onRetry, child: Text(context.l10n.retry)),
        ],
      ),
    );
  }
}
