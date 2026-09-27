import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/utils/l10n_extension.dart';
import '../../../library/domain/entities/book_series.dart';
import '../../../library/domain/entities/series_catalog.dart';
import '../../../library/domain/entities/user_book.dart';
import '../../../library/presentation/widgets/reading_status_ui.dart';
import '../bloc/book_details_bloc.dart';

/// "Volumes 1–2 of 3" of a saga, with the other books of it in the library.
class SeriesSection extends StatelessWidget {
  const SeriesSection({
    super.key,
    required this.userBook,
    required this.library,
  });

  final UserBook userBook;

  /// The whole library: the sagas to choose from and the other volumes.
  final List<UserBook> library;

  /// "Volume 2", "Volume 2 di 5", "Volumi 1–2 di 3"; null without a volume.
  static String? volumeLabel(
    BuildContext context,
    BookSeries series, {
    int? sagaTotal,
  }) {
    final l10n = context.l10n;
    final label = series.indexLabel;
    if (label == null) return null;
    final total = sagaTotal ?? series.total;
    if (series.isRange) {
      return total == null
          ? l10n.seriesVolumes(label)
          : l10n.seriesVolumesOf(label, total);
    }
    return total == null
        ? l10n.seriesVolume(label)
        : l10n.seriesVolumeOf(label, total);
  }

  Future<void> _edit(BuildContext context) async {
    final bloc = context.read<BookDetailsBloc>();
    final result = await showModalBottomSheet<_SeriesResult>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _SeriesEditor(
        initial: userBook.series,
        bookId: userBook.id,
        sagas: SeriesCatalog.of(library),
      ),
    );
    if (result != null) bloc.add(BookDetailsSeriesChanged(result.series));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final series = userBook.series;
    if (series == null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          icon: const Icon(Icons.collections_bookmark_outlined, size: 18),
          label: Text(l10n.seriesAdd),
          onPressed: () => _edit(context),
        ),
      );
    }
    final saga = SeriesCatalog.find(library, series.name);
    final others = [
      for (final b in saga?.books ?? const <UserBook>[])
        if (b.id != userBook.id) b,
    ];
    final label = volumeLabel(context, series, sagaTotal: saga?.total);
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.collections_bookmark_rounded),
            title: Text(series.name, style: theme.textTheme.titleMedium),
            subtitle: label == null ? null : Text(label),
            trailing: IconButton(
              tooltip: l10n.seriesEdit,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _edit(context),
            ),
          ),
          for (final other in others) ...[
            const Divider(height: 1),
            ListTile(
              dense: true,
              leading: Icon(other.status.icon, size: 20),
              title: Text(
                other.book.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: other.series!.index == null
                  ? null
                  : Text(volumeLabel(context, other.series!)!),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push(AppRoutes.bookDetails(other.id)),
            ),
          ],
        ],
      ),
    );
  }
}

/// The sheet's answer: a saga, or none when the book was taken out.
class _SeriesResult {
  const _SeriesResult(this.series);

  final BookSeries? series;
}

/// Two steps: pick (or create) the saga, then say which volumes the book
/// holds.
class _SeriesEditor extends StatefulWidget {
  const _SeriesEditor({
    required this.initial,
    required this.bookId,
    required this.sagas,
  });

  final BookSeries? initial;
  final String bookId;
  final List<Saga> sagas;

  @override
  State<_SeriesEditor> createState() => _SeriesEditorState();
}

class _SeriesEditorState extends State<_SeriesEditor> {
  final _formKey = GlobalKey<FormState>();
  final _search = TextEditingController();
  final _from = TextEditingController();
  final _to = TextEditingController();
  final _total = TextEditingController();

  /// Chosen saga name; null while picking.
  String? _name;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial != null) _prefill(initial.name, keep: initial);
    _search.addListener(() => setState(() {}));
    _from.addListener(() => setState(() {}));
    _to.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    _from.dispose();
    _to.dispose();
    _total.dispose();
    super.dispose();
  }

  Saga? get _saga => _name == null
      ? null
      : widget.sagas
          .where((s) => BookSeries.sameName(s.name, _name!))
          .firstOrNull;

  /// Other books of the chosen saga (not this one).
  List<UserBook> get _others => [
        for (final b in _saga?.books ?? const <UserBook>[])
          if (b.id != widget.bookId) b,
      ];

  /// Moves to the volume step for [name], prefilling what is known: the
  /// book's own volumes when editing, else the first free volume of the saga.
  void _choose(String name, {BookSeries? keep}) =>
      setState(() => _prefill(name, keep: keep));

  void _prefill(String name, {BookSeries? keep}) {
    _name = name.trim();
    final saga = _saga;
    String number(double? n) =>
        n == null ? '' : BookSeries(name: '', index: n).indexLabel!;
    if (keep != null && BookSeries.sameName(keep.name, name)) {
      _from.text = number(keep.index);
      _to.text = keep.isRange ? number(keep.indexEnd) : '';
      _total.text = (saga?.total ?? keep.total)?.toString() ?? '';
    } else {
      final others = _others;
      _from.text = others.isEmpty ? '1' : '${saga?.nextFreeVolume ?? 1}';
      _to.text = '';
      _total.text = saga?.total?.toString() ?? '';
    }
  }

  static double? _parse(String text) {
    final value = text.trim().replaceAll(',', '.');
    if (value.isEmpty) return null;
    final n = double.tryParse(value);
    // One decimal is enough for "2.5"; the column keeps one.
    return (n == null || n <= 0 || n > 9999) ? null : (n * 10).round() / 10;
  }

  /// A book of the saga that already holds one of the chosen volumes.
  UserBook? get _overlap {
    final from = _parse(_from.text);
    if (from == null) return null;
    final to = _parse(_to.text) ?? from;
    for (final b in _others) {
      final s = b.series!;
      final first = s.index;
      final last = s.lastIndex;
      if (first != null && last != null && from <= last && to >= first) {
        return b;
      }
    }
    return null;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final from = _parse(_from.text);
    final to = _parse(_to.text);
    final total = int.tryParse(_total.text.trim());
    Navigator.pop(
      context,
      _SeriesResult(
        BookSeries(
          name: _name!,
          index: from,
          indexEnd: (from != null && to != null && to > from) ? to : null,
          total: total != null && total > 0 ? total : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final picking = _name == null;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    picking ? l10n.seriesPickTitle : _name!,
                    style: theme.textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!picking)
                  TextButton(
                    onPressed: () => setState(() => _name = null),
                    child: Text(l10n.seriesChange),
                  ),
                IconButton(
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Flexible(child: picking ? _picker(context) : _volumes(context)),
        ],
      ),
    );
  }

  Widget _picker(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final query = _search.text.trim();
    final sagas = [
      for (final s in widget.sagas)
        if (s.name.toLowerCase().contains(query.toLowerCase())) s,
    ];
    final exact = widget.sagas.any((s) => BookSeries.sameName(s.name, query));
    final name = query.length > BookSeries.maxNameLength
        ? query.substring(0, BookSeries.maxNameLength)
        : query;
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: TextField(
            controller: _search,
            autofocus: widget.sagas.isEmpty,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              hintText: l10n.seriesSearchHint,
              prefixIcon: const Icon(Icons.search_rounded),
            ),
            onSubmitted: (_) {
              if (name.isNotEmpty) {
                final match = widget.sagas
                    .where((s) => BookSeries.sameName(s.name, name))
                    .firstOrNull;
                _choose(match?.name ?? name);
              }
            },
          ),
        ),
        const SizedBox(height: 8),
        if (name.isNotEmpty && !exact)
          ListTile(
            leading: const Icon(Icons.add_rounded),
            title: Text(l10n.seriesCreate(name)),
            onTap: () => _choose(name),
          ),
        if (widget.sagas.isEmpty && name.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
            child: Text(
              l10n.seriesNoSagas,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        for (final saga in sagas)
          ListTile(
            leading: const Icon(Icons.collections_bookmark_outlined),
            title: Text(saga.name),
            subtitle: Text(
              [
                l10n.seriesBooksInLibrary(saga.books.length),
                if (saga.total != null) l10n.seriesTotalCount(saga.total!),
              ].join(' · '),
            ),
            trailing: widget.initial != null &&
                    BookSeries.sameName(widget.initial!.name, saga.name)
                ? const Icon(Icons.check_rounded)
                : const Icon(Icons.chevron_right_rounded),
            onTap: () => _choose(saga.name, keep: widget.initial),
          ),
      ],
    );
  }

  Widget _volumes(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final overlap = _overlap;
    return Form(
      key: _formKey,
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _from,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: l10n.seriesIndex,
                    helperText: overlap == null
                        ? null
                        : l10n.seriesVolumeTaken(overlap.book.title),
                    helperMaxLines: 2,
                  ),
                  validator: (value) =>
                      (value ?? '').trim().isNotEmpty && _parse(value!) == null
                          ? l10n.seriesInvalid
                          : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _to,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: l10n.seriesIndexEnd),
                  validator: (value) {
                    final text = (value ?? '').trim();
                    if (text.isEmpty) return null;
                    final to = _parse(text);
                    final from = _parse(_from.text);
                    if (to == null) return l10n.seriesInvalid;
                    if (from == null || to <= from) {
                      return l10n.seriesRangeInvalid;
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l10n.seriesRangeHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _total,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l10n.seriesTotal,
              helperText: l10n.seriesTotalShared,
            ),
            validator: (value) {
              final text = (value ?? '').trim();
              if (text.isEmpty) return null;
              final n = int.tryParse(text);
              if (n == null || n <= 0) return l10n.seriesInvalid;
              final last = _parse(_to.text) ?? _parse(_from.text);
              if (last != null && n < last) return l10n.seriesTotalTooSmall;
              return null;
            },
          ),
          if (_others.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(l10n.seriesInLibrary, style: theme.textTheme.titleSmall),
            for (final b in _others)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(b.status.icon, size: 20),
                title: Text(
                  b.book.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: b.series!.index == null
                    ? null
                    : Text(SeriesSection.volumeLabel(context, b.series!)!),
              ),
          ],
          const SizedBox(height: 16),
          FilledButton(onPressed: _save, child: Text(l10n.save)),
          if (widget.initial != null)
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
              ),
              onPressed: () =>
                  Navigator.pop(context, const _SeriesResult(null)),
              child: Text(l10n.seriesRemove),
            ),
        ],
      ),
    );
  }
}
