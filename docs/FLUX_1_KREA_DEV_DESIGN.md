# FLUX.1-Krea-dev 文生图功能设计文档

## 概述

本文档描述 FLUX.1-Krea-dev 文生图功能的设计与实现，该功能使用 Black Forest Labs (BFL) 的 FLUX.1-Krea-dev 模型提供高质量的 AI 图像生成服务。

## 系统架构

### 核心组件

```
┌─────────────────────────────────────────────────────────────┐
│                     ChatBot Flutter App                     │
├─────────────────────────────────────────────────────────────┤
│  UI Layer                                                   │
│  ├── ChatScreen (图像生成界面)                               │
│  ├── SettingsScreen (API密钥配置)                           │
│  └── Image Display Components                              │
├─────────────────────────────────────────────────────────────┤
│  Service Layer                                              │
│  ├── FluxKreaService (主要服务类)                           │
│  ├── ImageGenerationService (服务管理)                      │
│  └── ImageSessionService (会话管理)                         │
├─────────────────────────────────────────────────────────────┤
│  Model Layer                                                │
│  ├── FluxKreaRequest (请求模型)                             │
│  ├── FluxKreaResponse (响应模型)                            │
│  └── FluxKreaResult (结果模型)                              │
├─────────────────────────────────────────────────────────────┤
│  Base Layer                                                 │
│  └── BaseApiService (基础API服务)                           │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                Black Forest Labs API                        │
│  ├── POST /v1/flux-krea-dev (提交生成请求)                  │
│  └── GET /v1/get_result?id={request_id} (获取结果)          │
└─────────────────────────────────────────────────────────────┘
```

## 核心功能

### 1. 图像生成流程

#### 1.1 异步生成机制
FLUX.1-Krea-dev 采用异步生成模式：

1. **提交请求阶段**：
   - 向 `/v1/flux-krea-dev` 端点提交生成请求
   - 接收包含请求 ID 的响应
   - 状态通常为 `pending` 或 `processing`

2. **轮询结果阶段**：
   - 使用请求 ID 定期查询 `/v1/get_result` 端点
   - 检查生成状态和进度
   - 直到获得最终图像 URL

#### 1.2 请求参数支持

```dart
class FluxKreaRequest {
  final String prompt;              // 必需：文本提示词
  final String? aspectRatio;        // 可选：宽高比 (1:1, 16:9, 9:16)
  final int? seed;                  // 可选：随机种子
  final bool? promptUpsampling;     // 可选：提示词增强
  final int? safetyTolerance;       // 可选：安全容忍度
  final String? outputFormat;       // 可选：输出格式 (png, jpg)
  final String? image;              // 可选：编辑源图像 (Base64)
  final double? strength;           // 可选：编辑强度 (0.0-1.0)
  final double? guidanceScale;      // 可选：引导比例
}
```

### 2. 核心API方法

#### 2.1 基础图像生成
```dart
Future<String> generateImage({
  required String prompt,
  String? aspectRatio,
  int? seed,
  String? outputFormat = 'png',
  int? safetyTolerance,
  Duration maxWaitTime = const Duration(seconds: 60),
  Duration pollInterval = const Duration(seconds: 2),
})
```

#### 2.2 OpenAI兼容接口
```dart
Future<String> generateImageWithOpenAISize({
  required String prompt,
  required String openAISize,  // '1024x1024', '1792x1024', '1024x1792'
  String? outputFormat = 'png',
  int? safetyTolerance,
  Duration maxWaitTime = const Duration(seconds: 120),
  Duration pollInterval = const Duration(seconds: 2),
})
```

#### 2.3 图像编辑功能
```dart
Future<String> editImage({
  required String prompt,
  required String imageUrl,
  double? strength = 0.8,
  double? guidanceScale = 2.5,
  String? aspectRatio,
  Duration maxWaitTime = const Duration(seconds: 60),
  Duration pollInterval = const Duration(seconds: 2),
})
```

### 3. 轮询机制设计

#### 3.1 智能轮询策略
- **基础间隔**：2秒
- **最大等待时间**：60-120秒（可配置）
- **指数退避**：临时错误时采用指数退避重试
- **最大重试次数**：3次

#### 3.2 错误处理分类
```dart
// 立即停止的错误
- Task not found (404)
- Task failed/Error status
- Invalid or expired request ID

// 可重试的错误  
- Network timeouts
- Temporary server errors
- Rate limiting (429)
```

### 4. OpenAI尺寸映射

为了与现有的 OpenAI 图像生成接口保持兼容性，实现了尺寸映射：

```dart
OpenAI Size → FLUX Aspect Ratio
'1024x1024' → '1:1'    (正方形)
'1792x1024' → '16:9'   (横向)
'1024x1792' → '9:16'   (竖向)
```

## 技术实现细节

### 1. 服务继承结构

```dart
BaseApiService
    ├── 提供基础HTTP客户端功能
    ├── 统一错误处理机制
    ├── 重试逻辑支持
    └── 日志记录功能

FluxKreaService extends BaseApiService
    ├── FLUX.1-Krea-dev 特定实现
    ├── 异步轮询机制
    ├── BFL API 认证 (X-Key header)
    └── 响应格式解析
```

### 2. API端点配置

```dart
class FluxKreaService extends BaseApiService {
  FluxKreaService({required String apiKey})
    : super(baseUrl: 'https://api.bfl.ai', apiKey: apiKey);

  // 认证头部
  Map<String, String> getHeaders() {
    return {
      'Content-Type': 'application/json',
      'X-Key': apiKey,  // BFL特有的认证方式
    };
  }
}
```

### 3. 状态管理

#### 3.1 生成状态
- `pending`: 请求已提交，等待处理
- `processing`: 正在生成图像
- `Ready`: 图像生成完成，可获取URL
- `Error`: 生成失败
- `Task not found`: 任务不存在或已过期

#### 3.2 会话集成
- 通过 `ImageSessionService` 管理生成历史
- 与现有的图像会话系统无缝集成
- 支持会话持久化和恢复

### 4. 错误处理机制

#### 4.1 网络层错误
```dart
void validateResponse(http.Response response) {
  if (response.statusCode < 200 || response.statusCode >= 300) {
    String errorMessage = 'Request failed with status ${response.statusCode}';
    try {
      final errorBody = jsonDecode(response.body);
      errorMessage = errorBody['error']?['message'] ?? 
                    errorBody['message'] ?? 
                    errorMessage;
    } catch (_) {}
    throw Exception('FLUX.1 Krea API error: $errorMessage');
  }
}
```

#### 4.2 业务逻辑错误
- API密钥无效或缺失
- 请求参数验证失败
- 生成任务超时
- 服务器内部错误

### 5. 调试和监控

#### 5.1 详细日志记录
```dart
if (kDebugMode) {
  print('[FLUX.1-Krea-dev] Starting image generation request');
  print('[FLUX.1-Krea-dev] Request URL: $baseUrl/v1/flux-krea-dev');
  print('[FLUX.1-Krea-dev] Request body: ${jsonEncode(request.toJson())}');
}
```

#### 5.2 性能监控
- 请求响应时间测量
- 轮询次数统计
- 成功率追踪
- 错误类型分析

## 集成指南

### 1. 配置要求

#### 1.1 API密钥配置
在应用设置中配置 Black Forest Labs API 密钥：
```dart
// SettingsProvider 中添加
String? bflApiKey;
```

#### 1.2 依赖项
```yaml
dependencies:
  http: ^1.1.0
  flutter: sdk: flutter
```

### 2. 使用示例

#### 2.1 基本文生图
```dart
final fluxService = FluxKreaService(apiKey: 'your_bfl_api_key');

try {
  final imageUrl = await fluxService.generateImage(
    prompt: '一只可爱的橙色猫咪坐在花园里',
    aspectRatio: '1:1',
    seed: 12345,
  );
  
  // 显示生成的图像
  displayImage(imageUrl);
} catch (e) {
  // 处理错误
  showError('图像生成失败: $e');
}
```

#### 2.2 兼容OpenAI接口
```dart
final imageUrl = await fluxService.generateImageWithOpenAISize(
  prompt: 'A beautiful sunset over mountains',
  openAISize: '1792x1024',  // 自动映射为 16:9
);
```

#### 2.3 图像编辑
```dart
final editedImageUrl = await fluxService.editImage(
  prompt: '将猫咪的颜色改为黑色',
  imageUrl: originalImageUrl,
  strength: 0.7,
  guidanceScale: 3.0,
);
```

### 3. 与现有系统集成

#### 3.1 图像生成服务集成
```dart
// ImageGenerationService 中添加 FLUX.1-Krea-dev 支持
class ImageGenerationService {
  Future<String> generateImage(String provider, String prompt) async {
    switch (provider) {
      case 'flux-krea':
        final service = FluxKreaService(apiKey: settings.bflApiKey);
        return await service.generateImage(prompt: prompt);
      // ... 其他提供商
    }
  }
}
```

#### 3.2 UI集成
在聊天界面中添加 FLUX.1-Krea-dev 作为图像生成选项：
```dart
// ChatScreen 中的图像生成器选择
final providers = ['openai-dalle', 'flux-krea', 'stable-diffusion'];
```

## 最佳实践

### 1. 性能优化

#### 1.1 合理设置超时时间
- 简单图像：60秒
- 复杂图像：120秒  
- 高分辨率图像：180秒

#### 1.2 轮询间隔优化
- 初始间隔：2秒
- 避免过于频繁的请求
- 根据历史数据调整间隔

### 2. 用户体验

#### 2.1 进度反馈
- 显示生成状态
- 提供预估完成时间
- 允许用户取消长时间运行的任务

#### 2.2 错误提示
- 提供用户友好的错误信息
- 区分临时错误和永久错误
- 提供重试选项

### 3. 安全考虑

#### 3.1 API密钥保护
- 使用安全存储机制
- 避免在日志中泄露密钥
- 实现密钥轮换机制

#### 3.2 内容过滤
- 利用 `safetyTolerance` 参数
- 实施客户端内容检查
- 遵守平台内容政策

## 故障排除

### 1. 常见问题

#### 1.1 认证失败
```
错误: FLUX.1 Krea API error: Unauthorized (401)
解决: 检查API密钥是否正确配置
```

#### 1.2 请求超时
```
错误: Image generation timed out after 60 seconds
解决: 增加 maxWaitTime 参数或简化提示词
```

#### 1.3 任务不存在
```
错误: Task not found: Request ID may be invalid or expired
解决: 重新提交生成请求，检查网络连接稳定性
```

### 2. 调试工具

#### 2.1 连接测试
```dart
final isConnected = await fluxService.testConnection();
if (!isConnected) {
  print('无法连接到 FLUX.1-Krea-dev API');
}
```

#### 2.2 详细日志
在调试模式下启用详细日志输出，追踪请求和响应过程。

## 版本历史

- **v1.0.0**: 初始实现，支持基础文生图功能
- **v1.1.0**: 添加 OpenAI 兼容接口
- **v1.2.0**: 增加图像编辑功能
- **v1.3.0**: 优化轮询机制和错误处理

## 相关文档

- [FLUX API Structure](./FLUX_API_STRUCTURE.md)
- [FLUX Usage Guide](./FLUX_Usage_Guide.md)
- [API Documentation](./API_DOCUMENTATION.md)
- [Black Forest Labs官方文档](https://docs.bfl.ai/)

---

本文档记录了 FLUX.1-Krea-dev 文生图功能的完整设计和实现细节，为开发者提供全面的技术参考。