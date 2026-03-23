import 'package:duckmouth/core/api/models_client.dart';

/// No-op [ModelsClient] for integration tests.
class FakeModelsClient implements ModelsClient {
  @override
  Future<FetchModelsResult> fetchModels({
    required String baseUrl,
    required String apiKey,
  }) async {
    return const FetchModelsSuccess([]);
  }
}
