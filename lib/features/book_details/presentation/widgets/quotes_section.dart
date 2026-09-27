import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/l10n_extension.dart';
import '../../../quotes/domain/entities/book_quote.dart';
import '../bloc/book_details_bloc.dart';
import 'quote_editor_sheet.dart';

/// The passages saved from the book, with a way to add more.
class QuotesSection extends StatelessWidget {
  const QuotesSection({super.key, required this.quotes});

  final List<BookQuote> quotes;

  static Future<void> _edit(BuildContext context, [BookQuote? quote]) async {
    final bloc = context.read<BookDetailsBloc>();
    final draft = await showQuoteEditorSheet(context, initial: quote);
    if (draft == null || draft.text.isEmpty) return;
    bloc.add(
      BookDetailsQuoteSaved(text: draft.text, page: draft.page, id: quote?.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (quotes.isEmpty)
          Text(
            l10n.quotesEmpty,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        for (final quote in quotes) _QuoteCard(quote: quote),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(l10n.quoteAdd),
            onPressed: () => _edit(context),
          ),
        ),
      ],
    );
  }
}

enum _QuoteAction { copy, edit, delete }

class _QuoteCard extends StatelessWidget {
  const _QuoteCard({required this.quote});

  final BookQuote quote;

  Future<void> _onAction(BuildContext context, _QuoteAction action) async {
    final l10n = context.l10n;
    switch (action) {
      case _QuoteAction.copy:
        final messenger = ScaffoldMessenger.of(context);
        final page = quote.page;
        await Clipboard.setData(
          ClipboardData(
            text: page == null
                ? quote.text
                : '${quote.text} (${l10n.quotePageShort(page)})',
          ),
        );
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(l10n.quoteCopied)));
      case _QuoteAction.edit:
        await QuotesSection._edit(context, quote);
      case _QuoteAction.delete:
        final bloc = context.read<BookDetailsBloc>();
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            content: Text(
              '«${quote.text}»',
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
            ),
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
                child: Text(l10n.quoteDelete),
              ),
            ],
          ),
        );
        if (confirmed ?? false) bloc.add(BookDetailsQuoteRemoved(quote.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final page = quote.page;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => QuotesSection._edit(context, quote),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '«${quote.text}»',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    if (page != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        l10n.quotePageShort(page),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<_QuoteAction>(
                onSelected: (action) => _onAction(context, action),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: _QuoteAction.copy,
                    child: ListTile(
                      leading: const Icon(Icons.copy_rounded),
                      title: Text(l10n.quoteCopy),
                    ),
                  ),
                  PopupMenuItem(
                    value: _QuoteAction.edit,
                    child: ListTile(
                      leading: const Icon(Icons.edit_outlined),
                      title: Text(l10n.quoteEdit),
                    ),
                  ),
                  PopupMenuItem(
                    value: _QuoteAction.delete,
                    child: ListTile(
                      leading: Icon(
                        Icons.delete_outline_rounded,
                        color: theme.colorScheme.error,
                      ),
                      title: Text(
                        l10n.quoteDelete,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
