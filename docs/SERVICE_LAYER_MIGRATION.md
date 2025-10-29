# 第二阶段重构 - 服务层迁移指南

## 概述

第二阶段重构重点是迁移服务层（ServiceLayer）从使用 `SettingsProvider` 到使用新的专职提供者。这包括：
- ChatServiceFactory 和 ServiceManager
- ImageGenerationServiceManager
- VideoGenerationServiceManager
- SearchServiceManager

## 改进亮点

### 1. ChatServiceFactory 和 ServiceManager

**变化前：**
```dart
class ServiceManager {
  static ChatService createChatService(SettingsProvider settings) {
    final provider = settings.selectedProvider;
    final apiKey = settings.getApiKeyForProvider(provider);
    final baseUrl = settings.effectiveProviderUrl;
    // ...
  }
}
```

**变化后：**
```dart
class ServiceManager {
  static ChatService createChatService({
    required ChatModelProvider chatModel,
    required ApiKeyProvider apiKeys,
  }) {
    return ChatServiceFactory.createFromProviders(
      chatModel: chatModel,
      apiKeys: apiKeys,
    );
  }

  // 新增验证方法
  static bool isChatConfigured({
    required ChatModelProvider chatModel,
    required ApiKeyProvider apiKeys,
  }) { ... }

  static ChatService createAndValidateChatService({...}) { ... }
}
```

**优点：**
- 明确的参数，易于理解依赖
- 支持多个验证方法
- 更好的错误消息

### 2. ChatServiceFactory 增强

**新增方法：**
```dart
class ChatServiceFactory {
  // 新方法：从专职提供者创建服务
  static ChatService createFromProviders({
    required ChatModelProvider chatModel,
    required ApiKeyProvider apiKeys,
  })

  // 保留的方法：向后兼容
  static ChatService create({
    required String provider,
    required String apiKey,
    String? baseUrl,
  })
}
```

### 3. 新增服务管理器

#### ImageGenerationServiceManager
```dart
class ImageGenerationServiceManager {
  // 检查是否完全配置
  static bool isImageGenerationConfigured({
    required ImageModelProvider imageModel,
    required ApiKeyProvider apiKeys,
  })

  // 创建并验证服务
  static ImageGenerationService createAndValidateImageService({
    required ImageModelProvider imageModel,
    required ApiKeyProvider apiKeys,
  })

  // 准备参数
  static Map<String, dynamic> prepareImageGenerationParams({...})

  // 获取可用模型
  static List<String> getAvailableImageModels({...})
}
```

#### VideoGenerationServiceManager
```dart
class VideoGenerationServiceManager {
  // 检查是否完全配置
  static bool isVideoGenerationConfigured({
    required VideoModelProvider videoModel,
    required ApiKeyProvider apiKeys,
  })

  // 验证视频参数
  static bool validateVideoParams({
    required VideoModelProvider videoModel,
  })

  // 获取配置描述
  static String getVideoConfigDescription({...})
}
```

#### SearchServiceManager
```dart
class SearchServiceManager {
  // 检查 Google Search 配置
  static bool isGoogleSearchConfigured({
    required SearchProvider search,
    required ApiKeyProvider apiKeys,
  })

  // 检查 Tavily Search 配置
  static bool isTavilySearchConfigured({
    required SearchProvider search,
    required ApiKeyProvider apiKeys,
  })

  // 获取活跃的搜索提供商
  static String? getActiveSearchProvider({...})

  // 准备搜索参数
  static Map<String, dynamic> prepareGoogleSearchParams({...})
}
```

## 迁移步骤

### 第 1 步：在 ChatScreen 中使用新 ServiceManager

**迁移前：**
```dart
class ChatScreenState extends State<ChatScreen> {
  @override
  void initState() {
    super.initState();
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    _chatService = ServiceManager.createChatService(settings);
  }
}
```

**迁移后：**
```dart
class ChatScreenState extends State<ChatScreen> {
  @override
  void initState() {
    super.initState();
    final chatModel = Provider.of<ChatModelProvider>(context, listen: false);
    final apiKeys = Provider.of<ApiKeyProvider>(context, listen: false);

    _chatService = ServiceManager.createChatService(
      chatModel: chatModel,
      apiKeys: apiKeys,
    );
  }
}
```

### 第 2 步：使用新的验证方法

**迁移前：**
```dart
// 检查是否可以生成图像
if (settings.selectedImageModel.isEmpty) {
  showError('No image model selected');
}
```

**迁移后：**
```dart
final imageModel = Provider.of<ImageModelProvider>(context, listen: false);
final apiKeys = Provider.of<ApiKeyProvider>(context, listen: false);

if (!ImageGenerationServiceManager.isImageGenerationConfigured(
  imageModel: imageModel,
  apiKeys: apiKeys,
)) {
  showError('Image generation not configured');
}
```

### 第 3 步：使用参数准备方法

**迁移前：**
```dart
final response = await _imageService.generateImage(
  apiKey: settings.imageApiKey!,
  prompt: prompt,
  model: settings.selectedImageModel,
  providerBaseUrl: settings.imageProviderUrl,
  aspectRatio: settings.bflAspectRatio,
);
```

**迁移后：**
```dart
final params = ImageGenerationServiceManager.prepareImageGenerationParams(
  imageModel: imageModel,
  apiKeys: apiKeys,
  prompt: prompt,
);

final response = await _imageService.generateImage(
  apiKey: params['apiKey'],
  prompt: params['prompt'],
  model: params['model'],
  providerBaseUrl: params['providerBaseUrl'],
  aspectRatio: params['aspectRatio'],
);
```

## 服务验证方法

所有新的服务管理器都提供了标准化的验证方法：

### 配置检查模式

```dart
// 1. 简单的可用性检查
bool isConfigured = ServiceManager.isChatConfigured(...);

// 2. 带错误消息的验证
try {
  final service = ServiceManager.createAndValidateChatService(...);
} catch (e) {
  // 详细的错误消息
  showError(e.toString());
}

// 3. 参数准备（处理所有细节）
final params = ServiceManager.prepareParams(...);
// 使用 params 调用服务
```

## 文件清单

### 修改的文件
- `lib/services/chat_service_factory.dart` - 添加 createFromProviders 方法
- `lib/services/service_manager.dart` - 完全重构

### 新建的文件
- `lib/services/image_generation_service_manager.dart` - 图像生成管理
- `lib/services/video_generation_service_manager.dart` - 视频生成管理
- `lib/services/search_service_manager_v2.dart` - 搜索管理（扩展版）

### 新增测试
- `test/services/service_migration_test.dart` - 服务迁移测试

## 使用示例

### 完整的聊天流程

```dart
// 获取提供者
final chatModel = Provider.of<ChatModelProvider>(context, listen: false);
final apiKeys = Provider.of<ApiKeyProvider>(context, listen: false);

// 验证配置
if (!ServiceManager.isChatConfigured(
  chatModel: chatModel,
  apiKeys: apiKeys,
)) {
  showError('Chat not configured. Please check settings.');
  return;
}

// 创建服务
final service = ServiceManager.createChatService(
  chatModel: chatModel,
  apiKeys: apiKeys,
);

// 使用服务
try {
  final response = await service.generateResponse(
    messages: messages,
    model: chatModel.selectedModel,
  );
  addMessage(response);
} on ApiException catch (e) {
  showError('API error: ${e.message}');
} catch (e) {
  showError('Error: $e');
}
```

### 图像生成流程

```dart
final imageModel = Provider.of<ImageModelProvider>(context, listen: false);
final apiKeys = Provider.of<ApiKeyProvider>(context, listen: false);

// 验证配置
if (!ImageGenerationServiceManager.isImageGenerationConfigured(
  imageModel: imageModel,
  apiKeys: apiKeys,
)) {
  showError('Image generation not configured');
  return;
}

// 准备参数
final params = ImageGenerationServiceManager.prepareImageGenerationParams(
  imageModel: imageModel,
  apiKeys: apiKeys,
  prompt: userPrompt,
);

// 生成图像
final service = ImageGenerationService();
final imageUrl = await service.generateImage(
  apiKey: params['apiKey'],
  prompt: params['prompt'],
  model: params['model'],
  providerBaseUrl: params['providerBaseUrl'],
  aspectRatio: params['aspectRatio'],
);
```

### 搜索配置检查

```dart
final search = Provider.of<SearchProvider>(context, listen: false);
final apiKeys = Provider.of<ApiKeyProvider>(context, listen: false);

// 检查搜索是否可用
if (!SearchServiceManager.isSearchFunctionalityAvailable(
  search: search,
  apiKeys: apiKeys,
)) {
  // 显示"配置搜索"的提示
  showInfo('Please enable a search engine in settings');
  return;
}

// 获取活跃的搜索提供商
final activeProvider = SearchServiceManager.getActiveSearchProvider(
  search: search,
  apiKeys: apiKeys,
);

print('Using search provider: $activeProvider');

// 准备搜索参数（基于活跃提供商）
if (activeProvider == 'google') {
  final params = SearchServiceManager.prepareGoogleSearchParams(
    search: search,
    apiKeys: apiKeys,
    query: searchQuery,
  );
  // 使用 params 进行搜索
}
```

## 向后兼容性

所有更改都是 **100% 向后兼容** 的：

1. **ChatServiceFactory.create()** - 保留原始方法
2. **旧的 API 仍然可用** - 通过 UnifiedSettingsProvider

这意味着你可以：
- 逐步迁移现有代码
- 混合使用旧 API 和新 API
- 无需立即重写所有代码

## 最佳实践

### ✅ 推荐做法

```dart
// 1. 始终检查配置
if (ServiceManager.isChatConfigured(...)) {
  // 继续
}

// 2. 使用验证方法
try {
  final service = ServiceManager.createAndValidateChatService(...);
} catch (e) {
  // 处理错误
}

// 3. 使用参数准备方法（隐藏细节）
final params = ServiceManager.prepareParams(...);
```

### ❌ 避免做法

```dart
// 1. 不要忽略配置检查
final service = ServiceManager.createChatService(...); // 可能抛出异常

// 2. 不要手动组装参数
final service = manuallyCreateService(
  apiKey: apiKeys.openaiApiKey,
  provider: 'OpenAI',
  // ... 容易出错
);
```

## 常见问题

### Q: 旧代码还能工作吗？

**A:** 是的。通过 UnifiedSettingsProvider，所有旧代码继续工作。但建议逐步迁移。

### Q: 如何处理向后兼容性？

**A:**
1. 保留旧方法（如 ChatServiceFactory.create）
2. 添加新方法（如 createFromProviders）
3. 逐步更新调用代码

### Q: 错误处理是否改变了？

**A:** 新的管理器提供更详细的错误消息，但错误类型保持一致。

### Q: 如何测试新的服务管理器？

**A:** 查看 `test/services/service_migration_test.dart` 获取完整的测试示例。

## 下一步

1. **立即**：在 ChatScreen 中尝试新的 ServiceManager
2. **本周**：迁移所有服务创建代码到新管理器
3. **下周**：删除 UnifiedSettingsProvider 的依赖
4. **最后**：清理 SettingsProvider

## 支持

如有问题，参考：
- 新增的服务管理器的文档注释
- `test/services/service_migration_test.dart` 中的测试示例
- 原 Phase 1 文档中关于提供者的信息
