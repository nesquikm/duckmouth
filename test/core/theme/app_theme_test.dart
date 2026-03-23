import 'package:duckmouth/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const brandedSeed = Color(0xFFE8A838);

  group('AppTheme', () {
    group('light', () {
      test('uses branded seed color', () {
        final theme = AppTheme.light;
        final scheme = theme.colorScheme;

        expect(
          scheme,
          equals(ColorScheme.fromSeed(
            seedColor: brandedSeed,
            brightness: Brightness.light,
          )),
        );
      });

      test('uses Material 3', () {
        expect(AppTheme.light.useMaterial3, isTrue);
      });

      test('has light brightness', () {
        expect(AppTheme.light.colorScheme.brightness, Brightness.light);
      });
    });

    group('dark', () {
      test('uses branded seed color', () {
        final theme = AppTheme.dark;
        final scheme = theme.colorScheme;

        expect(
          scheme,
          equals(ColorScheme.fromSeed(
            seedColor: brandedSeed,
            brightness: Brightness.dark,
          )),
        );
      });

      test('uses Material 3', () {
        expect(AppTheme.dark.useMaterial3, isTrue);
      });

      test('has dark brightness', () {
        expect(AppTheme.dark.colorScheme.brightness, Brightness.dark);
      });
    });
  });
}
