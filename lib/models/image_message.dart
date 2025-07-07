import 'chat_message.dart'; // Assuming ChatMessage and MessageSender are in here

class ImageMessage extends ChatMessage {
  final String? imageUrl;
  final String? imagePath;

  ImageMessage({
    required this.imageUrl,
    this.imagePath, // Make imagePath optional and nullable
    required super.text, // Prompt or a caption
    required super.sender,
    required super.timestamp,
    super.isLoading,
    super.error, // Added for error messages
  });

  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson(), // Include base ChatMessage fields
    'imageUrl': imageUrl,
    'imagePath': imagePath, // Include imagePath in JSON
    'type': 'image', // Add a type identifier
  };

  factory ImageMessage.fromJson(Map<String, dynamic> json) => ImageMessage(
    imageUrl: json['imageUrl'],
    imagePath: json['imagePath'], // Parse imagePath from JSON
    text: json['text'],
    sender: MessageSender.values.firstWhere(
      (e) => e.toString().split('.').last == json['sender'],
    ),
    timestamp: DateTime.parse(json['timestamp']),
    isLoading: json['isLoading'],
    error: json['error'],
  );

  @override
  ImageMessage copyWith({
    String? imageUrl,
    String? imagePath,
    String? text,
    MessageSender? sender,
    DateTime? timestamp,
    bool? isLoading,
    String? error,
  }) {
    return ImageMessage(
      imageUrl: imageUrl ?? this.imageUrl,
      imagePath: imagePath ?? this.imagePath,
      text: text ?? this.text,
      sender: sender ?? this.sender,
      timestamp: timestamp ?? this.timestamp,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}
