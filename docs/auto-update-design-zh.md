# 自动更新设计文档

## 概述

本文档概述了 Chibot Flutter 应用程序的自动更新功能的设计和实现，该功能从 GitHub 发布版本获取更新，并在多个平台上提供无缝安装。

## 架构

### 核心组件

1. **UpdateService** - 处理更新操作的主要服务类
2. **GitHub API 集成** - 获取最新版本信息
3. **平台特定处理器** - 管理每个平台的安装方法
4. **下载管理器** - 处理文件下载和安装

### 流程图

```
应用启动 → 检查更新 → 获取最新版本 → 比较版本 → 
下载更新 → 安装更新 → 重启应用
```

## 实现细节

### 1. GitHub API 集成

#### API 端点
```dart
static const String githubApiUrl = 'https://api.github.com/repos/mutse/chibot/releases/latest';
```

#### 响应结构
GitHub API 以 JSON 格式返回版本信息：
```json
{
  "tag_name": "v1.2.3",
  "name": "版本 v1.2.3",
  "body": "更新说明...",
  "assets": [
    {
      "name": "chibot-v1.2.3.apk",
      "browser_download_url": "https://...",
      "size": 12345678
    }
  ]
}
```

### 2. 版本比较

#### 当前实现
- 从 GitHub 获取最新版本
- 与当前应用版本比较
- 确定是否需要更新

#### 推荐改进
```dart
class VersionComparator {
  static bool isUpdateAvailable(String currentVersion, String latestVersion) {
    // 实现语义化版本比较
    return _compareVersions(currentVersion, latestVersion) < 0;
  }
  
  static int _compareVersions(String v1, String v2) {
    // 解析语义化版本并比较
  }
}
```

### 3. 平台特定处理

#### Android
- **文件类型**: `.apk`
- **安装方式**: 直接 APK 安装
- **存储位置**: 外部存储目录
- **权限**: 需要 `REQUEST_INSTALL_PACKAGES` 权限

#### iOS
- **文件类型**: App Store 链接
- **安装方式**: 重定向到 App Store
- **限制**: 由于 iOS 限制，无法直接安装

#### Windows
- **文件类型**: `.exe`
- **安装方式**: 下载并打开安装程序
- **存储位置**: 下载目录

#### macOS
- **文件类型**: `.dmg`
- **安装方式**: 下载并打开 DMG
- **存储位置**: 下载目录

#### Linux
- **文件类型**: `.AppImage`
- **安装方式**: 下载并打开 AppImage
- **存储位置**: 下载目录

### 4. 下载和安装流程

#### 下载流程
1. **验证 URL**: 确保下载 URL 可访问
2. **检查存储**: 验证足够的存储空间
3. **下载文件**: 使用 Dio 进行可靠下载
4. **验证完整性**: 可选的校验和验证
5. **安装**: 平台特定安装

#### 错误处理
- 网络连接问题
- 存储空间不足
- 无效的下载 URL
- 安装失败
- 权限拒绝

## 安全考虑

### 1. 仅使用 HTTPS
- 所有下载必须使用 HTTPS
- 验证 SSL 证书
- 防止中间人攻击

### 2. 文件完整性
```dart
class SecurityValidator {
  static Future<bool> verifyChecksum(String filePath, String expectedHash) async {
    // 实现 SHA-256 验证
  }
  
  static Future<bool> verifySignature(String filePath, String signature) async {
    // 实现数字签名验证
  }
}
```

### 3. 限制
- 实现指数退避重试失败请求
- 尊重 GitHub API 速率限制
- 适当缓存版本信息

## 用户体验

### 1. 更新通知
- **静默检查**: 后台更新检查
- **用户通知**: 清晰的更新提示
- **进度指示**: 下载和安装进度
- **错误反馈**: 用户友好的错误消息

### 2. 更新选项
- **自动**: 立即安装
- **手动**: 用户启动安装
- **推迟**: 稍后提醒
- **跳过**: 跳过此版本

### 3. 更新通道
- **稳定版**: 生产版本
- **测试版**: 预发布版本
- **每夜版**: 开发构建

## 配置

### 1. 更新设置
```dart
class UpdateConfig {
  static const bool enableAutoCheck = true;
  static const Duration checkInterval = Duration(hours: 24);
  static const bool enableSilentDownload = false;
  static const List<String> allowedChannels = ['stable'];
}
```

### 2. GitHub 仓库配置
- 仓库所有者和名称
- API 认证（可选）
- 版本标签模式
- 资源命名约定

## 错误处理和恢复

### 1. 网络故障
- 使用指数退避重试
- 回退到缓存的版本信息
- 通知用户连接问题

### 2. 下载失败
- 恢复中断的下载
- 清理部分下载
- 使用不同镜像重试

### 3. 安装失败
- 回滚到先前版本
- 提供手动安装说明
- 记录详细错误信息

## 监控和分析

### 1. 更新指标
- 更新检查频率
- 下载成功率
- 安装成功率
- 用户采用率

### 2. 错误跟踪
- 网络错误类型
- 下载失败原因
- 安装失败原因
- 用户反馈收集

## 测试策略

### 1. 单元测试
- 版本比较逻辑
- URL 生成
- 平台检测

### 2. 集成测试
- GitHub API 集成
- 下载功能
- 安装过程

### 3. 端到端测试
- 完整更新流程
- 错误场景
- 跨平台兼容性

## 部署考虑

### 1. 发布流程
- **标签创建**: 创建语义化版本标签
- **资源上传**: 上传平台特定二进制文件
- **发布说明**: 提供详细变更日志
- **预发布**: 标记为预发布用于测试

### 2. 二进制分发
- **Android**: 使用正确签名的 APK 文件
- **Windows**: MSI/EXE 安装程序
- **macOS**: 带有代码签名的 DMG 文件
- **Linux**: AppImage 或软件包文件

### 3. 发布自动化
- GitHub Actions 自动构建
- 发布前自动测试
- 资源上传自动化
- 发布说明生成

## 未来增强

### 1. 增量更新
- 实现二进制差异更新
- 减少下载大小
- 更快的更新过程

### 2. 后台更新
- 静默后台下载
- 应用重启时自动安装
- 用户偏好管理

### 3. 多通道支持
- 开发通道
- 测试通道
- 候选发布通道
- 稳定通道

### 4. 高级功能
- 更新调度
- 带宽管理
- 更新回滚功能
- A/B 测试支持

## 依赖项

### 必需包
```yaml
dependencies:
  http: ^1.1.0
  dio: ^5.0.0
  path_provider: ^2.0.0
  open_file: ^3.3.0
  url_launcher: ^6.1.0
```

### 可选包
```yaml
dependencies:
  crypto: ^3.0.0  # 校验和验证
  shared_preferences: ^2.0.0  # 更新偏好
  connectivity_plus: ^4.0.0  # 网络状态
```

## 结论

此自动更新系统通过 GitHub 发布版本提供了一种健壮、安全且用户友好的方式来分发应用程序更新。该实现支持多个平台，同时保持安全性并提供出色的用户体验。

模块化设计允许根据特定需求轻松扩展和定制，而全面的错误处理确保在不同网络条件和用户环境下的可靠性。