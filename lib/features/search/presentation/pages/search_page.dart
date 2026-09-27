import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/errors/failure_message.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/utils/l10n_extension.dart';
import '../../../../core/utils/language_names.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../library/presentation/widgets/library_skeleton.dart';
import '../bloc/explore_bloc.dart';
import '../bloc/genre_shelf_cubit.dart';
import '../bloc/recommendations_cubit.dart';
import '../bloc/search_bloc.dart';
import '../widgets/explore_home.dart';
import '../widgets/search_result_tile.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key, this.initialQuery});

  /// Typed in for the reader, e.g. to look for the next book of a saga.
  final String? initialQuery;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<SearchBloc>()),
        BlocProvider(
          create: (_) => getIt<ExploreBloc>()..add(const ExploreStarted()),
        ),
        BlocProvider(create: (_) => getIt<GenreShelfCubit>()..load()),
        BlocProvider(create: (_) => getIt<RecommendationsCubit>()..load()),
      ],
      child: SearchView(initialQuery: initialQuery),
    );
  }
}

class SearchView extends StatefulWidget {
  const SearchView({super.key, this.initialQuery});

  final String? initialQuery;

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _apply(widget.initialQuery);
  }

  /// The tab stays alive between visits, so a new query arrives here.
  @override
  void didUpdateWidget(SearchView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialQuery != oldWidget.initialQuery) {
      _apply(widget.initialQuery);
    }
  }

  void _apply(String? query) {
    if (query == null || query.trim().isEmpty) return;
    _controller.text = query;
    context.read<SearchBloc>().add(SearchQueryChanged(query));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    context.read<SearchBloc>().add(SearchQueryChanged(value));
    setState(() {});
  }

  void _clear() {
    _controller.clear();
    _onQueryChanged('');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.searchTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: _SearchField(
              controller: _controller,
              hint: l10n.searchHint,
              onChanged: _onQueryChanged,
              onClear: _clear,
            ),
          ),
          const _LanguageFilter(),
          Expanded(
            child: BlocBuilder<SearchBloc, SearchState>(
              builder: (context, state) => _Results(state: state),
            ),
          ),
        ],
      ),
    );
  }
}

/// Quick filter to search only books that exist in one language. Shown once a
/// search is under way, so the Explore page stays clean.
class _LanguageFilter extends StatelessWidget {
  const _LanguageFilter();

  @override
  Widget build(BuildContext context) {
    final searching = context.select(
      (SearchBloc bloc) => !bloc.state.status.isInitial,
    );
    final selected = context.select((SearchBloc bloc) => bloc.state.language);
    if (!searching) return const SizedBox.shrink();
    final l10n = context.l10n;

    Widget chip(String label, String? code) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(label),
            selected: selected == code,
            onSelected: (_) =>
                context.read<SearchBloc>().add(SearchLanguageChanged(code)),
          ),
        );

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          chip(l10n.filterAll, null),
          for (final code in filterLanguages) chip(languageName(code), code),
        ],
      ),
    );
  }
}

/// White pill-cornered field lifted off the page by a soft shadow.
class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.hint,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const border = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(14)),
      borderSide: BorderSide.none,
    );
    return Material(
      elevation: 4,
      shadowColor: Colors.black.withAlpha(50),
      borderRadius: BorderRadius.circular(14),
      color: scheme.surfaceContainerLowest,
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.search,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search_rounded, size: 22),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (controller.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: onClear,
                ),
              IconButton(
                tooltip: context.l10n.scanTitle,
                icon: const Icon(Icons.qr_code_scanner_rounded),
                onPressed: () => context.push(AppRoutes.scan),
              ),
            ],
          ),
          fillColor: scheme.surfaceContainerLowest,
          border: border,
          enabledBorder: border,
          focusedBorder: border,
        ),
      ),
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({required this.state});

  final SearchState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bloc = context.read<SearchBloc>();

    if (state.status.isInitial) return const ExploreHome();
    if (state.status.isLoading) return const LibrarySkeleton();
    if (state.status.isFailure) {
      return ErrorView(
        failure: state.failure!,
        onRetry: () => bloc.add(SearchQueryChanged(state.query)),
      );
    }

    if (state.books.isEmpty) {
      return EmptyState(
        icon: Icons.search_off_rounded,
        title: l10n.searchNoResultsTitle,
        message: l10n.searchNoResultsMessage(state.query),
      );
    }

    final hasFooter = state.hasMore || state.loadMoreFailure != null;
    return ListView.separated(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: state.books.length + (hasFooter ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index >= state.books.length) {
          return _Footer(state: state);
        }
        final book = state.books[index];
        return SearchResultTile(
          book: book,
          onTap: () => context.push(
            AppRoutes.preview(book.externalId),
            extra: book,
          ),
        );
      },
    );
  }
}

/// Built lazily when the list end is reached; loading the next page from
/// here also covers screens tall enough to show every result without scrolling.
class _Footer extends StatefulWidget {
  const _Footer({required this.state});

  final SearchState state;

  @override
  State<_Footer> createState() => _FooterState();
}

class _FooterState extends State<_Footer> {
  @override
  void initState() {
    super.initState();
    if (widget.state.loadMoreFailure == null) _loadMore();
  }

  void _loadMore() =>
      context.read<SearchBloc>().add(const SearchNextPageRequested());

  @override
  Widget build(BuildContext context) {
    final failure = widget.state.loadMoreFailure;
    if (failure != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Text(
              failureMessage(context.l10n, failure),
              textAlign: TextAlign.center,
            ),
            TextButton(
              onPressed: _loadMore,
              child: Text(context.l10n.retry),
            ),
          ],
        ),
      );
    }
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
    );
  }
}
