enum MessageSender { user, ai }

class ChatMessage {
  final String text;
  final MessageSender sender;
  final DateTime timestamp;
  final bool? isLoading; // Optional: for AI messages that are streaming
  final String? error; // Optional: for error messages

  ChatMessage({
    required this.text,
    required this.sender,
    required this.timestamp,
    this.isLoading,
    this.error,
  });

  // Convert a ChatMessage object into a Map object
  Map<String, dynamic> toJson() => {
        'text': text,
        'sender': sender.toString().split('.').last, // Convert enum to string
        'timestamp': timestamp.toIso8601String(),
        'isLoading': isLoading,
        'error': error,
      };

  // OpenAI API 需要的格式
  Map<String, String>? toApiJson() {
    if (text.isEmpty) {
      return null; // Return null if the message text is empty
    }
    return {
      'role': sender == MessageSender.user ? 'user' : 'assistant',
      'content': text,
    };
  }

  // Convert a Map object into a ChatMessage object
  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        text: json['text'],
        sender: MessageSender.values.firstWhere(
            (e) => e.toString().split('.').last == json['sender']),
        timestamp: DateTime.parse(json['timestamp']),
        isLoading: json['isLoading'],
        error: json['error'],
      );

  // CopyWith method for easier updates, especially for streaming
  ChatMessage copyWith({
    String? text,
    MessageSender? sender,
    DateTime? timestamp,
    bool? isLoading,
    String? error,
  }) {
    return ChatMessage(
      text: text ?? this.text,
      sender: sender ?? this.sender,
      timestamp: timestamp ?? this.timestamp,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}
