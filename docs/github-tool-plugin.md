# GitHub Tool Call 插件

## 使用

1. 在“设置 → 插件 → GitHub”输入个人访问令牌（PAT），点击“保存并测试连接”。成功后显示 GitHub 登录名。
2. 开启 GitHub 插件，选择支持工具调用的 OpenAI、OpenRouter 或自定义 OpenAI 兼容模型。
3. 在聊天中说明仓库，例如“读取 owner/repo 的 README”或“列出 owner/repo 的开放 Issue”。
4. 创建 Issue、发布普通评论或基于已有分支创建 PR 时，检查确认弹窗里的仓库、完整正文和分支参数。只有点击“确认本次操作”才发送写请求。

GitHub.com 是唯一支持的主机。不包含 OAuth、MCP、代码提交、分支创建、PR 合并或行内审查评论。Claude/Gemini 继续普通聊天。

推荐使用限定目标仓库的 fine-grained PAT；读取代码需要 Contents read，创建 Issue 需要 Issues write，创建 PR 需要 Pull requests write。测试连接仅验证账号，不代表拥有每个仓库的全部权限。

权限参考：https://docs.github.com/en/rest/authentication/permissions-required-for-fine-grained-personal-access-tokens

## 执行与恢复

- 默认关闭。PAT 沿用应用现有 SharedPreferences 本地存储，不包含在配置导出中。断开连接清除 PAT 并关闭插件。
- 列表默认每页 20 条，可显式请求下一页；每个工具结果最多 32 KiB，截断会明确标记。
- 每条用户请求最多 8 轮工具执行，每轮最多 32 个调用，顺序执行。之后请求模型给出最终回答。
- 停止、切换会话或离开聊天页后，不执行尚未发送的调用。已发送写请求会继续记录实际结果；超时/无法确定结果时显示“结果未知”。写请求不会自动重试。
- 在聊天中展开工具记录查看参数、结果及 GitHub 链接。恢复历史不会重新执行工具。应用中断时未完成的写入需要先到 GitHub 核对结果。

## 开发

`ToolPlugin` 提供工具定义和执行入口；`ToolRegistry` 负责注册与查找；`ToolOrchestrator` 负责确认、执行、续答及历史配对。`ToolChatService` 是独立于文本 `ChatService` 的能力接口，当前由 `OpenAIService` 实现。

工具协议历史、最终回答与执行记录保存在 `ChatMessage.metadata` 的 `toolProtocol`、`toolFinalText` 和 `toolRecords` 中。旧会话无需迁移。每轮调用从执行前开始保存配对结果占位符，完成后逐项替换，避免中途退出丢失已完成写入。

本地验证：

```sh
flutter analyze --no-pub
flutter test --no-pub
```

若本机配置的 HTTP 代理导致 Flutter 测试连接 localhost 失败，可仅为测试命令设置 `NO_PROXY=localhost,127.0.0.1,::1` 和 `no_proxy=localhost,127.0.0.1,::1`。

自动测试使用模拟 GitHub/模型响应，不消耗 API 额度、不修改真实仓库。真实 PAT 与模型端到端验证需在配置账号后按上述流程进行。
