import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:duckmouth/features/hotkey/domain/hotkey_config.dart';
import 'package:duckmouth/features/hotkey/ui/hotkey_recorder_dialog.dart';

void main() {
  group('HotkeyRecorderDialog', () {
    late HotkeyConfig? recordedConfig;

    Widget buildTestWidget() {
      recordedConfig = null;
      return MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (_) => HotkeyRecorderDialog(
                    currentMode: HotkeyMode.toggle,
                    onHotKeyRecorded: (config) {
                      recordedConfig = config;
                    },
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );
    }

    Future<void> openDialog(WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
    }

    testWidgets('shows initial prompt text', (tester) async {
      await openDialog(tester);
      expect(find.text('Press a key combination...'), findsOneWidget);
      expect(find.text('Record Hotkey'), findsOneWidget);
    });

    testWidgets('bare modifier does NOT fire callback', (tester) async {
      await openDialog(tester);

      // Press only Control — should not fire callback
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();

      expect(recordedConfig, isNull);
      // Dialog should still be open
      expect(find.text('Record Hotkey'), findsOneWidget);

      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();
    });

    testWidgets('modifier+key combo fires callback with correct config',
        (tester) async {
      await openDialog(tester);

      // Press Ctrl+Space
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();

      await tester.sendKeyDownEvent(
        LogicalKeyboardKey.space,
        physicalKey: PhysicalKeyboardKey.space,
      );
      await tester.pumpAndSettle();

      expect(recordedConfig, isNotNull);
      expect(recordedConfig!.modifiers, contains('control'));
      expect(recordedConfig!.keyCode, PhysicalKeyboardKey.space.usbHidUsage);
      expect(recordedConfig!.mode, HotkeyMode.toggle);
    });

    testWidgets('multiple modifiers work', (tester) async {
      await openDialog(tester);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump();

      await tester.sendKeyDownEvent(
        LogicalKeyboardKey.space,
        physicalKey: PhysicalKeyboardKey.space,
      );
      await tester.pumpAndSettle();

      expect(recordedConfig, isNotNull);
      expect(recordedConfig!.modifiers, contains('control'));
      expect(recordedConfig!.modifiers, contains('shift'));
    });

    testWidgets('escape cancels dialog', (tester) async {
      await openDialog(tester);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(recordedConfig, isNull);
      // Dialog should be closed
      expect(find.text('Record Hotkey'), findsNothing);
    });

    testWidgets('cancel button closes dialog', (tester) async {
      await openDialog(tester);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(recordedConfig, isNull);
      expect(find.text('Record Hotkey'), findsNothing);
    });

    testWidgets('non-modifier without modifier is ignored', (tester) async {
      await openDialog(tester);

      // Press A without any modifier — should not fire callback
      await tester.sendKeyDownEvent(
        LogicalKeyboardKey.keyA,
        physicalKey: PhysicalKeyboardKey.keyA,
      );
      await tester.pump();

      expect(recordedConfig, isNull);
      // Dialog should still be open
      expect(find.text('Record Hotkey'), findsOneWidget);
    });
  });
}
