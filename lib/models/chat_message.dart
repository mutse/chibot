import 'package:equatable/equatable.dart';
import '../core/logger.dart';

enum MessageSender { user, ai }

class ChatMessage extends Equatable {
  final String id;
  final String text;
  final MessageSender sender;
  final DateTime timestamp;
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? metadata;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.sender,
    required this.timestamp,
    this.isLoading = false,
    this.error,
    this.metadata,
  });

  // Factory constructor for user messages
  factory ChatMessage.user({
    required String id,
    required String text,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessage(
      id: id,
      text: text,
      sender: MessageSender.user,
      timestamp: timestamp ?? DateTime.now(),
      metadata: metadata,
    );
  }

  // Factory constructor for AI messages
  factory ChatMessage.ai({
    required String id,
    required String text,
    DateTime? timestamp,
    bool isLoading = false,
    String? error,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessage(
      id: id,
      text: text,
      sender: MessageSender.ai,
      timestamp: timestamp ?? DateTime.now(),
      isLoading: isLoading,
      error: error,
      metadata: metadata,
    );
  }

  // Factory constructor for loading messages
  factory ChatMessage.loading({
    required String id,
    DateTime? timestamp,
  }) {
    return ChatMessage(
      id: id,
      text: '',
      sender: MessageSender.ai,
      timestamp: timestamp ?? DateTime.now(),
      isLoading: true,
    );
  }

  // Factory constructor for error messages
  factory ChatMessage.error({
    required String id,
    required String error,
    DateTime? timestamp,
  }) {
    return ChatMessage(
      id: id,
      text: '',
      sender: MessageSender.ai,
      timestamp: timestamp ?? DateTime.now(),
      error: error,
    );
  }

  // Convert a ChatMessage object into a Map object
  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'sender': sender.name,
        'timestamp': timestamp.toIso8601String(),
        'isLoading': isLoading,
        'error': error,
        'metadata': metadata,
      };

  // OpenAI API format
  Map<String, String>? toApiJson() {
    if (text.isEmpty || isLoading || error != null) {
      return null;
    }
    return {
      'role': sender == MessageSender.user ? 'user' : 'assistant',
      'content': text,
    };
  }

  // Convert a Map object into a ChatMessage object
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    try {
      return ChatMessage(
        id: json['id'] as String,
        text: json['text'] as String,
        sender: MessageSender.values.firstWhere(
          (e) => e.name == json['sender'],
          orElse: () => MessageSender.ai,
        ),
        timestamp: DateTime.parse(json['timestamp'] as String),
        isLoading: json['isLoading'] as bool? ?? false,
        error: json['error'] as String?,
        metadata: json['metadata'] as Map<String, dynamic>?,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Failed to parse ChatMessage from JSON', 
        error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // CopyWith method for easier updates, especially for streaming
  ChatMessage copyWith({
    String? id,
    String? text,
    MessageSender? sender,
    DateTime? timestamp,
    bool? isLoading,
    String? error,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      sender: sender ?? this.sender,
      timestamp: timestamp ?? this.timestamp,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      metadata: metadata ?? this.metadata,
    );
  }

  // Getters for convenience
  bool get isUser => sender == MessageSender.user;
  bool get isAI => sender == MessageSender.ai;
  bool get hasError => error != null;
  bool get isEmpty => text.isEmpty && !isLoading && !hasError;
  bool get isValid => !isEmpty || isLoading || hasError;

  @override
  List<Object?> get props => [
        id,
        text,
        sender,
        timestamp,
        isLoading,
        error,
        metadata,
      ];

  @override
  String toString() {
    return 'ChatMessage(id: $id, sender: $sender, text: ${text.length > 50 ? '${text.substring(0, 50)}...' : text}, timestamp: $timestamp, isLoading: $isLoading, error: $error)';
  }
}
