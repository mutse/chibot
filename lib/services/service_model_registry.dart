/// 服务模型注册表 - 集中管理所有提供商的模型信息
///
/// 职责：
/// - 存储所有提供商的支持模型列表
/// - 提供模型查询接口
/// - 避免创建虚拟实例来获取模型列表
///
/// 使用示例：
/// ```dart
/// final models = ServiceModelRegistry.getModelsForProvider('OpenAI');
/// final allProviders = ServiceModelRegistry.supportedProviders;
/// ```
class ServiceModelRegistry {
  // Chat service models
  static const List<String> openAIModels = [
    'gpt-5.5',
    'gpt-5.4',
    'gpt-5.4-mini',
    'gpt-5.4-nano',
    'gpt-5.1',
    'gpt-5-mini',
    'gpt-5-nano',
    'gpt-4.1',
    'gpt-4.1-mini',
    'gpt-4.1-nano',
    'gpt-4o',
    'gpt-4o-mini',
    'o3',
    'o4-mini',
  ];

  static const List<String> geminiModels = [
    'gemini-2.5-pro',
    'gemini-2.5-flash',
    'gemini-2.5-flash-lite',
    'gemini-2.0-flash',
  ];

  static const List<String> claudeModels = [
    'claude-opus-4-1',
    'claude-sonnet-4-0',
    'claude-3-7-sonnet-latest',
    'claude-3-5-haiku-latest',
  ];

  // Image generation models
  static const List<String> googleImageModels = [
    'gemini-3.1-flash-image-preview',
    'gemini-3-pro-image-preview',
    'gemini-2.5-flash-image',
    'imagen-3',
  ];

  static const List<String> fluxModels = [
    'flux-pro-1.1',
    'flux-pro',
    'flux-dev',
    'flux-krea-dev',
  ];

  static const List<String> openAIImageModels = [
    'dall-e-3',
    'dall-e-2',
  ];

  static const List<String> stabilityImageModels = [
    'stable-diffusion-xl-1024-v1-0',
    'stable-diffusion-v3-large',
  ];

  // Video generation models
  static const List<String> videoModels = [
    'veo-3',
  ];

  // Search providers
  static const List<String> searchProviders = [
    'Google Custom Search',
    'Tavily',
  ];

  /// 获取聊天提供商支持的模型列表
  static List<String> getChatModelsForProvider(String provider) {
    switch (provider) {
      case 'OpenAI':
        return openAIModels;
      case 'Google':
        return geminiModels;
      case 'Anthropic':
        return claudeModels;
      default:
        return [];
    }
  }

  /// 获取图像生成提供商支持的模型列表
  static List<String> getImageModelsForProvider(String provider) {
    switch (provider) {
      case 'google':
      case 'Google':
        return googleImageModels;
      case 'flux':
      case 'Black Forest Labs':
        return fluxModels;
      case 'openai':
      case 'OpenAI':
        return openAIImageModels;
      case 'stability':
      case 'Stability AI':
        return stabilityImageModels;
      default:
        return [];
    }
  }

  /// 获取所有支持的聊天提供商
  static List<String> get chatProviders => [
    'OpenAI',
    'Google',
    'Anthropic',
  ];

  /// 获取所有支持的图像生成提供商
  static List<String> get imageProviders => [
    'google',
    'Black Forest Labs',
    'OpenAI',
    'Stability AI',
  ];

  /// 获取所有支持的视频生成提供商
  static List<String> get videoProviders => [
    'Google Veo3',
  ];

  /// 检查提供商是否支持指定模型
  static bool isSupportedModel(String provider, String model, String type) {
    List<String> models = [];

    if (type == 'chat') {
      models = getChatModelsForProvider(provider);
    } else if (type == 'image') {
      models = getImageModelsForProvider(provider);
    } else if (type == 'video') {
      models = videoModels;
    }

    return models.contains(model);
  }

  /// 获取所有支持的提供商
  static List<String> get supportedProviders => [
    ...chatProviders,
    ...imageProviders,
    ...videoProviders,
  ];
}
