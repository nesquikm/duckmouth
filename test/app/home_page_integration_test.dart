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
import 'package:the_logger_viewer_widget/the_logger_viewer_widget.dart';

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
  late MockSttRepository mockSttRepo;
  late MockSettingsRepository mockSettingsRepo;
  late MockPostProcessingRepository mockPpRepo;
  late MockHistoryRepository mockHistoryRepo;
  late MockClipboardService mockClipboard;
  late MockHotkeyService mockHotkeyService;
  late MockSoundService mockSoundService;

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

    // Default stubs
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
    when(() => mockClipboard.copyToClipboard(any())).thenAnswer((_) async {});
    when(() => mockSoundService.playRecordingStart(volume: any(named: 'volume')))
        .thenAnswer((_) async {});
    when(() => mockSoundService.playRecordingStop(volume: any(named: 'volume')))
        .thenAnswer((_) async {});
    when(() => mockSoundService.playTranscriptionComplete(
        volume: any(named: 'volume'))).thenAnswer((_) async {});

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
    final mockAccessibility = MockAccessibilityService();
    when(() => mockAccessibility.checkPermission())
        .thenAnswer((_) async => AccessibilityStatus.unknown);
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

  Widget buildApp() {
    return MaterialApp(
      home: BlocProvider<SettingsCubit>(
        create: (_) => GetIt.instance<SettingsCubit>()..loadSettings(),
        child: const HomePage(),
      ),
    );
  }

  group('HomePage integration', () {
    testWidgets('shows ready state initially', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Ready to record'), findsOneWidget);
      expect(find.text('Duckmouth'), findsOneWidget);
    });

    testWidgets(
      'full pipeline: record → transcribe → output (post-processing disabled)',
      (tester) async {
        // Set up the recording to succeed
        when(() => mockRecordingRepo.hasPermission())
            .thenAnswer((_) async => true);
        when(() => mockRecordingRepo.start(formatConfig: any(named: 'formatConfig'), deviceId: any(named: 'deviceId'))).thenAnswer((_) async {});
        when(() => mockRecordingRepo.stop())
            .thenAnswer((_) async => '/tmp/test.m4a');

        // Set up transcription to succeed
        when(() => mockSttRepo.transcribe(any()))
            .thenAnswer((_) async => 'Hello world');

        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        // Tap the record button and wait for async
        await tester.runAsync(() async {
          await tester.tap(find.byIcon(Icons.mic));
        });
        await tester.pumpAndSettle();

        // Should be recording
        expect(find.text('Recording...'), findsOneWidget);

        // Tap the stop button and let the async pipeline complete
        await tester.runAsync(() async {
          await tester.tap(find.byIcon(Icons.stop));
          // Give time for async pipeline: stop → transcribe → process
          await Future<void>.delayed(const Duration(milliseconds: 100));
        });
        await tester.pumpAndSettle();

        // The transcription cubit should have been called
        verify(() => mockSttRepo.transcribe('/tmp/test.m4a')).called(1);

        // Transcription result should appear
        expect(find.text('Hello world'), findsOneWidget);

        // Clipboard should have the text (output is copy mode by default)
        verify(() => mockClipboard.copyToClipboard('Hello world')).called(1);

        // History should have the entry
        verify(() => mockHistoryRepo.add(any())).called(1);
      },
    );

    testWidgets(
      'shows error and retry button on transcription failure',
      (tester) async {
        when(() => mockRecordingRepo.hasPermission())
            .thenAnswer((_) async => true);
        when(() => mockRecordingRepo.start(formatConfig: any(named: 'formatConfig'), deviceId: any(named: 'deviceId'))).thenAnswer((_) async {});
        when(() => mockRecordingRepo.stop())
            .thenAnswer((_) async => '/tmp/test.m4a');
        when(() => mockSttRepo.transcribe(any()))
            .thenThrow(Exception('Server down'));

        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        // Record
        await tester.runAsync(() async {
          await tester.tap(find.byIcon(Icons.mic));
        });
        await tester.pumpAndSettle();

        // Stop and let async pipeline run
        await tester.runAsync(() async {
          await tester.tap(find.byIcon(Icons.stop));
          await Future<void>.delayed(const Duration(milliseconds: 100));
        });
        await tester.pumpAndSettle();

        // Should show error
        expect(
          find.text('Transcription failed. Please try again.'),
          findsOneWidget,
        );

        // Should show retry/Try Again button
        expect(find.text('Try Again'), findsOneWidget);

        // Tap Try Again to reset
        await tester.tap(find.text('Try Again'));
        await tester.pumpAndSettle();

        expect(find.text('Ready to record'), findsOneWidget);
      },
    );

    testWidgets(
      'shows microphone permission error with guidance',
      (tester) async {
        when(() => mockRecordingRepo.hasPermission())
            .thenAnswer((_) async => false);
        when(() => mockRecordingRepo.requestPermission())
            .thenAnswer((_) async {});

        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        // Try to record
        await tester.runAsync(() async {
          await tester.tap(find.byIcon(Icons.mic));
          await Future<void>.delayed(const Duration(milliseconds: 100));
        });
        await tester.pumpAndSettle();

        // Should show permission error with guidance
        expect(find.textContaining('Microphone access required'),
            findsOneWidget);
        expect(find.textContaining('Microphone and enable access'),
            findsOneWidget);
      },
    );

    testWidgets('New Recording button resets state', (tester) async {
      when(() => mockRecordingRepo.hasPermission())
          .thenAnswer((_) async => true);
      when(() => mockRecordingRepo.start(formatConfig: any(named: 'formatConfig'), deviceId: any(named: 'deviceId'))).thenAnswer((_) async {});
      when(() => mockRecordingRepo.stop())
          .thenAnswer((_) async => '/tmp/test.m4a');
      when(() => mockSttRepo.transcribe(any()))
          .thenAnswer((_) async => 'Some text');

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Record
      await tester.runAsync(() async {
        await tester.tap(find.byIcon(Icons.mic));
      });
      await tester.pumpAndSettle();

      // Stop and wait for pipeline
      await tester.runAsync(() async {
        await tester.tap(find.byIcon(Icons.stop));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();

      // Result should appear
      expect(find.text('Some text'), findsOneWidget);

      // Find and tap New Recording
      expect(find.text('New Recording'), findsOneWidget);
      await tester.tap(find.text('New Recording'));
      await tester.pumpAndSettle();

      // Should be back to idle
      expect(find.text('Ready to record'), findsOneWidget);
    });

    testWidgets('AppBar shows Logs icon button', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.article_outlined), findsOneWidget);
      expect(find.byTooltip('Logs'), findsOneWidget);
    });

    testWidgets('tapping Logs button navigates to TheLoggerViewerPage',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Logs'));
      await tester.pumpAndSettle();

      expect(find.byType(TheLoggerViewerPage), findsOneWidget);
      expect(find.text('Log Viewer'), findsOneWidget);
    });

    testWidgets('shows empty recording error for blank transcription',
        (tester) async {
      when(() => mockRecordingRepo.hasPermission())
          .thenAnswer((_) async => true);
      when(() => mockRecordingRepo.start(formatConfig: any(named: 'formatConfig'), deviceId: any(named: 'deviceId'))).thenAnswer((_) async {});
      when(() => mockRecordingRepo.stop())
          .thenAnswer((_) async => '/tmp/test.m4a');
      when(() => mockSttRepo.transcribe(any()))
          .thenAnswer((_) async => '   ');

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.runAsync(() async {
        await tester.tap(find.byIcon(Icons.mic));
      });
      await tester.pumpAndSettle();

      await tester.runAsync(() async {
        await tester.tap(find.byIcon(Icons.stop));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();

      expect(find.textContaining('No speech detected'), findsOneWidget);
    });
  });
}
