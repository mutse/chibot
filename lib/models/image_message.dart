import '../core/logger.dart';
import 'chat_message.dart';

class ImageMessage extends ChatMessage {
  final String? imageUrl;
  final String? imagePath;
  final String? imageData; // For base64 encoded images
  final int? width;
  final int? height;
  final String? mimeType;
  final int? fileSize;

  const ImageMessage({
    required super.id,
    required super.text,
    required super.sender,
    required super.timestamp,
    this.imageUrl,
    this.imagePath,
    this.imageData,
    this.width,
    this.height,
    this.mimeType,
    this.fileSize,
    super.isLoading = false,
    super.error,
    super.metadata,
  });

  // Factory constructor for user image messages (with prompt)
  factory ImageMessage.userPrompt({
    required String id,
    required String prompt,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
  }) {
    return ImageMessage(
      id: id,
      text: prompt,
      sender: MessageSender.user,
      timestamp: timestamp ?? DateTime.now(),
      metadata: metadata,
    );
  }

  // Factory constructor for AI generated images
  factory ImageMessage.aiGenerated({
    required String id,
    required String prompt,
    String? imageUrl,
    String? imagePath,
    String? imageData,
    int? width,
    int? height,
    String? mimeType,
    int? fileSize,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
  }) {
    return ImageMessage(
      id: id,
      text: prompt,
      sender: MessageSender.ai,
      timestamp: timestamp ?? DateTime.now(),
      imageUrl: imageUrl,
      imagePath: imagePath,
      imageData: imageData,
      width: width,
      height: height,
      mimeType: mimeType,
      fileSize: fileSize,
      metadata: metadata,
    );
  }

  // Factory constructor for loading state
  factory ImageMessage.loading({
    required String id,
    required String prompt,
    DateTime? timestamp,
  }) {
    return ImageMessage(
      id: id,
      text: prompt,
      sender: MessageSender.ai,
      timestamp: timestamp ?? DateTime.now(),
      isLoading: true,
    );
  }

  // Factory constructor for error state
  factory ImageMessage.error({
    required String id,
    required String prompt,
    required String error,
    DateTime? timestamp,
  }) {
    return ImageMessage(
      id: id,
      text: prompt,
      sender: MessageSender.ai,
      timestamp: timestamp ?? DateTime.now(),
      error: error,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    'type': 'image',
    'imageUrl': imageUrl,
    'imagePath': imagePath,
    'imageData': imageData,
    'width': width,
    'height': height,
    'mimeType': mimeType,
    'fileSize': fileSize,
  };

  factory ImageMessage.fromJson(Map<String, dynamic> json) {
    try {
      final id = json['id'];
      final text = json['text'];
      final senderRaw = json['sender'];
      final timestampRaw = json['timestamp'];
      final imageUrl = json['imageUrl'];
      final imagePath = json['imagePath'];
      final imageData = json['imageData'];
      final width = json['width'];
      final height = json['height'];
      final mimeType = json['mimeType'];
      final fileSize = json['fileSize'];
      final isLoading = json['isLoading'];
      final error = json['error'];
      final metadata = json['metadata'];

      return ImageMessage(
        id: id is String ? id : '',
        text: text is String ? text : '',
        sender: MessageSender.values.firstWhere(
          (e) => e.name == senderRaw,
          orElse: () => MessageSender.ai,
        ),
        timestamp:
            timestampRaw is String && DateTime.tryParse(timestampRaw) != null
                ? DateTime.parse(timestampRaw)
                : DateTime.now(),
        imageUrl: imageUrl is String ? imageUrl : null,
        imagePath: imagePath is String ? imagePath : null,
        imageData: imageData is String ? imageData : null,
        width: width is int ? width : null,
        height: height is int ? height : null,
        mimeType: mimeType is String ? mimeType : null,
        fileSize: fileSize is int ? fileSize : null,
        isLoading: isLoading is bool ? isLoading : false,
        error: error is String ? error : null,
        metadata: metadata is Map<String, dynamic> ? metadata : null,
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to parse ImageMessage from JSON',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  ImageMessage copyWith({
    String? id,
    String? text,
    MessageSender? sender,
    DateTime? timestamp,
    bool? isLoading,
    String? error,
    Map<String, dynamic>? metadata,
    String? imageUrl,
    String? imagePath,
    String? imageData,
    int? width,
    int? height,
    String? mimeType,
    int? fileSize,
  }) {
    return ImageMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      sender: sender ?? this.sender,
      timestamp: timestamp ?? this.timestamp,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      metadata: metadata ?? this.metadata,
      imageUrl: imageUrl ?? this.imageUrl,
      imagePath: imagePath ?? this.imagePath,
      imageData: imageData ?? this.imageData,
      width: width ?? this.width,
      height: height ?? this.height,
      mimeType: mimeType ?? this.mimeType,
      fileSize: fileSize ?? this.fileSize,
    );
  }

  // Getters for convenience
  bool get hasImage =>
      imageUrl != null || imagePath != null || imageData != null;
  bool get hasLocalImage => imagePath != null;
  bool get hasRemoteImage => imageUrl != null;
  bool get hasImageData => imageData != null;
  bool get hasImageDimensions => width != null && height != null;

  String get displayText => text.isEmpty ? 'Image generated' : text;

  // Get the best available image source
  String? get bestImageSource {
    if (imagePath != null) return imagePath;
    if (imageUrl != null) return imageUrl;
    if (imageData != null) return imageData;
    return null;
  }

  @override
  List<Object?> get props => [
    ...super.props,
    imageUrl,
    imagePath,
    imageData,
    width,
    height,
    mimeType,
    fileSize,
  ];

  @override
  String toString() {
    return 'ImageMessage(id: $id, sender: $sender, prompt: ${text.length > 30 ? '${text.substring(0, 30)}...' : text}, hasImage: $hasImage, timestamp: $timestamp, isLoading: $isLoading, error: $error)';
  }
}
