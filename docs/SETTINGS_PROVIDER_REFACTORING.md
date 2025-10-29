# SettingsProvider 分解迁移指南

## 概述

原 `SettingsProvider`（1269 行）已被分解为 5 个专职提供者，大幅改进了代码的可维护性和测试性。

## 新的架构

```
SettingsProvider (1269 行，已分解)
│
├── ApiKeyProvider (170 行)
│   └── 管理所有 API 密钥
│       ├── OpenAI
│       ├── Claude
│       ├── Google
│       ├── FLUX Kontext
│       ├── Tavily
│       └── Google Search
│
├── ChatModelProvider (285 行)
│   └── 聊天模型配置
│       ├── 选定的提供商和模型
│       ├── 自定义提供商和模型
│       ├── 提供商 URL 配置
│       └── 模型注册
│
├── ImageModelProvider (280 行)
│   └── 图像生成配置
│       ├── 选定的提供商和模型
│       ├── 自定义提供商和模型
│       ├── BFL Aspect Ratio
│       └── 模型类型选择
│
├── VideoModelProvider (170 行)
│   └── 视频生成配置
│       ├── 提供商选择
│       ├── 分辨率、时长、质量
│       └── 宽高比设置
│
└── SearchProvider (250 行)
    └── 搜索引擎配置
        ├── Google Search (API Key、Engine ID、设置)
        └── Tavily (API Key、启用开关)
```

## 迁移策略

### 第 1 阶段：使用 UnifiedSettingsProvider（即时兼容）

对于现有代码，使用 `UnifiedSettingsProvider` 作为过渡层，零改动：

```dart
// main.dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => ApiKeyProvider()),
    ChangeNotifierProvider(create: (_) => ChatModelProvider()),
    ChangeNotifierProvider(create: (_) => ImageModelProvider()),
    ChangeNotifierProvider(create: (_) => VideoModelProvider()),
    ChangeNotifierProvider(create: (_) => SearchProvider()),
    // 向后兼容层
    ChangeNotifierProxyProvider5<
        ApiKeyProvider,
        ChatModelProvider,
        ImageModelProvider,
        VideoModelProvider,
        SearchProvider,
        UnifiedSettingsProvider>(
      create: (_) => throw UnimplementedError(),
      update: (_, apiKeys, chatModel, imageModel, videoModel, search, __) =>
          UnifiedSettingsProvider(
            apiKeyProvider: apiKeys,
            chatModelProvider: chatModel,
            imageModelProvider: imageModel,
            videoModelProvider: videoModel,
            searchProvider: search,
          ),
    ),
  ],
  // ...
)
```

### 第 2 阶段：逐步迁移代码

#### 示例 1：迁移 API Key 获取

**迁移前：**
```dart
final settings = Provider.of<SettingsProvider>(context);
final apiKey = settings.apiKey;
```

**迁移后（选项 A - 使用聚合层）：**
```dart
final settings = Provider.of<UnifiedSettingsProvider>(context);
final apiKey = settings.apiKey;
```

**迁移后（选项 B - 直接使用专职提供者，推荐）：**
```dart
final apiKeys = Provider.of<ApiKeyProvider>(context);
final apiKey = apiKeys.openaiApiKey;
```

#### 示例 2：迁移聊天模型选择

**迁移前：**
```dart
final settings = Provider.of<SettingsProvider>(context, listen: false);
await settings.setSelectedProvider('Google');
await settings.setSelectedModel('gemini-2.0-flash');
```

**迁移后：**
```dart
final chatModel = Provider.of<ChatModelProvider>(context, listen: false);
await chatModel.setSelectedProvider('Google');
await chatModel.setSelectedModel('gemini-2.0-flash');
```

#### 示例 3：迁移图像生成配置

**迁移前：**
```dart
final settings = Provider.of<SettingsProvider>(context);
final imageModel = settings.selectedImageModel;
final provider = settings.selectedImageProvider;
```

**迁移后：**
```dart
final imageModel = Provider.of<ImageModelProvider>(context);
final model = imageModel.selectedImageModel;
final provider = imageModel.selectedImageProvider;
```

## 迁移清单

### 第 1 步：更新 main.dart

- [ ] 添加 5 个新提供者的 `ChangeNotifierProvider`
- [ ] 添加 `UnifiedSettingsProvider` 的聚合
- [ ] 暂时保留旧 `SettingsProvider` 的导入（可选）

### 第 2 步：迁移高优先级文件

优先迁移以下文件（它们最常使用 SettingsProvider）：

1. [ ] `lib/services/chat_service_factory.dart` - 使用 `ChatModelProvider` + `ApiKeyProvider`
2. [ ] `lib/services/service_manager.dart` - 使用 `ChatModelProvider` + `ApiKeyProvider`
3. [ ] `lib/screens/chat_screen.dart` - 使用各专职提供者
4. [ ] `lib/screens/settings_screen.dart` - 使用各专职提供者

### 第 3 步：迁移中优先级文件

- [ ] `lib/services/image_generation_service.dart`
- [ ] `lib/screens/video_generation_screen.dart`

### 第 4 步：最后，移除旧 SettingsProvider

- [ ] 确认所有导入已更新
- [ ] 删除 `lib/providers/settings_provider.dart`
- [ ] 删除 `lib/providers/unified_settings_provider.dart`（如果不再需要）

## 具体迁移示例

### 例 1：在服务中迁移

**before/openai_chat_service.dart（使用 SettingsProvider）**
```dart
class OpenaiChatService extends BaseApiService {
  final SettingsProvider settings;

  OpenaiChatService(this.settings);

  @override
  String getApiKey() => settings.apiKey!;
}
```

**after/openai_chat_service.dart（使用 ApiKeyProvider）**
```dart
class OpenaiChatService extends BaseApiService {
  final ApiKeyProvider apiKeys;

  OpenaiChatService(this.apiKeys);

  @override
  String getApiKey() => apiKeys.openaiApiKey!;
}
```

### 例 2：在 UI 中迁移

**before/settings_screen.dart**
```dart
class SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return Column(
          children: [
            // API Keys
            TextFormField(
              initialValue: settings.apiKey,
              onChanged: (value) => settings.setApiKey(value),
            ),
            // Chat Model
            DropdownButton(
              value: settings.selectedModel,
              onChanged: (value) => settings.setSelectedModel(value),
              items: settings.availableModels.map(...).toList(),
            ),
          ],
        );
      },
    );
  }
}
```

**after/settings_screen.dart（分离关注点）**
```dart
class SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // API Keys 部分
        Consumer<ApiKeyProvider>(
          builder: (context, apiKeys, _) => TextFormField(
            initialValue: apiKeys.openaiApiKey,
            onChanged: (value) => apiKeys.setOpenaiApiKey(value),
          ),
        ),
        // Chat Model 部分
        Consumer<ChatModelProvider>(
          builder: (context, chatModel, _) => DropdownButton(
            value: chatModel.selectedModel,
            onChanged: (value) => chatModel.setSelectedModel(value),
            items: chatModel.availableModels.map(...).toList(),
          ),
        ),
        // Image Model 部分
        Consumer<ImageModelProvider>(
          builder: (context, imageModel, _) => DropdownButton(
            value: imageModel.selectedImageModel,
            onChanged: (value) => imageModel.setSelectedImageModel(value),
            items: imageModel.availableImageModels.map(...).toList(),
          ),
        ),
      ],
    );
  }
}
```

## 关键改进

### 1. 单一职责原则 (SRP)

| 提供者 | 职责 | 测试难度 |
|-------|------|--------|
| SettingsProvider | 什么都做（1269 行） | 极高 |
| ApiKeyProvider | 仅管理 API 密钥 | 低 |
| ChatModelProvider | 仅管理聊天模型 | 低 |
| ImageModelProvider | 仅管理图像配置 | 低 |
| VideoModelProvider | 仅管理视频配置 | 低 |
| SearchProvider | 仅管理搜索配置 | 低 |

### 2. 测试性改进

**测试聊天模型选择（迁移前）：**
```dart
test('select chat model', () async {
  // 需要初始化整个 SettingsProvider（1269 行代码）
  final settings = SettingsProvider();
  // ... 需要 mock 所有依赖
});
```

**测试聊天模型选择（迁移后）：**
```dart
test('select chat model', () async {
  // 仅初始化 ChatModelProvider（285 行代码）
  final chatModel = ChatModelProvider();
  await chatModel.setSelectedModel('gpt-4');
  expect(chatModel.selectedModel, equals('gpt-4'));
});
```

### 3. 代码重用

每个提供者都暴露了标准的导入/导出接口：

```dart
// 导出设置
final settings = {
  'apiKeys': apiKeyProvider.toMap(),
  'chatModel': chatModelProvider.toMap(),
  // ...
};
await saveToXml(settings);

// 导入设置
final loaded = await loadFromXml();
await apiKeyProvider.fromMap(loaded['apiKeys']);
await chatModelProvider.fromMap(loaded['chatModel']);
```

## 依赖关系

### 无循环依赖

```
Main (Provider 配置)
  ├─> ApiKeyProvider ✓ (独立)
  ├─> ChatModelProvider ✓ (依赖 ModelRegistry)
  ├─> ImageModelProvider ✓ (依赖 ModelType enum)
  ├─> VideoModelProvider ✓ (独立)
  ├─> SearchProvider ✓ (独立)
  └─> UnifiedSettingsProvider (聚合上述 5 个)
```

### 向后兼容

`UnifiedSettingsProvider` 提供与旧 `SettingsProvider` 相同的 API，允许：
- 零改动的即时使用
- 逐步迁移
- 渐进式的代码修改

## 常见问题

### Q1：我需要立即迁移所有代码吗？

**答：** 不需要。使用 `UnifiedSettingsProvider` 作为过渡层，你可以逐个文件迁移。

### Q2：性能会受影响吗？

**答：** 不会。实际上会改善：
- 更少的不必要的重建（只订阅需要的提供者）
- 更小的 Provider 消息范围

### Q3：如何处理需要多个提供者的页面？

**答：** 使用 `Consumer2`, `Consumer3` 等：

```dart
Consumer2<ChatModelProvider, ImageModelProvider>(
  builder: (context, chatModel, imageModel, _) => ...
)
```

## 下一步

1. **立即**：更新 `main.dart`，添加新提供者
2. **这周**：迁移 `ChatServiceFactory` 和 `ServiceManager`
3. **下周**：迁移 UI 层（`ChatScreen`, `SettingsScreen`）
4. **最后**：删除旧的 `SettingsProvider`

## 支持和问题

如有问题，参考各提供者的文档注释：

```dart
/// 负责管理所有 API 密钥的提供者
/// 职责：存储、加载、更新各个 AI 服务的 API 密钥
class ApiKeyProvider with ChangeNotifier {
  // 详细的方法文档
}
```

每个提供者都有：
- 完整的方法文档
- 导入/导出支持
- 便利方法和验证方法
- 清晰的职责边界
