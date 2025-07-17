# Google 免费搜索功能设计文档

## 功能概述

在现有 AI 聊天应用中增加 Google 免费搜索功能，允许用户通过 Google 搜索获取实时信息，并集成到 AI 对话中。

## 功能目标

1. 提供免费的 Google 搜索功能
2. 集成到现有 AI 对话流程
3. 保持用户体验一致性
4. 支持多种搜索类型和结果格式

## 技术架构

### 搜索服务设计

#### 1. Google 搜索服务类 (`GoogleSearchService`)
- **继承**: `BaseApiService`
- **功能**: 处理 Google 搜索 API 调用
- **位置**: `lib/services/google_search_service.dart`

#### 2. 搜索接口定义
- **接口**: `SearchService`
- **方法**: 
  - `Future<SearchResult> search(String query, {int count = 10})`
  - `Future<SearchResult> searchImages(String query, {int count = 10})`

#### 3. 数据模型
- **SearchResult**: 搜索结果包装类
- **SearchItem**: 单个搜索结果项
- **SearchResultType**: 搜索类型枚举

### 搜索实现方案

#### 方案一：Google Custom Search JSON API (推荐)
- **优点**: 官方支持，稳定可靠
- **限制**: 每日 100 次免费查询
- **实现**: 使用 Custom Search API key 和 Search Engine ID

#### 方案二：Google Programmable Search Engine
- **优点**: 完全免费
- **限制**: 需要创建自定义搜索引擎
- **实现**: 通过 HTTP 请求获取搜索结果

#### 方案三：Web Scraping (备选)
- **优点**: 无 API 限制
- **缺点**: 不稳定，可能违反 ToS
- **实现**: 使用 web scraping 技术

## 用户界面设计

### 设置界面集成
- **位置**: 设置页面新增 "搜索功能" 部分
- **配置项**:
  - 启用/禁用搜索功能
  - 选择搜索提供商（Google Custom Search / Programmable Search）
  - 输入 API Key 和 Search Engine ID
  - 搜索结果数量设置

### 聊天界面集成
- **触发方式**: 在消息前加 `/search` 命令
- **显示方式**: 搜索结果作为系统消息显示
- **交互**: 点击链接可直接打开网页

## 数据模型

### SearchResult
```dart
class SearchResult {
  final List<SearchItem> items;
  final SearchQuery query;
  final DateTime timestamp;
  final int totalResults;
}
```

### SearchItem
```dart
class SearchItem {
  final String title;
  final String snippet;
  final String link;
  final String? imageUrl;
  final DateTime? date;
}
```

### SearchQuery
```dart
class SearchQuery {
  final String query;
  final String searchType;
  final int count;
  final String? language;
  final String? region;
}
```

## 配置管理

### 设置存储
- **位置**: SettingsProvider
- **键值**:
  - `google_search_enabled`: 是否启用搜索
  - `google_search_api_key`: API Key
  - `google_search_engine_id`: Search Engine ID
  - `google_search_provider`: 搜索提供商类型
  - `google_search_result_count`: 默认结果数量

### 验证逻辑
- API Key 格式验证
- Search Engine ID 格式验证
- 网络连接测试
- 配额检查

## 错误处理

### 常见错误场景
1. **网络错误**: 显示友好的错误提示
2. **API 配额耗尽**: 提示用户升级配额或等待
3. **无效配置**: 引导用户检查设置
4. **搜索无结果**: 显示无结果提示

### 错误码映射
- `429`: 配额限制
- `403`: 权限错误
- `400`: 参数错误
- `500`: 服务器错误

## 性能优化

### 缓存策略
- **搜索结果缓存**: 缓存最近 100 个搜索
- **缓存时间**: 5 分钟 TTL
- **缓存键**: 基于查询字符串和内容哈希

### 请求优化
- **批量请求**: 支持批量搜索查询
- **分页加载**: 支持搜索结果分页
- **超时设置**: 10 秒请求超时

## 测试策略

### 单元测试
- SearchService 测试
- 数据模型测试
- 错误处理测试

### 集成测试
- 端到端搜索流程
- 设置界面交互
- 聊天界面集成

### 性能测试
- 并发搜索测试
- 内存使用测试
- 网络超时测试

## 安全考虑

### 数据保护
- API Key 加密存储
- 不记录用户搜索历史
- HTTPS 强制使用

### 内容过滤
- 成人内容过滤
- 恶意网站检测
- 结果安全验证

## 部署步骤

1. **代码实现**: 按照设计文档实现所有功能
2. **本地测试**: 功能测试和性能测试
3. **用户配置**: 提供设置指南
4. **文档更新**: 更新用户手册和开发文档
5. **灰度发布**: 小范围用户测试

## 后续扩展

### 功能增强
- 支持更多搜索引擎（Bing、DuckDuckGo）
- 高级搜索语法支持
- 搜索结果 AI 摘要
- 多语言搜索支持

### 集成扩展
- 与现有 AI 服务深度集成
- 搜索结果作为 AI 上下文
- 智能搜索建议
- 语音搜索支持