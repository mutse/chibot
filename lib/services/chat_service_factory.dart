import '../repositories/interfaces.dart';
import '../providers/chat_model_provider.dart';
import '../providers/api_key_provider.dart';
import 'openai_chat_service.dart';
import 'gemini_chat_service.dart';
import 'claude_chat_service.dart';
import 'exceptions/missing_api_key_exception.dart';

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
    final apiKey = apiKeys.getApiKeyForProvider(provider);
    final baseUrl = chatModel.providerUrl;

    if (apiKey == null || apiKey.isEmpty) {
      throw MissingApiKeyException(
        provider: provider,
        availableProviders: getConfiguredProviders(apiKeys),
      );
    }

    return create(
      provider: provider,
      apiKey: apiKey,
      baseUrl: baseUrl,
    );
  }

  /// 获取已配置 API Key 的提供商列表
  static List<String> getConfiguredProviders(ApiKeyProvider apiKeys) {
    final configured = <String>[];
    if (apiKeys.openaiApiKey != null && apiKeys.openaiApiKey!.isNotEmpty) {
      configured.add(openAI);
    }
    if (apiKeys.googleApiKey != null && apiKeys.googleApiKey!.isNotEmpty) {
      configured.add(gemini);
    }
    if (apiKeys.claudeApiKey != null && apiKeys.claudeApiKey!.isNotEmpty) {
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

  static List<String> getModelsForProvider(String provider) {
    switch (provider) {
      case openAI:
        return OpenAIService(apiKey: 'dummy').supportedModels;

      case gemini:
        return GeminiService(apiKey: 'dummy').supportedModels;

      case claude:
        return ClaudeService(apiKey: 'dummy').supportedModels;

      default:
        return [];
    }
  }
}
