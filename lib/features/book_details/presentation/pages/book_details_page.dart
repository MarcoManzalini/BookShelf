import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/errors/failure_message.dart';
import '../../../../core/utils/l10n_extension.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/expandable_text.dart';
import '../../../../core/widgets/rating_bar.dart';
import '../../../library/domain/entities/reading_status.dart';
import '../../../library/domain/entities/series_catalog.dart';
import '../../../library/domain/entities/user_book.dart';
import '../../../library/presentation/bloc/library_bloc.dart';
import '../../../library/presentation/widgets/reading_status_ui.dart';
import '../../../library/presentation/widgets/status_picker_sheet.dart';
import '../../../search/domain/entities/book.dart';
import '../../../search/domain/entities/reader_activity.dart';
import '../bloc/book_details_bloc.dart';
import '../widgets/author_section.dart';
import '../widgets/book_image_carousel.dart';
import '../widgets/book_format_section.dart';
import '../widgets/book_info_section.dart';
import '../widgets/buy_links_section.dart';
import '../widgets/reader_activity_view.dart';
import '../widgets/edition_picker_sheet.dart';
import '../widgets/loan_section.dart';
import '../widgets/notes_field.dart';
import '../widgets/quotes_section.dart';
import '../widgets/reading_dates_section.dart';
import '../widgets/shelves_section.dart';
import '../widgets/reading_progress_section.dart';
import '../widgets/reading_session_sheet.dart';
import '../widgets/reading_share_card.dart';
import '../widgets/reading_share_sheet.dart';
import '../widgets/reading_sessions_list.dart';
import '../widgets/related_books_row.dart';
import '../widgets/section_title.dart';
import '../widgets/series_section.dart';
import '../widgets/vibe_section.dart';

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
      child: const BookDetailsView(),
    );
  }
}

class BookDetailsView extends StatelessWidget {
  const BookDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MultiBlocListener(
      listeners: [
        BlocListener<BookDetailsBloc, BookDetailsState>(
          listenWhen: (previous, current) =>
              previous.userBook?.status != ReadingStatus.read &&
              previous.userBook != null &&
              current.userBook?.series?.lastIndex != null &&
              current.userBook?.status == ReadingStatus.read,
          listener: _suggestNextInSeries,
        ),
      ],
      child: BlocListener<BookDetailsBloc, BookDetailsState>(
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
                return _Content(state: state, book: book);
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Finishing a volume points to the next one: open it if it is already in
  /// the library, else search for it.
  void _suggestNextInSeries(BuildContext context, BookDetailsState state) {
    final l10n = context.l10n;
    final finished = state.userBook!;
    final series = finished.series!;
    final books = context.read<LibraryBloc>().state.books;
    final saga = SeriesCatalog.find(books, series.name);
    final next = series.nextIndex(sagaTotal: saga?.total);
    if (next == null) return;
    final inLibrary = saga?.bookWith(next);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 8),
          content: Text(l10n.seriesNextSnack(series.name, next)),
          action: SnackBarAction(
            label:
                inLibrary != null ? l10n.seriesNextOpen : l10n.seriesNextSearch,
            onPressed: () => inLibrary != null
                ? context.push(AppRoutes.bookDetails(inLibrary.id))
                : context.go(
                    AppRoutes.searchFor(
                      [series.name, finished.book.authors.firstOrNull]
                          .nonNulls
                          .join(' '),
                    ),
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
  });

  final BookDetailsState state;
  final Book book;
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final userBook = state.userBook;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        BookImageCarousel(
          images: book.images,
          title: book.title,
          author: book.authorsLabel,
        ),
        const SizedBox(height: 12),
        Text(
          book.title,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium,
        ),
        if (book.authors.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            book.authorsLabel,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w400,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (book.hasCommunityRating) ...[
          const SizedBox(height: 8),
          _CommunityRating(
            average: book.ratingAverage!,
            count: book.ratingsCount!,
          ),
        ],
        if (state.activity case final activity?)
          ReaderCountsLine(activity: activity),
        const SizedBox(height: 20),
        if (userBook == null)
          _AddButton(adding: state.saveStatus.isLoading)
        else
          _StatusSelector(status: userBook.status),
        if (state.activity case final activity?)
          ReadOnlineButton(
            workId: book.externalId,
            access: activity.ebookAccess,
          ),
        if (book.description != null) ...[
          SectionTitle(l10n.description),
          ExpandableText(book.description!),
        ],
        SectionTitle(l10n.details),
        BookInfoSection(book: book),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            icon: const Icon(Icons.auto_stories_outlined, size: 18),
            label: Text(l10n.editionChange),
            onPressed: () async {
              final bloc = context.read<BookDetailsBloc>();
              final edition = await showEditionPickerSheet(context, book);
              if (edition != null) {
                bloc.add(BookDetailsEditionSelected(edition));
              }
            },
          ),
        ),
        SectionTitle(l10n.buyTitle),
        BuyLinksSection(
          book: book,
          borrowable: state.activity?.ebookAccess == EbookAccess.borrowable,
        ),
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
        if (state.author != null) ...[
          SectionTitle(l10n.aboutAuthor),
          AuthorSection(author: state.author!),
        ],
        if (state.moreByAuthor.isNotEmpty) ...[
          SectionTitle(
            l10n.moreByAuthor(state.author?.name ?? book.authorsLabel),
          ),
          RelatedBooksRow(
            books: state.moreByAuthor,
            onTap: (b) => _openBook(context, b),
          ),
        ],
        if (state.similarBooks.isNotEmpty) ...[
          SectionTitle(l10n.similarBooks),
          RelatedBooksRow(
            books: state.similarBooks,
            onTap: (b) => _openBook(context, b),
          ),
        ],
        if (userBook != null) ...[
          const SizedBox(height: 32),
          _RemoveButton(onPressed: () => _confirmRemove(context)),
        ],
      ],
    );
  }

  /// Registers a session and, once it is saved, offers to share it.
  Future<void> _logSession(BuildContext context, UserBook userBook) async {
    final bloc = context.read<BookDetailsBloc>();
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final session = await showReadingSessionSheet(context, userBook);
    if (session == null) return;
    final lastLog = bloc.state.logs.firstOrNull?.id;
    bloc.add(
      BookDetailsSessionLogged(
        endPage: session.endPage,
        minutes: session.minutes,
      ),
    );
    final BookDetailsState saved;
    try {
      saved = await bloc.stream
          .firstWhere((s) => s.logs.firstOrNull?.id != lastLog)
          .timeout(const Duration(seconds: 8), onTimeout: () => bloc.state);
    } on StateError {
      return;
    }
    final log = saved.logs.firstOrNull;
    final saveBook = saved.userBook;
    // No new log: nothing was saved (or a time-less, page-less session).
    if (log == null || log.id == lastLog || saveBook == null) return;
    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.sessionSaved),
        action: SnackBarAction(
          label: l10n.sessionShare,
          onPressed: () {
            if (!context.mounted) return;
            showReadingShareSheet(
              context,
              ReadingShareData.from(saveBook, log),
              quotes: bloc.state.quotes,
            );
          },
        ),
      ),
    );
  }

  List<Widget> _readingSections(BuildContext context, UserBook userBook) {
    final l10n = context.l10n;
    final library = context.select((LibraryBloc bloc) => bloc.state.books);
    return [
      SectionTitle(l10n.shelvesTitle),
      ShelvesSection(userBook: userBook),
      SectionTitle(l10n.seriesTitle),
      SeriesSection(userBook: userBook, library: library),
      SectionTitle(l10n.formatTitle),
      BookFormatSection(userBook: userBook),
      SectionTitle(l10n.myProgress),
      ReadingProgressSection(userBook: userBook),
      const SizedBox(height: 8),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          icon: const Icon(Icons.timer_outlined, size: 18),
          label: Text(l10n.sessionRegister),
          onPressed: () => _logSession(context, userBook),
        ),
      ),
      if (state.logs.isNotEmpty) ...[
        SectionTitle(l10n.sessionsRecent),
        ReadingSessionsList(
          logs: state.logs,
          onShare: (log) => showReadingShareSheet(
            context,
            ReadingShareData.from(userBook, log),
            quotes: state.quotes,
          ),
        ),
      ],
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
      SectionTitle(l10n.vibeTitle),
      VibeSection(userBook: userBook),
      SectionTitle(l10n.readingDates),
      ReadingDatesSection(userBook: userBook),
      SectionTitle(l10n.loanTitle),
      LoanSection(userBook: userBook),
      SectionTitle(l10n.quotesTitle),
      QuotesSection(quotes: state.quotes),
      SectionTitle(l10n.notes),
      NotesField(initialNotes: userBook.notes),
    ];
  }

  void _openBook(BuildContext context, Book book) =>
      context.push(AppRoutes.preview(book.externalId), extra: book);
}

class _RemoveButton extends StatelessWidget {
  const _RemoveButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.error,
      ),
      icon: const Icon(Icons.delete_outline_rounded),
      label: Text(context.l10n.removeBook),
      onPressed: onPressed,
    );
  }
}

/// Open Library community rating, e.g. "★ 4.3 out of 5 · 444 ratings".
class _CommunityRating extends StatelessWidget {
  const _CommunityRating({required this.average, required this.count});

  final double average;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.star_rounded, size: 18, color: theme.colorScheme.secondary),
        const SizedBox(width: 4),
        Text(
          context.l10n.ratingSummary(average.toStringAsFixed(1), count),
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
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
    // Five statuses do not fit a segmented button on a phone: chips wrap.
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final s in ReadingStatus.values)
          ChoiceChip(
            avatar: Icon(s.icon, size: 18),
            showCheckmark: false,
            label: Text(s.label(l10n)),
            selected: s == status,
            onSelected: (_) {
              if (s != status) {
                context
                    .read<BookDetailsBloc>()
                    .add(BookDetailsStatusChanged(s));
              }
            },
          ),
      ],
    );
  }
}
