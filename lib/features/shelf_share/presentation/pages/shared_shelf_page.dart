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
import '../../../search/presentation/widgets/explore_home.dart';
import '../../../search/presentation/widgets/search_result_tile.dart';
import '../cubit/shared_shelf_cubit.dart';

/// A shelf opened from a share link: its books, read-only, and a button to
/// copy them into the reader's library.
class SharedShelfPage extends StatelessWidget {
  const SharedShelfPage({super.key, required this.token});

  final String token;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SharedShelfCubit>(param1: token)..load(),
      child: const SharedShelfView(),
    );
  }
}

class SharedShelfView extends StatelessWidget {
  const SharedShelfView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocConsumer<SharedShelfCubit, SharedShelfState>(
      listenWhen: (a, b) => a.saveStatus != b.saveStatus,
      listener: (context, state) {
        final message = switch (state.saveStatus) {
          SharedShelfSaveStatus.saved => l10n.sharedShelfSaved(state.added),
          SharedShelfSaveStatus.failure =>
            failureMessage(l10n, state.saveFailure!),
          _ => null,
        };
        if (message == null) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
      },
      builder: (context, state) {
        final shelf = state.shelf;
        return Scaffold(
          appBar: AppBar(
            // Opened from a link the page is the only route: offer the way
            // to the library instead of a back button that closes the app.
            leading: Navigator.of(context).canPop()
                ? null
                : IconButton(
                    tooltip: l10n.sharedShelfToLibrary,
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => context.go(AppRoutes.library),
                  ),
            title: Text(shelf?.shelfName ?? ''),
          ),
          body: _body(context, state),
          bottomNavigationBar: shelf == null || shelf.books.isEmpty
              ? null
              : SafeArea(
                  minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: FilledButton.icon(
                    onPressed: state.saveStatus == SharedShelfSaveStatus.saving
                        ? null
                        : context.read<SharedShelfCubit>().saveToLibrary,
                    icon: state.saveStatus == SharedShelfSaveStatus.saving
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.library_add_rounded),
                    label: Text(l10n.sharedShelfSave),
                  ),
                ),
        );
      },
    );
  }

  Widget _body(BuildContext context, SharedShelfState state) {
    final l10n = context.l10n;
    if (state.status.isFailure) {
      return ErrorView(
        failure: state.failure!,
        onRetry: context.read<SharedShelfCubit>().load,
      );
    }
    if (!state.status.isSuccess) return const LibrarySkeleton();
    final shelf = state.shelf;
    if (state.notFound || shelf == null) {
      return EmptyState(
        icon: Icons.link_off_rounded,
        title: l10n.sharedShelfNotFound,
      );
    }
    if (shelf.books.isEmpty) {
      return EmptyState(
        icon: Icons.shelves,
        title: l10n.sharedShelfEmpty,
      );
    }
    final theme = Theme.of(context);
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: shelf.books.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Text(
            [
              if (shelf.ownerName != null)
                l10n.sharedShelfOwner(shelf.ownerName!),
              l10n.sharedShelfBookCount(shelf.books.length),
            ].join(' · '),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          );
        }
        final book = shelf.books[index - 1];
        return SearchResultTile(
          book: book,
          onTap: () => openBookPreview(context, book),
        );
      },
    );
  }
}
