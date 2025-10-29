import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 负责搜索引擎相关的配置
/// 职责：管理 Google Search 和 Tavily 搜索引擎的设置
class SearchProvider with ChangeNotifier {
  // ==================== Google Custom Search ====================

  // Google Search API Key
  String? _googleSearchApiKey;
  static const String _googleSearchApiKeyKey = 'google_search_api_key';

  // Google Search Engine ID
  String? _googleSearchEngineId;
  static const String _googleSearchEngineIdKey = 'google_search_engine_id';

  // 是否启用 Google Search
  bool _googleSearchEnabled = false;
  static const String _googleSearchEnabledKey = 'google_search_enabled';

  // Google 搜索结果数量
  int _googleSearchResultCount = 10;
  static const String _googleSearchResultCountKey = 'google_search_result_count';

  // Google 搜索提供商类型
  String _googleSearchProvider = 'googleCustomSearch';
  static const String _googleSearchProviderKey = 'google_search_provider';

  // ==================== Tavily Search ====================

  // Tavily API Key
  String? _tavilyApiKey;
  static const String _tavilyApiKeyKey = 'tavily_api_key';

  // 是否启用 Tavily Search
  bool _tavilySearchEnabled = false;
  static const String _tavilySearchEnabledKey = 'tavily_search_enabled';

  // ==================== Getters ====================

  // Google Search Getters
  String? get googleSearchApiKey => _googleSearchApiKey;
  String? get googleSearchEngineId => _googleSearchEngineId;
  bool get googleSearchEnabled => _googleSearchEnabled;
  int get googleSearchResultCount => _googleSearchResultCount;
  String get googleSearchProvider => _googleSearchProvider;

  // Tavily Search Getters
  String? get tavilyApiKey => _tavilyApiKey;
  bool get tavilySearchEnabled => _tavilySearchEnabled;

  /// 检查是否至少配置了一个搜索引擎
  bool get hasSearchEngineConfigured {
    return (googleSearchEnabled && _googleSearchApiKey != null) ||
        (tavilySearchEnabled && _tavilyApiKey != null);
  }

  /// 获取当前活跃的搜索提供商
  String? get activeSearchProvider {
    if (tavilySearchEnabled) return 'tavily';
    if (googleSearchEnabled) return 'google';
    return null;
  }

  // ==================== 初始化 ====================

  SearchProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // 加载 Google Search 设置
    _googleSearchApiKey = prefs.getString(_googleSearchApiKeyKey);
    _googleSearchEngineId = prefs.getString(_googleSearchEngineIdKey);
    _googleSearchEnabled = prefs.getBool(_googleSearchEnabledKey) ?? false;
    _googleSearchResultCount = prefs.getInt(_googleSearchResultCountKey) ?? 10;
    _googleSearchProvider =
        prefs.getString(_googleSearchProviderKey) ?? 'googleCustomSearch';

    // 加载 Tavily Search 设置
    _tavilyApiKey = prefs.getString(_tavilyApiKeyKey);
    _tavilySearchEnabled = prefs.getBool(_tavilySearchEnabledKey) ?? false;

    notifyListeners();
  }

  // ==================== Google Search 配置方法 ====================

  /// 设置 Google Search API Key
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

  /// 设置 Google Search Engine ID
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

  /// 启用或禁用 Google Search
  Future<void> setGoogleSearchEnabled(bool enabled) async {
    _googleSearchEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_googleSearchEnabledKey, enabled);
    notifyListeners();
  }

  /// 设置 Google 搜索结果数量
  Future<void> setGoogleSearchResultCount(int count) async {
    if (count > 0 && count <= 100) {
      _googleSearchResultCount = count;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_googleSearchResultCountKey, count);
      notifyListeners();
    }
  }

  /// 设置 Google 搜索提供商类型
  Future<void> setGoogleSearchProvider(String provider) async {
    _googleSearchProvider = provider;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_googleSearchProviderKey, provider);
    notifyListeners();
  }

  // ==================== Tavily Search 配置方法 ====================

  /// 设置 Tavily API Key
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

  /// 启用或禁用 Tavily Search
  Future<void> setTavilySearchEnabled(bool enabled) async {
    _tavilySearchEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tavilySearchEnabledKey, enabled);
    notifyListeners();
  }

  // ==================== 验证方法 ====================

  /// 验证 Google Search 配置是否完整
  bool isGoogleSearchConfigured() {
    return _googleSearchApiKey != null &&
        _googleSearchEngineId != null &&
        _googleSearchEnabled;
  }

  /// 验证 Tavily Search 配置是否完整
  bool isTavilySearchConfigured() {
    return _tavilyApiKey != null && _tavilySearchEnabled;
  }

  // ==================== 导入/导出 ====================

  /// 导出搜索配置为 Map
  Map<String, dynamic> toMap() {
    return {
      _googleSearchApiKeyKey: _googleSearchApiKey,
      _googleSearchEngineIdKey: _googleSearchEngineId,
      _googleSearchEnabledKey: _googleSearchEnabled,
      _googleSearchResultCountKey: _googleSearchResultCount,
      _googleSearchProviderKey: _googleSearchProvider,
      _tavilyApiKeyKey: _tavilyApiKey,
      _tavilySearchEnabledKey: _tavilySearchEnabled,
    };
  }

  /// 从 Map 导入搜索配置
  Future<void> fromMap(Map<String, dynamic> data) async {
    // Google Search
    if (data.containsKey(_googleSearchApiKeyKey)) {
      _googleSearchApiKey = data[_googleSearchApiKeyKey];
    }
    if (data.containsKey(_googleSearchEngineIdKey)) {
      _googleSearchEngineId = data[_googleSearchEngineIdKey];
    }
    if (data.containsKey(_googleSearchEnabledKey)) {
      _googleSearchEnabled = data[_googleSearchEnabledKey] ?? false;
    }
    if (data.containsKey(_googleSearchResultCountKey)) {
      _googleSearchResultCount = data[_googleSearchResultCountKey] ?? 10;
    }
    if (data.containsKey(_googleSearchProviderKey)) {
      _googleSearchProvider = data[_googleSearchProviderKey] ?? 'googleCustomSearch';
    }

    // Tavily Search
    if (data.containsKey(_tavilyApiKeyKey)) {
      _tavilyApiKey = data[_tavilyApiKeyKey];
    }
    if (data.containsKey(_tavilySearchEnabledKey)) {
      _tavilySearchEnabled = data[_tavilySearchEnabledKey] ?? false;
    }

    final prefs = await SharedPreferences.getInstance();

    // 持久化 Google Search 配置
    if (_googleSearchApiKey != null) {
      await prefs.setString(_googleSearchApiKeyKey, _googleSearchApiKey!);
    } else {
      await prefs.remove(_googleSearchApiKeyKey);
    }
    if (_googleSearchEngineId != null) {
      await prefs.setString(_googleSearchEngineIdKey, _googleSearchEngineId!);
    } else {
      await prefs.remove(_googleSearchEngineIdKey);
    }
    await prefs.setBool(_googleSearchEnabledKey, _googleSearchEnabled);
    await prefs.setInt(_googleSearchResultCountKey, _googleSearchResultCount);
    await prefs.setString(_googleSearchProviderKey, _googleSearchProvider);

    // 持久化 Tavily Search 配置
    if (_tavilyApiKey != null) {
      await prefs.setString(_tavilyApiKeyKey, _tavilyApiKey!);
    } else {
      await prefs.remove(_tavilyApiKeyKey);
    }
    await prefs.setBool(_tavilySearchEnabledKey, _tavilySearchEnabled);

    notifyListeners();
  }
}
