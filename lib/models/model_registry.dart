import 'available_model.dart';

/// 模型注册表 - 所有模型信息的唯一来源
///
/// 分为两部分：
/// - 静态目录：各提供商的内置模型列表、默认模型与查询接口（原 ServiceModelRegistry，
///   已合并至此，services/service_model_registry.dart 删除）
/// - 实例注册表：运行时动态注册的模型（含用户自定义模型），带 5 分钟校验缓存，
///   由各专职 Provider 同步写入，供 SettingsModelsProvider / ModelProviderAdapter 读取展示
///
/// 使用示例：
/// ```dart
/// final models = ModelRegistry.getChatModelsForProvider('OpenAI');
/// final allProviders = ModelRegistry.supportedProviders;
/// ```
class ModelRegistry {
  // ============ 静态：内置模型目录 ============

  static const String defaultOpenAIModel = 'gpt-5.6-sol';
  static const String openAITitleModel = 'gpt-5.6-luna';
  static const String defaultGeminiModel = 'gemini-3.6-flash';
  static const String geminiTitleModel = 'gemini-3.5-flash-lite';
  static const String defaultClaudeModel = 'claude-opus-5';
  static const String claudeTitleModel = 'claude-haiku-4-5';
  static const String defaultOpenAIImageModel = 'gpt-image-2';
  static const String defaultGoogleImageModel = 'gemini-3.1-flash-image';
  static const String googleImageLiteModel = 'gemini-3.1-flash-lite-image';
  static const String googleImageProModel = 'gemini-3-pro-image';
  static const String legacyGoogleImageModel = 'gemini-2.5-flash-image';
  static const String defaultVideoModel = 'veo-3.1-generate-preview';

  // Chat service models
  static const List<String> openAIModels = [
    'gpt-5.6-sol',
    'gpt-5.6-terra',
    'gpt-5.6-luna',
    'gpt-5.5',
    'gpt-5.4',
    'gpt-5.4-mini',
    'gpt-5.4-nano',
  ];

  static const List<String> geminiModels = [
    'gemini-3.6-flash',
    'gemini-3.5-flash',
    'gemini-3.5-flash-lite',
    'gemini-3.1-flash-lite',
    'gemini-3.1-pro-preview',
    'gemini-2.5-pro',
    'gemini-2.5-flash',
    'gemini-2.5-flash-lite',
  ];

  static const List<String> claudeModels = [
    'claude-fable-5',
    'claude-opus-5',
    'claude-sonnet-5',
    'claude-opus-4-7',
    'claude-sonnet-4-6',
    'claude-haiku-4-5',
  ];

  // Image generation models
  static const List<String> googleImageModels = [
    defaultGoogleImageModel,
    googleImageLiteModel,
    googleImageProModel,
    legacyGoogleImageModel,
  ];

  static const List<String> fluxModels = [
    'flux-pro-1.1',
    'flux-pro',
    'flux-dev',
    'flux-krea-dev',
  ];

  static const List<String> openAIImageModels = [
    'gpt-image-2',
    'gpt-image-1.5',
    'dall-e-3',
  ];

  static const List<String> stabilityImageModels = [
    'stable-diffusion-xl-1024-v1-0',
    'stable-diffusion-v3-large',
  ];

  // Video generation models
  static const List<String> videoModels = [
    'veo-3.1-generate-preview',
    'veo-3.1-fast-generate-preview',
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
  static List<String> get chatProviders => ['OpenAI', 'Google', 'Anthropic'];

  /// 获取所有支持的图像生成提供商
  static List<String> get imageProviders => [
    'google',
    'Black Forest Labs',
    'OpenAI',
    'Stability AI',
  ];

  /// 获取所有支持的视频生成提供商
  static List<String> get videoProviders => ['Google Veo3'];

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

  // ============ 实例：运行时动态注册表 ============

  final Map<ModelType, List<AvailableModel>> _models = {
    ModelType.text: [],
    ModelType.image: [],
    ModelType.customOpenAI: [],
  };

  // 缓存验证时间
  final Map<String, DateTime> _lastValidated = {};
  final Duration cacheTtl = const Duration(minutes: 5);

  List<AvailableModel> getModels({required ModelType type}) =>
      List.unmodifiable(_models[type] ?? []);

  void registerModel(AvailableModel model) {
    _models[model.type]?.removeWhere(
      (m) => m.id == model.id && m.provider == model.provider,
    );
    _models[model.type]?.add(model);
    _lastValidated[_buildValidationKey(model.id, model.provider)] =
        DateTime.now();
  }

  bool shouldRefresh(String modelId, {String? provider}) {
    final cacheKey =
        provider == null ? modelId : _buildValidationKey(modelId, provider);
    final lastValidated = _lastValidated[cacheKey];
    return lastValidated == null ||
        DateTime.now().difference(lastValidated) > cacheTtl;
  }

  void clearType(ModelType type) {
    _models[type]?.clear();
  }

  void clear() {
    for (var type in _models.keys) {
      _models[type]?.clear();
    }
    _lastValidated.clear();
  }

  String _buildValidationKey(String modelId, String provider) {
    return '$provider::$modelId';
  }
}
