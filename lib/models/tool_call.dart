import 'dart:async';
import 'dart:convert';

class ToolDefinition {
  final String name;
  final String description;
  final Map<String, dynamic> properties;
  final List<String> required;
  final bool writes;
  const ToolDefinition(
    this.name,
    this.description,
    this.properties, {
    this.required = const [],
    this.writes = false,
  });
  Map<String, dynamic> toJson() => {
    'type': 'function',
    'function': {
      'name': name,
      'description': description,
      'parameters': {
        'type': 'object',
        'properties': properties,
        'required': required,
        'additionalProperties': false,
      },
    },
  };
  void validate(Map<String, dynamic> args) {
    for (final key in required) {
      if (!args.containsKey(key)) throw FormatException('Missing $key');
    }
    for (final entry in args.entries) {
      final schema = properties[entry.key] as Map<String, dynamic>?;
      if (schema == null) {
        throw FormatException('Unknown parameter ${entry.key}');
      }
      final value = entry.value;
      if (schema['type'] == 'string' &&
          (value is! String || value.trim().isEmpty)) {
        throw FormatException('Invalid ${entry.key}');
      }
      if (schema['type'] == 'integer' && (value is! int || value < 1)) {
        throw FormatException('Invalid ${entry.key}');
      }
      if (schema['enum'] is List && !(schema['enum'] as List).contains(value)) {
        throw FormatException('Invalid ${entry.key}');
      }
      if (value is int &&
          schema['maximum'] is int &&
          value > schema['maximum']) {
        throw FormatException('Invalid ${entry.key}');
      }
    }
  }
}

class ToolCall {
  final String id;
  final String name;
  final String arguments;
  const ToolCall(this.id, this.name, this.arguments);
  Map<String, dynamic> decodeArguments() {
    final value = jsonDecode(arguments);
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Arguments must be an object');
    }
    return value;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': 'function',
    'function': {'name': name, 'arguments': arguments},
  };
}

class ToolResult {
  final Map<String, dynamic> data;
  const ToolResult(this.data);
  factory ToolResult.error(String code, String message) =>
      ToolResult({'error': code, 'message': message});
  String get content => jsonEncode(data);
}

enum ToolExecutionStatus {
  running,
  awaitingApproval,
  completed,
  cancelled,
  rejected,
  outcomeUnknown,
  failed,
}

/// Execution state is separate from provider protocol and display messages.
class ToolExecutionEvent {
  final ToolCall call;
  ToolExecutionStatus status = ToolExecutionStatus.running;
  Map<String, dynamic>? arguments;
  bool writes = false;
  ToolResult? result;
  ToolExecutionEvent(this.call);
  void complete(ToolResult value) {
    result = value;
    status = switch (value.data['error']) {
      null => ToolExecutionStatus.completed,
      'cancelled' => ToolExecutionStatus.cancelled,
      'rejected' => ToolExecutionStatus.rejected,
      'outcome_unknown' => ToolExecutionStatus.outcomeUnknown,
      _ => ToolExecutionStatus.failed,
    };
  }

  Map<String, dynamic> toJson() => {
    'id': call.id,
    'name': call.name,
    'status':
        status == ToolExecutionStatus.outcomeUnknown
            ? 'outcome_unknown'
            : status.name,
    'writes': writes,
    if (arguments != null) 'arguments': arguments,
    if (result != null) 'result': result!.data,
  };
}

class ToolModelEvent {
  final String? text;
  final List<ToolCall>? calls;
  const ToolModelEvent.text(this.text) : calls = null;
  const ToolModelEvent.calls(this.calls) : text = null;
}

/// Separate capability; text-only services need no changes.
abstract interface class ToolChatService {
  Stream<ToolModelEvent> generateToolTurn({
    required List<Map<String, dynamic>> messages,
    required List<ToolDefinition> tools,
    required String model,
  });
}

class ToolCancellation {
  final Completer<void> _cancelled = Completer<void>();
  bool get isCancelled => _cancelled.isCompleted;
  Future<void> get whenCancelled => _cancelled.future;
  void cancel() {
    if (!isCancelled) _cancelled.complete();
  }
}

abstract interface class ToolPlugin {
  List<ToolDefinition> get tools;
  Future<ToolResult> execute(String name, Map<String, dynamic> arguments);
}
