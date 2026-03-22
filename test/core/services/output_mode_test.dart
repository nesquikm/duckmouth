import 'package:flutter_test/flutter_test.dart';

import 'package:duckmouth/core/services/output_mode.dart';

void main() {
  group('OutputMode', () {
    test('has three values', () {
      expect(OutputMode.values, hasLength(3));
    });

    test('label returns human-readable text', () {
      expect(OutputMode.copy.label, 'Copy to clipboard');
      expect(OutputMode.paste.label, 'Paste at cursor');
      expect(OutputMode.both.label, 'Paste & restore clipboard');
    });

    test('name returns enum name for persistence', () {
      expect(OutputMode.copy.name, 'copy');
      expect(OutputMode.paste.name, 'paste');
      expect(OutputMode.both.name, 'both');
    });
  });
}
