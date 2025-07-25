# 重构日志：设置页面模型信息数据结构

**日期：** 2025-07-20

## 1. 目标

本文档概述了设置页面模型信息数据结构的重构过程。主要目标是通过将模型提供商（例如 OpenAI、Gemini）直接与其相应的配置（API URL、API 密钥和默认模型）关联起来，创建一个更健壮、可扩展且用户友好的系统。

## 2. 旧结构存在的问题

以前的实现使用 `SharedPreferences` 中的单独键以“扁平”方式存储设置：
- `selected_model_provider`
- `openai_api_key`
- `openai_provider_url`
- `openai_selected_model`
- 等。

这种方法有几个缺点：
- **数据分散：** 单个提供商的配置分散在多个键中。
- **可伸缩性差：** 添加新提供商需要创建多个新键并在整个应用程序中硬编码逻辑。
- **糟糕的用户体验：** 当用户切换提供商时，应用程序无法自动加载该提供商之前保存的设置，从而强制手动重新输入。

## 3. 重构设计与实现步骤

重构过程遵循以下关键步骤：

### 步骤 1：创建统一数据模型

创建了一个新类 `ModelProviderSettings`，用于封装与单个模型提供商相关的所有设置。

**文件：** `lib/models/model_provider_settings.dart`

```dart
// lib/models/model_provider_settings.dart
import 'package:json_annotation/json_annotation.dart';

part 'model_provider_settings.g.dart';

@JsonSerializable()
class ModelProviderSettings {
  final String providerName;
  String apiBaseUrl;
  String apiKey;
  String selectedModel;

  ModelProviderSettings({
    required this.providerName,
    this.apiBaseUrl = '',
    this.apiKey = '',
    this.selectedModel = '',
  });

  factory ModelProviderSettings.fromJson(Map<String, dynamic> json) => _$ModelProviderSettingsFromJson(json);
  Map<String, dynamic> toJson() => _$ModelProviderSettingsToJson(this);
}
```
- **操作：** 将 `json_annotation` 和 `json_serializable` 添加到 `pubspec.yaml` 并运行 `build_runner` 以生成 `.g.dart` 文件。

### 步骤 2：更新 SharedPreferences 键

引入了新键来存储结构化数据，并标记旧键为已弃用，以方便干净的迁移。

**文件：** `lib/constants/shared_preferences_keys.dart`

- **已添加：**
  - `modelProvidersSettings`：存储表示所有提供商设置映射的 JSON 字符串 (`Map<String, ModelProviderSettings>`)。
  - `selectedProviderName`：存储当前活动提供商的名称。
- **已弃用：**
  - `selectedProvider`
  - `selectedModel`
  - `apiKey`
  - `providerUrl`

### 步骤 3：修改设置存储库（进行中）

`SettingsRepository` 正在更新以处理新的数据结构。

**文件：** `lib/repositories/settings_repository_impl.dart`
**接口：** `lib/repositories/interfaces.dart`

- **`SettingsRepository` 接口中的新方法：**
  - `Future<void> saveProviderSettings(Map<String, ModelProviderSettings> settings)`
  - `Future<Map<String, ModelProviderSettings>> getProviderSettings()`
  - `Future<void> saveSelectedProviderName(String name)`
  - `Future<String?> getSelectedProviderName()`
  - 用于读取旧键以支持数据迁移的方法。
  - 迁移完成后删除旧键的方法。

- **`SettingsRepositoryImpl` 中的实现：**
  - 实现新方法以将 `Map` 序列化为 JSON 字符串进行存储，并在检索时反序列化。

### 步骤 4：重构设置提供商（即将进行）

`SettingsProvider` 将被重构以管理新的 `Map<String, ModelProviderSettings>` 状态。

- 它将不再持有像 `_apiKey`、`_apiBaseUrl` 这样的独立状态变量。
- 数据迁移逻辑将添加到 `loadSettings()` 中，以无缝地将现有用户从旧的键值格式转换为新的结构化格式。
- `selectProvider()` 和 `updateCurrentProviderSettings()` 等方法将更新以使用新的数据映射。

### 步骤 5：更新 UI（即将进行）

`SettingsScreen` UI 将绑定到重构后的 `SettingsProvider`。

- 提供商下拉菜单现在将更新 `selectedProviderName`。
- API 密钥、URL 和模型的文本字段现在将根据所选提供商显示和更新 `currentProviderSettings` 的数据。
- 当用户切换提供商时，UI 将自动刷新并显示正确的数据。

此次重构将带来一个更清晰、更易于维护且用户友好的设置管理系统。