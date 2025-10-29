import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 负责视频生成相关的配置
/// 职责：管理视频生成提供商、模型、分辨率、时长、质量等设置
class VideoModelProvider with ChangeNotifier {
  // 当前选定的视频生成提供商
  String _selectedVideoProvider = 'Google Veo3';
  static const String _selectedVideoProviderKey = 'selected_video_provider';

  // 视频分辨率
  String _videoResolution = '720p';
  static const String _videoResolutionKey = 'video_resolution';

  // 视频时长
  String _videoDuration = '10s';
  static const String _videoDurationKey = 'video_duration';

  // 视频质量
  String _videoQuality = 'standard';
  static const String _videoQualityKey = 'video_quality';

  // 视频宽高比
  String _videoAspectRatio = '16:9';
  static const String _videoAspectRatioKey = 'video_aspect_ratio';

  // 预设的视频生成提供商基础 URL
  static const Map<String, String> defaultVideoBaseUrls = {
    'Google Veo3': 'https://generativelanguage.googleapis.com/v1beta',
  };

  // 支持的分辨率选项
  static const List<String> supportedResolutions = [
    '480p',
    '720p',
    '1080p',
  ];

  // 支持的时长选项
  static const List<String> supportedDurations = [
    '5s',
    '10s',
    '30s',
  ];

  // 支持的质量选项
  static const List<String> supportedQualities = [
    'draft',
    'standard',
    'high',
  ];

  // 支持的宽高比选项
  static const List<String> supportedAspectRatios = [
    '16:9',
    '9:16',
    '1:1',
    '4:3',
    '3:4',
  ];

  // ==================== Getters ====================

  String get selectedVideoProvider => _selectedVideoProvider;
  String get videoResolution => _videoResolution;
  String get videoDuration => _videoDuration;
  String get videoQuality => _videoQuality;
  String get videoAspectRatio => _videoAspectRatio;

  /// 获取当前选定的视频生成提供商的基础 URL
  String get videoProviderUrl {
    return defaultVideoBaseUrls[_selectedVideoProvider] ??
        defaultVideoBaseUrls['Google Veo3']!;
  }

  // ==================== 初始化 ====================

  VideoModelProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedVideoProvider =
        prefs.getString(_selectedVideoProviderKey) ?? 'Google Veo3';
    _videoResolution =
        prefs.getString(_videoResolutionKey) ?? '720p';
    _videoDuration =
        prefs.getString(_videoDurationKey) ?? '10s';
    _videoQuality =
        prefs.getString(_videoQualityKey) ?? 'standard';
    _videoAspectRatio =
        prefs.getString(_videoAspectRatioKey) ?? '16:9';
    notifyListeners();
  }

  // ==================== 设置方法 ====================

  /// 设置视频生成提供商
  Future<void> setSelectedVideoProvider(String provider) async {
    if (_selectedVideoProvider != provider) {
      _selectedVideoProvider = provider;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_selectedVideoProviderKey, provider);
      notifyListeners();
    }
  }

  /// 设置视频分辨率
  Future<void> setVideoResolution(String resolution) async {
    if (supportedResolutions.contains(resolution) &&
        _videoResolution != resolution) {
      _videoResolution = resolution;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_videoResolutionKey, resolution);
      notifyListeners();
    }
  }

  /// 设置视频时长
  Future<void> setVideoDuration(String duration) async {
    if (supportedDurations.contains(duration) &&
        _videoDuration != duration) {
      _videoDuration = duration;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_videoDurationKey, duration);
      notifyListeners();
    }
  }

  /// 设置视频质量
  Future<void> setVideoQuality(String quality) async {
    if (supportedQualities.contains(quality) &&
        _videoQuality != quality) {
      _videoQuality = quality;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_videoQualityKey, quality);
      notifyListeners();
    }
  }

  /// 设置视频宽高比
  Future<void> setVideoAspectRatio(String aspectRatio) async {
    if (supportedAspectRatios.contains(aspectRatio) &&
        _videoAspectRatio != aspectRatio) {
      _videoAspectRatio = aspectRatio;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_videoAspectRatioKey, aspectRatio);
      notifyListeners();
    }
  }

  // ==================== 验证方法 ====================

  /// 验证分辨率是否有效
  bool isValidResolution(String resolution) {
    return supportedResolutions.contains(resolution);
  }

  /// 验证时长是否有效
  bool isValidDuration(String duration) {
    return supportedDurations.contains(duration);
  }

  /// 验证质量是否有效
  bool isValidQuality(String quality) {
    return supportedQualities.contains(quality);
  }

  /// 验证宽高比是否有效
  bool isValidAspectRatio(String aspectRatio) {
    return supportedAspectRatios.contains(aspectRatio);
  }

  // ==================== 导入/导出 ====================

  /// 导出视频生成配置为 Map
  Map<String, dynamic> toMap() {
    return {
      _selectedVideoProviderKey: _selectedVideoProvider,
      _videoResolutionKey: _videoResolution,
      _videoDurationKey: _videoDuration,
      _videoQualityKey: _videoQuality,
      _videoAspectRatioKey: _videoAspectRatio,
    };
  }

  /// 从 Map 导入视频生成配置
  Future<void> fromMap(Map<String, dynamic> data) async {
    if (data.containsKey(_selectedVideoProviderKey)) {
      _selectedVideoProvider = data[_selectedVideoProviderKey];
    }
    if (data.containsKey(_videoResolutionKey) &&
        isValidResolution(data[_videoResolutionKey])) {
      _videoResolution = data[_videoResolutionKey];
    }
    if (data.containsKey(_videoDurationKey) &&
        isValidDuration(data[_videoDurationKey])) {
      _videoDuration = data[_videoDurationKey];
    }
    if (data.containsKey(_videoQualityKey) &&
        isValidQuality(data[_videoQualityKey])) {
      _videoQuality = data[_videoQualityKey];
    }
    if (data.containsKey(_videoAspectRatioKey) &&
        isValidAspectRatio(data[_videoAspectRatioKey])) {
      _videoAspectRatio = data[_videoAspectRatioKey];
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedVideoProviderKey, _selectedVideoProvider);
    await prefs.setString(_videoResolutionKey, _videoResolution);
    await prefs.setString(_videoDurationKey, _videoDuration);
    await prefs.setString(_videoQualityKey, _videoQuality);
    await prefs.setString(_videoAspectRatioKey, _videoAspectRatio);
    notifyListeners();
  }
}
