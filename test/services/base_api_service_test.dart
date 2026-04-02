import 'dart:convert';

import 'package:chibot/core/exceptions.dart';
import 'package:chibot/services/base_api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

class _TestApiService extends BaseApiService {
  _TestApiService({required http.Client client})
    : super(
        baseUrl: 'https://openrouter.ai/api/v1',
        apiKey: 'test-key',
        client: client,
      );

  @override
  String get providerName => 'Test Provider';

  @override
  Map<String, String> getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };
  }

  @override
  void validateResponse(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException('HTTP ${response.statusCode}', response.statusCode);
    }
  }
}

class _FakeStreamingClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    expect(request.url.toString(), 'https://openrouter.ai/api/v1/chat/completions');

    return http.StreamedResponse(
      Stream.value(
        utf8.encode(jsonEncode({
          'error': {
            'message': 'Provider returned error',
            'code': 429,
          },
        })),
      ),
      429,
      headers: {'content-type': 'application/json'},
    );
  }
}

void main() {
  group('BaseApiService stream errors', () {
    test('preserves ApiException details for non-2xx streaming responses', () async {
      final service = _TestApiService(client: _FakeStreamingClient());

      expect(
        () => service.postStream('/chat/completions', body: {'stream': true}),
        throwsA(
          isA<ApiException>()
              .having((error) => error.statusCode, 'statusCode', 429)
              .having((error) => error.message, 'message', 'Provider returned error')
              .having((error) => error.code, 'code', '429'),
        ),
      );
    });
  });
}
