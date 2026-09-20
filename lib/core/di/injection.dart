import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/cubit/auth_form_cubit.dart';
import '../../features/book_details/presentation/bloc/book_details_bloc.dart';
import '../../features/library/data/datasources/library_remote_data_source.dart';
import '../../features/library/data/repositories/library_repository_impl.dart';
import '../../features/library/domain/repositories/library_repository.dart';
import '../../features/library/domain/usecases/add_book_to_library.dart';
import '../../features/library/presentation/bloc/library_bloc.dart';
import '../../features/profile/data/datasources/profile_remote_data_source.dart';
import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/profile/presentation/bloc/profile_bloc.dart';
import '../../features/profile/presentation/cubit/theme_cubit.dart';
import '../../features/search/data/datasources/book_remote_data_source.dart';
import '../../features/search/data/repositories/book_search_repository_impl.dart';
import '../../features/search/domain/repositories/book_search_repository.dart';
import '../../features/search/presentation/bloc/search_bloc.dart';
import '../config/app_config.dart';
import '../router/app_router.dart';

final getIt = GetIt.instance;

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
    // Repositories
    ..registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(getIt()))
    ..registerLazySingleton<BookSearchRepository>(
      () => BookSearchRepositoryImpl(getIt()),
    )
    ..registerLazySingleton<LibraryRepository>(
      () => LibraryRepositoryImpl(getIt()),
    )
    ..registerLazySingleton<ProfileRepository>(
      () => ProfileRepositoryImpl(getIt()),
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
    ..registerFactory(() => SearchBloc(getIt()))
    ..registerFactory(() => ProfileBloc(getIt()))
    ..registerFactory(
      () => BookDetailsBloc(
        libraryRepository: getIt(),
        searchRepository: getIt(),
        addBook: getIt(),
      ),
    );
}
