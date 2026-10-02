import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:chibot/models/tool_call.dart';
import 'package:chibot/services/openai_chat_service.dart';

class Client extends http.BaseClient {
  final String sse;
  Map<String, dynamic>? body;
  Client(this.sse);
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    body = jsonDecode(await request.finalize().bytesToString());
    // Every UTF-8 byte is a separate network chunk.
    return http.StreamedResponse(
      Stream.fromIterable(utf8.encode(sse).map((b) => [b])),
      200,
    );
  }
}

String event(Map<String, dynamic> delta, [String? finish]) =>
    'data: ${jsonEncode({
      'choices': [
        {'delta': delta, 'finish_reason': finish},
      ],
    })}\n\n';
void main() {
  test(
    'assembles interleaved call arguments by index across arbitrary chunks',
    () async {
      final client = Client(
        '${event({'content': '查询'})}${event({
              'tool_calls': [
                {
                  'index': 1,
                  'id': 'b',
                  'function': {'name': 'second', 'arguments': '{"q":'},
                },
                {
                  'index': 0,
                  'id': 'a',
                  'function': {'name': 'first', 'arguments': '{"q":"'},
                },
              ],
            })}${event({
              'tool_calls': [
                {
                  'index': 0,
                  'function': {'arguments': '中文"}'},
                },
                {
                  'index': 1,
                  'function': {'arguments': '2}'},
                },
              ],
            })}${event({}, 'tool_calls')}data: [DONE]\n',
      );
      final service = OpenAIService(
        apiKey: 'key',
        baseUrl: 'https://custom.test/v1',
        client: client,
      );
      final events =
          await service
              .generateToolTurn(
                messages: [
                  {'role': 'user', 'content': 'hi'},
                ],
                tools: const [ToolDefinition('first', 'First', {})],
                model: 'custom',
              )
              .toList();
      expect(events.first.text, '查询');
      expect(events.last.calls!.map((c) => c.id), ['a', 'b']);
      expect(events.last.calls!.first.decodeArguments()['q'], '中文');
      expect(events.last.calls!.last.decodeArguments()['q'], 2);
      expect(client.body!['tools'][0]['function']['name'], 'first');
      expect(client.body!['tool_choice'], 'auto');
    },
  );
  test('truncated tool streams cannot emit executable calls', () async {
    final client = Client(
      '${event({
            'tool_calls': [
              {
                'index': 0,
                'id': 'a',
                'function': {'name': 'read', 'arguments': '{}'},
              },
            ],
          })}data: [DONE]\n',
    );
    final service = OpenAIService(apiKey: 'key', client: client);
    await expectLater(
      service.generateToolTurn(messages: [], tools: [], model: 'x').toList(),
      throwsStateError,
    );
  });
  test('provider error and invalid JSON abort the tool stream', () async {
    for (final sse in [
      'data: {"error":{"message":"secret"}}\n',
      'data: broken\n',
    ]) {
      final service = OpenAIService(apiKey: 'key', client: Client(sse));
      await expectLater(
        service.generateToolTurn(messages: [], tools: [], model: 'x').toList(),
        throwsA(anything),
      );
    }
  });
  test('duplicate call IDs cannot be replayed ambiguously', () async {
    final client = Client(
      event({
        'tool_calls': [
          {
            'index': 0,
            'id': 'same',
            'function': {'name': 'read', 'arguments': '{}'},
          },
          {
            'index': 1,
            'id': 'same',
            'function': {'name': 'read', 'arguments': '{}'},
          },
        ],
      }, 'tool_calls'),
    );
    final service = OpenAIService(apiKey: 'key', client: client);
    await expectLater(
      service.generateToolTurn(messages: [], tools: [], model: 'x').toList(),
      throwsStateError,
    );
  });
}
