// Settings round-trip test. For the full version, see test/integration/settings_e2e_test.dart.

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:duckmouth/core/services/output_mode.dart';
import 'package:duckmouth/features/settings/domain/api_config.dart';

import 'helpers/fakes/fake_settings_repository.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('settings round-trip: save and reload', (tester) async {
    final repo = FakeSettingsRepository();

    const config = ApiConfig(
      baseUrl: 'https://custom.api.com',
      apiKey: 'test-key-123',
      model: 'whisper-large',
      providerName: 'custom',
    );
    await repo.saveSttConfig(config);
    await repo.saveOutputMode(OutputMode.both);

    expect(await repo.loadSttConfig(), config);
    expect(await repo.loadOutputMode(), OutputMode.both);
  });
}
