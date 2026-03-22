import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:mocktail/mocktail.dart';

import 'package:duckmouth/features/hotkey/domain/hotkey_config.dart';
import 'package:duckmouth/features/hotkey/domain/hotkey_service.dart';
import 'package:duckmouth/features/hotkey/ui/hotkey_cubit.dart';
import 'package:duckmouth/features/hotkey/ui/hotkey_state.dart';

class MockHotkeyService extends Mock implements HotkeyService {}

class FakeHotKey extends Fake implements HotKey {}

void main() {
  late MockHotkeyService mockService;

  setUpAll(() {
    registerFallbackValue(FakeHotKey());
  });

  setUp(() {
    mockService = MockHotkeyService();
    when(() => mockService.unregisterAll()).thenAnswer((_) async {});
  });

  const toggleConfig = HotkeyConfig(
    keyCode: 0x00000020,
    modifiers: ['control', 'shift'],
    mode: HotkeyMode.toggle,
  );

  const pttConfig = HotkeyConfig(
    keyCode: 0x00000020,
    modifiers: ['control', 'shift'],
    mode: HotkeyMode.pushToTalk,
  );

  group('HotkeyCubit', () {
    test('initial state is HotkeyIdle', () {
      final cubit = HotkeyCubit(service: mockService);
      expect(cubit.state, isA<HotkeyIdle>());
      cubit.close();
    });

    blocTest<HotkeyCubit, HotkeyState>(
      'registerHotkey emits HotkeyRegistered on success',
      build: () {
        when(
          () => mockService.register(
            any(),
            onKeyDown: any(named: 'onKeyDown'),
            onKeyUp: any(named: 'onKeyUp'),
          ),
        ).thenAnswer((_) async {});
        return HotkeyCubit(service: mockService);
      },
      act: (cubit) => cubit.registerHotkey(toggleConfig),
      expect: () => [const HotkeyRegistered(config: toggleConfig)],
      verify: (_) {
        // unregisterAll is called once during registerHotkey, and once during
        // close() — so at least 1 call during the act phase.
        verify(
          () => mockService.register(
            any(),
            onKeyDown: any(named: 'onKeyDown'),
            onKeyUp: any(named: 'onKeyUp'),
          ),
        ).called(1);
      },
    );

    blocTest<HotkeyCubit, HotkeyState>(
      'registerHotkey emits HotkeyError on failure',
      build: () {
        when(
          () => mockService.register(
            any(),
            onKeyDown: any(named: 'onKeyDown'),
            onKeyUp: any(named: 'onKeyUp'),
          ),
        ).thenThrow(Exception('registration failed'));
        return HotkeyCubit(service: mockService);
      },
      act: (cubit) => cubit.registerHotkey(toggleConfig),
      expect: () => [
        isA<HotkeyError>().having(
          (e) => e.message,
          'message',
          contains('registration failed'),
        ),
      ],
    );

    blocTest<HotkeyCubit, HotkeyState>(
      'unregisterHotkey emits HotkeyIdle',
      build: () => HotkeyCubit(service: mockService),
      act: (cubit) => cubit.unregisterHotkey(),
      expect: () => [const HotkeyIdle()],
    );

    group('toggle mode', () {
      late HotkeyCubit cubit;
      late void Function() capturedOnKeyDown;

      setUp(() {
        when(
          () => mockService.register(
            any(),
            onKeyDown: any(named: 'onKeyDown'),
            onKeyUp: any(named: 'onKeyUp'),
          ),
        ).thenAnswer((invocation) async {
          capturedOnKeyDown =
              invocation.namedArguments[#onKeyDown] as void Function();
        });
        cubit = HotkeyCubit(service: mockService);
      });

      tearDown(() => cubit.close());

      test('first key down emits HotkeyActionStart', () async {
        await cubit.registerHotkey(toggleConfig);
        capturedOnKeyDown();
        expect(cubit.state, isA<HotkeyActionStart>());
        expect(cubit.isRecording, isTrue);
      });

      test('second key down emits HotkeyActionStop', () async {
        await cubit.registerHotkey(toggleConfig);
        capturedOnKeyDown();
        capturedOnKeyDown();
        expect(cubit.state, isA<HotkeyActionStop>());
        expect(cubit.isRecording, isFalse);
      });

      test('third key down emits HotkeyActionStart again', () async {
        await cubit.registerHotkey(toggleConfig);
        capturedOnKeyDown();
        capturedOnKeyDown();
        capturedOnKeyDown();
        expect(cubit.state, isA<HotkeyActionStart>());
        expect(cubit.isRecording, isTrue);
      });
    });

    group('push-to-talk mode', () {
      late HotkeyCubit cubit;
      late void Function() capturedOnKeyDown;
      late void Function() capturedOnKeyUp;

      setUp(() {
        when(
          () => mockService.register(
            any(),
            onKeyDown: any(named: 'onKeyDown'),
            onKeyUp: any(named: 'onKeyUp'),
          ),
        ).thenAnswer((invocation) async {
          capturedOnKeyDown =
              invocation.namedArguments[#onKeyDown] as void Function();
          capturedOnKeyUp =
              invocation.namedArguments[#onKeyUp] as void Function();
        });
        cubit = HotkeyCubit(service: mockService);
      });

      tearDown(() => cubit.close());

      test('key down emits HotkeyActionStart', () async {
        await cubit.registerHotkey(pttConfig);
        capturedOnKeyDown();
        expect(cubit.state, isA<HotkeyActionStart>());
        expect(cubit.isRecording, isTrue);
      });

      test('key up emits HotkeyActionStop', () async {
        await cubit.registerHotkey(pttConfig);
        capturedOnKeyDown();
        capturedOnKeyUp();
        expect(cubit.state, isA<HotkeyActionStop>());
        expect(cubit.isRecording, isFalse);
      });

      test('key up without key down does nothing', () async {
        await cubit.registerHotkey(pttConfig);
        // key up without prior key down — no action
        capturedOnKeyUp();
        expect(cubit.state, isA<HotkeyRegistered>());
      });
    });

    test('resetRecordingState resets isRecording', () async {
      when(
        () => mockService.register(
          any(),
          onKeyDown: any(named: 'onKeyDown'),
          onKeyUp: any(named: 'onKeyUp'),
        ),
      ).thenAnswer((invocation) async {
        final onKeyDown =
            invocation.namedArguments[#onKeyDown] as void Function();
        // Simulate a key down to set recording state.
        onKeyDown();
      });

      final cubit = HotkeyCubit(service: mockService);
      await cubit.registerHotkey(toggleConfig);
      expect(cubit.isRecording, isTrue);

      cubit.resetRecordingState();
      expect(cubit.isRecording, isFalse);

      await cubit.close();
    });

    test('close calls unregisterAll', () async {
      final cubit = HotkeyCubit(service: mockService);
      await cubit.close();
      verify(() => mockService.unregisterAll()).called(1);
    });
  });
}
