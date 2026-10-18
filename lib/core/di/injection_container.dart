import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/theme_cubit.dart';
import '../../core/services/sync_queue_local_data_source.dart';
import '../../core/services/app_cache_manager.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/home/data/datasources/home_remote_data_source.dart';
import '../../features/home/data/repositories/home_repository_impl.dart';
import '../../features/home/domain/repositories/home_repository.dart';
import '../../features/home/presentation/bloc/home_bloc.dart';
import '../../features/home/data/datasources/home_local_data_source.dart';
import '../../features/people/data/datasources/people_remote_data_source.dart';
import '../../features/people/data/datasources/people_local_data_source.dart';
import '../../features/people/data/repositories/people_repository_impl.dart';
import '../../features/people/domain/repositories/people_repository.dart';
import '../../features/people/presentation/bloc/people_bloc.dart';
import '../../features/people/presentation/bloc/add_person_bloc.dart';
import '../../features/people/presentation/bloc/ledger_bloc.dart';
import '../../features/people/presentation/bloc/add_transaction_bloc.dart';
import '../../features/people/presentation/bloc/all_debts_bloc.dart';
import '../../features/insights/data/datasources/insights_remote_data_source.dart';
import '../../features/insights/data/repositories/insights_repository_impl.dart';
import '../../features/insights/domain/repositories/insights_repository.dart';
import '../../features/insights/presentation/bloc/insights_bloc.dart';
import '../../features/legacy/data/datasources/legacy_remote_data_source.dart';
import '../../features/legacy/data/repositories/legacy_repository_impl.dart';
import '../../features/legacy/domain/repositories/legacy_repository.dart';
import '../../features/legacy/presentation/bloc/legacy_bloc.dart';
import '../../features/notifications/domain/repositories/notification_repository.dart';
import '../../features/notifications/data/repositories/notification_repository_impl.dart';
import '../../features/notifications/data/datasources/notification_remote_data_source.dart';
import '../../features/notifications/presentation/bloc/notification_cubit.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Features - Auth

  // Bloc
  sl.registerFactory(() => AuthBloc(authRepository: sl()));

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      sharedPreferences: sl(),
      cacheManager: sl(),
      peopleLocalDataSource: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(client: sl(), sharedPreferences: sl()),
  );

  // Features - Home
  sl.registerFactory(() => HomeBloc(repository: sl()));

  sl.registerLazySingleton<HomeRepository>(
    () => HomeRepositoryImpl(remoteDataSource: sl(), localDataSource: sl(), cacheManager: sl()),
  );

  sl.registerLazySingleton<HomeRemoteDataSource>(
    () => HomeRemoteDataSourceImpl(client: sl(), sharedPreferences: sl()),
  );

  sl.registerLazySingleton<HomeLocalDataSource>(
    () => HomeLocalDataSourceImpl(sharedPreferences: sl()),
  );

  // Features - People
  sl.registerFactory(() => PeopleBloc(repository: sl()));
  sl.registerFactory(() => AddPersonBloc(repository: sl()));
  sl.registerFactory(() => LedgerBloc(repository: sl()));
  sl.registerFactory(() => AddTransactionBloc(repository: sl()));
  sl.registerFactory(() => AllDebtsBloc(repository: sl()));

  sl.registerLazySingleton<PeopleLocalDataSource>(
    () => PeopleLocalDataSourceImpl(sharedPreferences: sl()),
  );

  sl.registerLazySingleton<PeopleRepository>(
    () => PeopleRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      syncQueue: sl(),
      sharedPreferences: sl(),
      cacheManager: sl(),
    ),
  );

  sl.registerLazySingleton<PeopleRemoteDataSource>(
    () => PeopleRemoteDataSourceImpl(client: sl(), sharedPreferences: sl()),
  );

  // Features - Insights
  sl.registerFactory(() => InsightsBloc(repository: sl()));
  sl.registerLazySingleton<InsightsRepository>(
    () => InsightsRepositoryImpl(remoteDataSource: sl(), cacheManager: sl()),
  );
  sl.registerLazySingleton<InsightsRemoteDataSource>(
    () => InsightsRemoteDataSourceImpl(client: sl(), sharedPreferences: sl()),
  );

  // Features - Legacy (Next of Kin)
  sl.registerFactory(() => LegacyBloc(repository: sl()));
  sl.registerLazySingleton<LegacyRepository>(
    () => LegacyRepositoryImpl(remoteDataSource: sl(), cacheManager: sl()),
  );
  sl.registerLazySingleton<LegacyRemoteDataSource>(
    () => LegacyRemoteDataSourceImpl(client: sl(), sharedPreferences: sl()),
  );

  // External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  sl.registerLazySingleton(() => http.Client());

  // Core Services
  sl.registerLazySingleton<AppCacheManager>(
    () => AppCacheManager(sharedPreferences: sl()),
  );
  sl.registerLazySingleton<SyncQueueLocalDataSource>(
    () => SyncQueueLocalDataSourceImpl(sharedPreferences: sl()),
  );

  // Theme
  sl.registerLazySingleton<ThemeCubit>(() => ThemeCubit(sharedPreferences: sl()));

  // Features - Notifications
  sl.registerLazySingleton<NotificationRemoteDataSource>(
    () => NotificationRemoteDataSourceImpl(client: sl(), sharedPreferences: sl()),
  );
  sl.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(
      sharedPreferences: sl(),
      remoteDataSource: sl(),
    ),
  );
  sl.registerLazySingleton<NotificationCubit>(
    () => NotificationCubit(repository: sl()),
  );
}
