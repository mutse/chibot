import '../repositories/interfaces.dart';
import '../providers/chat_model_provider.dart';
import '../providers/api_key_provider.dart';
import 'chat_service_factory.dart';

/// 服务管理器 - 使用专职提供者创建和验证服务
///
/// 改进：
/// - 使用 ChatModelProvider 和 ApiKeyProvider 代替 SettingsProvider
/// - 提供验证和配置检查方法
/// - 支持多提供商配置
///
/// 使用示例：
/// ```dart
/// final manager = ServiceManager();
/// final service = manager.createChatService(
///   chatModel: chatModelProvider,
///   apiKeys: apiKeyProvider,
/// );
/// ```
class ServiceManager {
  /// 从专职提供者创建聊天服务
  ///
  /// 如果 API Key 未配置，会抛出异常
  static ChatService createChatService({
    required ChatModelProvider chatModel,
    required ApiKeyProvider apiKeys,
  }) {
    return ChatServiceFactory.createFromProviders(
      chatModel: chatModel,
      apiKeys: apiKeys,
    );
  }

  /// 检查特定提供商是否已配置
  ///
  /// 返回 true 如果 API Key 已配置且非空
  static bool isProviderConfigured({
    required ApiKeyProvider apiKeys,
    required String provider,
  }) {
    final apiKey = apiKeys.getApiKeyForProvider(provider);
    return apiKey != null && apiKey.isNotEmpty;
  }

  /// 获取所有已配置的提供商列表
  ///
  /// 示例：
  /// ```dart
  /// final available = ServiceManager.getAvailableProviders(apiKeys: apiKeys);
  /// // 结果: ['OpenAI', 'Google'] (如果仅这两个已配置)
  /// ```
  static List<String> getAvailableProviders({
    required ApiKeyProvider apiKeys,
  }) {
    return ChatServiceFactory.supportedProviders
        .where((provider) => isProviderConfigured(
          apiKeys: apiKeys,
          provider: provider,
        ))
        .toList();
  }

  /// 验证聊天模型提供商是否完整配置
  ///
  /// 检查项：
  /// 1. API Key 是否已设置
  /// 2. 提供商是否被支持
  /// 3. 模型是否可用
  static bool isChatConfigured({
    required ChatModelProvider chatModel,
    required ApiKeyProvider apiKeys,
  }) {
    final provider = chatModel.selectedProvider;
    final hasApiKey = isProviderConfigured(
      apiKeys: apiKeys,
      provider: provider,
    );
    final hasModel = chatModel.selectedModel.isNotEmpty;

    return hasApiKey && hasModel;
  }

  /// 获取当前选定提供商的所有可用模型
  ///
  /// 返回列表包含预设模型和自定义模型
  static List<String> getAvailableModels({
    required ChatModelProvider chatModel,
  }) {
    return chatModel.availableModels;
  }

  /// 验证并创建聊天服务（带更详细的错误信息）
  ///
  /// 返回服务或抛出描述性异常
  static ChatService createAndValidateChatService({
    required ChatModelProvider chatModel,
    required ApiKeyProvider apiKeys,
  }) {
    // 检查 API Key
    final provider = chatModel.selectedProvider;
    if (!isProviderConfigured(apiKeys: apiKeys, provider: provider)) {
      throw Exception(
        'API key not configured for $provider provider. '
        'Please configure it in settings.',
      );
    }

    // 检查模型
    if (chatModel.selectedModel.isEmpty) {
      throw Exception(
        'No model selected for $provider provider. '
        'Please select a model in settings.',
      );
    }

    // 创建服务
    return createChatService(
      chatModel: chatModel,
      apiKeys: apiKeys,
    );
  }
}