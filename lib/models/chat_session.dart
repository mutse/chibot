import 'package:chibot/models/chat_message.dart';

class ChatSession {
  final String id;
  final String title;
  final List<ChatMessage> messages;
  final DateTime createdAt;

  ChatSession({
    required this.id,
    required this.title,
    required this.messages,
    required this.createdAt,
  });

  // Convert a ChatSession object into a Map object
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'messages': messages.map((msg) => msg.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };

  // Convert a Map object into a ChatSession object
  factory ChatSession.fromJson(Map<String, dynamic> json) => ChatSession(
        id: json['id'],
        title: json['title'],
        messages: (json['messages'] as List)
            .map((msgJson) => ChatMessage.fromJson(msgJson))
            .toList(),
        createdAt: DateTime.parse(json['createdAt']),
      );
}