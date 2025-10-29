# SettingsProvider 重构 - 快速参考卡

## 📚 新提供者一览表

### ApiKeyProvider
```dart
// 获取 API Key
apiKeys.openaiApiKey          // OpenAI Key
apiKeys.claudeApiKey          // Claude Key
apiKeys.googleApiKey          // Google/Gemini Key
apiKeys.fluxKontextApiKey     // FLUX Kontext Key
apiKeys.tavilyApiKey          // Tavily Key
apiKeys.getApiKeyForProvider('OpenAI') // 按提供商获取

// 设置 API Key
await apiKeys.setOpenaiApiKey('key');
await apiKeys.setClaudeApiKey('key');
// ... 其他 setter

// 验证
apiKeys.hasApiKeyForProvider('OpenAI')
apiKeys.hasAllRequiredKeys

// 导入导出
apiKeys.toMap()
await apiKeys.fromMap(data)
```

### ChatModelProvider
```dart
// 获取当前配置
chatModel.selectedProvider          // 'OpenAI', 'Google', 'Anthropic'
chatModel.selectedModel             // 选定的模型
chatModel.availableModels           // 当前提供商的可用模型列表
chatModel.allProviderNames          // 所有提供商
chatModel.providerUrl               // 提供商 API URL
chatModel.customModels              // 自定义模型列表

// 设置模型和提供商
await chatModel.setSelectedProvider('Google');
await chatModel.setSelectedModel('gemini-2.0-flash');
await chatModel.setProviderUrl('https://custom-url.com');

// 自定义模型管理
await chatModel.addCustomModel('my-custom-model');
await chatModel.removeCustomModel('my-custom-model');

// 自定义提供商
await chatModel.addCustomProvider('MyProvider', ['model1', 'model2']);
await chatModel.removeCustomProvider('MyProvider');

// 同步到模型注册表
await chatModel.syncModelsToRegistry();

// 导入导出
chatModel.toMap()
await chatModel.fromMap(data)
```

### ImageModelProvider
```dart
// 获取当前配置
imageModel.selectedImageProvider    // 图像提供商
imageModel.selectedImageModel       // 图像模型
imageModel.availableImageModels     // 可用的图像模型
imageModel.allImageProviderNames    // 所有图像提供商
imageModel.imageProviderUrl         // 图像提供商 URL
imageModel.bflAspectRatio           // BFL 宽高比设置
imageModel.selectedModelType        // 选定的模型类型

// 设置
await imageModel.setSelectedImageProvider('Black Forest Labs');
await imageModel.setSelectedImageModel('flux-kontext-pro');
await imageModel.setImageProviderUrl('https://custom-url.com');
await imageModel.setBflAspectRatio('21:9');
await imageModel.setSelectedModelType(ModelType.image);

// 自定义模型
await imageModel.addCustomImageModel('custom-img-model');
await imageModel.removeCustomImageModel('custom-img-model');

// 自定义提供商
await imageModel.addCustomImageProvider('MyImageProvider', ['model1']);
await imageModel.removeCustomImageProvider('MyImageProvider');

// 导入导出
imageModel.toMap()
await imageModel.fromMap(data)
```

### VideoModelProvider
```dart
// 获取当前配置
videoModel.selectedVideoProvider    // 'Google Veo3'
videoModel.videoResolution          // '720p', '480p', '1080p'
videoModel.videoDuration            // '5s', '10s', '30s'
videoModel.videoQuality             // 'draft', 'standard', 'high'
videoModel.videoAspectRatio         // '16:9', '9:16', '1:1', etc.

// 设置（只接受支持的值）
await videoModel.setVideoResolution('1080p');
await videoModel.setVideoDuration('30s');
await videoModel.setVideoQuality('high');
await videoModel.setVideoAspectRatio('9:16');

// 验证
videoModel.isValidResolution('1080p')
videoModel.isValidDuration('10s')
videoModel.isValidQuality('standard')
videoModel.isValidAspectRatio('16:9')

// 查看支持的选项
VideoModelProvider.supportedResolutions    // ['480p', '720p', '1080p']
VideoModelProvider.supportedDurations      // ['5s', '10s', '30s']
VideoModelProvider.supportedQualities      // ['draft', 'standard', 'high']
VideoModelProvider.supportedAspectRatios   // ['16:9', '9:16', '1:1', ...]

// 导入导出
videoModel.toMap()
await videoModel.fromMap(data)
```

### SearchProvider
```dart
// Google Search 配置
search.googleSearchApiKey           // Google Search API Key
search.googleSearchEngineId         // Google Search Engine ID
search.googleSearchEnabled          // 是否启用
search.googleSearchResultCount      // 搜索结果数量（1-100）
search.googleSearchProvider         // 搜索提供商类型

// Google Search 设置
await search.setGoogleSearchApiKey('key');
await search.setGoogleSearchEngineId('id');
await search.setGoogleSearchEnabled(true);
await search.setGoogleSearchResultCount(20);

// Tavily Search 配置
search.tavilyApiKey                 // Tavily API Key
search.tavilySearchEnabled          // 是否启用

// Tavily Search 设置
await search.setTavilyApiKey('key');
await search.setTavilySearchEnabled(true);

// 验证
search.isGoogleSearchConfigured()   // 检查 Google Search 是否完全配置
search.isTavilySearchConfigured()   // 检查 Tavily 是否完全配置
search.hasSearchEngineConfigured    // 是否至少配置了一个搜索引擎
search.activeSearchProvider         // 获取当前活跃的搜索提供商

// 导入导出
search.toMap()
await search.fromMap(data)
```

### UnifiedSettingsProvider（向后兼容层）
```dart
// 访问所有功能（向后兼容）
settings.apiKey                     // OpenAI API Key
settings.selectedModel              // 选定的聊天模型
settings.selectedImageProvider      // 选定的图像提供商
settings.videoResolution            // 视频分辨率
settings.googleSearchEnabled        // Google Search 是否启用

// 全局导入导出
final exported = await settings.exportSettings();
await settings.importSettings(exported);
```

---

## 🎯 使用场景快速查找

### "我想设置 OpenAI API Key"
```dart
final apiKeys = Provider.of<ApiKeyProvider>(context, listen: false);
await apiKeys.setOpenaiApiKey(userInput);
```

### "我想切换到 Google Gemini 模型"
```dart
final chatModel = Provider.of<ChatModelProvider>(context, listen: false);
await chatModel.setSelectedProvider('Google');
await chatModel.setSelectedModel('gemini-2.0-flash');
```

### "我想生成 1080p 的视频"
```dart
final videoModel = Provider.of<VideoModelProvider>(context, listen: false);
await videoModel.setVideoResolution('1080p');
```

### "我想启用 Google Search"
```dart
final search = Provider.of<SearchProvider>(context, listen: false);
await search.setGoogleSearchApiKey(apiKey);
await search.setGoogleSearchEngineId(engineId);
await search.setGoogleSearchEnabled(true);
```

### "我想在 Widget 中显示可用的模型"
```dart
Consumer<ChatModelProvider>(
  builder: (context, chatModel, _) => DropdownButton(
    items: chatModel.availableModels
        .map((model) => DropdownMenuItem(
          value: model,
          child: Text(model),
        ))
        .toList(),
    onChanged: (value) => chatModel.setSelectedModel(value),
  ),
)
```

### "我想备份和恢复设置"
```dart
// 导出设置
final settings = Provider.of<UnifiedSettingsProvider>(context, listen: false);
final exported = await settings.exportSettings();
final xml = SettingsXmlHandler.exportToXml(exported);

// 导入设置
final loaded = SettingsXmlHandler.importFromXml(xmlContent);
await settings.importSettings(loaded);
```

---

## 🔄 迁移对照表

### 旧 API → 新 API

| 旧代码 | 新代码 | 提供者 |
|-------|-------|-------|
| `settings.apiKey` | `apiKeys.openaiApiKey` | ApiKeyProvider |
| `settings.setApiKey()` | `apiKeys.setOpenaiApiKey()` | ApiKeyProvider |
| `settings.selectedModel` | `chatModel.selectedModel` | ChatModelProvider |
| `settings.setSelectedModel()` | `chatModel.setSelectedModel()` | ChatModelProvider |
| `settings.selectedProvider` | `chatModel.selectedProvider` | ChatModelProvider |
| `settings.setSelectedProvider()` | `chatModel.setSelectedProvider()` | ChatModelProvider |
| `settings.selectedImageModel` | `imageModel.selectedImageModel` | ImageModelProvider |
| `settings.setSelectedImageModel()` | `imageModel.setSelectedImageModel()` | ImageModelProvider |
| `settings.videoResolution` | `videoModel.videoResolution` | VideoModelProvider |
| `settings.setVideoResolution()` | `videoModel.setVideoResolution()` | VideoModelProvider |
| `settings.googleSearchEnabled` | `search.googleSearchEnabled` | SearchProvider |
| `settings.setGoogleSearchEnabled()` | `search.setGoogleSearchEnabled()` | SearchProvider |

---

## 📦 导入清单

```dart
// API Key 管理
import 'package:chibot/providers/api_key_provider.dart';

// 聊天模型配置
import 'package:chibot/providers/chat_model_provider.dart';

// 图像生成配置
import 'package:chibot/providers/image_model_provider.dart';

// 视频生成配置
import 'package:chibot/providers/video_model_provider.dart';

// 搜索配置
import 'package:chibot/providers/search_provider.dart';

// 向后兼容聚合层（可选）
import 'package:chibot/providers/unified_settings_provider.dart';
```

---

## ✅ 常见操作速查

```dart
// 获取当前 API Key
final apiKey = apiKeys.openaiApiKey;

// 检查是否配置了 API Key
if (apiKeys.openaiApiKey != null) { ... }

// 获取可用的模型列表
final models = chatModel.availableModels;

// 检查特定模型是否可用
if (chatModel.availableModels.contains('gpt-4')) { ... }

// 订阅模型变化
Consumer<ChatModelProvider>(
  builder: (context, chatModel, _) { ... }
)

// 订阅多个提供者
Consumer2<ChatModelProvider, ApiKeyProvider>(
  builder: (context, chatModel, apiKeys, _) { ... }
)

// 验证配置完整性
if (apiKeys.hasAllRequiredKeys && chatModel.selectedModel.isNotEmpty) {
  // 可以开始使用
}
```

---

**打印此卡片以便快速参考！** 📌
