enum MessageSender { user, ai }

class ChatMessage {
  final String text;
  final MessageSender sender;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.sender,
    required this.timestamp,
  });

  // OpenAI API 需要的格式
  Map<String, String> toApiJson() {
    return {
      'role': sender == MessageSender.user ? 'user' : 'assistant',
      'content': text,
    };
  }
}
