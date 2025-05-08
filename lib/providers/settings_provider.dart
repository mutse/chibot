import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  String? _apiKey;
  String _selectedModel = 'gpt-3.5-turbo'; // 默认模型
  String? _providerUrl; // 新增：模型 Provider URL

  static const String _apiKeyKey = 'openai_api_key';
  static const String _selectedModelKey = 'openai_selected_model';
  static const String _providerUrlKey = 'openai_provider_url'; // 新增 Key

  // 默认的 OpenAI API 基础 URL
  static const String defaultOpenAIBaseUrl = 'https://api.openai.com/v1';

  // 可选模型列表
  final List<String> _availableModels = [
    'gpt-3.5-turbo',
    'gpt-4',
    'gpt-4-turbo-preview',
    // 你可以根据需要添加更多模型
  ];

  SettingsProvider() {
    _loadSettings();
  }

  String? get apiKey => _apiKey;
  String get selectedModel => _selectedModel;
  List<String> get availableModels => _availableModels;

  // 获取 Provider URL，如果未设置则返回 OpenAI 默认 URL
  String get providerUrl {
    // 确保返回的 URL 后面没有 /chat/completions，因为 OpenAIService 会拼接
    final url = _providerUrl?.trim() ?? defaultOpenAIBaseUrl;
    if (url.endsWith('/')) {
      return url.substring(0, url.length - 1);
    }
    return url;
  }

  // 返回给UI显示的原始Provider URL，可能是空的
  String? get rawProviderUrl => _providerUrl;


  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _apiKey = prefs.getString(_apiKeyKey);
    _selectedModel = prefs.getString(_selectedModelKey) ?? 'gpt-3.5-turbo';
    _providerUrl = prefs.getString(_providerUrlKey); // 加载 Provider URL
    notifyListeners();
  }

  Future<void> setApiKey(String newApiKey) async {
    _apiKey = newApiKey;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyKey, newApiKey);
    notifyListeners();
  }

  Future<void> setSelectedModel(String newModel) async {
    if (_availableModels.contains(newModel)) {
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
  }
}
