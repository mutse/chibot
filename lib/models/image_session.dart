import 'package:equatable/equatable.dart';
import '../core/logger.dart';
import 'image_message.dart';

class ImageSession extends Equatable {
  final String id;
  final String title;
  final List<ImageMessage> messages;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String model;
  final String? provider;
  final Map<String, dynamic>? settings;
  final Map<String, dynamic>? metadata;

  const ImageSession({
    required this.id,
    required this.title,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
    required this.model,
    this.provider,
    this.settings,
    this.metadata,
  });

  // Factory constructor for new image sessions
  factory ImageSession.create({
    required String id,
    required String title,
    required String model,
    String? provider,
    Map<String, dynamic>? settings,
    Map<String, dynamic>? metadata,
  }) {
    final now = DateTime.now();
    return ImageSession(
      id: id,
      title: title,
      messages: [],
      createdAt: now,
      updatedAt: now,
      model: model,
      provider: provider,
      settings: settings,
      metadata: metadata,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'messages': messages.map((msg) => msg.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'model': model,
        'provider': provider,
        'settings': settings,
        'metadata': metadata,
      };

  factory ImageSession.fromJson(Map<String, dynamic> json) {
    try {
      return ImageSession(
        id: json['id'] as String,
        title: json['title'] as String,
        messages: (json['messages'] as List<dynamic>)
            .map((msgJson) => ImageMessage.fromJson(msgJson as Map<String, dynamic>))
            .toList(),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : DateTime.parse(json['createdAt'] as String),
        model: json['model'] as String? ?? '',
        provider: json['provider'] as String?,
        settings: json['settings'] as Map<String, dynamic>?,
        metadata: json['metadata'] as Map<String, dynamic>?,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Failed to parse ImageSession from JSON', 
        error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // Add a message to the session
  ImageSession addMessage(ImageMessage message) {
    return copyWith(
      messages: [...messages, message],
      updatedAt: DateTime.now(),
    );
  }

  // Update the last message in the session
  ImageSession updateLastMessage(ImageMessage message) {
    if (messages.isEmpty) {
      return addMessage(message);
    }
    
    final updatedMessages = List<ImageMessage>.from(messages);
    updatedMessages[updatedMessages.length - 1] = message;
    
    return copyWith(
      messages: updatedMessages,
      updatedAt: DateTime.now(),
    );
  }

  // Remove a message from the session
  ImageSession removeMessage(String messageId) {
    final updatedMessages = messages.where((msg) => msg.id != messageId).toList();
    return copyWith(
      messages: updatedMessages,
      updatedAt: DateTime.now(),
    );
  }

  // Clear all messages
  ImageSession clearMessages() {
    return copyWith(
      messages: [],
      updatedAt: DateTime.now(),
    );
  }

  // Update session title
  ImageSession updateTitle(String newTitle) {
    return copyWith(
      title: newTitle,
      updatedAt: DateTime.now(),
    );
  }

  // Update model
  ImageSession updateModel(String newModel, {String? newProvider}) {
    return copyWith(
      model: newModel,
      provider: newProvider ?? provider,
      updatedAt: DateTime.now(),
    );
  }

  // Update settings
  ImageSession updateSettings(Map<String, dynamic> newSettings) {
    return copyWith(
      settings: newSettings,
      updatedAt: DateTime.now(),
    );
  }

  // CopyWith method for immutability
  ImageSession copyWith({
    String? id,
    String? title,
    List<ImageMessage>? messages,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? model,
    String? provider,
    Map<String, dynamic>? settings,
    Map<String, dynamic>? metadata,
  }) {
    return ImageSession(
      id: id ?? this.id,
      title: title ?? this.title,
      messages: messages ?? this.messages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      model: model ?? this.model,
      provider: provider ?? this.provider,
      settings: settings ?? this.settings,
      metadata: metadata ?? this.metadata,
    );
  }

  // Getters for convenience
  bool get isEmpty => messages.isEmpty;
  bool get isNotEmpty => messages.isNotEmpty;
  int get messageCount => messages.length;
  ImageMessage? get lastMessage => messages.isNotEmpty ? messages.last : null;
  ImageMessage? get firstMessage => messages.isNotEmpty ? messages.first : null;
  
  // Get valid messages (non-empty, non-error)
  List<ImageMessage> get validMessages => messages.where((msg) => msg.isValid).toList();
  
  // Get generated images count
  int get generatedImagesCount => messages.where((msg) => msg.hasImage).length;
  
  // Get display title (truncated if too long)
  String get displayTitle => title.length > 50 ? '${title.substring(0, 50)}...' : title;
  
  // Get model display name
  String get modelDisplayName {
    if (provider != null) {
      return '$provider - $model';
    }
    return model;
  }

  @override
  List<Object?> get props => [
        id,
        title,
        messages,
        createdAt,
        updatedAt,
        model,
        provider,
        settings,
        metadata,
      ];

  @override
  String toString() {
    return 'ImageSession(id: $id, title: $title, messageCount: $messageCount, model: $model, provider: $provider, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}
