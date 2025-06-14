import 'package:chibot/models/image_message.dart';

class ImageSession {
  final String id;
  final String title;
  final List<ImageMessage> messages;
  final DateTime createdAt;
  final String model;

  ImageSession({
    required this.id,
    required this.title,
    required this.messages,
    required this.createdAt,
    required this.model,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'messages': messages.map((msg) => msg.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'model': model,
      };

  factory ImageSession.fromJson(Map<String, dynamic> json) => ImageSession(
        id: json['id'],
        title: json['title'],
        messages: (json['messages'] as List)
            .map((msgJson) => ImageMessage.fromJson(msgJson))
            .toList(),
        createdAt: DateTime.parse(json['createdAt']),
        model: json['model'] ?? '',
      );
}
