import 'dart:convert';

import 'package:chibot/services/gemini_chat_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

class _GeminiRequestClient extends http.BaseClient {
  Map<String, dynamic>? requestBody;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requestBody = jsonDecode(await request.finalize().bytesToString());
    return http.StreamedResponse(
      Stream.value(
        utf8.encode(
          jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': 'Hello'},
                  ],
                },
              },
            ],
          }),
        ),
      ),
      200,
      headers: {'content-type': 'application/json'},
    );
  }
}

void main() {
  test('Gemini 3.6 request omits deprecated sampling parameters', () async {
    final client = _GeminiRequestClient();
    final service = GeminiService(apiKey: 'test-key', client: client);

    final response =
        await service
            .generateResponse(
              prompt: 'Hello',
              context: const [],
              model: 'gemini-3.6-flash',
              parameters: {'temperature': 0.2, 'topP': 0.8, 'topK': 20},
            )
            .join();

    final generationConfig =
        client.requestBody?['generationConfig'] as Map<String, dynamic>;
    expect(response, equals('Hello'));
    expect(generationConfig, isNot(contains('temperature')));
    expect(generationConfig, isNot(contains('topP')));
    expect(generationConfig, isNot(contains('topK')));
    expect(generationConfig['maxOutputTokens'], equals(4096));
  });
}
