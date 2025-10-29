# 在 main.dart 中集成新提供者

## 快速集成指南

### 步骤 1：导入新提供者

在 `main.dart` 顶部添加以下导入：

```dart
import 'package:chibot/providers/api_key_provider.dart';
import 'package:chibot/providers/chat_model_provider.dart';
import 'package:chibot/providers/image_model_provider.dart';
import 'package:chibot/providers/video_model_provider.dart';
import 'package:chibot/providers/search_provider.dart';
import 'package:chibot/providers/unified_settings_provider.dart';
```

### 步骤 2：更新 MultiProvider

在 `main()` 函数中，找到 `MultiProvider` 并添加新的提供者：

```dart
void main() async {
  // ... 初始化代码 ...

  runApp(
    MultiProvider(
      providers: [
        // ==================== 新的专职提供者 ====================
        ChangeNotifierProvider(create: (_) => ApiKeyProvider()),
        ChangeNotifierProvider(create: (_) => ChatModelProvider()),
        ChangeNotifierProvider(create: (_) => ImageModelProvider()),
        ChangeNotifierProvider(create: (_) => VideoModelProvider()),
        ChangeNotifierProvider(create: (_) => SearchProvider()),

        // ==================== 向后兼容聚合层 ====================
        ChangeNotifierProxyProvider5<
            ApiKeyProvider,
            ChatModelProvider,
            ImageModelProvider,
            VideoModelProvider,
            SearchProvider,
            UnifiedSettingsProvider>(
          create: (_) => throw UnimplementedError(),
          update: (
            _,
            apiKeys,
            chatModel,
            imageModel,
            videoModel,
            search,
            __,
          ) =>
              UnifiedSettingsProvider(
                apiKeyProvider: apiKeys,
                chatModelProvider: chatModel,
                imageModelProvider: imageModel,
                videoModelProvider: videoModel,
                searchProvider: search,
              ),
        ),

        // ==================== 其他现有提供者 ====================
        // ... 保留现有的其他提供者 ...
      ],
      child: const MyApp(),
    ),
  );
}
```

### 步骤 3：验证编译

运行以下命令验证没有编译错误：

```bash
flutter pub get
flutter analyze
```

### 步骤 4：测试

运行新的测试文件：

```bash
flutter test test/providers/settings_refactoring_test.dart
```

---

## 验证检查清单

- [ ] 所有导入都添加了
- [ ] MultiProvider 中添加了 5 个新提供者
- [ ] ChangeNotifierProxyProvider5 正确配置
- [ ] `flutter analyze` 无错误
- [ ] `flutter test` 通过所有测试
- [ ] 应用可以正常启动
- [ ] 设置页面可以正常打开
- [ ] 现有功能仍然正常工作（向后兼容）

---

## 常见问题

### Q: 我是否需要立即修改所有使用 SettingsProvider 的代码？

**答：** 不需要。`UnifiedSettingsProvider` 提供完全的向后兼容性。你可以：
1. 立即添加新提供者
2. 逐步迁移现有代码
3. 在完全迁移后再移除旧提供者

### Q: 如果代码中使用了 `SettingsProvider`，会发生什么？

**答：** 可以继续使用（通过 `UnifiedSettingsProvider`），但推荐逐步迁移到专职提供者。

### Q: 性能会受到影响吗？

**答：** 不会，实际上可能会改善。使用专职提供者时，只有需要该提供者的 Widget 会在其变化时重建。

---

## 下一步：逐步迁移代码

添加新提供者后，可以开始迁移现有代码。参考：

📖 [SETTINGS_PROVIDER_REFACTORING.md](./SETTINGS_PROVIDER_REFACTORING.md) - 详细的迁移指南

---

## 支持

如有问题，参考：
- 📝 提供者的代码文档注释
- 🧪 测试文件中的使用示例
- 📖 迁移指南文档
