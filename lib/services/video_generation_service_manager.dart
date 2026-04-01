import '../providers/video_model_provider.dart';
import '../providers/api_key_provider.dart';
import 'video_generation_service.dart';
import 'veo3_service.dart';
import 'service_config_validator.dart';

/// 视频生成服务管理器 - 使用专职提供者创建视频生成服务
///
/// 改进：
/// - 使用 VideoModelProvider 和 ApiKeyProvider 代替 SettingsProvider
/// - 统一的视频生成服务创建和验证
/// - 支持视频参数配置（分辨率、时长、质量等）
///
/// 使用示例：
/// ```dart
/// final manager = VideoGenerationServiceManager();
/// final isConfigured = VideoGenerationServiceManager.isVideoGenerationConfigured(
///   videoModel: videoModelProvider,
///   apiKeys: apiKeyProvider,
/// );
///
/// if (isConfigured) {
///   final service = VideoGenerationServiceManager.createAndValidateVideoService(
///     videoModel: videoModelProvider,
///     apiKeys: apiKeyProvider,
///   );
/// }
/// ```
class VideoGenerationServiceManager {
  static const String veo3Provider = 'Google Veo3';

  /// 检查视频生成是否已完全配置
  ///
  /// 检查项：
  /// 1. API Key 是否已设置
  /// 2. 提供商是否被支持
  static bool isVideoGenerationConfigured({
    required VideoModelProvider videoModel,
    required ApiKeyProvider apiKeys,
  }) {
    final apiKey =
        apiKeys.googleApiKey; // Video generation currently uses Google API

    return ServiceConfigValidator.hasText(apiKey);
  }

  /// 验证并创建视频生成服务（带更详细的错误信息）
  ///
  /// 返回服务或抛出描述性异常
  static VideoGenerationService createAndValidateVideoService({
    required VideoModelProvider videoModel,
    required ApiKeyProvider apiKeys,
  }) {
    // 检查 API Key (当前使用 Google API)
    final apiKey = ServiceConfigValidator.requireText(
      apiKeys.googleApiKey,
      'API key not configured for video generation. '
      'Please configure Google API key in settings.',
    );

    // 返回已验证配置的服务
    return Veo3Service(apiKey: apiKey);
  }

  /// 获取所有支持的视频生成提供商
  static List<String> get supportedVideoProviders => [veo3Provider];

  /// 检查特定视频提供商是否已配置
  ///
  /// 返回 true 如果相应的 API Key 已配置且非空
  static bool isVideoProviderConfigured({
    required ApiKeyProvider apiKeys,
    required String provider,
  }) {
    switch (provider) {
      case veo3Provider:
        // Veo3 uses Google API
        return ServiceConfigValidator.hasText(apiKeys.googleApiKey);
      default:
        return false;
    }
  }

  /// 获取所有已配置的视频生成提供商列表
  static List<String> getAvailableVideoProviders({
    required ApiKeyProvider apiKeys,
  }) {
    return supportedVideoProviders
        .where(
          (provider) =>
              isVideoProviderConfigured(apiKeys: apiKeys, provider: provider),
        )
        .toList();
  }

  /// 为视频生成准备参数
  ///
  /// 这个方法收集所有必要的参数，准备好传递给 VideoGenerationService
  static Map<String, dynamic> prepareVideoGenerationParams({
    required VideoModelProvider videoModel,
    required ApiKeyProvider apiKeys,
    required String prompt,
  }) {
    final apiKey = ServiceConfigValidator.requireText(
      apiKeys.googleApiKey,
      'API key not configured for video generation. '
      'Please configure Google API key in settings.',
    );

    return {
      'apiKey': apiKey,
      'prompt': prompt,
      'provider': videoModel.selectedVideoProvider,
      'resolution': videoModel.videoResolution,
      'duration': videoModel.videoDuration,
      'quality': videoModel.videoQuality,
      'aspectRatio': videoModel.videoAspectRatio,
    };
  }

  /// 验证视频参数是否有效
  ///
  /// 检查所有视频配置参数是否被支持
  static bool validateVideoParams({required VideoModelProvider videoModel}) {
    return videoModel.isValidResolution(videoModel.videoResolution) &&
        videoModel.isValidDuration(videoModel.videoDuration) &&
        videoModel.isValidQuality(videoModel.videoQuality) &&
        videoModel.isValidAspectRatio(videoModel.videoAspectRatio);
  }

  /// 获取视频配置的描述字符串
  ///
  /// 用于UI展示当前配置
  static String getVideoConfigDescription({
    required VideoModelProvider videoModel,
  }) {
    return '${videoModel.videoResolution} @ ${videoModel.videoDuration} (${videoModel.videoQuality}) - ${videoModel.videoAspectRatio}';
  }
}
