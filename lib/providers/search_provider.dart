import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_key_provider.dart';

/// 负责搜索引擎相关的配置
/// 职责：管理 Google Search 和 Tavily 搜索引擎的设置
class SearchProvider with ChangeNotifier {
  final ApiKeyProvider _apiKeyProvider;

  // ==================== Google Custom Search ====================

  // Google Search Engine ID
  String? _googleSearchEngineId;
  static const String _googleSearchEngineIdKey = 'google_search_engine_id';

  // 是否启用 Google Search
  bool _googleSearchEnabled = false;
  static const String _googleSearchEnabledKey = 'google_search_enabled';

  // Google 搜索结果数量
  int _googleSearchResultCount = 10;
  static const String _googleSearchResultCountKey =
      'google_search_result_count';

  // Google 搜索提供商类型
  String _googleSearchProvider = 'googleCustomSearch';
  static const String _googleSearchProviderKey = 'google_search_provider';

  // ==================== Tavily Search ====================

  // 是否启用 Tavily Search
  bool _tavilySearchEnabled = false;
  static const String _tavilySearchEnabledKey = 'tavily_search_enabled';

  // ==================== Getters ====================

  // Google Search Getters
  String? get googleSearchApiKey => _apiKeyProvider.googleSearchApiKey;
  String? get googleSearchEngineId => _googleSearchEngineId;
  bool get googleSearchEnabled => _googleSearchEnabled;
  int get googleSearchResultCount => _googleSearchResultCount;
  String get googleSearchProvider => _googleSearchProvider;

  // Tavily Search Getters
  String? get tavilyApiKey => _apiKeyProvider.tavilyApiKey;
  bool get tavilySearchEnabled => _tavilySearchEnabled;

  /// 检查是否至少配置了一个搜索引擎
  bool get hasSearchEngineConfigured {
    return (googleSearchEnabled && googleSearchApiKey != null) ||
        (tavilySearchEnabled && tavilyApiKey != null);
  }

  /// 获取当前活跃的搜索提供商
  String? get activeSearchProvider {
    if (tavilySearchEnabled) return 'tavily';
    if (googleSearchEnabled) return 'google';
    return null;
  }

  // ==================== 初始化 ====================

  SearchProvider({ApiKeyProvider? apiKeyProvider})
    : _apiKeyProvider = apiKeyProvider ?? ApiKeyProvider() {
    _apiKeyProvider.addListener(_onApiKeyProviderChanged);
    _loadSettings();
  }

  void _onApiKeyProviderChanged() {
    notifyListeners();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // 加载 Google Search 设置
    _googleSearchEngineId = prefs.getString(_googleSearchEngineIdKey);
    _googleSearchEnabled = prefs.getBool(_googleSearchEnabledKey) ?? false;
    _googleSearchResultCount = prefs.getInt(_googleSearchResultCountKey) ?? 10;
    _googleSearchProvider =
        prefs.getString(_googleSearchProviderKey) ?? 'googleCustomSearch';

    // 加载 Tavily Search 设置
    _tavilySearchEnabled = prefs.getBool(_tavilySearchEnabledKey) ?? false;

    notifyListeners();
  }

  // ==================== Google Search 配置方法 ====================

  /// 设置 Google Search API Key
  Future<void> setGoogleSearchApiKey(String? key) async {
    await _apiKeyProvider.setGoogleSearchApiKey(key);
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
    await _apiKeyProvider.setTavilyApiKey(key);
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
    return googleSearchApiKey != null &&
        _googleSearchEngineId != null &&
        _googleSearchEnabled;
  }

  /// 验证 Tavily Search 配置是否完整
  bool isTavilySearchConfigured() {
    return tavilyApiKey != null && _tavilySearchEnabled;
  }

  // ==================== 导入/导出 ====================

  /// 导出搜索配置为 Map
  Map<String, dynamic> toMap() {
    return {
      _googleSearchEngineIdKey: _googleSearchEngineId,
      _googleSearchEnabledKey: _googleSearchEnabled,
      _googleSearchResultCountKey: _googleSearchResultCount,
      _googleSearchProviderKey: _googleSearchProvider,
      _tavilySearchEnabledKey: _tavilySearchEnabled,
    };
  }

  /// 从 Map 导入搜索配置
  Future<void> fromMap(Map<String, dynamic> data) async {
    // Google Search
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
      _googleSearchProvider =
          data[_googleSearchProviderKey] ?? 'googleCustomSearch';
    }

    // Tavily Search
    if (data.containsKey(_tavilySearchEnabledKey)) {
      _tavilySearchEnabled = data[_tavilySearchEnabledKey] ?? false;
    }

    if (data.containsKey('google_search_api_key')) {
      await _apiKeyProvider.setGoogleSearchApiKey(
        data['google_search_api_key'],
      );
    }
    if (data.containsKey('tavily_api_key')) {
      await _apiKeyProvider.setTavilyApiKey(data['tavily_api_key']);
    }

    final prefs = await SharedPreferences.getInstance();

    // 持久化 Google Search 配置
    if (_googleSearchEngineId != null) {
      await prefs.setString(_googleSearchEngineIdKey, _googleSearchEngineId!);
    } else {
      await prefs.remove(_googleSearchEngineIdKey);
    }
    await prefs.setBool(_googleSearchEnabledKey, _googleSearchEnabled);
    await prefs.setInt(_googleSearchResultCountKey, _googleSearchResultCount);
    await prefs.setString(_googleSearchProviderKey, _googleSearchProvider);

    await prefs.setBool(_tavilySearchEnabledKey, _tavilySearchEnabled);

    notifyListeners();
  }

  @override
  void dispose() {
    _apiKeyProvider.removeListener(_onApiKeyProviderChanged);
    super.dispose();
  }
}
