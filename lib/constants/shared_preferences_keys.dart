class SharedPreferencesKeys {
  // Settings Keys
  static const String selectedProvider = 'selected_model_provider';
  static const String selectedModel = 'openai_selected_model';
  static const String selectedModelType = 'selected_model_type';
  
  // API Keys
  static const String apiKey = 'openai_api_key';
  static const String imageApiKey = 'image_api_key';
  static const String claudeApiKey = 'claude_api_key';
  static const String tavilyApiKey = 'tavily_api_key';
  
  // Provider URLs
  static const String providerUrl = 'openai_provider_url';
  static const String imageProviderUrl = 'image_provider_url';
  
  // Custom Models and Providers
  static const String customModels = 'custom_models_list';
  static const String customProviders = 'custom_providers_map';
  static const String customImageModels = 'custom_image_models_list';
  static const String customImageProviders = 'custom_image_providers_map';
  
  // Image Settings
  static const String selectedImageProvider = 'selected_image_provider';
  static const String selectedImageModel = 'selected_image_model';
  
  // Session Storage
  static const String chatSessions = 'chat_sessions';
  static const String imageSessions = 'image_sessions';
  
  // App Settings
  static const String enableWebSearch = 'enable_web_search';
  static const String autoSaveSessions = 'auto_save_sessions';
  static const String maxSessionHistory = 'max_session_history';
}