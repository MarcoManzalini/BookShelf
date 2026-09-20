import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/errors/failure_message.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/utils/l10n_extension.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../library/presentation/widgets/library_skeleton.dart';
import '../bloc/search_bloc.dart';
import '../widgets/search_result_tile.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SearchBloc>(),
      child: const SearchView(),
    );
  }
}

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final _controller = TextEditingController();

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
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              onChanged: _onQueryChanged,
              decoration: InputDecoration(
                hintText: l10n.searchHint,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _controller.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: _clear,
                      ),
              ),
            ),
          ),
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

class _Results extends StatelessWidget {
  const _Results({required this.state});

  final SearchState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bloc = context.read<SearchBloc>();

    if (state.status.isInitial) {
      return EmptyState(
        icon: Icons.travel_explore_rounded,
        title: l10n.searchInitialTitle,
        message: l10n.searchInitialMessage,
      );
    }
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
