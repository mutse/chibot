import '../models/video_message.dart';

class VideoGenerationRequest {
  final String prompt;
  final VideoResolution resolution;
  final VideoDuration duration;
  final String quality;
  final String style;
  final String aspectRatio;
  final Map<String, dynamic>? additionalConfig;

  VideoGenerationRequest({
    required this.prompt,
    this.resolution = VideoResolution.res720p,
    this.duration = VideoDuration.seconds10,
    this.quality = 'standard',
    this.style = 'realistic',
    this.aspectRatio = '16:9',
    this.additionalConfig,
  });

  Map<String, dynamic> toJson() {
    return {
      'prompt': prompt,
      'videoConfig': {
        'resolution': resolution.label,
        'duration': duration.label,
        'aspectRatio': aspectRatio,
      },
      'generationConfig': {
        'quality': quality,
        'style': style,
        ...?additionalConfig,
      },
    };
  }
}

class VideoGenerationResponse {
  final String? jobId;
  final String? videoUrl;
  final VideoStatus status;
  final double? progress;
  final String? thumbnail;
  final String? error;
  final Map<String, dynamic>? metadata;

  VideoGenerationResponse({
    this.jobId,
    this.videoUrl,
    required this.status,
    this.progress,
    this.thumbnail,
    this.error,
    this.metadata,
  });

  factory VideoGenerationResponse.fromJson(Map<String, dynamic> json) {
    return VideoGenerationResponse(
      jobId: json['jobId'] ?? json['name'],
      videoUrl: json['videoUrl'] ?? json['url'],
      status: _parseStatus(json['status'] ?? json['state']),
      progress: json['progress']?.toDouble(),
      thumbnail: json['thumbnail'],
      error: json['error'],
      metadata: json['metadata'],
    );
  }

  static VideoStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
      case 'queued':
        return VideoStatus.pending;
      case 'processing':
      case 'in_progress':
      case 'running':
        return VideoStatus.processing;
      case 'completed':
      case 'succeeded':
      case 'done':
        return VideoStatus.completed;
      case 'failed':
      case 'error':
        return VideoStatus.failed;
      default:
        return VideoStatus.pending;
    }
  }
}

class VideoGenerationProgress {
  final String jobId;
  final VideoStatus status;
  final double progress;
  final String? message;
  final String? currentStep;

  VideoGenerationProgress({
    required this.jobId,
    required this.status,
    required this.progress,
    this.message,
    this.currentStep,
  });
}

abstract class VideoGenerationService {
  Future<VideoGenerationResponse> generateVideo(VideoGenerationRequest request);
  Future<VideoGenerationResponse> checkGenerationStatus(String jobId);
  Stream<VideoGenerationProgress> getGenerationProgress(String jobId);
  Future<void> cancelGeneration(String jobId);
  Future<String?> downloadVideo(String videoUrl, String localPath);
}