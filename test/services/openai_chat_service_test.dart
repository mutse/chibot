import 'dart:convert';

import 'package:chibot/core/exceptions.dart';
import 'package:chibot/services/openai_chat_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

class _OpenRouterErrorClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    expect(
      request.url.toString(),
      'https://openrouter.ai/api/v1/chat/completions',
    );
    expect(request.headers['X-Title'], 'Chibot');

    return http.StreamedResponse(
      Stream.value(
        utf8.encode(
          jsonEncode({
            'error': {
              'message': 'Provider returned error',
              'code': 429,
              'metadata': {
                'provider_name': 'OpenAI',
                'raw': {
                  'message':
                      'Rate limit exceeded for gpt-4o on the selected upstream provider.',
                },
              },
            },
          }),
        ),
      ),
      429,
      headers: {'content-type': 'application/json'},
    );
  }
}

class _OpenAIRequestClient extends http.BaseClient {
  Map<String, dynamic>? requestBody;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requestBody = jsonDecode(await request.finalize().bytesToString());
    return http.StreamedResponse(
      Stream.value(utf8.encode('data: [DONE]\n')),
      200,
      headers: {'content-type': 'text/event-stream'},
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
        () => service
            .generateResponse(
              prompt: 'Hello',
              context: const [],
              model: 'openai/gpt-4o',
            )
            .drain<void>(),
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

  group('OpenAIService latest model contract', () {
    test('does not send legacy sampling parameters to GPT-5.6', () async {
      final client = _OpenAIRequestClient();
      final service = OpenAIService(apiKey: 'test-key', client: client);

      await service
          .generateResponse(
            prompt: 'Hello',
            context: const [],
            model: 'gpt-5.6-sol',
          )
          .drain<void>();

      expect(client.requestBody?['model'], equals('gpt-5.6-sol'));
      expect(client.requestBody, isNot(contains('temperature')));
      expect(client.requestBody?['max_completion_tokens'], equals(4096));
    });
  });
}
