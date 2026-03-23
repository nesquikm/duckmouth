import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:mocktail/mocktail.dart';

import 'package:duckmouth/app/home_page.dart';
import 'package:duckmouth/core/services/accessibility_service.dart';
import 'package:duckmouth/core/services/clipboard_service.dart';
import 'package:duckmouth/core/services/output_mode.dart';
import 'package:duckmouth/core/services/sound_config.dart';
import 'package:duckmouth/core/services/sound_service.dart';
import 'package:duckmouth/features/history/domain/history_repository.dart';
import 'package:duckmouth/features/history/domain/transcription_entry.dart';
import 'package:duckmouth/features/history/ui/history_cubit.dart';
import 'package:duckmouth/features/hotkey/domain/hotkey_config.dart';
import 'package:duckmouth/features/hotkey/domain/hotkey_service.dart';
import 'package:duckmouth/features/hotkey/ui/hotkey_cubit.dart';
import 'package:duckmouth/features/post_processing/domain/post_processing_config.dart';
import 'package:duckmouth/features/post_processing/domain/post_processing_repository.dart';
import 'package:duckmouth/features/post_processing/ui/post_processing_cubit.dart';
import 'package:duckmouth/features/recording/domain/audio_format_config.dart';
import 'package:duckmouth/features/recording/domain/recording_repository.dart';
import 'package:duckmouth/features/recording/ui/recording_cubit.dart';
import 'package:duckmouth/features/settings/domain/settings_repository.dart';
import 'package:duckmouth/features/settings/ui/settings_cubit.dart';
import 'package:duckmouth/features/settings/ui/settings_state.dart';
import 'package:duckmouth/features/transcription/domain/stt_repository.dart';
import 'package:duckmouth/features/transcription/ui/transcription_cubit.dart';

class MockRecordingRepository extends Mock implements RecordingRepository {}

class MockSttRepository extends Mock implements SttRepository {}

class MockSettingsRepository extends Mock implements SettingsRepository {}

class MockPostProcessingRepository extends Mock
    implements PostProcessingRepository {}

class MockHistoryRepository extends Mock implements HistoryRepository {}

class MockClipboardService extends Mock implements ClipboardService {}

class MockHotkeyService extends Mock implements HotkeyService {}

class MockSoundService extends Mock implements SoundService {}

class MockAccessibilityService extends Mock implements AccessibilityService {}

class FakeHotKey extends Fake implements HotKey {}

class FakeTranscriptionEntry extends Fake implements TranscriptionEntry {}

void main() {
  late MockRecordingRepository mockRecordingRepo;
  late MockSettingsRepository mockSettingsRepo;
  late MockPostProcessingRepository mockPpRepo;
  late MockHistoryRepository mockHistoryRepo;
  late MockClipboardService mockClipboard;
  late MockHotkeyService mockHotkeyService;
  late MockSoundService mockSoundService;
  late MockSttRepository mockSttRepo;
  late MockAccessibilityService mockAccessibility;

  setUpAll(() {
    registerFallbackValue(FakeHotKey());
    registerFallbackValue(FakeTranscriptionEntry());
    registerFallbackValue(const AudioFormatConfig());
  });

  setUp(() {
    mockRecordingRepo = MockRecordingRepository();
    mockSttRepo = MockSttRepository();
    mockSettingsRepo = MockSettingsRepository();
    mockPpRepo = MockPostProcessingRepository();
    mockHistoryRepo = MockHistoryRepository();
    mockClipboard = MockClipboardService();
    mockHotkeyService = MockHotkeyService();
    mockSoundService = MockSoundService();
    mockAccessibility = MockAccessibilityService();

    when(() => mockRecordingRepo.dispose()).thenAnswer((_) async {});
    when(() => mockRecordingRepo.durationStream)
        .thenAnswer((_) => const Stream<Duration>.empty());
    when(() => mockSettingsRepo.loadSttConfig())
        .thenAnswer((_) async => null);
    when(() => mockSettingsRepo.loadPostProcessingConfig())
        .thenAnswer((_) async => const PostProcessingConfig());
    when(() => mockSettingsRepo.loadOutputMode())
        .thenAnswer((_) async => OutputMode.copy);
    when(() => mockSettingsRepo.loadHotkeyConfig())
        .thenAnswer((_) async => HotkeyConfig.defaultConfig);
    when(() => mockSettingsRepo.loadSoundConfig())
        .thenAnswer((_) async => const SoundConfig());
    when(() => mockSettingsRepo.loadAudioFormatConfig())
        .thenAnswer((_) async => const AudioFormatConfig());
    when(() => mockSettingsRepo.loadSelectedInputDevice())
        .thenAnswer((_) async => null);
    when(() => mockSettingsRepo.loadThemeMode())
        .thenAnswer((_) async => AppThemeMode.system);
    when(() => mockHotkeyService.unregisterAll()).thenAnswer((_) async {});
    when(
      () => mockHotkeyService.register(
        any(),
        onKeyDown: any(named: 'onKeyDown'),
        onKeyUp: any(named: 'onKeyUp'),
      ),
    ).thenAnswer((_) async {});
    when(() => mockHistoryRepo.getAll()).thenAnswer((_) async => []);
    when(() => mockHistoryRepo.add(any())).thenAnswer((_) async {});
    when(() => mockClipboard.copyToClipboard(any()))
        .thenAnswer((_) async {});
    when(() => mockSoundService.playRecordingStart(
            volume: any(named: 'volume')))
        .thenAnswer((_) async {});
    when(() => mockSoundService.playRecordingStop(
            volume: any(named: 'volume')))
        .thenAnswer((_) async {});
    when(() => mockSoundService.playTranscriptionComplete(
            volume: any(named: 'volume')))
        .thenAnswer((_) async {});

    // Return denied so the banner shows.
    when(() => mockAccessibility.checkPermission())
        .thenAnswer((_) async => AccessibilityStatus.denied);

    final sl = GetIt.instance;
    sl.registerLazySingleton<ClipboardService>(() => mockClipboard);
    sl.registerLazySingleton<SoundService>(() => mockSoundService);
    sl.registerFactory<SttRepository>(() => mockSttRepo);
    sl.registerFactory<PostProcessingRepository>(() => mockPpRepo);
    sl.registerFactory<RecordingCubit>(
      () => RecordingCubit(repository: mockRecordingRepo),
    );
    sl.registerFactory<TranscriptionCubit>(
      () => TranscriptionCubit(repositoryFactory: () => mockSttRepo),
    );
    sl.registerFactory<SettingsCubit>(
      () => SettingsCubit(
        repository: mockSettingsRepo,
        accessibilityService: mockAccessibility,
      ),
    );
    sl.registerFactory<PostProcessingCubit>(
      () => PostProcessingCubit(
        repositoryFactory: () => mockPpRepo,
        config: const PostProcessingConfig(),
      ),
    );
    sl.registerFactory<HotkeyCubit>(
      () => HotkeyCubit(service: mockHotkeyService),
    );
    sl.registerFactory<HistoryCubit>(
      () => HistoryCubit(repository: mockHistoryRepo),
    );
  });

  tearDown(() {
    GetIt.instance.reset();
  });

  Widget buildApp({required Brightness brightness}) {
    return MaterialApp(
      theme: brightness == Brightness.light
          ? ThemeData.light()
          : ThemeData.dark(),
      home: BlocProvider<SettingsCubit>(
        create: (_) => GetIt.instance<SettingsCubit>()..loadSettings(),
        child: const HomePage(),
      ),
    );
  }

  /// Finds the accessibility banner Container by looking for the warning icon
  /// and returning its ancestor Container with a BoxDecoration.
  BoxDecoration? findBannerDecoration(WidgetTester tester) {
    final bannerFinder = find.ancestor(
      of: find.text('Grant Access'),
      matching: find.byType(Container),
    );
    // The decorated container is the one with BoxDecoration.
    for (final element in bannerFinder.evaluate()) {
      final container = element.widget as Container;
      if (container.decoration is BoxDecoration) {
        return container.decoration! as BoxDecoration;
      }
    }
    return null;
  }

  /// Finds the icon color of the warning icon in the banner.
  Color? findBannerIconColor(WidgetTester tester) {
    final iconFinder = find.byIcon(Icons.warning_amber_rounded);
    if (iconFinder.evaluate().isEmpty) return null;
    final icon = tester.widget<Icon>(iconFinder);
    return icon.color;
  }

  group('Accessibility banner dark mode colors', () {
    testWidgets('uses light colors in light theme', (tester) async {
      await tester.pumpWidget(buildApp(brightness: Brightness.light));
      await tester.pumpAndSettle();

      final decoration = findBannerDecoration(tester);
      expect(decoration, isNotNull);
      expect(decoration!.color, equals(Colors.orange.shade50));
      expect(
        (decoration.border! as Border).top.color,
        equals(Colors.orange.shade200),
      );

      final iconColor = findBannerIconColor(tester);
      expect(iconColor, equals(Colors.orange.shade700));
    });

    testWidgets('uses dark colors in dark theme', (tester) async {
      await tester.pumpWidget(buildApp(brightness: Brightness.dark));
      await tester.pumpAndSettle();

      final decoration = findBannerDecoration(tester);
      expect(decoration, isNotNull);
      expect(decoration!.color, equals(const Color(0xFF3A2A0A)));
      expect(
        (decoration.border! as Border).top.color,
        equals(Colors.orange.shade800),
      );

      final iconColor = findBannerIconColor(tester);
      expect(iconColor, equals(Colors.orange.shade300));
    });

    testWidgets('banner colors differ between light and dark themes',
        (tester) async {
      // Light theme
      await tester.pumpWidget(buildApp(brightness: Brightness.light));
      await tester.pumpAndSettle();
      final lightDecoration = findBannerDecoration(tester);
      final lightIconColor = findBannerIconColor(tester);

      // Dark theme
      await tester.pumpWidget(buildApp(brightness: Brightness.dark));
      await tester.pumpAndSettle();
      final darkDecoration = findBannerDecoration(tester);
      final darkIconColor = findBannerIconColor(tester);

      expect(lightDecoration, isNotNull);
      expect(darkDecoration, isNotNull);
      expect(lightDecoration!.color, isNot(equals(darkDecoration!.color)),
          reason: 'Background color should differ between themes');
      expect(lightIconColor, isNot(equals(darkIconColor)),
          reason: 'Icon color should differ between themes');
    });
  });
}
