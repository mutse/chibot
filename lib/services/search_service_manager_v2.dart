import '../providers/search_provider.dart';
import '../providers/api_key_provider.dart';
import 'google_search_service.dart';

/// 搜索服务管理器 - 使用专职提供者创建搜索服务
///
/// 改进：
/// - 使用 SearchProvider 和 ApiKeyProvider 代替 SettingsProvider
/// - 统一的搜索服务创建和验证
/// - 支持多个搜索提供商（Google, Tavily）
///
/// 使用示例：
/// ```dart
/// final manager = SearchServiceManager();
/// if (SearchServiceManager.isGoogleSearchConfigured(
///   search: searchProvider,
///   apiKeys: apiKeyProvider,
/// )) {
///   final service = SearchServiceManager.createGoogleSearchService(
///     search: searchProvider,
///     apiKeys: apiKeyProvider,
///   );
/// }
/// ```
class SearchServiceManager {
  /// 检查 Google Custom Search 是否已完全配置
  ///
  /// 检查项：
  /// 1. API Key 是否已设置
  /// 2. Search Engine ID 是否已设置
  /// 3. 搜索功能是否已启用
  static bool isGoogleSearchConfigured({
    required SearchProvider search,
    required ApiKeyProvider apiKeys,
  }) {
    return search.isGoogleSearchConfigured() &&
        apiKeys.googleSearchApiKey != null &&
        apiKeys.googleSearchApiKey!.isNotEmpty;
  }

  /// 检查 Tavily Search 是否已完全配置
  ///
  /// 检查项：
  /// 1. API Key 是否已设置
  /// 2. 搜索功能是否已启用
  static bool isTavilySearchConfigured({
    required SearchProvider search,
    required ApiKeyProvider apiKeys,
  }) {
    return search.isTavilySearchConfigured() &&
        apiKeys.tavilyApiKey != null &&
        apiKeys.tavilyApiKey!.isNotEmpty;
  }

  /// 检查是否至少配置了一个搜索引擎
  static bool hasSearchEngineConfigured({
    required SearchProvider search,
    required ApiKeyProvider apiKeys,
  }) {
    return isGoogleSearchConfigured(search: search, apiKeys: apiKeys) ||
        isTavilySearchConfigured(search: search, apiKeys: apiKeys);
  }

  /// 获取当前活跃的搜索提供商
  ///
  /// 返回 'google', 'tavily' 或 null（如果都未启用）
  static String? getActiveSearchProvider({
    required SearchProvider search,
    required ApiKeyProvider apiKeys,
  }) {
    if (isTavilySearchConfigured(search: search, apiKeys: apiKeys)) {
      return 'tavily';
    }
    if (isGoogleSearchConfigured(search: search, apiKeys: apiKeys)) {
      return 'google';
    }
    return null;
  }

  /// 创建并验证 Google Custom Search 服务
  ///
  /// 抛出异常如果配置不完整
  static GoogleSearchService createAndValidateGoogleSearchService({
    required SearchProvider search,
    required ApiKeyProvider apiKeys,
  }) {
    if (!isGoogleSearchConfigured(search: search, apiKeys: apiKeys)) {
      throw Exception(
        'Google Custom Search is not properly configured. '
        'Please set API key, Search Engine ID, and enable search in settings.',
      );
    }

    return GoogleSearchService(
      apiKey: apiKeys.googleSearchApiKey!,
      searchEngineId: search.googleSearchEngineId!,
    );
  }

  /// 验证 Google Custom Search 配置并获取搜索参数
  ///
  /// 返回包含搜索参数的 Map，如果配置无效则抛出异常
  static Map<String, dynamic> prepareGoogleSearchParams({
    required SearchProvider search,
    required ApiKeyProvider apiKeys,
    required String query,
  }) {
    if (!isGoogleSearchConfigured(search: search, apiKeys: apiKeys)) {
      throw Exception(
        'Google Custom Search API key or Search Engine ID is not configured.',
      );
    }

    return {
      'apiKey': apiKeys.googleSearchApiKey!,
      'engineId': search.googleSearchEngineId!,
      'query': query,
      'resultCount': search.googleSearchResultCount,
    };
  }

  /// 验证 Tavily Search 配置并获取搜索参数
  ///
  /// 返回包含搜索参数的 Map，如果配置无效则抛出异常
  static Map<String, dynamic> prepareTavilySearchParams({
    required SearchProvider search,
    required ApiKeyProvider apiKeys,
    required String query,
  }) {
    if (!isTavilySearchConfigured(search: search, apiKeys: apiKeys)) {
      throw Exception(
        'Tavily API key is not configured.',
      );
    }

    return {
      'apiKey': apiKeys.tavilyApiKey!,
      'query': query,
    };
  }

  /// 获取当前活跃搜索引擎的配置状态描述
  ///
  /// 用于 UI 展示
  static String getSearchConfigDescription({
    required SearchProvider search,
    required ApiKeyProvider apiKeys,
  }) {
    if (isTavilySearchConfigured(search: search, apiKeys: apiKeys)) {
      return 'Tavily Search (Enabled)';
    }
    if (isGoogleSearchConfigured(search: search, apiKeys: apiKeys)) {
      return 'Google Custom Search (Enabled)';
    }
    return 'No search engine configured';
  }

  /// 获取所有支持的搜索提供商
  static List<String> get supportedSearchProviders => [
    'Google Custom Search',
    'Tavily',
  ];

  /// 获取所有已启用的搜索提供商
  static List<String> getEnabledSearchProviders({
    required SearchProvider search,
    required ApiKeyProvider apiKeys,
  }) {
    final enabled = <String>[];

    if (isGoogleSearchConfigured(search: search, apiKeys: apiKeys)) {
      enabled.add('Google Custom Search');
    }
    if (isTavilySearchConfigured(search: search, apiKeys: apiKeys)) {
      enabled.add('Tavily');
    }

    return enabled;
  }

  /// 检查搜索功能是否可以使用
  ///
  /// 返回 true 如果至少有一个搜索引擎被启用且完全配置
  static bool isSearchFunctionalityAvailable({
    required SearchProvider search,
    required ApiKeyProvider apiKeys,
  }) {
    return hasSearchEngineConfigured(search: search, apiKeys: apiKeys);
  }
}
