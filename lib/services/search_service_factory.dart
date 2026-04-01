import 'package:flutter/foundation.dart';
import '../providers/search_provider.dart';
import '../providers/api_key_provider.dart';
import 'google_search_service.dart';
import '../models/search_result.dart' as search_result_lib;
import 'service_config_validator.dart';
import 'web_search_service.dart';

enum SearchBackend { google, tavily }

class ActiveSearchService {
  final SearchBackend provider;
  final Object service;

  const ActiveSearchService({required this.provider, required this.service});

  GoogleSearchService? get googleService =>
      service is GoogleSearchService ? service as GoogleSearchService : null;

  WebSearchService? get tavilyService =>
      service is WebSearchService ? service as WebSearchService : null;
}

/// 搜索服务工厂 - 统一搜索服务的创建和管理
///
/// 职责：
/// - 创建搜索服务实例
/// - 验证搜索配置
/// - 管理支持的搜索提供商
/// - 构建搜索参数
///
/// 支持的搜索提供商：
/// - Google Custom Search
/// - Tavily (计划中)
///
/// 使用示例：
/// ```dart
/// if (SearchServiceFactory.isGoogleSearchConfigured(
///   search: searchProvider,
///   apiKeys: apiKeyProvider,
/// )) {
///   final service = SearchServiceFactory.createGoogleSearchService(
///     search: searchProvider,
///     apiKeys: apiKeyProvider,
///   );
/// }
/// ```
class SearchServiceFactory {
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
        ServiceConfigValidator.hasText(apiKeys.googleSearchApiKey) &&
        ServiceConfigValidator.hasText(search.googleSearchEngineId);
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
        ServiceConfigValidator.hasText(apiKeys.tavilyApiKey);
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
  /// 优先级：Tavily > Google
  static SearchBackend? getActiveSearchProvider({
    required SearchProvider search,
    required ApiKeyProvider apiKeys,
  }) {
    if (isTavilySearchConfigured(search: search, apiKeys: apiKeys)) {
      return SearchBackend.tavily;
    }
    if (isGoogleSearchConfigured(search: search, apiKeys: apiKeys)) {
      return SearchBackend.google;
    }
    return null;
  }

  /// 创建 Google Custom Search 服务
  ///
  /// 抛出异常如果配置不完整
  static GoogleSearchService createGoogleSearchService({
    required SearchProvider search,
    required ApiKeyProvider apiKeys,
  }) {
    if (!isGoogleSearchConfigured(search: search, apiKeys: apiKeys)) {
      throw Exception(
        'Google Custom Search is not properly configured. '
        'Please set API key, Search Engine ID, and enable search in settings.',
      );
    }

    if (kDebugMode) {
      print('[SearchServiceFactory] Creating Google Search Service');
      print('[SearchServiceFactory] Engine ID: ${search.googleSearchEngineId}');
    }

    return GoogleSearchService(
      apiKey: ServiceConfigValidator.requireText(
        apiKeys.googleSearchApiKey,
        'Google Custom Search API key is not configured.',
      ),
      searchEngineId: ServiceConfigValidator.requireText(
        search.googleSearchEngineId,
        'Google Custom Search Engine ID is not configured.',
      ),
      provider:
          search.googleSearchProvider == 'googleCustomSearch'
              ? search_result_lib.SearchProvider.googleCustomSearch
              : search_result_lib.SearchProvider.programmableSearch,
    );
  }

  /// 创建 Tavily 搜索服务
  static WebSearchService createTavilySearchService({
    required SearchProvider search,
    required ApiKeyProvider apiKeys,
  }) {
    if (!isTavilySearchConfigured(search: search, apiKeys: apiKeys)) {
      throw Exception(
        'Tavily Search is not properly configured. '
        'Please set API key and enable search in settings.',
      );
    }

    return WebSearchService(
      apiKey: ServiceConfigValidator.requireText(
        apiKeys.tavilyApiKey,
        'Tavily API key is not configured.',
      ),
    );
  }

  /// 创建搜索服务（根据活跃提供商）
  ///
  /// 返回当前配置的搜索服务，如果没有配置任何搜索引擎则返回 null
  static ActiveSearchService? createSearchService({
    required SearchProvider search,
    required ApiKeyProvider apiKeys,
  }) {
    final provider = getActiveSearchProvider(search: search, apiKeys: apiKeys);

    switch (provider) {
      case SearchBackend.google:
        return ActiveSearchService(
          provider: provider!,
          service: createGoogleSearchService(search: search, apiKeys: apiKeys),
        );
      case SearchBackend.tavily:
        return ActiveSearchService(
          provider: provider!,
          service: createTavilySearchService(search: search, apiKeys: apiKeys),
        );
      case null:
        return null;
    }
  }

  /// 将 Google 搜索结果格式化为可注入 prompt 的纯文本
  static String formatGoogleSearchResult(
    search_result_lib.SearchResult result,
  ) {
    final buffer = StringBuffer();

    for (var i = 0; i < result.items.length; i++) {
      final item = result.items[i];
      buffer.writeln('${i + 1}. ${item.title}');
      buffer.writeln(item.snippet);
      buffer.writeln(item.link);
      buffer.writeln();
    }

    final formatted = buffer.toString().trim();
    return formatted.isEmpty ? '未找到相关搜索结果。' : formatted;
  }

  /// 使用当前活跃搜索引擎执行网页搜索，并返回可直接拼入 prompt 的文本
  static Future<String> searchWebAsPromptContext({
    required SearchProvider search,
    required ApiKeyProvider apiKeys,
    required String query,
  }) async {
    final provider = getActiveSearchProvider(search: search, apiKeys: apiKeys);

    switch (provider) {
      case SearchBackend.tavily:
        return createTavilySearchService(
          search: search,
          apiKeys: apiKeys,
        ).searchWeb(query);
      case SearchBackend.google:
        final result = await createGoogleSearchService(
          search: search,
          apiKeys: apiKeys,
        ).search(query, count: search.googleSearchResultCount);
        return formatGoogleSearchResult(result);
      default:
        throw Exception('No search engine configured.');
    }
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
      'apiKey': ServiceConfigValidator.requireText(
        apiKeys.googleSearchApiKey,
        'Google Custom Search API key is not configured.',
      ),
      'engineId': ServiceConfigValidator.requireText(
        search.googleSearchEngineId,
        'Google Custom Search Engine ID is not configured.',
      ),
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
      throw Exception('Tavily API key is not configured.');
    }

    return {
      'apiKey': ServiceConfigValidator.requireText(
        apiKeys.tavilyApiKey,
        'Tavily API key is not configured.',
      ),
      'query': query,
    };
  }

  /// 验证搜索配置
  ///
  /// 异步验证方法，用于彻底检查搜索服务的可用性
  static Future<bool> validateConfiguration({
    required SearchProvider search,
    required ApiKeyProvider apiKeys,
  }) async {
    try {
      final activeService = createSearchService(
        search: search,
        apiKeys: apiKeys,
      );
      if (activeService == null) {
        return false;
      }

      if (activeService.googleService != null) {
        return await activeService.googleService!.validateConfiguration();
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('[SearchServiceFactory] Validation error: $e');
      }
      return false;
    }
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
  static List<String> get supportedProviders => [
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
