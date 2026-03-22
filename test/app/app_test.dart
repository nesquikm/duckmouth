import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:mocktail/mocktail.dart';

import 'package:duckmouth/app/app.dart';
import 'package:duckmouth/core/services/clipboard_service.dart';
import 'package:duckmouth/core/services/output_mode.dart';
import 'package:duckmouth/features/hotkey/domain/hotkey_config.dart';
import 'package:duckmouth/features/hotkey/domain/hotkey_service.dart';
import 'package:duckmouth/features/hotkey/ui/hotkey_cubit.dart';
import 'package:duckmouth/features/post_processing/domain/post_processing_config.dart';
import 'package:duckmouth/features/post_processing/domain/post_processing_repository.dart';
import 'package:duckmouth/features/post_processing/ui/post_processing_cubit.dart';
import 'package:duckmouth/features/recording/domain/recording_repository.dart';
import 'package:duckmouth/features/recording/ui/recording_cubit.dart';
import 'package:duckmouth/features/settings/domain/settings_repository.dart';
import 'package:duckmouth/features/settings/ui/settings_cubit.dart';
import 'package:duckmouth/features/transcription/domain/stt_repository.dart';
import 'package:duckmouth/features/transcription/ui/transcription_cubit.dart';

class MockRecordingRepository extends Mock implements RecordingRepository {}

class MockSttRepository extends Mock implements SttRepository {}

class MockSettingsRepository extends Mock implements SettingsRepository {}

class MockPostProcessingRepository extends Mock
    implements PostProcessingRepository {}

class MockClipboardService extends Mock implements ClipboardService {}

class MockHotkeyService extends Mock implements HotkeyService {}

class FakeHotKey extends Fake implements HotKey {}

void main() {
  late MockRecordingRepository mockRepo;
  late MockSttRepository mockSttRepo;
  late MockSettingsRepository mockSettingsRepo;
  late MockPostProcessingRepository mockPpRepo;

  setUpAll(() {
    registerFallbackValue(FakeHotKey());
  });

  setUp(() {
    mockRepo = MockRecordingRepository();
    mockSttRepo = MockSttRepository();
    mockSettingsRepo = MockSettingsRepository();
    mockPpRepo = MockPostProcessingRepository();
    when(() => mockRepo.dispose()).thenAnswer((_) async {});
    when(() => mockRepo.durationStream)
        .thenAnswer((_) => const Stream<Duration>.empty());
    when(() => mockSettingsRepo.loadSttConfig())
        .thenAnswer((_) async => null);
    when(() => mockSettingsRepo.loadPostProcessingConfig())
        .thenAnswer((_) async => const PostProcessingConfig());
    when(() => mockSettingsRepo.loadOutputMode())
        .thenAnswer((_) async => OutputMode.copy);
    when(() => mockSettingsRepo.loadHotkeyConfig())
        .thenAnswer((_) async => HotkeyConfig.defaultConfig);

    final mockHotkeyService = MockHotkeyService();
    when(() => mockHotkeyService.unregisterAll()).thenAnswer((_) async {});
    when(
      () => mockHotkeyService.register(
        any(),
        onKeyDown: any(named: 'onKeyDown'),
        onKeyUp: any(named: 'onKeyUp'),
      ),
    ).thenAnswer((_) async {});

    final sl = GetIt.instance;
    sl.registerLazySingleton<ClipboardService>(MockClipboardService.new);
    sl.registerFactory<RecordingCubit>(
      () => RecordingCubit(repository: mockRepo),
    );
    sl.registerFactory<TranscriptionCubit>(
      () => TranscriptionCubit(repository: mockSttRepo),
    );
    sl.registerFactory<SettingsCubit>(
      () => SettingsCubit(repository: mockSettingsRepo),
    );
    sl.registerFactory<PostProcessingCubit>(
      () => PostProcessingCubit(
        repository: mockPpRepo,
        config: const PostProcessingConfig(),
      ),
    );
    sl.registerFactory<HotkeyCubit>(
      () => HotkeyCubit(service: mockHotkeyService),
    );
  });

  tearDown(() {
    GetIt.instance.reset();
  });

  testWidgets('DuckmouthApp renders without error', (tester) async {
    await tester.pumpWidget(const DuckmouthApp());
    expect(find.text('Duckmouth'), findsOneWidget);
    expect(find.text('Ready to record'), findsOneWidget);
  });
}
