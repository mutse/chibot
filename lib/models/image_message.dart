import 'chat_message.dart'; // Assuming ChatMessage and MessageSender are in here

class ImageMessage extends ChatMessage {
  final String imageUrl;

  ImageMessage({
    required this.imageUrl,
    required String text, // Prompt or a caption
    required MessageSender sender,
    required DateTime timestamp,
    bool? isLoading,
    String? error, // Added for error messages
  }) : super(
          text: text,
          sender: sender,
          timestamp: timestamp,
          isLoading: isLoading,
          error: error,
        );

  @override
  ImageMessage copyWith({
    String? imageUrl,
    String? text,
    MessageSender? sender,
    DateTime? timestamp,
    bool? isLoading,
    String? error,
  }) {
    return ImageMessage(
      imageUrl: imageUrl ?? this.imageUrl,
      text: text ?? this.text,
      sender: sender ?? this.sender,
      timestamp: timestamp ?? this.timestamp,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}