import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../library/domain/entities/user_book.dart';
import 'library_csv_exporter.dart';

/// Writes the library CSV to a temporary file and opens the share sheet.
class LibraryExportService {
  const LibraryExportService();

  Future<void> exportCsv(List<UserBook> books, {DateTime? now}) async {
    final day = (now ?? DateTime.now()).toIso8601String().substring(0, 10);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/bookshelf-library-$day.csv');
    await file.writeAsString(LibraryCsvExporter.build(books));
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'text/csv')],
        subject: 'BookShelf',
      ),
    );
  }
}
