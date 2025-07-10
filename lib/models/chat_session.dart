import 'package:equatable/equatable.dart';
import '../core/logger.dart';
import 'chat_message.dart';

class ChatSession extends Equatable {
  final String id;
  final String title;
  final List<ChatMessage> messages;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? modelUsed;
  final String? providerUsed;
  final Map<String, dynamic>? metadata;

  const ChatSession({
    required this.id,
    required this.title,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
    this.modelUsed,
    this.providerUsed,
    this.metadata,
  });

  // Factory constructor for new sessions
  factory ChatSession.create({
    required String id,
    required String title,
    String? modelUsed,
    String? providerUsed,
    Map<String, dynamic>? metadata,
  }) {
    final now = DateTime.now();
    return ChatSession(
      id: id,
      title: title,
      messages: [],
      createdAt: now,
      updatedAt: now,
      modelUsed: modelUsed,
      providerUsed: providerUsed,
      metadata: metadata,
    );
  }

  // Convert a ChatSession object into a Map object
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'messages': messages.map((msg) => msg.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'modelUsed': modelUsed,
        'providerUsed': providerUsed,
        'metadata': metadata,
      };

  // Convert a Map object into a ChatSession object
  factory ChatSession.fromJson(Map<String, dynamic> json) {
    try {
      return ChatSession(
        id: json['id'] as String,
        title: json['title'] as String,
        messages: (json['messages'] as List<dynamic>)
            .map((msgJson) => ChatMessage.fromJson(msgJson as Map<String, dynamic>))
            .toList(),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: json['updatedAt'] != null 
            ? DateTime.parse(json['updatedAt'] as String)
            : DateTime.parse(json['createdAt'] as String),
        modelUsed: json['modelUsed'] as String?,
        providerUsed: json['providerUsed'] as String?,
        metadata: json['metadata'] as Map<String, dynamic>?,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Failed to parse ChatSession from JSON', 
        error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // Add a message to the session
  ChatSession addMessage(ChatMessage message) {
    return copyWith(
      messages: [...messages, message],
      updatedAt: DateTime.now(),
    );
  }

  // Update the last message in the session
  ChatSession updateLastMessage(ChatMessage message) {
    if (messages.isEmpty) {
      return addMessage(message);
    }
    
    final updatedMessages = List<ChatMessage>.from(messages);
    updatedMessages[updatedMessages.length - 1] = message;
    
    return copyWith(
      messages: updatedMessages,
      updatedAt: DateTime.now(),
    );
  }

  // Remove a message from the session
  ChatSession removeMessage(String messageId) {
    final updatedMessages = messages.where((msg) => msg.id != messageId).toList();
    return copyWith(
      messages: updatedMessages,
      updatedAt: DateTime.now(),
    );
  }

  // Clear all messages
  ChatSession clearMessages() {
    return copyWith(
      messages: [],
      updatedAt: DateTime.now(),
    );
  }

  // Update session title
  ChatSession updateTitle(String newTitle) {
    return copyWith(
      title: newTitle,
      updatedAt: DateTime.now(),
    );
  }

  // CopyWith method for immutability
  ChatSession copyWith({
    String? id,
    String? title,
    List<ChatMessage>? messages,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? modelUsed,
    String? providerUsed,
    Map<String, dynamic>? metadata,
  }) {
    return ChatSession(
      id: id ?? this.id,
      title: title ?? this.title,
      messages: messages ?? this.messages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      modelUsed: modelUsed ?? this.modelUsed,
      providerUsed: providerUsed ?? this.providerUsed,
      metadata: metadata ?? this.metadata,
    );
  }

  // Getters for convenience
  bool get isEmpty => messages.isEmpty;
  bool get isNotEmpty => messages.isNotEmpty;
  int get messageCount => messages.length;
  ChatMessage? get lastMessage => messages.isNotEmpty ? messages.last : null;
  ChatMessage? get firstMessage => messages.isNotEmpty ? messages.first : null;
  
  // Get messages for API (filtered for valid messages)
  List<ChatMessage> get validMessages => messages.where((msg) => msg.isValid).toList();
  
  // Get display title (truncated if too long)
  String get displayTitle => title.length > 50 ? '${title.substring(0, 50)}...' : title;

  @override
  List<Object?> get props => [
        id,
        title,
        messages,
        createdAt,
        updatedAt,
        modelUsed,
        providerUsed,
        metadata,
      ];

  @override
  String toString() {
    return 'ChatSession(id: $id, title: $title, messageCount: $messageCount, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}