import 'package:get_it/get_it.dart';

import 'package:duckmouth/features/recording/data/recording_repository_impl.dart';
import 'package:duckmouth/features/recording/domain/recording_repository.dart';
import 'package:duckmouth/features/recording/ui/recording_cubit.dart';

final sl = GetIt.instance;

Future<void> setupServiceLocator() async {
  sl.registerLazySingleton<RecordingRepository>(
    RecordingRepositoryImpl.new,
  );

  sl.registerFactory<RecordingCubit>(
    () => RecordingCubit(repository: sl<RecordingRepository>()),
  );
}
