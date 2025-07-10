class AppConstants {
  // UI Constants
  static const double sidebarWidth = 260.0;
  static const double defaultPadding = 16.0;
  static const double messagePadding = 12.0;
  static const double borderRadius = 12.0;
  static const double iconSize = 24.0;

  // Timeouts
  static const Duration loadingTimeout = Duration(seconds: 30);
  static const Duration requestTimeout = Duration(seconds: 60);
  static const Duration typingIndicatorDelay = Duration(milliseconds: 500);

  // API Constants
  static const int maxRetries = 3;
  static const int maxImageGenerationRetries = 3;
  static const int maxMessagesInContext = 50;
  static const int maxMessageLength = 4000;

  // File paths
  static const String chatSessionsFile = 'chat_sessions.json';
  static const String imageSessionsFile = 'image_sessions.json';
  static const String settingsFile = 'app_settings.json';

  // API Base URLs
  static const String openAIBaseUrl = 'https://api.openai.com/v1';
  static const String geminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta';
  static const String claudeBaseUrl = 'https://api.anthropic.com/v1';
  static const String tavilyBaseUrl = 'https://api.tavily.com';
  static const String bingBaseUrl = 'https://api.bing.microsoft.com/v7.0';

  // Default Models
  static const String defaultTextModel = 'gpt-4o';
  static const String defaultImageModel = 'dall-e-3';
  static const String defaultProvider = 'OpenAI';

  // App Info
  static const String appName = 'Chi AI Chatbot';
  static const String appVersion = '0.1.2';
  static const String githubUrl = 'https://github.com/mutse/chibot';
}
