import '../providers/image_model_provider.dart';
import '../providers/api_key_provider.dart';
import 'image_generation_service.dart';
import 'service_config_validator.dart';

/// 图像生成服务管理器 - 使用专职提供者创建图像生成服务
///
/// 改进：
/// - 使用 ImageModelProvider 和 ApiKeyProvider 代替 SettingsProvider
/// - 统一的图像生成服务创建和验证
/// - 支持多个图像生成提供商
///
/// 使用示例：
/// ```dart
/// final manager = ImageGenerationServiceManager();
/// final service = ImageGenerationService();
/// final imageUrl = await service.generateImage(
///   apiKey: apiKeys.getImageApiKeyForProvider(imageModel.selectedImageProvider),
///   prompt: 'A beautiful sunset',
///   model: imageModel.selectedImageModel,
///   providerBaseUrl: imageModel.imageProviderUrl,
///   aspectRatio: imageModel.bflAspectRatio,
/// );
/// ```
class ImageGenerationServiceManager {
  /// 检查图像生成是否已完全配置
  ///
  /// 检查项：
  /// 1. API Key 是否已设置
  /// 2. 模型是否已选择
  /// 3. 提供商是否被支持
  static bool isImageGenerationConfigured({
    required ImageModelProvider imageModel,
    required ApiKeyProvider apiKeys,
  }) {
    final provider = imageModel.selectedImageProvider;
    final apiKey = apiKeys.getImageApiKeyForProvider(provider);
    final hasModel = imageModel.selectedImageModel.isNotEmpty;

    return ServiceConfigValidator.hasText(apiKey) && hasModel;
  }

  /// 验证并创建图像生成服务（带更详细的错误信息）
  ///
  /// 返回服务或抛出描述性异常
  static ImageGenerationService createAndValidateImageService({
    required ImageModelProvider imageModel,
    required ApiKeyProvider apiKeys,
  }) {
    // 检查 API Key
    final provider = imageModel.selectedImageProvider;
    final apiKey = apiKeys.getImageApiKeyForProvider(provider);

    if (!ServiceConfigValidator.hasText(apiKey)) {
      throw Exception(
        'API key not configured for $provider image provider. '
        'Please configure it in settings.',
      );
    }

    // 检查模型
    if (imageModel.selectedImageModel.isEmpty) {
      throw Exception(
        'No image model selected for $provider provider. '
        'Please select a model in settings.',
      );
    }

    // 返回已验证配置的服务
    return ImageGenerationService();
  }

  /// 获取当前选定提供商的所有可用图像模型
  ///
  /// 返回列表包含预设模型和自定义模型
  static List<String> getAvailableImageModels({
    required ImageModelProvider imageModel,
  }) {
    return imageModel.availableImageModels;
  }

  /// 获取所有支持的图像生成提供商
  static List<String> get supportedImageProviders => [
    'OpenAI',
    'Stability AI',
    'Black Forest Labs',
    'Google',
  ];

  /// 检查特定图像提供商是否已配置
  ///
  /// 返回 true 如果 API Key 已配置且非空
  static bool isImageProviderConfigured({
    required ApiKeyProvider apiKeys,
    required String provider,
  }) {
    final apiKey = apiKeys.getImageApiKeyForProvider(provider);
    return ServiceConfigValidator.hasText(apiKey);
  }

  /// 获取所有已配置的图像生成提供商列表
  static List<String> getAvailableImageProviders({
    required ApiKeyProvider apiKeys,
  }) {
    return supportedImageProviders
        .where(
          (provider) =>
              isImageProviderConfigured(apiKeys: apiKeys, provider: provider),
        )
        .toList();
  }

  /// 为图像生成准备参数
  ///
  /// 这个方法收集所有必要的参数，准备好传递给 ImageGenerationService
  static Map<String, dynamic> prepareImageGenerationParams({
    required ImageModelProvider imageModel,
    required ApiKeyProvider apiKeys,
    required String prompt,
  }) {
    final provider = imageModel.selectedImageProvider;
    final apiKey = ServiceConfigValidator.requireText(
      apiKeys.getImageApiKeyForProvider(provider),
      'API key not configured for $provider image provider. '
      'Please configure it in settings.',
    );

    return {
      'apiKey': apiKey,
      'prompt': prompt,
      'model': imageModel.selectedImageModel,
      'providerBaseUrl': imageModel.imageProviderUrl,
      'aspectRatio': imageModel.bflAspectRatio,
    };
  }
}
