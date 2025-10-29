import 'chat_message.dart';

enum VideoStatus {
  pending,
  processing,
  completed,
  failed,
  downloading,
}

enum VideoResolution {
  res480p('480p', 640, 480),
  res720p('720p', 1280, 720),
  res1080p('1080p', 1920, 1080);

  final String label;
  final int width;
  final int height;

  const VideoResolution(this.label, this.width, this.height);

  static VideoResolution fromString(String value) {
    switch (value.toLowerCase()) {
      case '480p':
        return VideoResolution.res480p;
      case '720p':
        return VideoResolution.res720p;
      case '1080p':
        return VideoResolution.res1080p;
      default:
        return VideoResolution.res720p;
    }
  }
}

enum VideoDuration {
  seconds5('5s', 5),
  seconds10('10s', 10),
  seconds15('15s', 15),
  seconds30('30s', 30);

  final String label;
  final int seconds;

  const VideoDuration(this.label, this.seconds);

  static VideoDuration fromSeconds(int seconds) {
    switch (seconds) {
      case 5:
        return VideoDuration.seconds5;
      case 10:
        return VideoDuration.seconds10;
      case 15:
        return VideoDuration.seconds15;
      case 30:
        return VideoDuration.seconds30;
      default:
        return VideoDuration.seconds10;
    }
  }
}

class VideoMessage extends ChatMessage {
  final String? videoUrl;
  final String? localPath;
  final String? thumbnail;
  final VideoDuration duration;
  final VideoResolution resolution;
  final VideoStatus status;
  final String? jobId;
  final double? progress;
  final String prompt; // Store the video generation prompt

  VideoMessage({
    required String id,
    required String text,
    required super.sender,
    required super.timestamp,
    super.isLoading,
    super.metadata,
    this.videoUrl,
    this.localPath,
    this.thumbnail,
    this.duration = VideoDuration.seconds10,
    this.resolution = VideoResolution.res720p,
    this.status = VideoStatus.pending,
    this.jobId,
    this.progress,
    String? prompt,
  }) : prompt = prompt ?? text,
        super(
          id: id,
          text: text,
        );

  @override
  VideoMessage copyWith({
    String? id,
    String? text,
    MessageSender? sender,
    DateTime? timestamp,
    bool? isLoading,
    Map<String, dynamic>? metadata,
    String? error,
    String? videoUrl,
    String? localPath,
    String? thumbnail,
    VideoDuration? duration,
    VideoResolution? resolution,
    VideoStatus? status,
    String? jobId,
    double? progress,
    String? prompt,
  }) {
    return VideoMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      sender: sender ?? this.sender,
      timestamp: timestamp ?? this.timestamp,
      isLoading: isLoading ?? this.isLoading,
      metadata: metadata ?? this.metadata,
      videoUrl: videoUrl ?? this.videoUrl,
      localPath: localPath ?? this.localPath,
      thumbnail: thumbnail ?? this.thumbnail,
      duration: duration ?? this.duration,
      resolution: resolution ?? this.resolution,
      status: status ?? this.status,
      jobId: jobId ?? this.jobId,
      progress: progress ?? this.progress,
      prompt: prompt ?? this.prompt,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    return {
      ...json,
      'prompt': prompt,
      'videoUrl': videoUrl,
      'localPath': localPath,
      'thumbnail': thumbnail,
      'duration': duration.seconds,
      'resolution': resolution.label,
      'status': status.name,
      'jobId': jobId,
      'progress': progress,
    };
  }

  factory VideoMessage.fromJson(Map<String, dynamic> json) {
    return VideoMessage(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      text: json['text'] ?? json['content'] ?? '',
      sender: MessageSender.values.firstWhere(
        (s) => s.name == (json['sender'] ?? 'user'),
        orElse: () => MessageSender.user,
      ),
      timestamp: DateTime.parse(json['timestamp']),
      isLoading: json['isLoading'] ?? false,
      metadata: json['metadata'],
      videoUrl: json['videoUrl'],
      localPath: json['localPath'],
      thumbnail: json['thumbnail'],
      duration: VideoDuration.fromSeconds(json['duration'] ?? 10),
      resolution: VideoResolution.fromString(json['resolution'] ?? '720p'),
      status: VideoStatus.values.firstWhere(
        (s) => s.name == (json['status'] ?? 'pending'),
        orElse: () => VideoStatus.pending,
      ),
      jobId: json['jobId'],
      progress: json['progress']?.toDouble(),
      prompt: json['prompt'] ?? json['text'] ?? json['content'] ?? '',
    );
  }
}