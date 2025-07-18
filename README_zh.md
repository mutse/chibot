# Chi Chatbot

<img src=./assets/images/logo.png width=40% height=40%/>
  
Chi Chatbot AI 是一个基于 Flutter 的跨平台应用程序，它提供了一个直观的聊天界面，用于与 AI 语言模型进行交互。目前通过统一的界面支持集成 OpenAI 模型（如 GPT-4）和 Google Gemini 模型。

## 截图

![](./images/chibot-mac.jpg)

## 功能特性
  
- **多提供商支持**：支持 OpenAI、Google Gemini、Anthropic Claude 和自定义 AI 模型
- **流式输出**：AI 模型的实时响应，支持服务器发送事件
- **文本生成图像**：使用 DALL-E、Gemini 或其他图像生成模型生成图像
- **网络搜索**：集成 Tavily 或 Google Search API 的网络搜索功能
- **会话管理**：持久化聊天会话，支持对话历史记录
- **桌面集成**：系统托盘支持、窗口管理和右键菜单
- **多语言支持**：英文和中文本地化
- **现代聊天界面**：简洁的用户界面，支持侧边栏导航
- **可自定义设置**：配置 API 密钥、模型选择、提供商 URL 和系统提示词
- **跨平台**：使用 Flutter 构建，兼容移动端、桌面端平台

## 架构
  
Chi Chatbot 遵循清晰的架构设计，各层职责明确分离：

- **模型层**：带有 JSON 序列化的 Dart 数据结构类
- **服务层**：使用仓库模式处理数据持久化和 API 通信
- **提供器层**：使用 Provider 模式进行状态管理
- **展示层**：聊天、设置和关于界面的 UI 组件

### 核心组件

- **状态管理**：使用 Provider 模式的集中式状态管理
- **服务层**：UI 与业务逻辑之间的清晰分离
- **仓库模式**：服务处理数据持久化和 API 通信
- **模型层**：带有 JSON 序列化的 Dart 数据结构类

### 服务架构

- **BaseApiService**：具有重试逻辑、错误处理和流式功能的抽象基类
- **OpenAIService**：处理 OpenAI GPT 模型的流式响应
- **GeminiService**：管理 Google Gemini API 调用
- **ClaudeService**：集成 Anthropic Claude 模型的流式支持
- **ChatServiceFactory**：用于创建适当聊天服务的工厂
- **ServiceManager**：使用设置管理服务创建的辅助工具
- **ImageGenerationService**：管理图像生成请求
- **ChatSessionService** 和 **ImageSessionService**：处理会话持久化
- **WebSearchService**：集成网络搜索功能（Tavily/Google Search）
- **ImageSaveService**：处理图像保存到设备存储
  
## 快速开始
  
### 前置要求
  
- Flutter SDK
- Dart
- OpenAI 或 Google Gemini 的 API 密钥
  
### 安装步骤
  
1. 克隆仓库：

    ```zsh
    $ git clone https://github.com/mutse/chibot.git
    ```

2. 进入项目目录：

    ```zsh
    $ cd chibot
    ```

3. 安装依赖：

    ```zsh
    $ flutter pub get
    ```

4. 运行应用程序：

    ```zsh
    $ flutter run
    ```

### 配置

1. 启动应用程序
2. 导航到设置
3. 输入您的 OpenAI 或 Google Gemini API 密钥
4. 选择您偏好的 AI 模型
5. （可选）如需要，配置自定义提供商 URL

## 项目结构

    ```zsh
    lib/
    ├── main.dart                 # 应用程序入口点
    ├── models/
    │   ├── chat_message.dart     # 聊天消息的数据模型
    │   ├── chat_session.dart     # 对话会话管理
    │   ├── image_session.dart    # 图像生成会话管理
    │   └── image_message.dart    # 图像内容的专用消息类型
    ├── providers/
    │   ├── settings_provider.dart # 应用设置的状态管理
    │   └── chat_provider.dart    # 聊天会话的状态管理
    ├── screens/
    │   ├── chat_screen.dart      # 带侧边栏的主聊天界面
    │   ├── settings_screen.dart  # 设置配置界面
    │   └── about_screen.dart     # 应用信息和致谢
    ├── services/
    │   ├── base_api_service.dart  # 具有通用功能的抽象基类
    │   ├── openai_service.dart    # OpenAI GPT 服务实现
    │   ├── gemini_service.dart    # Google Gemini 服务实现
    │   ├── claude_service.dart    # Anthropic Claude 服务实现
    │   ├── chat_service_factory.dart # 服务创建的工厂类
    │   ├── service_manager.dart   # 服务管理的辅助工具
    │   ├── image_generation_service.dart # 图像生成功能
    │   ├── chat_session_service.dart     # 聊天会话持久化
    │   ├── image_session_service.dart    # 图像会话持久化
    │   ├── web_search_service.dart       # 网络搜索集成
    │   └── image_save_service.dart       # 图像保存到设备存储
    ├── l10n/
    │   ├── app_en.arb           # 英文本地化
    │   └── app_zh.arb           # 中文本地化
    └── utils/
        ├── constants.dart       # 应用常量和配置
        └── validators.dart      # 输入验证工具
    ```

## 支持平台
  
- **桌面端**：macOS、Windows、Linux（支持系统托盘和窗口管理）
- **移动端**：iOS、Android
  
## 技术栈
  
- **Flutter**：跨平台 UI 框架
- **Dart**：编程语言
- **Provider**：状态管理解决方案
- **HTTP 客户端**：用于与 AI 提供商进行 API 通信
- **SharedPreferences**：持久化设置存储
- **Window Manager**：桌面窗口管理
- **System Tray**：桌面系统托盘集成
- **Localization**：多语言支持
  
## 许可证
  
本项目采用 MIT [许可证](./LICENSE) - 详情请查看 LICENSE 文件。
  
## 作者
  
Mutse Young © 2025