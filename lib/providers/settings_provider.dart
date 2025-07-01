import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/settings_screen.dart'; // Import ModelType enum

class SettingsProvider with ChangeNotifier {
  String _selectedProvider = 'OpenAI'; // 新增：默认提供商为 OpenAI
  String? _apiKey;
  String? _imageApiKey; // Added for image API key
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
  static const String _imageApiKeyKey =
      'image_api_key'; // Added for image API key
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

  // 默认的各提供商 API 基础 URL
  static const Map<String, String> defaultBaseUrls = {
    'OpenAI': 'https://api.openai.com/v1',
    'Google':
        'https://generativelanguage.googleapis.com/v1beta', // Gemini API 基础 URL
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
  String? get tavilyApiKey => _tavilyApiKey;

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
    _tavilyApiKey = prefs.getString(_tavilyApiKeyKey); // Load Tavily API key
    _selectedModel = prefs.getString(_selectedModelKey) ?? 'gpt-4o';
    _providerUrl = prefs.getString(_providerUrlKey); // 加载 Provider URL
    _customModels = prefs.getStringList(_customModelsKey) ?? []; // 加载自定义模型
    final String? customProvidersString = prefs.getString(_customProvidersKey);
    if (customProvidersString != null) {
      try {
        // Assuming customProvidersString is a JSON string like '{"providerName":["model1","model2"]}'
        // This part needs careful implementation for deserialization, e.g., using dart:convert
        // For simplicity, this example might need a more robust JSON parsing strategy.
        // Placeholder for actual deserialization:
        // _customProviders = Map<String, List<String>>.from(json.decode(customProvidersString));
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
    _selectedImageModel = prefs.getString(_selectedModelKey) ?? 'dall-e-3';
    _imageProviderUrl = prefs.getString(_imageProviderUrlKey);
    _customImageModels = prefs.getStringList(_customImageModelsKey) ?? [];
    final String? customImageProvidersString = prefs.getString(
      _customImageProvidersKey,
    );
    if (customImageProvidersString != null) {
      try {
        // _customImageProviders = Map<String, List<String>>.from(json.decode(customImageProvidersString));
      } catch (e) {
        if (kDebugMode) {
          print('Error loading custom image providers: $e');
        }
        _customImageProviders = {};
      }
    }

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
      } else if (_customProviders.containsKey(_selectedProvider) &&
          (_customProviders[_selectedProvider]?.isNotEmpty ?? false)) {
        _selectedModel = _customProviders[_selectedProvider]!.first;
      } else if (currentAvailableModels.isNotEmpty) {
        _selectedModel = currentAvailableModels.first;
      } else {
        _selectedModel = ''; // No models available
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
    await SharedPreferences.getInstance();
    // await prefs.setString(_customImageProvidersKey, json.encode(_customImageProviders)); // Needs robust serialization
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
    await SharedPreferences.getInstance();
    // This needs a robust way to serialize the map, e.g., to a JSON string.
    // Placeholder for actual serialization:
    // await prefs.setString(_customProvidersKey, json.encode(_customProviders));
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
}
