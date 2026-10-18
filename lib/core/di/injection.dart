import 'dart:io';

import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/cubit/auth_form_cubit.dart';
import '../../features/book_details/presentation/bloc/book_details_bloc.dart';
import '../../features/book_details/presentation/bloc/editions_cubit.dart';
import '../../features/home_widget/reading_widget_sync.dart';
import '../../features/library/data/datasources/library_remote_data_source.dart';
import '../../features/library/data/local/library_cache.dart';
import '../../features/library/data/repositories/library_repository_impl.dart';
import '../../features/library/domain/repositories/library_repository.dart';
import '../../features/library/domain/usecases/add_book_to_library.dart';
import '../../features/library/presentation/bloc/library_bloc.dart';
import '../../features/profile/data/datasources/profile_remote_data_source.dart';
import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/profile/presentation/bloc/profile_bloc.dart';
import '../../features/profile/presentation/cubit/theme_cubit.dart';
import '../../features/library_io/data/library_export_service.dart';
import '../../features/library_io/data/open_library_reading_log.dart';
import '../../features/library_io/domain/library_importer.dart';
import '../../features/library_io/presentation/cubit/import_cubit.dart';
import '../../features/quotes/data/datasources/quote_remote_data_source.dart';
import '../../features/quotes/data/repositories/quote_repository_impl.dart';
import '../../features/quotes/domain/repositories/quote_repository.dart';
import '../../features/reminders/data/loan_reminders.dart';
import '../../features/reminders/data/reading_reminders.dart';
import '../../features/reminders/data/reminder_scheduler.dart';
import '../../features/scanner/presentation/cubit/isbn_scan_cubit.dart';
import '../../features/shelf_share/data/datasources/shelf_share_remote_data_source.dart';
import '../../features/shelf_share/data/repositories/shelf_share_repository_impl.dart';
import '../../features/shelf_share/domain/repositories/shelf_share_repository.dart';
import '../../features/shelf_share/domain/usecases/save_shared_shelf.dart';
import '../../features/shelf_share/presentation/cubit/shared_shelf_cubit.dart';
import '../../features/shelf_share/presentation/cubit/shelf_share_cubit.dart';
import '../../features/stats/data/datasources/reading_log_remote_data_source.dart';
import '../../features/stats/data/repositories/reading_log_repository_impl.dart';
import '../../features/stats/domain/repositories/reading_log_repository.dart';
import '../../features/stats/presentation/cubit/stats_cubit.dart';
import '../../features/search/data/datasources/book_remote_data_source.dart';
import '../../features/search/data/search_language_preference.dart';
import '../../features/search/data/repositories/book_search_repository_impl.dart';
import '../../features/search/domain/repositories/book_search_repository.dart';
import '../../features/search/domain/entities/book.dart';
import '../../features/search/domain/entities/explore_genre.dart';
import '../../features/search/domain/entities/explore_section.dart';
import '../../features/search/presentation/bloc/explore_bloc.dart';
import '../../features/search/presentation/bloc/explore_genre_cubit.dart';
import '../../features/search/presentation/bloc/explore_section_cubit.dart';
import '../../features/search/presentation/bloc/genre_shelf_cubit.dart';
import '../../features/search/presentation/bloc/recommendations_cubit.dart';
import '../../features/search/presentation/bloc/search_bloc.dart';
import '../config/app_config.dart';
import '../router/app_router.dart';

final getIt = GetIt.instance;

Future<File> _libraryCacheFile() async {
  final dir = await getApplicationSupportDirectory();
  return File('${dir.path}/library_cache.json');
}

/// Registers everything. Requires `Supabase.initialize` to have run.
Future<void> configureDependencies() async {
  final prefs = await SharedPreferences.getInstance();

  getIt
    ..registerSingleton<SupabaseClient>(Supabase.instance.client)
    ..registerSingleton<SharedPreferences>(prefs)
    ..registerLazySingleton<Dio>(
      () => Dio(
        BaseOptions(
          baseUrl: AppConfig.openLibraryBaseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
          headers: const {
            'User-Agent': AppConfig.userAgent,
            'Accept': 'application/json',
          },
        ),
      ),
    )
    // Data sources
    ..registerLazySingleton(() => AuthRemoteDataSource(getIt()))
    ..registerLazySingleton<BookRemoteDataSource>(
      () => OpenLibraryDataSource(getIt()),
    )
    ..registerLazySingleton<LibraryRemoteDataSource>(
      () => SupabaseLibraryDataSource(getIt()),
    )
    ..registerLazySingleton(() => ProfileRemoteDataSource(getIt()))
    ..registerLazySingleton<ReadingLogRemoteDataSource>(
      () => SupabaseReadingLogDataSource(getIt()),
    )
    ..registerLazySingleton<QuoteRemoteDataSource>(
      () => SupabaseQuoteDataSource(getIt()),
    )
    ..registerLazySingleton<ShelfShareRemoteDataSource>(
      () => SupabaseShelfShareDataSource(getIt()),
    )
    // Repositories
    ..registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(getIt()))
    ..registerLazySingleton<BookSearchRepository>(
      () => BookSearchRepositoryImpl(getIt()),
    )
    ..registerLazySingleton<LibraryRepository>(
      () => LibraryRepositoryImpl(
        getIt(),
        cache: FileLibraryCache(_libraryCacheFile),
        currentUserId: () => getIt<SupabaseClient>().auth.currentUser?.id,
      ),
    )
    ..registerLazySingleton<ReadingLogRepository>(
      () => ReadingLogRepositoryImpl(getIt()),
    )
    ..registerLazySingleton<ProfileRepository>(
      () => ProfileRepositoryImpl(getIt()),
    )
    ..registerLazySingleton<QuoteRepository>(
      () => QuoteRepositoryImpl(getIt()),
    )
    ..registerLazySingleton<ShelfShareRepository>(
      () => ShelfShareRepositoryImpl(getIt()),
    )
    ..registerLazySingleton(() => SaveSharedShelf(getIt()))
    ..registerLazySingleton<ReminderScheduler>(LocalNotificationScheduler.new)
    ..registerLazySingleton(
      () => ReadingReminders(getIt(), getIt(), getIt(), getIt()),
      dispose: (r) => r.dispose(),
    )
    ..registerLazySingleton(
      () => LoanReminders(getIt(), getIt(), getIt()),
      dispose: (r) => r.dispose(),
    )
    ..registerLazySingleton(
      () => ReadingWidgetSync(getIt(), getIt(), getIt())..start(),
      dispose: (s) => s.dispose(),
    )
    // Use cases
    ..registerLazySingleton(() => AddBookToLibrary(getIt(), getIt()))
    // App-wide blocs (singletons, provided at the root)
    ..registerLazySingleton(() => AuthBloc(getIt()), dispose: (b) => b.close())
    ..registerLazySingleton(
      () => LibraryBloc(getIt(), getIt()),
      dispose: (b) => b.close(),
    )
    ..registerLazySingleton(
      () => ThemeCubit(getIt()),
      dispose: (c) => c.close(),
    )
    ..registerLazySingleton<GoRouter>(() => createRouter(getIt<AuthBloc>()))
    // Screen-scoped blocs (new instance per page)
    ..registerFactory(() => AuthFormCubit(getIt()))
    ..registerLazySingleton(() => SearchLanguagePreference(getIt()))
    ..registerFactory(
      () => SearchBloc(getIt(), languagePreference: getIt()),
    )
    ..registerFactory(() => ExploreBloc(getIt()))
    ..registerFactory(() => GenreShelfCubit(getIt()))
    ..registerFactory(() => RecommendationsCubit(getIt(), getIt()))
    ..registerFactory(() => IsbnScanCubit(getIt()))
    ..registerFactory(() => StatsCubit(getIt(), getIt()))
    ..registerLazySingleton(() => const LibraryExportService())
    ..registerFactory(
      () => ImportCubit(
        LibraryImporter(getIt(), getIt()),
        OpenLibraryReadingLog(getIt()),
      ),
    )
    ..registerFactoryParam<ShelfShareCubit, String, void>(
      (shelfName, _) => ShelfShareCubit(shelfName, getIt()),
    )
    ..registerFactoryParam<SharedShelfCubit, String, void>(
      (token, _) => SharedShelfCubit(token, getIt(), getIt()),
    )
    ..registerFactoryParam<EditionsCubit, Book, void>(
      (book, _) => EditionsCubit(getIt(), book),
    )
    ..registerFactoryParam<ExploreGenreCubit, ExploreGenre, void>(
      (genre, _) => ExploreGenreCubit(getIt(), genre),
    )
    ..registerFactoryParam<ExploreSectionCubit, ExploreSection, void>(
      (section, _) => ExploreSectionCubit(getIt(), section),
    )
    ..registerFactory(() => ProfileBloc(getIt()))
    ..registerFactory(
      () => BookDetailsBloc(
        libraryRepository: getIt(),
        searchRepository: getIt(),
        addBook: getIt(),
        readingLogs: getIt(),
        quotes: getIt(),
      ),
    );
}
