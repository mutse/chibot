import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 负责管理所有 API 密钥的提供者
/// 职责：存储、加载、更新各个 AI 服务的 API 密钥
class ApiKeyProvider with ChangeNotifier {
  // OpenAI API Key
  String? _openaiApiKey;
  static const String _openaiApiKeyKey = 'openai_api_key';

  // Claude API Key
  String? _claudeApiKey;
  static const String _claudeApiKeyKey = 'claude_api_key';

  // Google API Key (用于 Gemini 和图像生成)
  String? _googleApiKey;
  static const String _googleApiKeyKey = 'google_api_key';

  // FLUX Kontext API Key
  String? _fluxKontextApiKey;
  static const String _fluxKontextApiKeyKey = 'flux_kontext_api_key';

  // Tavily API Key (用于网络搜索)
  String? _tavilyApiKey;
  static const String _tavilyApiKeyKey = 'tavily_api_key';

  // Google Search API Key
  String? _googleSearchApiKey;
  static const String _googleSearchApiKeyKey = 'google_search_api_key';

  // Google Search Engine ID
  String? _googleSearchEngineId;
  static const String _googleSearchEngineIdKey = 'google_search_engine_id';

  // ==================== Getters ====================

  String? get openaiApiKey => _openaiApiKey;
  String? get claudeApiKey => _claudeApiKey;
  String? get googleApiKey => _googleApiKey;
  String? get fluxKontextApiKey => _fluxKontextApiKey;
  String? get tavilyApiKey => _tavilyApiKey;
  String? get googleSearchApiKey => _googleSearchApiKey;
  String? get googleSearchEngineId => _googleSearchEngineId;

  // 便利 getter：用于向后兼容（旧代码中使用 apiKey 指代 OpenAI）
  String? get apiKey => _openaiApiKey;

  // ==================== 便利方法：根据提供商获取 API Key ====================

  String? getApiKeyForProvider(String provider) {
    switch (provider.toLowerCase()) {
      case 'openai':
        return _openaiApiKey;
      case 'google':
      case 'gemini':
        return _googleApiKey;
      case 'anthropic':
      case 'claude':
        return _claudeApiKey;
      default:
        return null;
    }
  }

  String? getImageApiKeyForProvider(String provider) {
    switch (provider.toLowerCase()) {
      case 'openai':
        return _openaiApiKey;
      case 'google':
        return _googleApiKey;
      case 'black forest labs':
      case 'flux':
        return _fluxKontextApiKey;
      default:
        return null;
    }
  }

  // ==================== 初始化 ====================

  ApiKeyProvider() {
    _loadApiKeys();
  }

  Future<void> _loadApiKeys() async {
    final prefs = await SharedPreferences.getInstance();
    _openaiApiKey = prefs.getString(_openaiApiKeyKey);
    _claudeApiKey = prefs.getString(_claudeApiKeyKey);
    _googleApiKey = prefs.getString(_googleApiKeyKey);
    _fluxKontextApiKey = prefs.getString(_fluxKontextApiKeyKey);
    _tavilyApiKey = prefs.getString(_tavilyApiKeyKey);
    _googleSearchApiKey = prefs.getString(_googleSearchApiKeyKey);
    _googleSearchEngineId = prefs.getString(_googleSearchEngineIdKey);
    notifyListeners();
  }

  // ==================== Setters ====================

  Future<void> setOpenaiApiKey(String? key) async {
    _openaiApiKey = key;
    final prefs = await SharedPreferences.getInstance();
    if (key != null) {
      await prefs.setString(_openaiApiKeyKey, key);
    } else {
      await prefs.remove(_openaiApiKeyKey);
    }
    notifyListeners();
  }

  Future<void> setClaudeApiKey(String? key) async {
    _claudeApiKey = key;
    final prefs = await SharedPreferences.getInstance();
    if (key != null) {
      await prefs.setString(_claudeApiKeyKey, key);
    } else {
      await prefs.remove(_claudeApiKeyKey);
    }
    notifyListeners();
  }

  Future<void> setGoogleApiKey(String? key) async {
    _googleApiKey = key;
    final prefs = await SharedPreferences.getInstance();
    if (key != null) {
      await prefs.setString(_googleApiKeyKey, key);
    } else {
      await prefs.remove(_googleApiKeyKey);
    }
    notifyListeners();
  }

  Future<void> setFluxKontextApiKey(String? key) async {
    _fluxKontextApiKey = key;
    final prefs = await SharedPreferences.getInstance();
    if (key != null) {
      await prefs.setString(_fluxKontextApiKeyKey, key);
    } else {
      await prefs.remove(_fluxKontextApiKeyKey);
    }
    notifyListeners();
  }

  Future<void> setTavilyApiKey(String? key) async {
    _tavilyApiKey = key;
    final prefs = await SharedPreferences.getInstance();
    if (key != null) {
      await prefs.setString(_tavilyApiKeyKey, key);
    } else {
      await prefs.remove(_tavilyApiKeyKey);
    }
    notifyListeners();
  }

  Future<void> setGoogleSearchApiKey(String? key) async {
    _googleSearchApiKey = key;
    final prefs = await SharedPreferences.getInstance();
    if (key != null) {
      await prefs.setString(_googleSearchApiKeyKey, key);
    } else {
      await prefs.remove(_googleSearchApiKeyKey);
    }
    notifyListeners();
  }

  Future<void> setGoogleSearchEngineId(String? id) async {
    _googleSearchEngineId = id;
    final prefs = await SharedPreferences.getInstance();
    if (id != null) {
      await prefs.setString(_googleSearchEngineIdKey, id);
    } else {
      await prefs.remove(_googleSearchEngineIdKey);
    }
    notifyListeners();
  }

  // ==================== 验证方法 ====================

  /// 检查指定提供商是否已配置 API Key
  bool hasApiKeyForProvider(String provider) {
    return getApiKeyForProvider(provider) != null;
  }

  /// 检查所有必需的 API Key 是否已配置
  bool get hasAllRequiredKeys {
    return _openaiApiKey != null || _googleApiKey != null || _claudeApiKey != null;
  }

  // ==================== 导入/导出 ====================

  /// 导出所有 API 密钥为 Map（用于设置导出）
  Map<String, String?> toMap() {
    return {
      _openaiApiKeyKey: _openaiApiKey,
      _claudeApiKeyKey: _claudeApiKey,
      _googleApiKeyKey: _googleApiKey,
      _fluxKontextApiKeyKey: _fluxKontextApiKey,
      _tavilyApiKeyKey: _tavilyApiKey,
      _googleSearchApiKeyKey: _googleSearchApiKey,
      _googleSearchEngineIdKey: _googleSearchEngineId,
    };
  }

  /// 从 Map 导入 API 密钥
  Future<void> fromMap(Map<String, dynamic> data) async {
    if (data.containsKey(_openaiApiKeyKey)) {
      await setOpenaiApiKey(data[_openaiApiKeyKey]);
    }
    if (data.containsKey(_claudeApiKeyKey)) {
      await setClaudeApiKey(data[_claudeApiKeyKey]);
    }
    if (data.containsKey(_googleApiKeyKey)) {
      await setGoogleApiKey(data[_googleApiKeyKey]);
    }
    if (data.containsKey(_fluxKontextApiKeyKey)) {
      await setFluxKontextApiKey(data[_fluxKontextApiKeyKey]);
    }
    if (data.containsKey(_tavilyApiKeyKey)) {
      await setTavilyApiKey(data[_tavilyApiKeyKey]);
    }
    if (data.containsKey(_googleSearchApiKeyKey)) {
      await setGoogleSearchApiKey(data[_googleSearchApiKeyKey]);
    }
    if (data.containsKey(_googleSearchEngineIdKey)) {
      await setGoogleSearchEngineId(data[_googleSearchEngineIdKey]);
    }
  }
}
