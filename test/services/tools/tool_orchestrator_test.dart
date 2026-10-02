import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:chibot/models/chat_message.dart';
import 'package:chibot/models/tool_call.dart';
import 'package:chibot/services/tools/tool_orchestrator.dart';

class Plugin implements ToolPlugin {
  int executions = 0;
  Future<ToolResult> Function()? handler;
  @override
  List<ToolDefinition> get tools => const [
    ToolDefinition(
      'read',
      'Read',
      {
        'q': {'type': 'string'},
      },
      required: ['q'],
    ),
    ToolDefinition(
      'write',
      'Write',
      {
        'q': {'type': 'string'},
      },
      required: ['q'],
      writes: true,
    ),
  ];
  @override
  Future<ToolResult> execute(String name, Map<String, dynamic> args) async {
    executions++;
    return handler == null ? const ToolResult({'ok': true}) : await handler!();
  }
}

class Model implements ToolChatService {
  final List<List<ToolModelEvent>> turns;
  final List<List<Map<String, dynamic>>> requests = [];
  final List<List<ToolDefinition>> definitions = [];
  Model(this.turns);
  @override
  Stream<ToolModelEvent> generateToolTurn({
    required List<Map<String, dynamic>> messages,
    required List<ToolDefinition> tools,
    required String model,
  }) async* {
    requests.add(
      List<Map<String, dynamic>>.from(jsonDecode(jsonEncode(messages))),
    );
    definitions.add(tools);
    yield* Stream.fromIterable(turns[requests.length - 1]);
  }
}

const read = ToolCall('r', 'read', '{"q":"repo"}');
const write = ToolCall('w', 'write', '{"q":"body"}');
void main() {
  late Plugin plugin;
  late ToolCancellation cancellation;
  late List<Map<String, dynamic>> updates;
  setUp(() {
    plugin = Plugin();
    cancellation = ToolCancellation();
    updates = [];
  });
  ToolOrchestrator create({
    Future<bool> Function(ToolCall, Map<String, dynamic>)? confirm,
  }) => ToolOrchestrator(
    registry: ToolRegistry([plugin]),
    cancellation: cancellation,
    confirm: confirm ?? (_, _) async => true,
    onUpdate: (m) async {
      updates.add(m);
    },
  );
  Future<List<String>> run(ToolOrchestrator o, Model m) =>
      o.run(service: m, model: 'm', history: [], prompt: 'hi').toList();

  test(
    'multiple calls execute sequentially and feed matching IDs back before final answer',
    () async {
      final model = Model([
        [
          const ToolModelEvent.text('Checking'),
          const ToolModelEvent.calls([read, write]),
        ],
        [const ToolModelEvent.text('Done')],
      ]);
      final o = create();
      expect(await run(o, model), ['Checking', 'Done']);
      expect(plugin.executions, 2);
      final request = model.requests.last;
      expect(request.map((m) => m['role']), [
        'user',
        'assistant',
        'tool',
        'tool',
      ]);
      expect(request[2]['tool_call_id'], 'r');
      expect(request[3]['tool_call_id'], 'w');
      expect(o.metadata['toolFinalText'], 'Done');
      expect((updates.first['toolRecords'] as List).first['status'], 'running');
    },
  );
  test(
    'rejecting a write never executes it and returns structured rejection',
    () async {
      final o = create(confirm: (_, _) async => false);
      final model = Model([
        [
          const ToolModelEvent.calls([write]),
        ],
        [const ToolModelEvent.text('Rejected')],
      ]);
      await run(o, model);
      expect(plugin.executions, 0);
      expect(
        jsonDecode(model.requests.last.last['content'])['error'],
        'rejected',
      );
    },
  );
  test(
    'cancellation unblocks confirmation and prevents subsequent execution',
    () async {
      final pending = Completer<bool>();
      final entered = Completer<void>();
      final o = create(
        confirm: (_, _) {
          entered.complete();
          return pending.future;
        },
      );
      final model = Model([
        [
          const ToolModelEvent.calls([write, read]),
        ],
      ]);
      final result = run(o, model);
      await entered.future;
      cancellation.cancel();
      await result;
      pending.complete(true);
      expect(plugin.executions, 0);
      expect(model.requests.length, 1);
      expect((o.metadata['toolProtocol'] as List).length, 3);
    },
  );
  test('an in-flight write retains its outcome after cancellation', () async {
    final response = Completer<ToolResult>();
    final dispatched = Completer<void>();
    plugin.handler = () {
      dispatched.complete();
      return response.future;
    };
    final o = create();
    final model = Model([
      [
        const ToolModelEvent.calls([write, read]),
      ],
    ]);
    final result = run(o, model);
    await dispatched.future;
    cancellation.cancel();
    response.complete(
      const ToolResult({
        'data': {'html_url': 'https://github.com/o/r/issues/1'},
      }),
    );
    await result;
    final records = o.metadata['toolRecords'] as List;
    expect(records[0]['status'], 'completed');
    expect(records[1]['status'], 'cancelled');
    expect(plugin.executions, 1);
  });
  test(
    'unknown tools, malformed JSON, arrays and invalid fields never execute',
    () async {
      for (final call in [
        const ToolCall('a', 'unknown', '{}'),
        const ToolCall('b', 'read', '{'),
        const ToolCall('c', 'read', '[]'),
        const ToolCall('d', 'read', '{"q":4}'),
        const ToolCall('e', 'read', '{"q":"x","extra":true}'),
      ]) {
        final model = Model([
          [
            ToolModelEvent.calls([call]),
          ],
          [],
        ]);
        await run(create(), model);
        expect(
          jsonDecode(model.requests.last.last['content'])['error'],
          'invalid_arguments',
        );
      }
      expect(plugin.executions, 0);
    },
  );
  test(
    'eight tool rounds followed by a final tools-disabled model turn',
    () async {
      final model = Model([
        ...List.generate(
          8,
          (_) => [
            const ToolModelEvent.calls([read]),
          ],
        ),
        [const ToolModelEvent.text('Final')],
      ]);
      await run(create(), model);
      expect(plugin.executions, 8);
      expect(model.definitions.last, isEmpty);
    },
  );
  test('a ninth tool round is refused', () async {
    final model = Model(
      List.generate(
        9,
        (_) => [
          const ToolModelEvent.calls([read]),
        ],
      ),
    );
    await expectLater(run(create(), model), throwsStateError);
    expect(plugin.executions, 8);
  });
  test(
    'history roundtrips through ChatMessage without replay or duplicate prelude',
    () async {
      final o = create();
      await run(
        o,
        Model([
          [
            const ToolModelEvent.text('Prelude'),
            const ToolModelEvent.calls([read]),
          ],
          [const ToolModelEvent.text('Answer')],
        ]),
      );
      final saved = ChatMessage.fromJson(
        ChatMessage.ai(
          id: 'a',
          text: 'PreludeAnswer',
          metadata: o.metadata,
        ).toJson(),
      );
      final history = ToolOrchestrator.buildHistory([saved], 'next');
      expect(history.map((m) => m['role']), [
        'assistant',
        'tool',
        'assistant',
        'user',
      ]);
      expect(history[2]['content'], 'Answer');
      expect(plugin.executions, 1);
    },
  );
  test(
    'context truncation never splits tool calls from their results',
    () async {
      final o = create();
      await run(
        o,
        Model([
          [
            const ToolModelEvent.calls([read, write]),
          ],
          [],
        ]),
      );
      final history = ToolOrchestrator.buildHistory([
        ...List.generate(100, (i) => ChatMessage.user(id: '$i', text: 'old')),
        ChatMessage.ai(id: 'a', text: '', metadata: o.metadata),
      ], 'next');
      final assistant = history.indexWhere((m) => m.containsKey('tool_calls'));
      expect(history[assistant + 1]['tool_call_id'], 'r');
      expect(history[assistant + 2]['tool_call_id'], 'w');
    },
  );
  test(
    'a mid-round snapshot retains completed writes and paired unfinished calls',
    () async {
      final pending = Completer<bool>();
      final secondApproval = Completer<void>();
      var approvals = 0;
      final o = create(
        confirm: (_, _) {
          if (++approvals == 1) return Future.value(true);
          secondApproval.complete();
          return pending.future;
        },
      );
      final model = Model([
        [
          const ToolModelEvent.calls([
            write,
            ToolCall('second', 'write', '{"q":"second"}'),
          ]),
        ],
      ]);
      final running = run(o, model);
      await secondApproval.future;
      final snapshot = ChatMessage.fromJson(
        ChatMessage.ai(
          id: 'saved',
          text: '',
          isLoading: true,
          metadata: o.metadata,
        ).toJson(),
      );
      final history = ToolOrchestrator.buildHistory([snapshot], 'next');
      expect(history.map((m) => m['role']), [
        'assistant',
        'tool',
        'tool',
        'user',
      ]);
      expect(jsonDecode(history[1]['content'])['ok'], true);
      expect(jsonDecode(history[2]['content'])['error'], 'interrupted');
      expect(snapshot.isLoading, false);
      cancellation.cancel();
      await running;
      pending.complete(true);
      expect(plugin.executions, 1);
    },
  );
}
