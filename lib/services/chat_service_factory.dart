import '../repositories/interfaces.dart';
import 'openai_chat_service.dart';
import 'gemini_chat_service.dart';
import 'claude_chat_service.dart';

class ChatServiceFactory {
  static const String openAI = 'OpenAI';
  static const String gemini = 'Google';
  static const String claude = 'Anthropic';

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
