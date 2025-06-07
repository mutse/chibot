import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  String _selectedProvider = 'OpenAI'; // 新增：默认提供商为 OpenAI
  String? _apiKey;
  String _selectedModel = 'gpt-4o'; // 默认模型
  String? _providerUrl; // 新增：模型 Provider URL
  List<String> _customModels = []; // 新增：自定义模型列表
  Map<String, List<String>> _customProviders = {}; // 新增：自定义提供商及其模型列表

  static const String _apiKeyKey = 'openai_api_key';
  static const String _selectedModelKey = 'openai_selected_model';
  static const String _providerUrlKey = 'openai_provider_url'; // 新增 Key
  static const String _customModelsKey = 'custom_models_list'; // 新增 Key for custom models
  static const String _selectedProviderKey = 'selected_model_provider'; // 新增 Key for provider
  static const String _customProvidersKey = 'custom_providers_map'; // 新增 Key for custom providers

  // 默认的各提供商 API 基础 URL
  static const Map<String, String> defaultBaseUrls = {
    'OpenAI': 'https://api.openai.com/v1',
    'Google': 'https://generativelanguage.googleapis.com/v1beta', // Gemini API 基础 URL
  };

  // 可选模型列表
  final List<String> _presetModels = [
    'gpt-4',
    'gpt-4o',
    'gpt-4.1',
    'gemini-2.0-flash', // 更新为实际存在的 Gemini 模型
    'gemini-2.5-pro-preview-06-05',
    'gemini-2.5-flash-preview-05-20',
    // 你可以根据需要添加更多模型
  ];

  // 分类预设模型
  final Map<String, List<String>> _categorizedPresetModels = {
    'OpenAI': [
      'gpt-4',
      'gpt-4o',
      'gpt-4.1',
    ],
    'Google': [
      'gemini-2.0-flash',
      'gemini-2.5-pro-preview-06-05',
      'gemini-2.5-flash-preview-05-20',
    ],
  };

  // Getter for all provider names (preset and custom)
  List<String> get allProviderNames {
    final names = defaultBaseUrls.keys.toList();
    names.addAll(_customProviders.keys);
    return List.unmodifiable(names.toSet().toList()); // Remove duplicates and make unmodifiable
  }

  SettingsProvider() {
    _loadSettings();
  }

  String? get apiKey => _apiKey;
  String get selectedModel => _selectedModel;
  String get selectedProvider => _selectedProvider;

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
    return List.unmodifiable(modelsToShow.toSet().toList()); // toSet().toList() to remove duplicates and make unmodifiable
  }

  List<String> get customModels => List.unmodifiable(_customModels);

  // 获取 Provider URL，优先使用用户设置的URL，否则返回当前选定提供商的默认URL
  String get providerUrl {
    // 确保返回的 URL 后面没有 /chat/completions 或其他特定路径后缀，因为 Service 层会拼接
    String baseUrl = _providerUrl?.trim() ?? defaultBaseUrls[_selectedProvider] ?? defaultBaseUrls['OpenAI']!;
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
    _selectedProvider = prefs.getString(_selectedProviderKey) ?? 'OpenAI'; // 加载 Provider
    notifyListeners();
    // Ensure the selected model is valid for the loaded provider
    _validateSelectedModelForProvider();
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
      if (_selectedProvider == 'OpenAI' && (_categorizedPresetModels['OpenAI']?.isNotEmpty ?? false)) {
        _selectedModel = _categorizedPresetModels['OpenAI']!.first;
      } else if (_selectedProvider == 'Google' && (_categorizedPresetModels['Google']?.isNotEmpty ?? false)) {
        _selectedModel = _categorizedPresetModels['Google']!.first;
      } else if (_customProviders.containsKey(_selectedProvider) && (_customProviders[_selectedProvider]?.isNotEmpty ?? false)) {
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

  Future<void> setApiKey(String newApiKey) async {
    _apiKey = newApiKey;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyKey, newApiKey);
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
    _providerUrl = (newUrl == null || newUrl.trim().isEmpty) ? null : newUrl.trim();
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
    if (modelName.trim().isEmpty || _customModels.contains(modelName.trim()) || _presetModels.contains(modelName.trim())) {
      return; // 不添加空名称、重复名称或与预设模型冲突的名称
    }
    _customModels.add(modelName.trim());
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_customModelsKey, _customModels);
    notifyListeners();
    // Ensure the selected model is valid for the loaded provider
    _validateSelectedModelForProvider();
  }

  Future<void> addCustomProviderWithModels(String providerName, List<String> models) async {
    if (providerName.trim().isEmpty || models.isEmpty) return;
    // Prevent overwriting preset providers
    if (defaultBaseUrls.containsKey(providerName.trim())) return;

    _customProviders[providerName.trim()] = models.map((m) => m.trim()).where((m) => m.isNotEmpty).toList();
    final prefs = await SharedPreferences.getInstance();
    // This needs a robust way to serialize the map, e.g., to a JSON string.
    // Placeholder for actual serialization:
    // await prefs.setString(_customProvidersKey, json.encode(_customProviders));
    notifyListeners();
    // Optionally, switch to the new provider and select its first model
    // setSelectedProvider(providerName.trim());
  }

  Future<void> removeCustomModel(String modelName) async {
    if (_customModels.remove(modelName)) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_customModelsKey, _customModels);
      // 如果移除的是当前选中的模型，则重置为当前提供商的默认模型
      if (_selectedModel == modelName) {
        _validateSelectedModelForProvider(); // This will set a default if needed
      }
      notifyListeners();
    }
  }
}
