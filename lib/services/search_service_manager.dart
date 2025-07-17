import 'google_search_service.dart';
import '../models/search_result.dart';
import '../providers/settings_provider.dart';

class SearchServiceManager {
  static GoogleSearchService? _googleSearchService;

  static Future<GoogleSearchService?> getSearchService(SettingsProvider settings) async {
    if (!settings.googleSearchEnabled) {
      return null;
    }

    if (_googleSearchService == null || 
        _googleSearchService!.apiKey != settings.googleSearchApiKey ||
        _googleSearchService!.searchEngineId != settings.googleSearchEngineId) {
      
      if (settings.googleSearchApiKey == null || settings.googleSearchApiKey!.isEmpty ||
          settings.googleSearchEngineId == null || settings.googleSearchEngineId!.isEmpty) {
        return null;
      }

      _googleSearchService = GoogleSearchService(
        apiKey: settings.googleSearchApiKey!,
        searchEngineId: settings.googleSearchEngineId!,
        provider: settings.googleSearchProvider == 'googleCustomSearch' 
            ? SearchProvider.googleCustomSearch 
            : SearchProvider.programmableSearch,
      );
    }

    return _googleSearchService;
  }

  static Future<bool> validateConfiguration(SettingsProvider settings) async {
    if (!settings.googleSearchEnabled) {
      return false;
    }

    final service = await getSearchService(settings);
    if (service == null) {
      return false;
    }

    try {
      return await service.validateConfiguration();
    } catch (e) {
      return false;
    }
  }

  static void clearCache() {
    _googleSearchService = null;
  }

  static String getSearchInstructions() {
    return '''
Google 搜索功能使用说明：

1. 启用功能：
   - 在设置中启用 "Google 搜索功能"

2. 配置 API：
   - 获取 Google Custom Search API Key
   - 创建 Custom Search Engine 并获取 Engine ID
   - 在设置中填入 API Key 和 Engine ID

3. 使用方法：
   - 在聊天输入框中输入 /search 关键词
   - 例如：/search 最新AI技术发展
   - 系统将返回搜索结果并整合到对话中

4. 注意事项：
   - 每日免费配额：100次查询
   - 支持中文和英文搜索
   - 可调整搜索结果数量（1-20条）

如何获取 API Key 和 Engine ID：
1. 访问 https://developers.google.com/custom-search/v1/introduction
2. 创建项目并启用 Custom Search API
3. 创建自定义搜索引擎
4. 获取 API Key 和 Engine ID
    '''.trim();
  }
}