import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/errors/failure_message.dart';
import '../../../../core/utils/l10n_extension.dart';
import '../../../../core/widgets/text_input_dialog.dart';
import '../../../library/domain/entities/reading_status.dart';
import '../../../library/presentation/bloc/library_bloc.dart';
import '../../data/library_export_service.dart';
import '../../data/open_library_reading_log.dart';
import '../../domain/import_row.dart';
import '../cubit/import_cubit.dart';

/// Bring a Goodreads or Open Library library in, or take yours out as a CSV.
class ImportExportPage extends StatelessWidget {
  const ImportExportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ImportCubit>(),
      child: Scaffold(
        appBar: AppBar(title: Text(context.l10n.ioTitle)),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: const [
            _ImportCard(),
            SizedBox(height: 16),
            _ExportCard(),
          ],
        ),
      ),
    );
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _ImportCard extends StatelessWidget {
  const _ImportCard();

  Future<void> _pick(BuildContext context) async {
    final cubit = context.read<ImportCubit>();
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['csv'],
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    cubit.loadFile(file.name, utf8.decode(bytes, allowMalformed: true));
  }

  Future<void> _askUsername(BuildContext context) async {
    final l10n = context.l10n;
    final cubit = context.read<ImportCubit>();
    final username = await showTextInputDialog<String>(
      context,
      title: l10n.ioOpenLibraryDialogTitle,
      hintText: l10n.ioOpenLibraryHint,
      keyboardType: TextInputType.url,
      parse: OpenLibraryReadingLog.parseUsername,
      validator: (text) => OpenLibraryReadingLog.parseUsername(text) == null
          ? l10n.ioOpenLibraryInvalid
          : null,
    );
    if (username != null) await cubit.loadOpenLibrary(username);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _CardShell(
      title: l10n.ioImportTitle,
      child: BlocBuilder<ImportCubit, ImportState>(
        builder: (context, state) => switch (state.step) {
          ImportStep.idle => _Idle(
              onPick: () => _pick(context),
              onOpenLibrary: () => _askUsername(context),
            ),
          ImportStep.fetching => const _Fetching(),
          ImportStep.invalidFile => _Invalid(onPick: () => _pick(context)),
          ImportStep.sourceFailed => _SourceFailed(
              error: state.sourceError!,
              onRetry: () => _askUsername(context),
            ),
          ImportStep.ready => _Ready(state: state),
          ImportStep.running => _Running(state: state),
          ImportStep.done => _Done(state: state),
        },
      ),
    );
  }
}

class _Idle extends StatelessWidget {
  const _Idle({required this.onPick, required this.onOpenLibrary});

  final VoidCallback onPick;
  final VoidCallback onOpenLibrary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.ioImportBody, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: onPick,
          icon: const Icon(Icons.upload_file_rounded),
          label: Text(l10n.ioPickFile),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                l10n.ioOrSeparator,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 20),
        Text(l10n.ioOpenLibraryBody, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: onOpenLibrary,
          icon: const Icon(Icons.local_library_outlined),
          label: Text(l10n.ioOpenLibraryButton),
        ),
      ],
    );
  }
}

class _Fetching extends StatelessWidget {
  const _Fetching();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              context.l10n.ioFetching,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

/// The Open Library reading log could not be read.
class _SourceFailed extends StatelessWidget {
  const _SourceFailed({required this.error, required this.onRetry});

  final ReadingLogError error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final message = switch (error) {
      ReadingLogError.userNotFound => l10n.ioOlUserNotFound,
      ReadingLogError.private => l10n.ioOlPrivate,
      ReadingLogError.empty => l10n.ioOlEmpty,
      ReadingLogError.network => l10n.ioOlNetwork,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          message,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => context.read<ImportCubit>().reset(),
                child: Text(l10n.ioBack),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: onRetry,
                child: Text(l10n.ioOpenLibraryButton),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Invalid extends StatelessWidget {
  const _Invalid({required this.onPick});

  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.ioInvalidFile,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton(onPressed: onPick, child: Text(l10n.ioTryAnother)),
      ],
    );
  }
}

class _Ready extends StatelessWidget {
  const _Ready({required this.state});

  final ImportState state;

  int _count(ReadingStatus status) =>
      state.rows.where((r) => r.status == status).length;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(state.fileName ?? '', style: theme.textTheme.bodySmall),
        const SizedBox(height: 6),
        Text(
          l10n.ioFound(state.rows.length),
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 2),
        Text(
          l10n.ioFoundBreakdown(
            _count(ReadingStatus.read),
            _count(ReadingStatus.reading),
            _count(ReadingStatus.wantToRead),
          ),
          style: theme.textTheme.bodyMedium,
        ),
        if (state.skippedLines > 0) ...[
          const SizedBox(height: 6),
          Text(
            l10n.ioSkippedLines(state.skippedLines),
            style: theme.textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => context.read<ImportCubit>().reset(),
                child: Text(l10n.cancel),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: () => context.read<ImportCubit>().start(),
                child: Text(l10n.ioStart),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Running extends StatelessWidget {
  const _Running({required this.state});

  final ImportState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final progress = state.progress!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.ioRunning, style: theme.textTheme.titleSmall),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child:
              LinearProgressIndicator(value: progress.fraction, minHeight: 10),
        ),
        const SizedBox(height: 8),
        Text(
          '${progress.processed} / ${progress.total}',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 10),
        Text(l10n.ioRunningHint, style: theme.textTheme.bodySmall),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () => context.read<ImportCubit>().cancel(),
          child: Text(l10n.ioCancel),
        ),
      ],
    );
  }
}

class _Done extends StatelessWidget {
  const _Done({required this.state});

  final ImportState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = state.progress!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (p.cancelled)
          _Notice(text: l10n.ioCancelled)
        else if (p.aborted != null)
          _Notice(
            text: '${l10n.ioAborted}\n${failureMessage(l10n, p.aborted!)}',
          ),
        _Line(label: l10n.ioImported, value: p.imported, strong: true),
        _Line(label: l10n.ioDuplicates, value: p.duplicates),
        _Line(label: l10n.ioNotFound, value: p.notFound.length),
        if (p.failed.isNotEmpty)
          _Line(label: l10n.ioFailed, value: p.failed.length),
        if (p.notFound.isNotEmpty || p.failed.isNotEmpty)
          _Unmatched(rows: [...p.notFound, ...p.failed]),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => context.read<ImportCubit>().reset(),
          child: Text(l10n.ioDone),
        ),
      ],
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value, this.strong = false});

  final String label;
  final int value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Text(
            '$value',
            style: (strong
                ? theme.textTheme.titleMedium
                : theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

/// The books that could not be matched, so the reader can add them by hand.
class _Unmatched extends StatelessWidget {
  const _Unmatched({required this.rows});

  final List<ImportRow> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text(
        context.l10n.ioNotFound,
        style: theme.textTheme.titleSmall,
      ),
      children: [
        for (final row in rows.take(200))
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title:
                Text(row.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: row.author == null ? null : Text(row.author!),
          ),
      ],
    );
  }
}

class _ExportCard extends StatelessWidget {
  const _ExportCard();

  Future<void> _export(BuildContext context) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final books = context.read<LibraryBloc>().state.books;
    if (books.isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.ioExportEmpty)));
      return;
    }
    try {
      await getIt<LibraryExportService>().exportCsv(books);
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.ioExportError)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _CardShell(
      title: l10n.ioExportTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.ioExportBody,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => _export(context),
            icon: const Icon(Icons.ios_share_rounded),
            label: Text(l10n.ioExportButton),
          ),
        ],
      ),
    );
  }
}
