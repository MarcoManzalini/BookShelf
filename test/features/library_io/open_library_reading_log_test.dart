import 'package:bookshelf/features/library/domain/entities/reading_status.dart';
import 'package:bookshelf/features/library_io/data/open_library_reading_log.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

Map<String, dynamic> _entry(String id, String title) => {
      'work': {
        'title': title,
        'key': '/works/$id',
        'author_names': ['Frank Herbert'],
      },
      'logged_date': '2025/09/23, 02:11:08',
    };

void main() {
  late MockDio dio;
  late OpenLibraryReadingLog log;

  setUp(() {
    dio = MockDio();
    log = OpenLibraryReadingLog(dio);
  });

  void stubShelf(String shelf, List<Map<String, dynamic>> entries) {
    when(
      () => dio.get<Map<String, dynamic>>(
        '/people/reader/books/$shelf.json',
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(),
        data: {'numFound': entries.length, 'reading_log_entries': entries},
      ),
    );
  }

  void stubError(int status) {
    when(
      () => dio.get<Map<String, dynamic>>(
        any(),
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenThrow(
      DioException(
        requestOptions: RequestOptions(),
        response:
            Response(requestOptions: RequestOptions(), statusCode: status),
        type: DioExceptionType.badResponse,
      ),
    );
  }

  group('parseUsername', () {
    test('accepts names, @names and profile links', () {
      expect(OpenLibraryReadingLog.parseUsername(' mekBot '), 'mekBot');
      expect(
        OpenLibraryReadingLog.parseUsername('@mario_rossi'),
        'mario_rossi',
      );
      expect(
        OpenLibraryReadingLog.parseUsername(
          'https://openlibrary.org/people/mekBot/books/already-read',
        ),
        'mekBot',
      );
    });

    test('rejects anything else', () {
      expect(OpenLibraryReadingLog.parseUsername(''), isNull);
      expect(OpenLibraryReadingLog.parseUsername('two words'), isNull);
      expect(OpenLibraryReadingLog.parseUsername('a/b'), isNull);
    });
  });

  test('reads the three shelves with their statuses', () async {
    stubShelf('want-to-read', [_entry('OL1W', 'Dune Messiah')]);
    stubShelf('currently-reading', [_entry('OL2W', 'Children of Dune')]);
    stubShelf('already-read', [_entry('OL3W', 'Dune')]);

    final rows = await log.fetch('reader');

    expect(rows.map((r) => (r.workId, r.status)), [
      ('OL1W', ReadingStatus.wantToRead),
      ('OL2W', ReadingStatus.reading),
      ('OL3W', ReadingStatus.read),
    ]);
    expect(rows.last.title, 'Dune');
    expect(rows.last.author, 'Frank Herbert');
    expect(rows.last.addedOn, DateTime(2025, 9, 23));
    expect(rows.last.finishedOn, isNull);
  });

  test('an empty log is reported', () {
    for (final shelf in ['want-to-read', 'currently-reading', 'already-read']) {
      stubShelf(shelf, const []);
    }
    expect(
      log.fetch('reader'),
      throwsA(
        isA<ReadingLogException>()
            .having((e) => e.error, 'error', ReadingLogError.empty),
      ),
    );
  });

  for (final (status, error) in [
    (404, ReadingLogError.userNotFound),
    (403, ReadingLogError.private),
    (500, ReadingLogError.network),
  ]) {
    test('HTTP $status becomes $error', () {
      stubError(status);
      expect(
        log.fetch('reader'),
        throwsA(
          isA<ReadingLogException>().having((e) => e.error, 'error', error),
        ),
      );
    });
  }

  test('entries without a work are skipped', () {
    expect(
      OpenLibraryReadingLog.rowFromEntry(const {}, ReadingStatus.read),
      isNull,
    );
  });
}
