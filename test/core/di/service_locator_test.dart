import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:duckmouth/core/di/service_locator.dart';

void main() {
  tearDown(() {
    GetIt.instance.reset();
  });

  test('setupServiceLocator completes without error', () async {
    await setupServiceLocator();
    expect(sl, isNotNull);
  });

  test('sl is the GetIt singleton', () {
    expect(sl, same(GetIt.instance));
  });
}
