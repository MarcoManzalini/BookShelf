import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/goodreads_csv_parser.dart';
import '../../domain/import_row.dart';
import '../../domain/library_importer.dart';

enum ImportStep { idle, ready, running, done, invalidFile }

class ImportState extends Equatable {
  const ImportState({
    this.step = ImportStep.idle,
    this.fileName,
    this.rows = const [],
    this.skippedLines = 0,
    this.progress,
  });

  final ImportStep step;
  final String? fileName;
  final List<ImportRow> rows;

  /// Lines of the file that had no title.
  final int skippedLines;
  final ImportProgress? progress;

  @override
  List<Object?> get props => [step, fileName, rows, skippedLines, progress];
}

/// Drives the import screen: read the file, show what it holds, run the
/// import with progress, and report what happened.
class ImportCubit extends Cubit<ImportState> {
  ImportCubit(this._importer) : super(const ImportState());

  final LibraryImporter _importer;
  bool _cancel = false;
  StreamSubscription<ImportProgress>? _subscription;

  /// [text] is the decoded content of the picked file.
  void loadFile(String name, String text) {
    try {
      final result = GoodreadsCsvParser.parse(text);
      emit(
        result.rows.isEmpty
            ? ImportState(step: ImportStep.invalidFile, fileName: name)
            : ImportState(
                step: ImportStep.ready,
                fileName: name,
                rows: result.rows,
                skippedLines: result.skipped,
              ),
      );
    } on CsvFormatException {
      emit(ImportState(step: ImportStep.invalidFile, fileName: name));
    } catch (_) {
      // Anything else the CSV decoder chokes on is "not a readable file".
      emit(ImportState(step: ImportStep.invalidFile, fileName: name));
    }
  }

  Future<void> start() async {
    if (state.step != ImportStep.ready) return;
    _cancel = false;
    final rows = state.rows;
    emit(
      ImportState(
        step: ImportStep.running,
        fileName: state.fileName,
        rows: rows,
        skippedLines: state.skippedLines,
        progress: ImportProgress(total: rows.length),
      ),
    );

    final done = Completer<void>();
    _subscription = _importer.run(rows, isCancelled: () => _cancel).listen(
          (progress) => emit(
            ImportState(
              step: ImportStep.running,
              fileName: state.fileName,
              rows: rows,
              skippedLines: state.skippedLines,
              progress: progress,
            ),
          ),
          onDone: done.complete,
        );
    await done.future;

    emit(
      ImportState(
        step: ImportStep.done,
        fileName: state.fileName,
        rows: rows,
        skippedLines: state.skippedLines,
        progress: state.progress,
      ),
    );
  }

  /// Stops after the rows already in flight; what was imported stays.
  void cancel() => _cancel = true;

  void reset() => emit(const ImportState());

  @override
  Future<void> close() {
    _cancel = true;
    _subscription?.cancel();
    return super.close();
  }
}
