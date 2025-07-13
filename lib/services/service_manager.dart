import '../repositories/interfaces.dart';
import '../providers/settings_provider.dart';
import 'chat_service_factory.dart';

class ServiceManager {
  static ChatService createChatService(SettingsProvider settings) {
    final provider = settings.selectedProvider;
    final apiKey = settings.getApiKeyForProvider(provider);
    final baseUrl = settings.effectiveProviderUrl;
    
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API key not configured for provider: $provider');
    }
    
    return ChatServiceFactory.create(
      provider: provider,
      apiKey: apiKey,
      baseUrl: baseUrl,
    );
  }
  
  static bool isProviderConfigured(SettingsProvider settings, String provider) {
    final apiKey = settings.getApiKeyForProvider(provider);
    return apiKey != null && apiKey.isNotEmpty;
  }
  
  static List<String> getAvailableProviders(SettingsProvider settings) {
    return ChatServiceFactory.supportedProviders
        .where((provider) => isProviderConfigured(settings, provider))
        .toList();
  }
}