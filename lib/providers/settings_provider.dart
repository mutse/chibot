import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chibot/screens/settings_screen.dart'; // Import ModelType enum
import 'package:chibot/utils/settings_xml_handler.dart';
import 'dart:convert';

class SettingsProvider with ChangeNotifier {
  String _selectedProvider = 'OpenAI'; // 新增：默认提供商为 OpenAI
  String? _apiKey;
  String? _imageApiKey; // Added for image API key
  String? _claudeApiKey; // Added for Claude API key
  String _selectedModel = 'gpt-4o'; // 默认模型
  String? _providerUrl; // 新增：模型 Provider URL
  List<String> _customModels = []; // 新增：自定义模型列表
  Map<String, List<String>> _customProviders = {}; // 新增：自定义提供商及其模型列表

  // Image Generation Settings
  String _selectedImageProvider = 'OpenAI'; // Default image provider
  String _selectedImageModel = 'dall-e-3'; // Default image model
  String? _imageProviderUrl; // URL for the image generation provider
  List<String> _customImageModels = [];
  Map<String, List<String>> _customImageProviders =
      {}; // Added to force recompile

  ModelType _selectedModelType = ModelType.text; // Default to text model type

  static const String _apiKeyKey = 'openai_api_key';
  static const String _imageApiKeyKey = 'image_api_key'; // Added for image API key
  static const String _claudeApiKeyKey = 'claude_api_key'; // Added for Claude API key
  static const String _selectedModelKey = 'openai_selected_model';
  static const String _providerUrlKey = 'openai_provider_url';
  static const String _customModelsKey = 'custom_models_list';
  static const String _selectedProviderKey = 'selected_model_provider';
  static const String _customProvidersKey = 'custom_providers_map';
  static const String _selectedModelTypeKey = 'selected_model_type';

  // Keys for Image Generation Settings
  static const String _selectedImageProviderKey = 'selected_image_provider';
  static const String _selectedImageModelKey = 'selected_image_model';
  static const String _imageProviderUrlKey = 'image_provider_url';
  static const String _customImageModelsKey = 'custom_image_models_list';
  static const String _customImageProvidersKey = 'custom_image_providers_map';

  String? _tavilyApiKey;
  static const String _tavilyApiKeyKey = 'tavily_api_key';

  // Google Search Settings
  String? _googleSearchApiKey;
  String? _googleSearchEngineId;
  bool _googleSearchEnabled = false;
  int _googleSearchResultCount = 10;
  String _googleSearchProvider = 'googleCustomSearch';

  static const String _googleSearchApiKeyKey = 'google_search_api_key';
  static const String _googleSearchEngineIdKey = 'google_search_engine_id';
  static const String _googleSearchEnabledKey = 'google_search_enabled';
  static const String _googleSearchResultCountKey = 'google_search_result_count';
  static const String _googleSearchProviderKey = 'google_search_provider';

  bool _tavilySearchEnabled = false;
  static const String _tavilySearchEnabledKey = 'tavily_search_enabled';

  // 默认的各提供商 API 基础 URL
  static const Map<String, String> defaultBaseUrls = {
    'OpenAI': 'https://api.openai.com/v1',
    'Google': 'https://generativelanguage.googleapis.com/v1beta', // Gemini API 基础 URL
    'Anthropic': 'https://api.anthropic.com/v1', // Claude API 基础 URL
  };

  // Default base URLs for image generation providers
  static const Map<String, String> defaultImageBaseUrls = {
    'OpenAI': 'https://api.openai.com/v1',
    'Stability AI':
        'https://api.stability.ai', // Example, confirm actual base URL
  };

  // 可选模型列表
  final List<String> _presetModels = [
    'gpt-4',
    'gpt-4o',
    'gpt-4.1',
    'gemini-2.0-flash',
    'gemini-2.5-pro-preview-06-05',
    'gemini-2.5-flash-preview-05-20',
  ];

  // 分类预设模型
  final Map<String, List<String>> _categorizedPresetModels = {
    'OpenAI': ['gpt-4', 'gpt-4o', 'gpt-4.1'],
    'Google': [
      'gemini-2.0-flash',
      'gemini-2.5-pro-preview-06-05',
      'gemini-2.5-flash-preview-05-20',
    ],
    'Anthropic': [
      'claude-3-5-sonnet-20241022',
      'claude-3-5-haiku-20241022',
      'claude-3-opus-20240229',
      'claude-3-sonnet-20240229',
      'claude-3-haiku-20240307',
    ],
  };

  // Preset models for image generation
  final Map<String, List<String>> _categorizedPresetImageModels = {
    'OpenAI': ['dall-e-3', 'dall-e-2'],
    'Stability AI': [
      'stable-diffusion-xl-1024-v1-0', // Example model ID
      'stable-diffusion-v1-6', // Example model ID
      // Add other Stability AI models as needed
    ],
  };

  // Getter for all provider names (preset and custom)
  List<String> get allProviderNames {
    final names = defaultBaseUrls.keys.toList();
    names.addAll(_customProviders.keys);
    return List.unmodifiable(
      names.toSet().toList(),
    ); // Remove duplicates and make unmodifiable
  }

  SettingsProvider() {
    _loadSettings();
  }

  String? get apiKey => _apiKey;
  String get selectedModel => _selectedModel;
  String get selectedProvider => _selectedProvider;
  String? get imageApiKey => _imageApiKey; // Added getter for image API key
  String? get claudeApiKey => _claudeApiKey; // Added getter for Claude API key
  String? get tavilyApiKey => _tavilyApiKey;
  String? get googleSearchApiKey => _googleSearchApiKey;
  String? get googleSearchEngineId => _googleSearchEngineId;
  bool get googleSearchEnabled => _googleSearchEnabled;
  int get googleSearchResultCount => _googleSearchResultCount;
  String get googleSearchProvider => _googleSearchProvider;
  bool get tavilySearchEnabled => _tavilySearchEnabled;

  // Getters for Image Generation Settings
  String get selectedImageProvider => _selectedImageProvider;
  String get selectedImageModel => _selectedImageModel;
  ModelType get selectedModelType => _selectedModelType;

  List<String> get availableImageModels {
    List<String> modelsToShow = [];
    if (_categorizedPresetImageModels.containsKey(_selectedImageProvider)) {
      modelsToShow.addAll(
        _categorizedPresetImageModels[_selectedImageProvider] ?? [],
      );
    } else if (_customImageProviders.containsKey(_selectedImageProvider)) {
      modelsToShow.addAll(_customImageProviders[_selectedImageProvider] ?? []);
    }
    modelsToShow.addAll(_customImageModels);
    return List.unmodifiable(modelsToShow.toSet().toList());
  }

  List<String> get allImageProviderNames {
    final names = defaultImageBaseUrls.keys.toList();
    names.addAll(_customImageProviders.keys);
    return List.unmodifiable(names.toSet().toList());
  }

  String get imageProviderUrl {
    String baseUrl =
        _imageProviderUrl?.trim() ??
        defaultImageBaseUrls[_selectedImageProvider] ??
        defaultImageBaseUrls['OpenAI']!;
    if (baseUrl.endsWith('/')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 1);
    }
    return baseUrl;
  }

  String? get rawImageProviderUrl => _imageProviderUrl;

  List<String> get availableModels {
    List<String> modelsToShow = [];
    if (_selectedProvider == 'OpenAI') {
      modelsToShow.addAll(_categorizedPresetModels['OpenAI'] ?? []);
    } else if (_selectedProvider == 'Google') {
      modelsToShow.addAll(_categorizedPresetModels['Google'] ?? []);
    } else if (_selectedProvider == 'Anthropic') {
      modelsToShow.addAll(_categorizedPresetModels['Anthropic'] ?? []);
    } else if (_customProviders.containsKey(_selectedProvider)) {
      // Handle custom provider
      modelsToShow.addAll(_customProviders[_selectedProvider] ?? []);
    }
    // Add general custom models that might not be tied to a specific custom provider
    // but could be used with preset providers if named correctly.
    modelsToShow.addAll(_customModels);
    return List.unmodifiable(
      modelsToShow.toSet().toList(),
    ); // toSet().toList() to remove duplicates and make unmodifiable
  }

  List<String> get customModels => List.unmodifiable(_customModels);
  List<String> get customImageModels => List.unmodifiable(_customImageModels);

  // 获取 Provider URL，优先使用用户设置的URL，否则返回当前选定提供商的默认URL
  String get providerUrl {
    // 确保返回的 URL 后面没有 /chat/completions 或其他特定路径后缀，因为 Service 层会拼接
    String baseUrl =
        _providerUrl?.trim() ??
        defaultBaseUrls[_selectedProvider] ??
        defaultBaseUrls['OpenAI']!;
    if (baseUrl.endsWith('/')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 1);
    }
    return baseUrl;
  }

  // 返回给UI显示的原始Provider URL，可能是空的
  String? get rawProviderUrl => _providerUrl;

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _apiKey = prefs.getString(_apiKeyKey);
    _imageApiKey = prefs.getString(_imageApiKeyKey); // Load image API key
    _claudeApiKey = prefs.getString(_claudeApiKeyKey); // Load Claude API key
    _tavilyApiKey = prefs.getString(_tavilyApiKeyKey); // Load Tavily API key
    _googleSearchApiKey = prefs.getString(_googleSearchApiKeyKey);
    _googleSearchEngineId = prefs.getString(_googleSearchEngineIdKey);
    _googleSearchEnabled = prefs.getBool(_googleSearchEnabledKey) ?? false;
    _googleSearchResultCount = prefs.getInt(_googleSearchResultCountKey) ?? 10;
    _googleSearchProvider = prefs.getString(_googleSearchProviderKey) ?? 'googleCustomSearch';
    _selectedModel = prefs.getString(_selectedModelKey) ?? 'gpt-4o';
    _providerUrl = prefs.getString(_providerUrlKey); // 加载 Provider URL
    _customModels = prefs.getStringList(_customModelsKey) ?? []; // 加载自定义模型
    final String? customProvidersString = prefs.getString(_customProvidersKey);
    if (customProvidersString != null) {
      try {
        // Deserialize custom providers from JSON
        _customProviders = Map<String, List<String>>.from(
          json.decode(customProvidersString).map(
            (key, value) => MapEntry(key, List<String>.from(value)),
          ),
        );
      } catch (e) {
        if (kDebugMode) {
          print('Error loading custom providers: $e');
        }
        _customProviders = {}; // Reset on error
      }
    }
    _selectedProvider =
        prefs.getString(_selectedProviderKey) ?? 'OpenAI'; // 加载 Provider
    _selectedModelType =
        ModelType.values[prefs.getInt(_selectedModelTypeKey) ??
            ModelType.text.index];

    // Load Image Generation Settings
    _selectedImageProvider =
        prefs.getString(_selectedImageProviderKey) ?? 'OpenAI';
    _selectedImageModel = prefs.getString(_selectedImageModelKey) ?? 'dall-e-3';
    _imageProviderUrl = prefs.getString(_imageProviderUrlKey);
    _customImageModels = prefs.getStringList(_customImageModelsKey) ?? [];
    final String? customImageProvidersString = prefs.getString(
      _customImageProvidersKey,
    );
    if (customImageProvidersString != null) {
      try {
        _customImageProviders = Map<String, List<String>>.from(
          json.decode(customImageProvidersString).map(
            (key, value) => MapEntry(key, List<String>.from(value)),
          ),
        );
      } catch (e) {
        if (kDebugMode) {
          print('Error loading custom image providers: $e');
        }
        _customImageProviders = {};
      }
    }

    _tavilySearchEnabled = prefs.getBool(_tavilySearchEnabledKey) ?? false;

    notifyListeners();
    // Ensure the selected model is valid for the loaded provider
    _validateSelectedModelForProvider();
    _validateSelectedImageModelForProvider();
  }

  Future<void> setSelectedProvider(String newProvider) async {
    if (_selectedProvider != newProvider) {
      _selectedProvider = newProvider;
      // If it's a known preset provider, set its default URL.
      // For custom providers, the URL might be set differently or not at all by default.
      if (defaultBaseUrls.containsKey(newProvider)) {
        _providerUrl = defaultBaseUrls[newProvider];
      } else {
        // For custom providers, we might clear the URL or handle it based on specific logic.
        // For now, let's clear it, assuming custom providers will have their URLs set manually.
        _providerUrl = null;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_selectedProviderKey, newProvider);
      if (_providerUrl != null) {
        await prefs.setString(_providerUrlKey, _providerUrl!);
      } else {
        // 如果 defaultBaseUrls[newProvider] 返回 null（理论上不应发生），则移除旧的 key
        await prefs.remove(_providerUrlKey);
      }

      // _validateSelectedModelForProvider 会为新的提供商设置默认模型，并处理其持久化
      _validateSelectedModelForProvider();
      notifyListeners();
    }
  }

  void _validateSelectedModelForProvider() {
    final currentAvailableModels = availableModels;
    if (!currentAvailableModels.contains(_selectedModel)) {
      if (_selectedProvider == 'OpenAI' &&
          (_categorizedPresetModels['OpenAI']?.isNotEmpty ?? false)) {
        _selectedModel = _categorizedPresetModels['OpenAI']!.first;
      } else if (_selectedProvider == 'Google' &&
          (_categorizedPresetModels['Google']?.isNotEmpty ?? false)) {
        _selectedModel = _categorizedPresetModels['Google']!.first;
      } else if (_selectedProvider == 'Anthropic' &&
          (_categorizedPresetModels['Anthropic']?.isNotEmpty ?? false)) {
        _selectedModel = _categorizedPresetModels['Anthropic']!.first;
      } else if (_customProviders.containsKey(_selectedProvider) &&
          (_customProviders[_selectedProvider]?.isNotEmpty ?? false)) {
        _selectedModel = _customProviders[_selectedProvider]!.first;
      } else if (currentAvailableModels.isNotEmpty) {
        _selectedModel = currentAvailableModels.first;
      } else {
        _selectedModel = ''; // No models available
      }
      if (kDebugMode) {
        print('Model validation changed selectedModel to: $_selectedModel');
      }
      // 异步保存更改后的 selectedModel
      SharedPreferences.getInstance().then((prefs) {
        prefs.setString(_selectedModelKey, _selectedModel);
      });
    }
  }

  Future<void> setApiKey(String? apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    _apiKey = apiKey;
    if (apiKey == null || apiKey.isEmpty) {
      await prefs.remove(_apiKeyKey);
    } else {
      await prefs.setString(_apiKeyKey, apiKey);
    }
    notifyListeners();
  }

  Future<void> setImageApiKey(String? apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    _imageApiKey = apiKey;
    if (apiKey == null || apiKey.isEmpty) {
      await prefs.remove(_imageApiKeyKey);
    } else {
      await prefs.setString(_imageApiKeyKey, apiKey);
    }
    notifyListeners();
  }

  Future<void> setClaudeApiKey(String? apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    _claudeApiKey = apiKey;
    if (apiKey == null || apiKey.isEmpty) {
      await prefs.remove(_claudeApiKeyKey);
    } else {
      await prefs.setString(_claudeApiKeyKey, apiKey);
    }
    notifyListeners();
  }

  void setTavilyApiKey(String? key) {
    _tavilyApiKey = key;
    SharedPreferences.getInstance().then((prefs) {
      if (key == null || key.isEmpty) {
        prefs.remove(_tavilyApiKeyKey);
      } else {
        prefs.setString(_tavilyApiKeyKey, key);
      }
    });
    notifyListeners();
  }

  Future<void> setTavilySearchEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    _tavilySearchEnabled = enabled;
    await prefs.setBool(_tavilySearchEnabledKey, enabled);
    notifyListeners();
  }

  // Methods for Image Generation Settings
  Future<void> setSelectedImageProvider(String newProvider) async {
    if (_selectedImageProvider != newProvider) {
      _selectedImageProvider = newProvider;
      if (defaultImageBaseUrls.containsKey(newProvider)) {
        _imageProviderUrl = defaultImageBaseUrls[newProvider];
      } else {
        _imageProviderUrl = null;
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_selectedImageProviderKey, newProvider);
      if (_imageProviderUrl != null) {
        await prefs.setString(_imageProviderUrlKey, _imageProviderUrl!);
      } else {
        await prefs.remove(_imageProviderUrlKey);
      }
      _validateSelectedImageModelForProvider();
      notifyListeners();
    }
  }

  void _validateSelectedImageModelForProvider() {
    final currentAvailableImageModels = availableImageModels;
    if (!currentAvailableImageModels.contains(_selectedImageModel)) {
      if (_categorizedPresetImageModels.containsKey(_selectedImageProvider) &&
          (_categorizedPresetImageModels[_selectedImageProvider]?.isNotEmpty ??
              false)) {
        _selectedImageModel =
            _categorizedPresetImageModels[_selectedImageProvider]!.first;
      } else if (_customImageProviders.containsKey(_selectedImageProvider) &&
          (_customImageProviders[_selectedImageProvider]?.isNotEmpty ??
              false)) {
        _selectedImageModel =
            _customImageProviders[_selectedImageProvider]!.first;
      } else if (currentAvailableImageModels.isNotEmpty) {
        _selectedImageModel = currentAvailableImageModels.first;
      } else {
        _selectedImageModel = ''; // No models available
      }
      SharedPreferences.getInstance().then((prefs) {
        prefs.setString(_selectedImageModelKey, _selectedImageModel);
      });
    }
  }

  Future<void> setSelectedImageModel(String newModel) async {
    if (availableImageModels.contains(newModel)) {
      _selectedImageModel = newModel;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_selectedImageModelKey, newModel);
      notifyListeners();
    }
  }

  Future<void> setSelectedModelType(ModelType newType) async {
    if (_selectedModelType != newType) {
      _selectedModelType = newType;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_selectedModelTypeKey, newType.index);
      notifyListeners();
    }
  }

  Future<void> setImageProviderUrl(String? newUrl) async {
    _imageProviderUrl =
        (newUrl == null || newUrl.trim().isEmpty) ? null : newUrl.trim();
    final prefs = await SharedPreferences.getInstance();
    if (_imageProviderUrl == null) {
      await prefs.remove(_imageProviderUrlKey);
    } else {
      await prefs.setString(_imageProviderUrlKey, _imageProviderUrl!);
    }
    notifyListeners();
    _validateSelectedImageModelForProvider();
  }

  Future<void> addCustomImageModel(String modelName) async {
    if (modelName.trim().isEmpty ||
        _customImageModels.contains(modelName.trim()) ||
        (_categorizedPresetImageModels.values
            .expand((x) => x)
            .contains(modelName.trim()))) {
      return;
    }
    _customImageModels.add(modelName.trim());
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_customImageModelsKey, _customImageModels);
    notifyListeners();
    _validateSelectedImageModelForProvider();
  }

  Future<void> removeCustomImageModel(String modelName) async {
    if (_customImageModels.remove(modelName)) {
      await SharedPreferences.getInstance().then(
        (prefs) =>
            prefs.setStringList(_customImageModelsKey, _customImageModels),
      );
      if (_selectedImageModel == modelName) {
        _validateSelectedImageModelForProvider();
      }
      notifyListeners();
    }
  }

  Future<void> addCustomImageProviderWithModels(
    String providerName,
    List<String> models,
  ) async {
    if (providerName.trim().isEmpty || models.isEmpty) return;
    if (defaultImageBaseUrls.containsKey(providerName.trim())) return;

    _customImageProviders[providerName.trim()] =
        models.map((m) => m.trim()).where((m) => m.isNotEmpty).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_customImageProvidersKey, json.encode(_customImageProviders));
    notifyListeners();
  }

  Future<void> addCustomTextModel(String modelName) async {
    if (modelName.trim().isEmpty ||
        _customModels.contains(modelName.trim()) ||
        _presetModels.contains(modelName.trim())) {
      return; // 不添加空名称、重复名称或与预设模型冲突的名称
    }
    _customModels.add(modelName.trim());
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_customModelsKey, _customModels);
    notifyListeners();
    // Ensure the selected model is valid for the loaded provider
    _validateSelectedModelForProvider();
  }

  Future<void> setSelectedModel(String newModel) async {
    // 检查模型是否在当前可用模型列表中
    if (availableModels.contains(newModel)) {
      _selectedModel = newModel;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_selectedModelKey, newModel);
      notifyListeners();
    }
  }

  Future<void> setProviderUrl(String? newUrl) async {
    _providerUrl =
        (newUrl == null || newUrl.trim().isEmpty) ? null : newUrl.trim();
    final prefs = await SharedPreferences.getInstance();
    if (_providerUrl == null) {
      await prefs.remove(_providerUrlKey);
    } else {
      await prefs.setString(_providerUrlKey, _providerUrl!);
    }
    notifyListeners();
    // Ensure the selected model is valid for the loaded provider
    _validateSelectedModelForProvider();
  }

  Future<void> addCustomModel(String modelName) async {
    if (modelName.trim().isEmpty ||
        _customModels.contains(modelName.trim()) ||
        _presetModels.contains(modelName.trim())) {
      return; // 不添加空名称、重复名称或与预设模型冲突的名称
    }
    _customModels.add(modelName.trim());
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_customModelsKey, _customModels);
    notifyListeners();
    // Ensure the selected model is valid for the loaded provider
    _validateSelectedModelForProvider();
  }

  Future<void> addCustomProviderWithModels(
    String providerName,
    List<String> models,
  ) async {
    if (providerName.trim().isEmpty || models.isEmpty) return;
    // Prevent overwriting preset providers
    if (defaultBaseUrls.containsKey(providerName.trim())) return;

    _customProviders[providerName.trim()] =
        models.map((m) => m.trim()).where((m) => m.isNotEmpty).toList();
    final prefs = await SharedPreferences.getInstance();
    // Serialize the custom providers map to JSON
    await prefs.setString(_customProvidersKey, json.encode(_customProviders));
    notifyListeners();
    // Optionally, switch to the new provider and select its first model
    // setSelectedProvider(providerName.trim());
  }

  Future<void> removeCustomModel(String modelName) async {
    if (_customModels.remove(modelName)) {
      await SharedPreferences.getInstance().then(
        (prefs) => prefs.setStringList(_customModelsKey, _customModels),
      );
      // 如果移除的是当前选中的模型，则重置为当前提供商的默认模型
      if (_selectedModel == modelName) {
        _validateSelectedModelForProvider(); // This will set a default if needed
      }
      notifyListeners();
    }
  }

  // Google Search Settings Methods
  Future<void> setGoogleSearchApiKey(String? apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    _googleSearchApiKey = apiKey;
    if (apiKey == null || apiKey.isEmpty) {
      await prefs.remove(_googleSearchApiKeyKey);
    } else {
      await prefs.setString(_googleSearchApiKeyKey, apiKey);
    }
    notifyListeners();
  }

  Future<void> setGoogleSearchEngineId(String? engineId) async {
    final prefs = await SharedPreferences.getInstance();
    _googleSearchEngineId = engineId;
    if (engineId == null || engineId.isEmpty) {
      await prefs.remove(_googleSearchEngineIdKey);
    } else {
      await prefs.setString(_googleSearchEngineIdKey, engineId);
    }
    notifyListeners();
  }

  Future<void> setGoogleSearchEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    _googleSearchEnabled = enabled;
    await prefs.setBool(_googleSearchEnabledKey, enabled);
    notifyListeners();
  }

  Future<void> setGoogleSearchResultCount(int count) async {
    final prefs = await SharedPreferences.getInstance();
    _googleSearchResultCount = count.clamp(1, 20);
    await prefs.setInt(_googleSearchResultCountKey, _googleSearchResultCount);
    notifyListeners();
  }

  Future<void> setGoogleSearchProvider(String provider) async {
    final prefs = await SharedPreferences.getInstance();
    _googleSearchProvider = provider;
    await prefs.setString(_googleSearchProviderKey, provider);
    notifyListeners();
  }

  // Export settings to XML
  Future<String> exportSettingsToXml() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsMap = <String, dynamic>{};
      
      // Get all settings from SharedPreferences
      settingsMap[_apiKeyKey] = prefs.getString(_apiKeyKey);
      settingsMap[_imageApiKeyKey] = prefs.getString(_imageApiKeyKey);
      settingsMap[_claudeApiKeyKey] = prefs.getString(_claudeApiKeyKey);
      settingsMap[_tavilyApiKeyKey] = prefs.getString(_tavilyApiKeyKey);
      settingsMap[_googleSearchApiKeyKey] = prefs.getString(_googleSearchApiKeyKey); // Google Search API Key
      settingsMap[_googleSearchEngineIdKey] = prefs.getString(_googleSearchEngineIdKey); // Google Search Engine ID
      settingsMap[_googleSearchEnabledKey] = prefs.getBool(_googleSearchEnabledKey);
      settingsMap[_googleSearchResultCountKey] = prefs.getInt(_googleSearchResultCountKey);
      settingsMap[_googleSearchProviderKey] = prefs.getString(_googleSearchProviderKey);
      settingsMap[_tavilySearchEnabledKey] = prefs.getBool(_tavilySearchEnabledKey);
      settingsMap[_selectedModelKey] = prefs.getString(_selectedModelKey);
      settingsMap[_providerUrlKey] = prefs.getString(_providerUrlKey);
      settingsMap[_customModelsKey] = prefs.getStringList(_customModelsKey);
      settingsMap[_selectedProviderKey] = prefs.getString(_selectedProviderKey);
      settingsMap[_customProvidersKey] = prefs.getString(_customProvidersKey);
      settingsMap[_selectedModelTypeKey] = prefs.getInt(_selectedModelTypeKey);
      settingsMap[_selectedImageProviderKey] = prefs.getString(_selectedImageProviderKey);
      settingsMap[_selectedImageModelKey] = prefs.getString(_selectedImageModelKey);
      settingsMap[_imageProviderUrlKey] = prefs.getString(_imageProviderUrlKey);
      settingsMap[_customImageModelsKey] = prefs.getStringList(_customImageModelsKey);
      settingsMap[_customImageProvidersKey] = prefs.getString(_customImageProvidersKey);
      
      if (kDebugMode) {
        print('Settings map for export: $settingsMap');
      }
      
      return SettingsXmlHandler.exportToXml(settingsMap);
    } catch (e) {
      if (kDebugMode) {
        print('Error in exportSettingsToXml: $e');
      }
      throw Exception('Failed to export settings: $e');
    }
  }

  // Import settings from XML
  Future<void> importSettingsFromXml(String xmlContent) async {
    try {
      final settingsMap = SettingsXmlHandler.importFromXml(xmlContent);
      final prefs = await SharedPreferences.getInstance();
      
      // Clear existing settings first (optional, depends on requirements)
      // await _clearAllSettings(prefs);
      
      // Import API keys
      if (settingsMap[_apiKeyKey] != null) {
        await prefs.setString(_apiKeyKey, settingsMap[_apiKeyKey]);
        _apiKey = settingsMap[_apiKeyKey];
      }
      
      if (settingsMap[_imageApiKeyKey] != null) {
        await prefs.setString(_imageApiKeyKey, settingsMap[_imageApiKeyKey]);
        _imageApiKey = settingsMap[_imageApiKeyKey];
      }
      
      if (settingsMap[_claudeApiKeyKey] != null) {
        await prefs.setString(_claudeApiKeyKey, settingsMap[_claudeApiKeyKey]);
        _claudeApiKey = settingsMap[_claudeApiKeyKey];
      }
      
      if (settingsMap[_tavilyApiKeyKey] != null) {
        await prefs.setString(_tavilyApiKeyKey, settingsMap[_tavilyApiKeyKey]);
        _tavilyApiKey = settingsMap[_tavilyApiKeyKey];
      }
      // Google Search API Key（解密后存储）
      if (settingsMap[_googleSearchApiKeyKey] != null) {
        await prefs.setString(_googleSearchApiKeyKey, settingsMap[_googleSearchApiKeyKey]);
        _googleSearchApiKey = settingsMap[_googleSearchApiKeyKey];
      }
      // Google Search Engine ID
      if (settingsMap[_googleSearchEngineIdKey] != null) {
        await prefs.setString(_googleSearchEngineIdKey, settingsMap[_googleSearchEngineIdKey]);
        _googleSearchEngineId = settingsMap[_googleSearchEngineIdKey];
      }
      
      if (settingsMap[_googleSearchEnabledKey] != null) {
        await prefs.setBool(_googleSearchEnabledKey, settingsMap[_googleSearchEnabledKey]);
        _googleSearchEnabled = settingsMap[_googleSearchEnabledKey];
      }
      
      if (settingsMap[_googleSearchResultCountKey] != null) {
        await prefs.setInt(_googleSearchResultCountKey, settingsMap[_googleSearchResultCountKey]);
        _googleSearchResultCount = settingsMap[_googleSearchResultCountKey];
      }
      
      if (settingsMap[_googleSearchProviderKey] != null) {
        await prefs.setString(_googleSearchProviderKey, settingsMap[_googleSearchProviderKey]);
        _googleSearchProvider = settingsMap[_googleSearchProviderKey];
      }
      
      if (settingsMap[_tavilySearchEnabledKey] != null) {
        await prefs.setBool(_tavilySearchEnabledKey, settingsMap[_tavilySearchEnabledKey]);
        _tavilySearchEnabled = settingsMap[_tavilySearchEnabledKey];
      }
      
      // Import model settings
      if (settingsMap[_selectedModelKey] != null) {
        await prefs.setString(_selectedModelKey, settingsMap[_selectedModelKey]);
        _selectedModel = settingsMap[_selectedModelKey];
        if (kDebugMode) {
          print('Imported selectedModel: $_selectedModel');
        }
      }
      
      if (settingsMap[_providerUrlKey] != null) {
        await prefs.setString(_providerUrlKey, settingsMap[_providerUrlKey]);
        _providerUrl = settingsMap[_providerUrlKey];
      }
      
      if (settingsMap[_customModelsKey] != null) {
        await prefs.setStringList(_customModelsKey, settingsMap[_customModelsKey]);
        _customModels = settingsMap[_customModelsKey];
      }
      
      if (settingsMap[_selectedProviderKey] != null) {
        await prefs.setString(_selectedProviderKey, settingsMap[_selectedProviderKey]);
        _selectedProvider = settingsMap[_selectedProviderKey];
        if (kDebugMode) {
          print('Imported selectedProvider: $_selectedProvider');
        }
      }
      
      // Load custom providers first before validating models
      if (settingsMap[_customProvidersKey] != null) {
        await prefs.setString(_customProvidersKey, settingsMap[_customProvidersKey]);
        try {
          _customProviders = Map<String, List<String>>.from(json.decode(settingsMap[_customProvidersKey]));
        } catch (e) {
          if (kDebugMode) {
            print('Error parsing custom providers: $e');
          }
          _customProviders = {};
        }
      }
      
      // Special handling: If selected provider is custom but not in _customProviders, add it with the selected model
      if (!defaultBaseUrls.containsKey(_selectedProvider) && 
          !_customProviders.containsKey(_selectedProvider) &&
          _selectedModel.isNotEmpty) {
        // Create a custom provider with the selected model
        _customProviders[_selectedProvider] = [_selectedModel];
        // Save to preferences
        await prefs.setString(_customProvidersKey, json.encode(_customProviders));
        if (kDebugMode) {
          print('Created custom provider $_selectedProvider with model $_selectedModel');
        }
      }
      
      if (settingsMap[_selectedModelTypeKey] != null) {
        await prefs.setInt(_selectedModelTypeKey, settingsMap[_selectedModelTypeKey]);
        _selectedModelType = ModelType.values[settingsMap[_selectedModelTypeKey]];
      }
      
      // Import image settings
      if (settingsMap[_selectedImageProviderKey] != null) {
        await prefs.setString(_selectedImageProviderKey, settingsMap[_selectedImageProviderKey]);
        _selectedImageProvider = settingsMap[_selectedImageProviderKey];
      }
      
      if (settingsMap[_selectedImageModelKey] != null) {
        await prefs.setString(_selectedImageModelKey, settingsMap[_selectedImageModelKey]);
        _selectedImageModel = settingsMap[_selectedImageModelKey];
      }
      
      if (settingsMap[_imageProviderUrlKey] != null) {
        await prefs.setString(_imageProviderUrlKey, settingsMap[_imageProviderUrlKey]);
        _imageProviderUrl = settingsMap[_imageProviderUrlKey];
      }
      
      if (settingsMap[_customImageModelsKey] != null) {
        await prefs.setStringList(_customImageModelsKey, settingsMap[_customImageModelsKey]);
        _customImageModels = settingsMap[_customImageModelsKey];
      }
      
      if (settingsMap[_customImageProvidersKey] != null) {
        await prefs.setString(_customImageProvidersKey, settingsMap[_customImageProvidersKey]);
        try {
          _customImageProviders = Map<String, List<String>>.from(json.decode(settingsMap[_customImageProvidersKey]));
        } catch (e) {
          if (kDebugMode) {
            print('Error parsing custom image providers: $e');
          }
          _customImageProviders = {};
        }
      }
      
      // Now validate settings after all data is loaded
      _validateSelectedModelForProvider();
      _validateSelectedImageModelForProvider();
      
      notifyListeners();
      
      // Add a small delay to ensure UI updates properly
      await Future.delayed(const Duration(milliseconds: 100));
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error importing settings from XML: $e');
      }
      throw Exception('Failed to import settings: $e');
    }
  }

  // Helper method to clear all settings (optional)
  Future<void> _clearAllSettings(SharedPreferences prefs) async {
    await prefs.remove(_apiKeyKey);
    await prefs.remove(_imageApiKeyKey);
    await prefs.remove(_claudeApiKeyKey);
    await prefs.remove(_tavilyApiKeyKey);
    await prefs.remove(_googleSearchApiKeyKey);
    await prefs.remove(_googleSearchEngineIdKey);
    await prefs.remove(_googleSearchEnabledKey);
    await prefs.remove(_googleSearchResultCountKey);
    await prefs.remove(_googleSearchProviderKey);
    await prefs.remove(_tavilySearchEnabledKey);
    await prefs.remove(_selectedModelKey);
    await prefs.remove(_providerUrlKey);
    await prefs.remove(_customModelsKey);
    await prefs.remove(_selectedProviderKey);
    await prefs.remove(_customProvidersKey);
    await prefs.remove(_selectedModelTypeKey);
    await prefs.remove(_selectedImageProviderKey);
    await prefs.remove(_selectedImageModelKey);
    await prefs.remove(_imageProviderUrlKey);
    await prefs.remove(_customImageModelsKey);
    await prefs.remove(_customImageProvidersKey);
  }

  // Get the appropriate API key for the current provider
  String? getApiKeyForProvider(String provider) {
    switch (provider) {
      case 'OpenAI':
        return _apiKey;
      case 'Google':
        return _apiKey; // Using OpenAI key for now
      case 'Anthropic':
        return _claudeApiKey;
      default:
        return _apiKey;
    }
  }

  // Get effective provider URL (removing trailing slashes)
  String get effectiveProviderUrl {
    String baseUrl =
        _providerUrl?.trim() ??
        defaultBaseUrls[_selectedProvider] ??
        defaultBaseUrls['OpenAI']!;
    if (baseUrl.endsWith('/')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 1);
    }
    return baseUrl;
  }
}
