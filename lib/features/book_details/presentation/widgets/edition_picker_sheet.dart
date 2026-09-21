import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/errors/failure_message.dart';
import '../../../../core/utils/cover_url.dart';
import '../../../../core/utils/l10n_extension.dart';
import '../../../../core/utils/language_names.dart';
import '../../../../core/widgets/book_cover.dart';
import '../../../search/domain/entities/book.dart';
import '../../../search/domain/entities/book_edition.dart';
import '../bloc/editions_cubit.dart';

/// Lets the reader pick the edition they actually own: page count, ISBN,
/// cover and publisher then match their copy.
Future<BookEdition?> showEditionPickerSheet(BuildContext context, Book book) {
  return showModalBottomSheet<BookEdition>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => BlocProvider(
      create: (_) => getIt<EditionsCubit>(param1: book)..load(),
      child: _EditionPicker(current: book),
    ),
  );
}

class _EditionPicker extends StatefulWidget {
  const _EditionPicker({required this.current});

  final Book current;

  @override
  State<_EditionPicker> createState() => _EditionPickerState();
}

class _EditionPickerState extends State<_EditionPicker> {
  /// null = every language. Starts on the reader's language when available.
  String? _language;
  bool _languageInitialised = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: BlocBuilder<EditionsCubit, EditionsState>(
          builder: (context, state) {
            if (state.status.isSuccess && !_languageInitialised) {
              _languageInitialised = true;
              final mine = iso3ForLanguage(
                Localizations.localeOf(context).languageCode,
              );
              if (mine != null && state.languages.contains(mine)) {
                _language = mine;
              }
            }
            final shown = state.editions
                .where((e) => _language == null || e.language == _language)
                .toList();
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                  child: Text(
                    l10n.editionTitle,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                if (state.languages.length > 1)
                  SizedBox(
                    height: 44,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        _LanguageChip(
                          label: l10n.filterAll,
                          selected: _language == null,
                          onTap: () => setState(() => _language = null),
                        ),
                        for (final code in state.languages)
                          _LanguageChip(
                            label: languageName(code),
                            selected: _language == code,
                            onTap: () => setState(() => _language = code),
                          ),
                      ],
                    ),
                  ),
                Flexible(child: _body(context, state, shown)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    EditionsState state,
    List<BookEdition> shown,
  ) {
    final l10n = context.l10n;
    if (state.status.isFailure) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(failureMessage(l10n, state.failure!)),
      );
    }
    if (!state.status.isSuccess) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (shown.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(l10n.editionNone),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      itemCount: shown.length,
      itemBuilder: (context, index) {
        final edition = shown[index];
        return _EditionTile(
          edition: edition,
          selected: edition.key == widget.current.editionKey,
          onTap: () => Navigator.pop(context, edition),
        );
      },
    );
  }
}

class _LanguageChip extends StatelessWidget {
  const _LanguageChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        labelStyle: TextStyle(
          color: selected
              ? Theme.of(context).colorScheme.onPrimary
              : Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}

class _EditionTile extends StatelessWidget {
  const _EditionTile({
    required this.edition,
    required this.selected,
    required this.onTap,
  });

  final BookEdition edition;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final headline = [
      if (edition.publisher != null) edition.publisher!,
      if (edition.publishedYear != null) '${edition.publishedYear}',
    ].join(' · ');
    final details = [
      if (edition.pageCount != null) l10n.pagesCount(edition.pageCount!),
      if (edition.format != null) edition.format!,
      if (edition.language != null) languageName(edition.language!),
    ].join(' · ');
    return ListTile(
      selected: selected,
      onTap: onTap,
      leading: BookCover(
        url: edition.coverUrl,
        title: edition.title,
        size: CoverSize.small,
        width: 40,
        height: 60,
      ),
      title: Text(
        headline.isEmpty ? (edition.title ?? edition.key) : headline,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        [
          if (details.isNotEmpty) details,
          if (edition.isbn != null) 'ISBN ${edition.isbn}',
        ].join('\n'),
        style: theme.textTheme.bodySmall,
      ),
      isThreeLine: details.isNotEmpty && edition.isbn != null,
      trailing: selected ? const Icon(Icons.check_circle_rounded) : null,
    );
  }
}
