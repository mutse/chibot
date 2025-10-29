import 'video_message.dart';

class VideoSettings {
  final VideoResolution resolution;
  final VideoDuration duration;
  final String quality;
  final String style;
  final String aspectRatio;

  VideoSettings({
    this.resolution = VideoResolution.res720p,
    this.duration = VideoDuration.seconds10,
    this.quality = 'standard',
    this.style = 'realistic',
    this.aspectRatio = '16:9',
  });

  Map<String, dynamic> toJson() {
    return {
      'resolution': resolution.label,
      'duration': duration.seconds,
      'quality': quality,
      'style': style,
      'aspectRatio': aspectRatio,
    };
  }

  factory VideoSettings.fromJson(Map<String, dynamic> json) {
    return VideoSettings(
      resolution: VideoResolution.fromString(json['resolution'] ?? '720p'),
      duration: VideoDuration.fromSeconds(json['duration'] ?? 10),
      quality: json['quality'] ?? 'standard',
      style: json['style'] ?? 'realistic',
      aspectRatio: json['aspectRatio'] ?? '16:9',
    );
  }

  VideoSettings copyWith({
    VideoResolution? resolution,
    VideoDuration? duration,
    String? quality,
    String? style,
    String? aspectRatio,
  }) {
    return VideoSettings(
      resolution: resolution ?? this.resolution,
      duration: duration ?? this.duration,
      quality: quality ?? this.quality,
      style: style ?? this.style,
      aspectRatio: aspectRatio ?? this.aspectRatio,
    );
  }
}

class VideoSession {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<VideoMessage> videos;
  final VideoSettings settings;
  final int totalDuration;
  final Map<String, dynamic>? metadata;

  VideoSession({
    required this.id,
    required this.title,
    required this.createdAt,
    this.updatedAt,
    required this.videos,
    required this.settings,
    this.totalDuration = 0,
    this.metadata,
  });

  int get videoCount => videos.where((v) => v.status == VideoStatus.completed).length;

  int calculateTotalDuration() {
    return videos
        .where((v) => v.status == VideoStatus.completed)
        .fold(0, (sum, video) => sum + video.duration.seconds);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'videos': videos.map((v) => v.toJson()).toList(),
      'settings': settings.toJson(),
      'totalDuration': totalDuration,
      'metadata': metadata,
    };
  }

  factory VideoSession.fromJson(Map<String, dynamic> json) {
    final videos = (json['videos'] as List<dynamic>?)
            ?.map((v) => VideoMessage.fromJson(v as Map<String, dynamic>))
            .toList() ??
        [];

    return VideoSession(
      id: json['id'],
      title: json['title'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      videos: videos,
      settings: VideoSettings.fromJson(json['settings'] ?? {}),
      totalDuration: json['totalDuration'] ?? 0,
      metadata: json['metadata'],
    );
  }

  VideoSession copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<VideoMessage>? videos,
    VideoSettings? settings,
    int? totalDuration,
    Map<String, dynamic>? metadata,
  }) {
    return VideoSession(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      videos: videos ?? this.videos,
      settings: settings ?? this.settings,
      totalDuration: totalDuration ?? this.totalDuration,
      metadata: metadata ?? this.metadata,
    );
  }

  VideoSession addVideo(VideoMessage video) {
    final newVideos = List<VideoMessage>.from(videos)..add(video);
    return copyWith(
      videos: newVideos,
      updatedAt: DateTime.now(),
      totalDuration: calculateTotalDuration(),
    );
  }

  VideoSession updateVideo(int index, VideoMessage video) {
    final newVideos = List<VideoMessage>.from(videos);
    if (index >= 0 && index < newVideos.length) {
      newVideos[index] = video;
    }
    return copyWith(
      videos: newVideos,
      updatedAt: DateTime.now(),
      totalDuration: calculateTotalDuration(),
    );
  }

  VideoSession removeVideo(int index) {
    final newVideos = List<VideoMessage>.from(videos);
    if (index >= 0 && index < newVideos.length) {
      newVideos.removeAt(index);
    }
    return copyWith(
      videos: newVideos,
      updatedAt: DateTime.now(),
      totalDuration: calculateTotalDuration(),
    );
  }
}