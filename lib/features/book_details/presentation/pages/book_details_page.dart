import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/errors/failure_message.dart';
import '../../../../core/utils/l10n_extension.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/expandable_text.dart';
import '../../../../core/widgets/rating_bar.dart';
import '../../../library/domain/entities/reading_status.dart';
import '../../../library/domain/entities/user_book.dart';
import '../../../library/presentation/widgets/reading_status_ui.dart';
import '../../../library/presentation/widgets/status_picker_sheet.dart';
import '../../../search/domain/entities/book.dart';
import '../bloc/book_details_bloc.dart';
import '../widgets/book_image_carousel.dart';
import '../widgets/book_info_section.dart';
import '../widgets/notes_field.dart';
import '../widgets/reading_dates_section.dart';
import '../widgets/reading_progress_section.dart';
import '../widgets/section_title.dart';

class BookDetailsPage extends StatelessWidget {
  /// A book saved in the library, addressed by its `user_books.id`.
  const BookDetailsPage.library({super.key, required String userBookId})
      : _userBookId = userBookId,
        _book = null;

  /// A search result shown as a preview, with an "add" action.
  const BookDetailsPage.preview({super.key, required Book book})
      : _book = book,
        _userBookId = null;

  final String? _userBookId;
  final Book? _book;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final bloc = getIt<BookDetailsBloc>();
        final id = _userBookId;
        bloc.add(
          id != null
              ? BookDetailsLibraryRequested(id)
              : BookDetailsPreviewRequested(_book!),
        );
        return bloc;
      },
      child:
          BookDetailsView(heroTag: 'cover_${_userBookId ?? _book!.externalId}'),
    );
  }
}

class BookDetailsView extends StatelessWidget {
  const BookDetailsView({super.key, required this.heroTag});

  final String heroTag;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocListener<BookDetailsBloc, BookDetailsState>(
      listenWhen: (previous, current) =>
          previous.removed != current.removed ||
          (previous.saveStatus != current.saveStatus &&
              current.saveStatus.isFailure),
      listener: (context, state) {
        final messenger = ScaffoldMessenger.of(context);
        if (state.removed) {
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(l10n.bookRemoved)));
          context.pop();
        } else if (state.failure != null) {
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(content: Text(failureMessage(l10n, state.failure!))),
            );
        }
      },
      // Unfocusing on pop makes the notes field save before the page closes.
      child: PopScope(
        onPopInvokedWithResult: (_, __) => FocusScope.of(context).unfocus(),
        child: Scaffold(
          appBar: AppBar(
            actions: [
              BlocBuilder<BookDetailsBloc, BookDetailsState>(
                buildWhen: (p, c) => p.isInLibrary != c.isInLibrary,
                builder: (context, state) => state.isInLibrary
                    ? IconButton(
                        tooltip: l10n.removeBook,
                        icon: const Icon(Icons.delete_outline_rounded),
                        onPressed: () => _confirmRemove(context),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(2),
              child: BlocSelector<BookDetailsBloc, BookDetailsState, bool>(
                selector: (state) => state.saveStatus.isLoading,
                builder: (context, saving) => saving
                    ? const LinearProgressIndicator(minHeight: 2)
                    : const SizedBox(height: 2),
              ),
            ),
          ),
          body: BlocBuilder<BookDetailsBloc, BookDetailsState>(
            builder: (context, state) {
              if (state.status.isFailure && state.failure != null) {
                return ErrorView(failure: state.failure!);
              }
              final book = state.book;
              if (book == null) {
                return const Center(child: CircularProgressIndicator());
              }
              return _Content(state: state, book: book, heroTag: heroTag);
            },
          ),
        ),
      ),
    );
  }
}

Future<void> _confirmRemove(BuildContext context) async {
  final l10n = context.l10n;
  final bloc = context.read<BookDetailsBloc>();
  final title = bloc.state.book?.title ?? '';
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.removeBookTitle),
      content: Text(l10n.removeBookMessage(title)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            minimumSize: const Size(88, 44),
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.remove),
        ),
      ],
    ),
  );
  if (confirmed ?? false) bloc.add(const BookDetailsRemoveRequested());
}

class _Content extends StatelessWidget {
  const _Content({
    required this.state,
    required this.book,
    required this.heroTag,
  });

  final BookDetailsState state;
  final Book book;
  final String heroTag;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final userBook = state.userBook;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        BookImageCarousel(images: book.images, heroTag: heroTag),
        const SizedBox(height: 12),
        Text(
          book.title,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
        if (book.authors.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            book.authorsLabel,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 20),
        if (userBook == null)
          _AddButton(adding: state.saveStatus.isLoading)
        else
          _StatusSelector(status: userBook.status),
        if (book.description != null) ...[
          SectionTitle(l10n.description),
          ExpandableText(book.description!),
        ],
        SectionTitle(l10n.details),
        BookInfoSection(book: book),
        if (book.subjects.isNotEmpty) ...[
          SectionTitle(l10n.subjects),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final subject in book.subjects)
                Chip(
                  label: Text(subject),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ],
        if (userBook != null) ..._readingSections(context, userBook),
      ],
    );
  }

  List<Widget> _readingSections(BuildContext context, UserBook userBook) {
    final l10n = context.l10n;
    return [
      SectionTitle(l10n.myProgress),
      ReadingProgressSection(userBook: userBook),
      SectionTitle(l10n.myRating),
      Align(
        alignment: Alignment.centerLeft,
        child: AppRatingBar(
          rating: userBook.rating,
          onChanged: (rating) => context
              .read<BookDetailsBloc>()
              .add(BookDetailsRatingChanged(rating)),
        ),
      ),
      SectionTitle(l10n.readingDates),
      ReadingDatesSection(userBook: userBook),
      SectionTitle(l10n.notes),
      NotesField(initialNotes: userBook.notes),
      const SizedBox(height: 32),
      OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.error,
        ),
        icon: const Icon(Icons.delete_outline_rounded),
        label: Text(l10n.removeBook),
        onPressed: () => _confirmRemove(context),
      ),
    ];
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.adding});

  final bool adding;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FilledButton.icon(
      onPressed: adding
          ? null
          : () async {
              final bloc = context.read<BookDetailsBloc>();
              final status = await showStatusPickerSheet(context);
              if (status != null) bloc.add(BookDetailsAddRequested(status));
            },
      icon: adding
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.add_rounded),
      label: Text(l10n.addToLibrary),
    );
  }
}

class _StatusSelector extends StatelessWidget {
  const _StatusSelector({required this.status});

  final ReadingStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SegmentedButton<ReadingStatus>(
      showSelectedIcon: false,
      segments: [
        for (final s in ReadingStatus.values)
          ButtonSegment(
            value: s,
            icon: Icon(s.icon, size: 18),
            label: Text(
              s.label(l10n),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      selected: {status},
      onSelectionChanged: (selection) => context
          .read<BookDetailsBloc>()
          .add(BookDetailsStatusChanged(selection.first)),
    );
  }
}
