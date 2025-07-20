# 用户手册

欢迎使用 Chibot 用户手册。本手册将帮助您快速上手并充分利用本应用的各项功能。

## 目录
1. [简介](#简介)
2. [安装](#安装)
3. [快速入门](#快速入门)
4. [主要功能](#主要功能)
5. [常见问题](#常见问题)
6. [故障排查](#故障排查)
7. [支持与反馈](#支持与反馈)

---

## 简介

Chi Chatbot AI（Chibot）是一款基于 Flutter 的跨平台智能聊天应用，支持与 OpenAI（如 GPT-4）、Google Gemini 和 Anthropic Claude 等主流大模型对话。应用界面简洁，支持多平台运行，适合多种场景下的智能问答、文本生成和图像生成。

## 安装

### 前置条件

- 拥有 OpenAI 或 Google Gemini 或 Anthropic Claude 的 API Key
- 或拥有兼容 OpenAI 的模型供应商的 API Key

### 安装步骤

1. 访问 [Chibot Releases](https://github.com/mutse/chibot/releases) 获取适合您设备的最新安装包并下载。
2. 也可以访问 [Chibot 网站](https://chibot.mutse.top) 下载最新软件包。

## 快速入门

1. 启动应用。
2. 进入“设置”页面。
3. 输入您的 OpenAI 或 Google Gemini API Key。
4. 选择您想要使用的 AI 模型。
5. （可选）如有需要，可配置自定义 Provider URL。
6. 返回主界面，即可开始与 AI 聊天。

## 主要功能

- **多模型支持**：可与 OpenAI 和 Google Gemini 等主流大模型对话。
- **流式输出**：AI 回复实时显示，体验更流畅。
- **文本生成图片**：输入描述，AI 可生成相应图片。
- **Flux Kontext 图像生成**: 本应用支持使用来自 Black Forest Labs 的 Flux Kontext 模型进行图像生成。
  - **获取 Flux Kontext API Key**: 访问 [Black Forest Labs 网站](https://www.blackforestlabs.ai/) 注册并获取 API Key。
  - **在应用中配置**: 进入“设置”页面，选择“图像模型”，并选择“Black Forest Labs”作为提供商，输入您的 API Key，并选择所需的模型（例如 `flux-kontext-pro`）。
  - **如何使用**: 在聊天输入框中，输入您的图像描述。模型将根据您的文本生成图像。您还可以通过提供图像和文本提示来使用图像到图像的编辑功能。
- **联网搜索**：支持联网生成更丰富的文本内容。
- **简洁聊天界面**：消息收发清晰，操作便捷。
- **自定义设置**：可配置 API Key、模型选择、Provider URL 等。
- **多平台兼容**：支持 macOS、iOS、Android、Windows、Linux 等。

## 常见问题

**Q1：如何获取 API Key？**
A1：请前往 OpenAI 或 Google Gemini 官方网站注册并获取 API Key。

**Q2：支持哪些平台？**
A2：Chibot 支持 macOS、iOS、Android、Windows 和 Linux。

**Q3：如何切换 AI 模型？**
A3：在“设置”页面选择您想要的模型即可。

## 故障排查

- **无法联网/无响应**：请检查网络连接及 API Key 是否正确。
- **依赖安装失败**：请确保已正确安装 Flutter SDK 和 Dart。
- **界面显示异常**：尝试重启应用或清理缓存。
- **API Key 无效**：请确认 API Key 是否过期或输入有误。

## 支持与反馈

如需帮助或有建议，请通过以下方式联系开发者：
- GitHub Issues: https://github.com/mutse/chibot/issues
- 邮箱：young@mutse.top

感谢您的使用与支持！ 