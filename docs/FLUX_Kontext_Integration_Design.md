# FLUX.1 Kontext 模型集成设计文档

## 概述

本文档描述了将 Black Forest Labs 的 FLUX.1 Kontext 模型集成到 Flutter AI 聊天机器人应用中的详细设计方案。FLUX.1 Kontext 是一个先进的文本到图像生成模型，支持文本生图和图像编辑功能。

## 目标

1. 集成 FLUX.1 Kontext 作为新的图像生成服务
2. 支持文本到图像生成
3. 支持图像到图像编辑
4. 保持与现有架构的一致性
5. 提供用户友好的配置界面

## API 规范

### 基础信息

- **API 端点**: `https://api.bfl.ai/v1/flux-kontext-pro`
- **认证方式**: `x-key` (推荐) 或 `Authorization: Bearer`（部分历史文档/兼容性）
- **请求格式**: JSON
- **响应格式**: JSON + 轮询机制
- **状态轮询端点**: `https://api.bfl.ai/v1/get_result?id={request_id}`

> **注意**：新版服务推荐使用 `x-key` 头部传递 API Key，部分旧实现或第三方库可能仍支持 `Authorization: Bearer`。

### 核心功能

#### 1. 文本到图像 (Text-to-Image)

**请求参数**:
```json
{
  "prompt": "string (必填)",
  "aspect_ratio": "string (可选, 如 16:9, 1:1, 9:16, 21:9, 4:3, 3:4, 5:4, 4:5)",
  "seed": "integer (可选, 用于复现)",
  "prompt_upsampling": "boolean (可选)",
  "safety_tolerance": "integer (0-6, 可选)",
  "output_format": "jpeg | png (可选)"
}
```

**响应格式**:
```json
{
  "id": "req-123abc",
  "status": "pending",
  "polling_url": "https://api.bfl.ai/v1/get_result?id=req-123abc"
}
```

#### 2. 图像到图像 (Image-to-Image)

**额外参数**:
```json
{
  "image": "string (URL 或 base64)",
  "strength": "float (0-1, 默认 0.8)",
  "guidance_scale": "float (1-10, 默认 2.5)"
}
```

#### 3. 轮询机制
- 通过 `polling_url` 轮询获取生成结果，推荐每 2-3 秒轮询一次。
- 最大等待时间建议 60-120 秒，超时需提示用户。
- 结果状态包括：`pending`、`processing`、`ready`、`failed`。
- 成功时返回图片 URL，失败时返回错误信息。

**结果响应示例**:
```json
{
  "status": "ready",
  "result": {
    "sample": "https://storage.googleapis.com/generated-image-url.png",
    "prompt": "original prompt text",
    "metadata": {
      "aspect_ratio": "16:9",
      "seed": 12345,
      "safety_check": "passed",
      "model_schedule": "flux-kontext-pro",
      "insights": "image analysis tags"
    }
  }
}
```

**错误响应示例**:
```json
{
  "status": "failed",
  "error": { "message": "Invalid prompt" }
}
```

### 字段说明
- `prompt`：描述生成图片的文本
- `aspect_ratio`：宽高比，支持多种格式，默认 1:1
- `seed`：随机种子，便于结果复现
- `prompt_upsampling`：是否对 prompt 进行增强
- `safety_tolerance`：安全容忍度，0-6
- `output_format`：输出图片格式，png 或 jpeg
- `image`：参考图片（URL 或 base64）
- `strength`：图像编辑强度，0-1，默认 0.8
- `guidance_scale`：文本引导强度，1-10，默认 2.5

### 认证与安全
- 推荐使用 `x-key` 头部传递 API Key。
- 兼容 `Authorization: Bearer` 头部，但部分新接口仅支持 `x-key`。
- 建议后端统一校验，前端不应暴露明文 Key。

### 错误处理
- 认证失败：401 Unauthorized
- 参数错误：400 Bad Request
- 速率限制：429 Too Many Requests
- 服务错误：500 Internal Server Error
- 轮询超时：自定义错误，需前端处理
- 错误响应均包含 `error.message` 字段

## 架构设计

### 类结构设计

#### 1. FluxKontextService (新服务类)

```dart
class FluxKontextService extends BaseApiService implements ImageGenerationService {
  // 配置
  final String apiKey;
  final String baseUrl = 'https://api.bfl.ml/v1';
  
  // 核心方法
  Future<ImageGenerationResponse> generateImage({
    required String prompt,
    String? aspectRatio,
    int? seed,
    String? outputFormat,
    int? safetyTolerance,
  });
  
  Future<ImageGenerationResponse> editImage({
    required String prompt,
    required String imageUrl,
    double? strength,
    double? guidanceScale,
    String? aspectRatio,
  });
  
  // 轮询结果
  Future<FluxKontextResult> pollResult(String requestId);
}
```

#### 2. 数据模型

```dart
class FluxKontextRequest {
  final String prompt;
  final String? aspectRatio;
  final int? seed;
  final bool? promptUpsampling;
  final int? safetyTolerance;
  final String? outputFormat;
  final String? image;
  final double? strength;
  final double? guidanceScale;
}

class FluxKontextResponse {
  final String id;
  final String status;
  final String pollingUrl;
}

class FluxKontextResult {
  final String sampleUrl;  // 生成图片的URL
  final String? prompt;
  final Map<String, dynamic>? metadata;
}
```

### 集成点

#### 1. ServiceFactory 扩展

在 `ChatServiceFactory` 中添加 FLUX.1 Kontext 支持：

```dart
class ImageServiceFactory {
  static ImageGenerationService create(ProviderType type, String apiKey) {
    switch (type) {
      case ProviderType.fluxKontext:
        return FluxKontextService(apiKey: apiKey);
      // 其他现有服务...
    }
  }
}
```

#### 2. SettingsProvider 扩展

添加 FLUX.1 Kontext 配置：

```dart
class SettingsProvider extends ChangeNotifier {
  String _fluxKontextApiKey = '';
  String _fluxKontextModel = 'flux-kontext-pro';
  
  // Getter & Setter
  String get fluxKontextApiKey => _fluxKontextApiKey;
  set fluxKontextApiKey(String value) {
    _fluxKontextApiKey = value;
    notifyListeners();
  }
}
```

#### 3. UI 更新

在设置页面添加 FLUX.1 Kontext 配置区域：

- API Key 输入框
- 模型选择下拉菜单
- 测试连接按钮

## 错误处理

### 错误类型

1. **认证错误**: 401 Unauthorized
2. **参数错误**: 400 Bad Request
3. **速率限制**: 429 Too Many Requests
4. **服务错误**: 500 Internal Server Error
5. **轮询超时**: 请求处理超时

### 处理策略

- 显示用户友好的错误消息
- 提供重试机制
- 记录详细错误日志
- 支持离线模式提示

## 用户界面设计

### 设置界面

1. **FLUX.1 Kontext 配置卡片**
   - API Key 输入 (密码字段)
   - 模型选择 (flux-kontext-pro)
   - 测试按钮
   - 使用统计信息

2. **图像生成界面**
   - 新增 "FLUX.1 Kontext" 选项
   - 高级参数配置 (宽高比、种子等)
   - 图像编辑模式切换

### 生成界面增强

1. **参数面板**
   - 宽高比选择器 (16:9, 1:1, 9:16, 自定义)
   - 随机种子生成
   - 输出格式选择
   - 安全等级调节

2. **图像编辑模式**
   - 上传参考图
   - 强度滑块 (0-1)
   - 引导尺度调节

## 性能优化

### 轮询优化

- 指数退避重试策略
- 最大轮询时间限制 (60秒)
- 取消机制支持

### 缓存策略

- 缓存生成的图片URL (24小时)
- 缓存用户参数设置
- 预加载常用配置

## 测试策略

### 单元测试

1. **服务层测试**
   - API 调用测试
   - 错误处理测试
   - 轮询机制测试

2. **模型测试**
   - JSON 序列化测试
   - 参数验证测试

### 集成测试

1. **端到端测试**
   - 完整生图流程
   - 错误场景模拟
   - 并发请求测试

### UI 测试

1. **设置页面测试**
   - 配置保存/加载
   - 输入验证
   - 状态管理

## 部署计划

### 阶段 1: 基础集成
- [ ] 创建 FluxKontextService
- [ ] 实现基本生成功能
- [ ] 添加设置支持

### 阶段 2: 高级功能
- [ ] 图像编辑功能
- [ ] 高级参数配置
- [ ] 错误处理完善

### 阶段 3: UI 优化
- [ ] 设置界面美化
- [ ] 生成界面增强
- [ ] 性能优化

## 风险评估

### 技术风险

1. **API 变更**: 监控官方 API 更新
2. **速率限制**: 实现请求队列
3. **网络问题**: 添加重试机制

### 用户体验风险

1. **生图延迟**: 添加进度指示器
2. **参数复杂**: 提供预设模板
3. **错误恢复**: 优雅的错误处理

## 监控和日志

### 监控指标

- API 调用成功率
- 平均生成时间
- 错误率统计
- 用户使用频率

### 日志记录

- 请求参数日志
- 响应时间日志
- 错误详情日志
- 用户操作日志

## 兼容性

### 平台支持

- iOS: 13.0+
- Android: API 21+
- Web: 现代浏览器
- macOS: 10.15+

### 向后兼容

- 保持现有功能不变
- 平滑升级路径
- 配置迁移支持

## 未来扩展

### 可能的功能扩展

1. **批量生成**: 支持一次生成多张图片
2. **历史记录**: 查看生成历史
3. **收藏功能**: 保存喜欢的参数组合
4. **社区分享**: 分享生成结果
5. **模板库**: 预设提示模板

### 技术扩展

1. **其他模型**: 支持 FLUX.1 系列其他模型
2. **实时预览**: 生成过程实时预览
3. **AI 优化**: 智能参数推荐
4. **性能提升**: 本地缓存优化