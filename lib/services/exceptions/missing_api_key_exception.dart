/// 自定义异常：缺少 API 密钥
/// 当试图创建聊天服务但所选提供商的 API 密钥未配置时抛出
class MissingApiKeyException implements Exception {
  final String provider;
  final List<String> availableProviders;

  MissingApiKeyException({
    required this.provider,
    required this.availableProviders,
  });

  /// 获取用户友好的错误信息
  String get userFriendlyMessage {
    if (availableProviders.isEmpty) {
      return 'No API keys configured. Please configure at least one provider in Settings:\n'
          '- OpenAI (GPT-5 / GPT-4.1)\n'
          '- Google (Gemini)\n'
          '- Anthropic (Claude)\n\n'
          'Tap the Settings icon to add your API keys.';
    }

    final available = availableProviders.join(', ');
    return 'API key not configured for $provider.\n\n'
        'Available providers: $available\n\n'
        'Go to Settings to:\n'
        '1. Add a key for $provider, or\n'
        '2. Switch to an available provider: $available';
  }

  @override
  String toString() => userFriendlyMessage;
}
