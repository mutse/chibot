# FLUX.1 Kontext 使用指南

## 快速开始

### 1. 获取 API Key

1. 访问 [Black Forest Labs](https://api.bfl.ml)
2. 注册账号并获取 API Key
3. 在应用设置中配置 FLUX.1 Kontext

### 2. 配置应用

#### 方法一：通过设置界面
1. 打开应用设置
2. 选择 "图像模型"
3. 选择 "FLUX.1 Kontext" 作为提供商
4. 输入你的 API Key
5. 选择模型（flux-kontext-pro 或 flux-kontext-dev）

#### 方法二：通过代码配置

```dart
// 在设置 Provider 中配置
final settings = Provider.of<SettingsProvider>(context, listen: false);
settings.setSelectedImageProvider('FLUX.1 Kontext');
settings.setSelectedImageModel('flux-kontext-pro');
settings.setImageApiKey('your-flux-api-key');
```

### 3. 使用示例

#### 生成图像

```dart
import 'package:chibot/services/flux_image_service.dart';

// 创建服务
final fluxService = FluxKontextImageService(apiKey: 'your-api-key');

// 文本到图像
final imageUrl = await fluxService.generateImage(
  prompt: 'a beautiful landscape with mountains and lake',
  aspectRatio: '16:9',
  seed: 12345, // 可选，用于复现
);

// 图像到图像编辑
final editedUrl = await fluxService.editImage(
  prompt: 'add a sunset to this landscape',
  imageUrl: 'https://example.com/original.jpg',
  strength: 0.7, // 参考图保留强度
  guidanceScale: 2.5, // 文本贴合度
);
```

#### 使用通用图像服务

```dart
import 'package:chibot/services/image_generation_service.dart';

final service = ImageGenerationService();

// 使用 FLUX.1 Kontext
final imageUrl = await service.generateImage(
  apiKey: 'your-flux-api-key',
  prompt: 'a cyberpunk city at night',
  model: 'flux-kontext-pro',
  providerBaseUrl: 'https://api.bfl.ml/v1',
  openAISize: '1024x1024',
);
```

## 高级配置

### 参数说明

| 参数 | 类型 | 说明 | 默认值 |
|---|---|---|---|
| `prompt` | String | 图像描述文本 | 必填 |
| `aspectRatio` | String | 宽高比 (1:1, 16:9, 9:16, 21:9, 4:3, 3:4, 5:4, 4:5) | 1:1 |
| `seed` | int | 随机种子，用于复现结果 | null |
| `outputFormat` | String | 输出格式 (png, jpeg) | png |
| `safetyTolerance` | int | 安全容忍度 (0-6) | null |
| `strength` | double | 图像编辑强度 (0-1) | 0.8 |
| `guidanceScale` | double | 文本引导强度 (1-10) | 2.5 |

### 错误处理

```dart
try {
  final imageUrl = await fluxService.generateImage(
    prompt: 'your prompt',
    aspectRatio: '16:9',
  );
  print('Generated image: $imageUrl');
} catch (e) {
  if (e.toString().contains('FLUX.1 Kontext API error')) {
    print('API Error: $e');
  } else if (e.toString().contains('timed out')) {
    print('Request timed out');
  } else {
    print('Unknown error: $e');
  }
}
```

### 测试连接

```dart
final service = FluxKontextImageService(apiKey: 'your-api-key');
final isConnected = await service.testConnection();
print('FLUX.1 connection: $isConnected');
```

## 使用场景示例

### 1. 创意内容生成
```dart
final url = await fluxService.generateImage(
  prompt: 'a fantasy castle floating in the clouds, magical atmosphere, 4K',
  aspectRatio: '16:9',
  seed: 42,
);
```

### 2. 产品可视化
```dart
final url = await fluxService.generateImage(
  prompt: 'modern smartphone on clean white background, product photography style',
  aspectRatio: '1:1',
);
```

### 3. 图像编辑增强
```dart
final url = await fluxService.editImage(
  prompt: 'add golden hour lighting to this photo',
  imageUrl: 'https://example.com/photo.jpg',
  strength: 0.6,
);
```

## 性能优化建议

1. **缓存策略**: 缓存生成的图像 URL 以减少重复请求
2. **超时设置**: 合理设置 `maxWaitTime` 避免长时间等待
3. **错误重试**: 实现指数退避重试机制
4. **并发控制**: 限制同时进行的生成请求数量

## 故障排除

### 常见问题

| 问题 | 解决方案 |
|---|---|
| API Key 无效 | 检查 API Key 是否正确，确保有访问权限 |
| 请求超时 | 增加 `maxWaitTime` 或减少 `pollInterval` |
| 生成失败 | 检查提示词是否包含敏感内容 |
| 连接错误 | 验证网络连接和 API 端点 |

### 调试模式

```dart
// 启用详细日志
final service = FluxKontextImageService(apiKey: 'your-key');
// 所有服务调用都会打印详细日志到控制台
```

## 与现有系统集成

### 在聊天应用中使用

```dart
// 在 ChatScreen 中集成
Future<void> _generateImageFromPrompt(String prompt) async {
  final settings = Provider.of<SettingsProvider>(context, listen: false);
  
  if (settings.selectedImageProvider == 'FLUX.1 Kontext') {
    final service = FluxKontextImageService(apiKey: settings.imageApiKey!);
    
    try {
      final imageUrl = await service.generateImage(prompt: prompt);
      // 将生成的图像添加到聊天记录
      _addImageMessage(imageUrl);
    } catch (e) {
      _showError('图像生成失败: $e');
    }
  }
}
```

## 最佳实践

1. **提示词优化**：使用详细的描述性语言
2. **参数调整**：根据需求调整宽高比和种子值
3. **错误处理**：始终实现适当的错误处理
4. **用户体验**：显示进度指示器
5. **成本控制**：监控 API 调用频率

## 兼容性说明

- **最低 Flutter 版本**: 3.0.0
- **支持平台**: iOS, Android, Web, macOS
- **网络要求**: 需要互联网连接
- **API 限制**: 遵循 Black Forest Labs 的使用条款和速率限制