import 'package:flutter_test/flutter_test.dart';
import 'package:duckmouth/app/app.dart';

void main() {
  testWidgets('DuckmouthApp renders without error', (tester) async {
    await tester.pumpWidget(const DuckmouthApp());
    expect(find.text('Duckmouth'), findsOneWidget);
    expect(find.text('Ready to record'), findsOneWidget);
  });
}
