import '../repositories/interfaces.dart';
import '../providers/chat_model_provider.dart';
import '../providers/api_key_provider.dart';
import 'openai_chat_service.dart';
import 'gemini_chat_service.dart';
import 'claude_chat_service.dart';
import 'exceptions/missing_api_key_exception.dart';
import 'service_model_registry.dart';
import 'service_config_validator.dart';

/// 聊天服务工厂 - 使用专职提供者创建聊天服务
///
/// 改进：
/// - 使用 ChatModelProvider 和 ApiKeyProvider 代替 SettingsProvider
/// - 更清晰的职责分离
/// - 更易于测试和依赖注入
class ChatServiceFactory {
  static const String openAI = 'OpenAI';
  static const String gemini = 'Google';
  static const String claude = 'Anthropic';

  /// 从专职提供者创建聊天服务
  ///
  /// 使用示例：
  /// ```dart
  /// final chatModel = ChatModelProvider();
  /// final apiKeys = ApiKeyProvider();
  /// final service = ChatServiceFactory.createFromProviders(
  ///   chatModel: chatModel,
  ///   apiKeys: apiKeys,
  /// );
  /// ```
  static ChatService createFromProviders({
    required ChatModelProvider chatModel,
    required ApiKeyProvider apiKeys,
  }) {
    final provider = chatModel.selectedProvider;
    final rawApiKey = apiKeys.getApiKeyForProvider(provider);
    final baseUrl = chatModel.providerUrl;

    if (!ServiceConfigValidator.hasText(rawApiKey)) {
      throw MissingApiKeyException(
        provider: provider,
        availableProviders: getConfiguredProviders(apiKeys),
      );
    }

    final apiKey = ServiceConfigValidator.requireText(
      rawApiKey,
      'API key not configured for $provider provider.',
    );

    return create(provider: provider, apiKey: apiKey, baseUrl: baseUrl);
  }

  /// 获取已配置 API Key 的提供商列表
  static List<String> getConfiguredProviders(ApiKeyProvider apiKeys) {
    final configured = <String>[];
    if (ServiceConfigValidator.hasText(apiKeys.openaiApiKey)) {
      configured.add(openAI);
    }
    if (ServiceConfigValidator.hasText(apiKeys.googleApiKey)) {
      configured.add(gemini);
    }
    if (ServiceConfigValidator.hasText(apiKeys.claudeApiKey)) {
      configured.add(claude);
    }
    return configured;
  }

  /// 传统方式创建聊天服务（保持向后兼容）
  static ChatService create({
    required String provider,
    required String apiKey,
    String? baseUrl,
  }) {
    switch (provider) {
      case openAI:
        return OpenAIService(apiKey: apiKey, baseUrl: baseUrl);

      case gemini:
        return GeminiService(apiKey: apiKey, baseUrl: baseUrl);

      case claude:
        return ClaudeService(apiKey: apiKey, baseUrl: baseUrl);

      default:
        // Treat all custom providers as OpenAI-compatible
        return OpenAIService(apiKey: apiKey, baseUrl: baseUrl);
    }
  }

  static List<String> get supportedProviders => [openAI, gemini, claude];

  static bool isSupported(String provider) =>
      supportedProviders.contains(provider);

  /// 获取指定提供商支持的模型列表 (使用注册表，无需创建虚拟实例)
  static List<String> getModelsForProvider(String provider) {
    return ServiceModelRegistry.getChatModelsForProvider(provider);
  }

  /// 获取所有可用的提供商和模型
  static Map<String, List<String>> getAllProvidersAndModels() {
    return {
      for (final provider in supportedProviders)
        provider: getModelsForProvider(provider),
    };
  }
}
