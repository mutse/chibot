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
