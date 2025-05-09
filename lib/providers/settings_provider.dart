import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  String _selectedProvider = 'OpenAI'; // 新增：默认提供商为 OpenAI
  String? _apiKey;
  String _selectedModel = 'gpt-3.5-turbo'; // 默认模型
  String? _providerUrl; // 新增：模型 Provider URL
  List<String> _customModels = []; // 新增：自定义模型列表

  static const String _apiKeyKey = 'openai_api_key';
  static const String _selectedModelKey = 'openai_selected_model';
  static const String _providerUrlKey = 'openai_provider_url'; // 新增 Key
  static const String _customModelsKey = 'custom_models_list'; // 新增 Key for custom models
  static const String _selectedProviderKey = 'selected_model_provider'; // 新增 Key for provider

  // 默认的各提供商 API 基础 URL
  static const Map<String, String> defaultBaseUrls = {
    'OpenAI': 'https://api.openai.com/v1',
    'Google': 'https://generativelanguage.googleapis.com/v1beta', // Gemini API 基础 URL
  };

  // 可选模型列表
  final List<String> _presetModels = [
    'gpt-3.5-turbo',
    'gpt-4',
    'gpt-4-turbo-preview',
    'gemini-1.0-pro', // 更新为实际存在的 Gemini 模型
    'gemini-1.5-pro-latest',
    'gemini-pro-vision',
    // 你可以根据需要添加更多模型
  ];

  // 分类预设模型
  final Map<String, List<String>> _categorizedPresetModels = {
    'OpenAI': [
      'gpt-3.5-turbo',
      'gpt-4',
      'gpt-4-turbo-preview',
    ],
    'Google': [
      'gemini-1.0-pro',
      'gemini-1.5-pro-latest',
      'gemini-pro-vision',
    ],
  };

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
    }
    // 自定义模型暂时对所有提供商可见，或根据需要调整
    modelsToShow.addAll(_customModels);
    return List.unmodifiable(modelsToShow.toSet().toList()); // toSet().toList() to remove duplicates if any
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
    _selectedModel = prefs.getString(_selectedModelKey) ?? 'gpt-3.5-turbo';
    _providerUrl = prefs.getString(_providerUrlKey); // 加载 Provider URL
    _customModels = prefs.getStringList(_customModelsKey) ?? []; // 加载自定义模型
    _selectedProvider = prefs.getString(_selectedProviderKey) ?? 'OpenAI'; // 加载 Provider
    notifyListeners();
    // Ensure the selected model is valid for the loaded provider
    _validateSelectedModelForProvider();
  }

  Future<void> setSelectedProvider(String newProvider) async {
    // 检查新的提供商是否是已知的（即在 defaultBaseUrls 中有定义）
    if (_selectedProvider != newProvider && defaultBaseUrls.containsKey(newProvider)) {
      _selectedProvider = newProvider;
      // 当提供商改变时，自动将 _providerUrl 设置为新提供商的默认 URL
      // 用户之后仍然可以通过 setProviderUrl 方法设置自定义 URL
      _providerUrl = defaultBaseUrls[newProvider];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_selectedProviderKey, newProvider);
      // 保存更新后的 providerUrl (如果它是非null)
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
