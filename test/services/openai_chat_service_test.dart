import 'dart:convert';

import 'package:chibot/core/exceptions.dart';
import 'package:chibot/services/openai_chat_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

class _OpenRouterErrorClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    expect(request.url.toString(), 'https://openrouter.ai/api/v1/chat/completions');
    expect(request.headers['X-Title'], 'Chibot');

    return http.StreamedResponse(
      Stream.value(
        utf8.encode(jsonEncode({
          'error': {
            'message': 'Provider returned error',
            'code': 429,
            'metadata': {
              'provider_name': 'OpenAI',
              'raw': {
                'message': 'Rate limit exceeded for gpt-4o on the selected upstream provider.',
              },
            },
          },
        })),
      ),
      429,
      headers: {'content-type': 'application/json'},
    );
  }
}

void main() {
  group('OpenAIService with OpenRouter', () {
    test('surfaces detailed OpenRouter 429 errors', () async {
      final service = OpenAIService(
        apiKey: 'test-key',
        baseUrl: 'https://openrouter.ai/api/v1',
        client: _OpenRouterErrorClient(),
      );

      expect(
        () => service.generateResponse(
          prompt: 'Hello',
          context: const [],
          model: 'openai/gpt-4o',
        ).drain<void>(),
        throwsA(
          isA<ApiException>()
              .having((error) => error.statusCode, 'statusCode', 429)
              .having(
                (error) => error.message,
                'message',
                contains('OpenRouter rate limit exceeded'),
              )
              .having(
                (error) => error.message,
                'message',
                contains('provider: OpenAI'),
              )
              .having(
                (error) => error.message,
                'message',
                contains('Rate limit exceeded for gpt-4o'),
              ),
        ),
      );
    });
  });
}
