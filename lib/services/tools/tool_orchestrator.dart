import 'dart:convert';
import '../../constants/app_constants.dart';
import '../../models/chat_message.dart';
import '../../models/tool_call.dart';

class ToolRegistry {
  final Map<String, ToolPlugin> _plugins = {};
  final Map<String, ToolDefinition> _definitions = {};
  ToolRegistry(List<ToolPlugin> plugins) {
    for (final plugin in plugins) {
      for (final tool in plugin.tools) {
        if (_plugins.containsKey(tool.name)) {
          throw ArgumentError('Duplicate tool');
        }
        _plugins[tool.name] = plugin;
        _definitions[tool.name] = tool;
      }
    }
  }
  List<ToolDefinition> get tools => _definitions.values.toList();
  ToolDefinition? definition(String name) => _definitions[name];
  Future<ToolResult> execute(ToolCall call, Map<String, dynamic> args) =>
      _plugins[call.name]!.execute(call.name, args);
}

/// A run owns its transcript and never resumes persisted operations.
class ToolOrchestrator {
  final ToolRegistry registry;
  final ToolCancellation cancellation;
  final Future<bool> Function(ToolCall, Map<String, dynamic>) confirm;
  final Future<void> Function(Map<String, dynamic>) onUpdate;
  final List<Map<String, dynamic>> _protocol = [];
  final List<ToolExecutionEvent> _records = [];
  String _finalText = '';
  ToolOrchestrator({
    required this.registry,
    required this.cancellation,
    required this.confirm,
    required this.onUpdate,
  });
  Map<String, dynamic> get metadata =>
      jsonDecode(
            jsonEncode({
              'toolProtocol': _protocol,
              'toolRecords': _records.map((e) => e.toJson()).toList(),
              'toolFinalText': _finalText,
            }),
          )
          as Map<String, dynamic>;
  static List<Map<String, dynamic>> buildHistory(
    List<ChatMessage> history,
    String prompt,
  ) {
    final groups = <List<Map<String, dynamic>>>[];
    for (final message in history) {
      if (message.isLoading) continue;
      final protocol = message.metadata?['toolProtocol'];
      final group = <Map<String, dynamic>>[];
      if (message.isAI && protocol is List && protocol.isNotEmpty) {
        group.addAll(protocol.map((m) => Map<String, dynamic>.from(m as Map)));
      }
      final finalText = message.metadata?['toolFinalText'];
      final api =
          finalText is String && protocol is List
              ? (finalText.isEmpty
                  ? null
                  : {'role': 'assistant', 'content': finalText})
              : message.toApiJson();
      if (api != null) group.add(Map<String, dynamic>.from(api));
      if (group.isNotEmpty) groups.add(group);
    }
    var count = groups.fold<int>(0, (n, group) => n + group.length);
    while (groups.length > 1 && count >= AppConstants.maxMessagesInContext) {
      count -= groups.removeAt(0).length;
    }
    return [
      ...groups.expand((g) => g),
      {'role': 'user', 'content': prompt},
    ];
  }

  Stream<String> run({
    required ToolChatService service,
    required String model,
    required List<ChatMessage> history,
    required String prompt,
  }) async* {
    final messages = buildHistory(history, prompt);
    for (var round = 0; round <= 8; round++) {
      if (cancellation.isCancelled) return;
      var text = '';
      var calls = <ToolCall>[];
      await for (final event in service.generateToolTurn(
        messages: messages,
        tools: round == 8 ? [] : registry.tools,
        model: model,
      )) {
        if (cancellation.isCancelled) return;
        if (event.text != null) {
          text += event.text!;
          yield event.text!;
        }
        if (event.calls != null) calls = event.calls!;
      }
      if (calls.isEmpty) {
        _finalText = text;
        await onUpdate(metadata);
        return;
      }
      if (round == 8) throw StateError('Tool call limit reached (8)');
      final assistant = <String, dynamic>{
        'role': 'assistant',
        'content': text.isEmpty ? null : text,
        'tool_calls': calls.map((c) => c.toJson()).toList(),
      };
      final roundStart = _protocol.length;
      _protocol.add(assistant);
      // Always persist paired messages, including an explicit unknown outcome
      // until each call finishes. A crash must not silently erase an earlier write.
      _protocol.addAll(
        calls.map(
          (call) => {
            'role': 'tool',
            'tool_call_id': call.id,
            'content':
                ToolResult.error(
                  'interrupted',
                  'No completed outcome recorded. Never repeat a write without new confirmation.',
                ).content,
          },
        ),
      );
      for (var callIndex = 0; callIndex < calls.length; callIndex++) {
        final call = calls[callIndex];
        final resultIndex = roundStart + 1 + callIndex;
        final record = ToolExecutionEvent(call);
        _records.add(record);
        ToolResult result;
        try {
          if (cancellation.isCancelled) {
            result = ToolResult.error(
              'cancelled',
              'Cancelled before execution',
            );
          } else {
            final definition = registry.definition(call.name);
            if (definition == null) throw const FormatException('Unknown tool');
            final args = call.decodeArguments();
            definition.validate(args);
            record.arguments = args;
            record.writes = definition.writes;
            record.status =
                definition.writes
                    ? ToolExecutionStatus.awaitingApproval
                    : ToolExecutionStatus.running;
            await onUpdate(metadata);
            final approved =
                !definition.writes ||
                await Future.any<bool>([
                  confirm(call, Map.unmodifiable(args)),
                  cancellation.whenCancelled.then((_) => false),
                ]);
            if (cancellation.isCancelled) {
              result = ToolResult.error(
                'cancelled',
                'Cancelled before execution',
              );
            } else if (!approved) {
              result = ToolResult.error(
                'rejected',
                'User rejected this operation. Do not retry it.',
              );
            } else {
              record.status = ToolExecutionStatus.running;
              if (definition.writes) {
                _protocol[resultIndex]['content'] =
                    ToolResult.error(
                      'outcome_unknown',
                      'Write outcome not yet recorded. Check GitHub before attempting another write.',
                    ).content;
              }
              await onUpdate(metadata);
              result =
                  cancellation.isCancelled
                      ? ToolResult.error(
                        'cancelled',
                        'Cancelled before execution',
                      )
                      : await registry.execute(call, args);
            }
          }
        } on FormatException catch (e) {
          result = ToolResult.error('invalid_arguments', e.message);
        } catch (_) {
          result = ToolResult.error('tool_failed', 'Tool execution failed');
        }
        record.complete(result);
        _protocol[resultIndex]['content'] = result.content;
        await onUpdate(metadata);
      }
      messages.addAll(_protocol.sublist(roundStart));
      await onUpdate(metadata);
    }
  }
}
