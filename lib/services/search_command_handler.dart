import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/search_result.dart';
import '../services/search_service_manager.dart';
import '../providers/settings_provider.dart';
import '../models/chat_message.dart';

class SearchCommandHandler {
  static const String searchCommand = '/search';
  static const String searchImageCommand = '/search_image';

  static bool isSearchCommand(String message) {
    return message.trim().startsWith(searchCommand) || 
           message.trim().startsWith(searchImageCommand);
  }

  static String extractSearchQuery(String message) {
    final trimmed = message.trim();
    if (trimmed.startsWith(searchCommand)) {
      return trimmed.substring(searchCommand.length).trim();
    } else if (trimmed.startsWith(searchImageCommand)) {
      return trimmed.substring(searchImageCommand.length).trim();
    }
    return '';
  }

  static bool isImageSearch(String message) {
    return message.trim().startsWith(searchImageCommand);
  }

  static Future<List<ChatMessage>> handleSearchCommand(
    BuildContext context,
    String query,
    bool isImage,
  ) async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    
    if (!settings.googleSearchEnabled) {
      return [
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: 'Google 搜索功能未启用。请在设置中启用搜索功能并配置 API 密钥。',
          sender: MessageSender.ai,
          timestamp: DateTime.now(),
        ),
      ];
    }

    final searchService = await SearchServiceManager.getSearchService(settings);
    if (searchService == null) {
      return [
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: '搜索服务配置不完整。请检查 API Key 和 Search Engine ID 是否正确配置。',
          sender: MessageSender.ai,
          timestamp: DateTime.now(),
        ),
      ];
    }

    try {
      final searchResult = isImage
          ? await searchService.searchImages(query, count: settings.googleSearchResultCount)
          : await searchService.search(query, count: settings.googleSearchResultCount);

      return _formatSearchResults(searchResult, query, isImage);
    } catch (e) {
      return [
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: '搜索失败：${e.toString()}',
          sender: MessageSender.ai,
          timestamp: DateTime.now(),
        ),
      ];
    }
  }

  static List<ChatMessage> _formatSearchResults(
    SearchResult searchResult,
    String query,
    bool isImage,
  ) {
    final messages = <ChatMessage>[];
    
    // Add search summary
    messages.add(ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: '为您找到 ${searchResult.items.length} 条关于 "${query}" 的${isImage ? "图片" : "网页"}搜索结果：',
      sender: MessageSender.ai,
      timestamp: DateTime.now(),
      metadata: {'type': 'system'},
    ));

    // Add search results
    for (var i = 0; i < searchResult.items.length; i++) {
      final item = searchResult.items[i];
      final content = _formatSearchItem(item, i + 1, isImage);
      
      messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: content,
        sender: MessageSender.ai,
        timestamp: DateTime.now(),
        metadata: {'type': 'system'},
      ));
    }

    return messages;
  }

  static String _formatSearchItem(SearchItem item, int index, bool isImage) {
    final buffer = StringBuffer();
    buffer.writeln('$index. **${item.title}**');
    buffer.writeln('   ${item.snippet}');
    buffer.writeln('   🔗 ${item.link}');
    
    if (isImage && item.imageUrl != null) {
      buffer.writeln('   🖼️ ${item.imageUrl}');
    }
    
    return buffer.toString().trim();
  }

  static String getHelpMessage() {
    return '''
搜索命令使用帮助：

📍 基本搜索：
/search [关键词] - 搜索相关网页
例如：/search 人工智能最新进展

📷 图片搜索：
/search_image [关键词] - 搜索相关图片
例如：/search_image 风景壁纸

💡 使用提示：
- 支持中文和英文搜索
- 搜索结果会直接显示在对话中
- 点击链接可访问原始网页
- 最多显示20条结果（可在设置中调整）

⚙️ 使用前请确保：
1. 已在设置中启用 Google 搜索功能
2. 已配置有效的 API Key 和 Search Engine ID

如遇到问题，请检查设置中的搜索配置。
    '''.trim();
  }

  static Widget buildSearchResultWidget(ChatMessage message) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.search, color: Colors.blue, size: 16),
          SizedBox(height: 4),
          Text(
            message.text,
            style: TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}