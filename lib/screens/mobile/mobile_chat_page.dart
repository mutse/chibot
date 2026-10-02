import 'package:chibot/widgets/tool_chat_run.dart';
import 'package:chibot/widgets/tool_call_records.dart';
import 'package:chibot/l10n/app_localizations.dart';
import 'package:chibot/models/available_model.dart' as available_model;
import 'package:chibot/models/chat_message.dart';
import 'package:chibot/models/chat_session.dart';
import 'package:chibot/providers/api_key_provider.dart';
import 'package:chibot/providers/chat_model_provider.dart';
import 'package:chibot/providers/search_provider.dart';
import 'package:chibot/providers/unified_settings_provider.dart';
import 'package:chibot/screens/mobile/mobile_ui.dart';
import 'package:chibot/screens/settings_screen.dart';
import 'package:chibot/services/chat_session_service.dart';
import 'package:chibot/services/exceptions/missing_api_key_exception.dart';
import 'package:chibot/services/markdown_export_service.dart';
import 'package:chibot/services/search_service_factory.dart';
import 'package:chibot/services/service_manager.dart';
import 'package:chibot/widgets/chat_markdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';

class MobileChatPage extends StatefulWidget {
  final VoidCallback? onOpenAppMenu;
  final VoidCallback? onOpenImages;
  final VoidCallback? onOpenVideo;
  final VoidCallback? onOpenModels;
  final VoidCallback? onOpenHistory;
  final VoidCallback? onDataChanged;

  const MobileChatPage({
    super.key,
    this.onOpenAppMenu,
    this.onOpenImages,
    this.onOpenVideo,
    this.onOpenModels,
    this.onOpenHistory,
    this.onDataChanged,
  });

  @override
  State<MobileChatPage> createState() => MobileChatPageState();
}

class MobileChatPageState extends State<MobileChatPage> {
  final ChatSessionService _sessionService = ChatSessionService();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _composerFocus = FocusNode();

  final List<ChatMessage> _messages = [];
  List<ChatSession> _sessions = [];
  String? _currentSessionId;
  ToolChatRun? _toolRun;
  bool _isLoading = false;
  bool _enableWebSearch = false;
  // Bumped whenever the visible conversation changes so an in-flight response
  // cannot write into (or save over) a different session.
  int _conversationGeneration = 0;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    final sessions = await _sessionService.loadSessions();
    sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    if (!mounted) return;
    setState(() {
      _sessions = sessions;
    });
  }

  void startNewChat() {
    stopGeneration();
    context.read<UnifiedSettingsProvider>().setSelectedModelType(
      available_model.ModelType.text,
    );
    setState(() {
      _conversationGeneration++;
      _messages.clear();
      _currentSessionId = null;
      _isLoading = false;
    });
  }

  void loadSession(ChatSession session) {
    stopGeneration();
    context.read<UnifiedSettingsProvider>().setSelectedModelType(
      available_model.ModelType.text,
    );
    setState(() {
      _conversationGeneration++;
      _messages
        ..clear()
        ..addAll(session.messages);
      _currentSessionId = session.id;
      _isLoading = false;
    });
    _scrollToBottom();
  }

  Future<String?> _buildPromptWithWebSearch({
    required String text,
    required SearchProvider searchProvider,
    required ApiKeyProvider apiKeys,
    required int generation,
  }) async {
    if (!_enableWebSearch) {
      return text;
    }

    if (!SearchServiceFactory.isSearchFunctionalityAvailable(
      search: searchProvider,
      apiKeys: apiKeys,
    )) {
      _appendAiMessage('未启用任何网络搜索功能，请先在设置页完成模型或搜索配置。');
      return null;
    }

    try {
      final webResult = await SearchServiceFactory.searchWebAsPromptContext(
        search: searchProvider,
        apiKeys: apiKeys,
        query: text,
      );
      if (!mounted) return null;
      return AppLocalizations.of(context)!.webSearchPrompt(webResult, text);
    } catch (e) {
      if (!mounted || generation != _conversationGeneration) return null;
      _appendAiMessage(
        AppLocalizations.of(context)!.webSearchFailed(e.toString()),
      );
      return null;
    }
  }

  void _appendAiMessage(String text) {
    if (!mounted) return;
    setState(() {
      _messages.add(
        ChatMessage.ai(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          text: text,
        ),
      );
      _isLoading = false;
    });
    _scrollToBottom();
  }

  Future<void> _ensureCurrentSession(
    ChatMessage userMessage,
    String prompt,
  ) async {
    if (_currentSessionId != null) {
      return;
    }

    _currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();
    final chatModel = context.read<ChatModelProvider>();
    final newSession = ChatSession(
      id: _currentSessionId!,
      title: prompt.length > 34 ? '${prompt.substring(0, 34)}...' : prompt,
      messages: [userMessage],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      modelUsed: chatModel.selectedModel,
      providerUsed: chatModel.selectedProvider,
    );
    await _sessionService.saveSession(newSession);
    await _loadSessions();
    widget.onDataChanged?.call();
  }

  ChatSession? _buildCurrentSnapshot() {
    if (_currentSessionId == null) {
      return null;
    }

    final existing = _sessions.where((item) => item.id == _currentSessionId);
    final current = existing.isEmpty ? null : existing.first;
    final firstMessageText =
        _messages.isNotEmpty ? _messages.first.text : '新对话';
    final generatedTitle =
        firstMessageText.length > 34
            ? '${firstMessageText.substring(0, 34)}...'
            : firstMessageText;
    return ChatSession(
      id: _currentSessionId!,
      title: current?.title ?? generatedTitle,
      messages: List<ChatMessage>.from(_messages),
      createdAt: current?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      modelUsed: current?.modelUsed,
      providerUsed: current?.providerUsed,
    );
  }

  Future<void> _saveCurrentSnapshot() async {
    final snapshot = _buildCurrentSnapshot();
    if (snapshot == null) {
      return;
    }
    await _sessionService.saveSession(snapshot);
    await _loadSessions();
    widget.onDataChanged?.call();
  }

  void stopGeneration() {
    final run = _toolRun;
    run?.cancel();
    if (!_isLoading) return;
    _conversationGeneration++;
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (_messages.isNotEmpty && _messages.last.isAI) {
          _messages[_messages.length - 1] = _messages.last.copyWith(
            isLoading: false,
            text:
                _messages.last.text.isEmpty
                    ? AppLocalizations.of(context)!.toolStopped
                    : _messages.last.text,
          );
        }
      });
      _saveCurrentSnapshot();
    }
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isLoading) {
      return;
    }

    final searchProvider = context.read<SearchProvider>();
    final apiKeys = context.read<ApiKeyProvider>();
    final chatModelProvider = context.read<ChatModelProvider>();
    final localizations = AppLocalizations.of(context)!;
    final generation = _conversationGeneration;
    bool isCurrent() => mounted && generation == _conversationGeneration;

    _textController.clear();
    // Block re-entry while the (optional) web search is running.
    setState(() {
      _isLoading = true;
    });
    final prompt = await _buildPromptWithWebSearch(
      text: text,
      searchProvider: searchProvider,
      apiKeys: apiKeys,
      generation: generation,
    );
    if (!isCurrent()) {
      return;
    }
    if (prompt == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    // Prior turns only: the service appends [prompt] as the final user turn,
    // and toApiJson() already skips loading/error placeholders.
    final history = List<ChatMessage>.from(_messages);
    final userMessage = ChatMessage.user(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: prompt,
    );

    setState(() {
      _messages.add(userMessage);
      _messages.add(
        ChatMessage.loading(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
        ),
      );
    });
    _scrollToBottom();
    await _ensureCurrentSession(userMessage, text);
    if (!isCurrent()) {
      return;
    }

    final apiKey = apiKeys.getApiKeyForProvider(
      chatModelProvider.selectedProvider,
    );
    if (apiKey == null || apiKey.isEmpty) {
      _replaceLastAiMessage(localizations.apiKeyNotSetError);
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final chatService = ServiceManager.createChatService(
        chatModel: chatModelProvider,
        apiKeys: apiKeys,
      );
      await _saveCurrentSnapshot();
      if (!mounted || !isCurrent()) return;
      final messageId = _messages.last.id;
      final run = ToolChatRun(
        context: context,
        sessionId: _currentSessionId!,
        messageId: messageId,
        onMetadata: (metadata) {
          if (!mounted || _currentSessionId == null) return;
          final index = _messages.indexWhere((m) => m.id == messageId);
          if (index >= 0) {
            setState(() {
              _messages[index] = _messages[index].copyWith(metadata: metadata);
            });
          }
        },
      );
      _toolRun = run;
      final stream = run.generate(
        service: chatService,
        prompt: prompt,
        history: history,
        model: chatModelProvider.selectedModel,
      );

      var fullResponse = '';
      await for (final chunk in stream) {
        if (!isCurrent()) {
          return;
        }
        fullResponse += chunk;
        _replaceLastAiMessage(
          fullResponse.isEmpty ? localizations.aiIsThinking : fullResponse,
          isLoading: true,
        );
        _scrollToBottom();
      }
      if (!isCurrent()) {
        return;
      }

      _replaceLastAiMessage(
        fullResponse.isEmpty ? localizations.noResponseFromAI : fullResponse,
      );
      await _saveCurrentSnapshot();
    } catch (error) {
      if (!isCurrent()) {
        return;
      }
      if (error is MissingApiKeyException) {
        _replaceLastAiMessage(error.userFriendlyMessage);
      } else {
        _replaceLastAiMessage('错误：$error');
      }
    } finally {
      if (isCurrent()) {
        setState(() {
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _replaceLastAiMessage(String text, {bool isLoading = false}) {
    if (!mounted) return;

    setState(() {
      if (_messages.isEmpty) {
        _messages.add(
          ChatMessage.ai(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            text: text,
            isLoading: isLoading,
          ),
        );
      } else {
        final lastIndex = _messages.length - 1;
        _messages[lastIndex] = ChatMessage.ai(
          id: _messages[lastIndex].id,
          text: text,
          timestamp: _messages[lastIndex].timestamp,
          metadata: _messages[lastIndex].metadata,
          isLoading: isLoading,
        );
      }
    });
  }

  Future<void> _deleteSession(ChatSession session) async {
    await _sessionService.deleteSession(session.id);
    if (!mounted) return;
    if (_currentSessionId == session.id) {
      startNewChat();
    }
    await _loadSessions();
    widget.onDataChanged?.call();
  }

  Future<void> _exportSession(ChatSession session) async {
    await MarkdownExportService.exportToMarkdown(session, context);
  }

  Future<void> _exportAllSessions() async {
    final l10n = AppLocalizations.of(context)!;
    if (_sessions.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.noChatSessionsToExport)));
      return;
    }

    await MarkdownExportService.exportMultipleToMarkdown(_sessions, context);
  }

  void _showModelSheet() {
    final theme = Theme.of(context);
    final chatModel = context.read<ChatModelProvider>();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: MobileSurface(
              padding: const EdgeInsets.all(18),
              child: StatefulBuilder(
                builder: (context, setModalState) {
                  final availableModels = chatModel.availableModels;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '聊天模型',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: MobilePalette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            chatModel.allProviderNames
                                .map(
                                  (provider) => MobilePill(
                                    label: provider,
                                    selected:
                                        provider == chatModel.selectedProvider,
                                    onTap: () async {
                                      await chatModel.setSelectedProvider(
                                        provider,
                                      );
                                      setModalState(() {});
                                      setState(() {});
                                    },
                                  ),
                                )
                                .toList(),
                      ),
                      const SizedBox(height: 18),
                      ...availableModels.map(
                        (model) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            model,
                            style: const TextStyle(
                              color: MobilePalette.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          trailing:
                              model == chatModel.selectedModel
                                  ? const Icon(
                                    Icons.check_circle,
                                    color: MobilePalette.primary,
                                  )
                                  : const Icon(
                                    Icons.circle_outlined,
                                    color: MobilePalette.border,
                                  ),
                          onTap: () async {
                            await chatModel.setSelectedModel(model);
                            if (!mounted) return;
                            Navigator.of(this.context).pop();
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          widget.onOpenModels?.call();
                        },
                        icon: const Icon(Icons.tune_rounded),
                        label: const Text('打开模型设置'),
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void _showSessionSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: MobileSurface(
              padding: const EdgeInsets.all(18),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.72,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          '聊天会话',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: MobilePalette.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        MobileIconCircleButton(
                          icon: Icons.add_rounded,
                          tooltip: '新建对话',
                          onTap: () {
                            Navigator.pop(context);
                            startNewChat();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      children: [
                        ActionChip(
                          label: const Text('历史'),
                          onPressed: () {
                            Navigator.pop(context);
                            widget.onOpenHistory?.call();
                          },
                        ),
                        ActionChip(
                          label: const Text('模型'),
                          onPressed: () {
                            Navigator.pop(context);
                            widget.onOpenModels?.call();
                          },
                        ),
                        ActionChip(
                          label: const Text('设置'),
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              this.context,
                              MaterialPageRoute(
                                builder: (_) => const SettingsScreen(),
                              ),
                            );
                          },
                        ),
                        ActionChip(
                          label: Text(
                            AppLocalizations.of(context)!.exportAllChats,
                          ),
                          onPressed: () async {
                            Navigator.pop(context);
                            await _exportAllSessions();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Flexible(
                      child:
                          _sessions.isEmpty
                              ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Text(
                                    '还没有聊天会话。',
                                    style: TextStyle(
                                      color: MobilePalette.textSecondary,
                                    ),
                                  ),
                                ),
                              )
                              : ListView.separated(
                                itemCount: _sessions.length,
                                separatorBuilder:
                                    (context, index) =>
                                        const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final session = _sessions[index];
                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(
                                      session.displayTitle,
                                      style: const TextStyle(
                                        color: MobilePalette.textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${formatMobileDate(session.updatedAt)} • ${session.messageCount} 条消息',
                                      style: const TextStyle(
                                        color: MobilePalette.textSecondary,
                                      ),
                                    ),
                                    leading: CircleAvatar(
                                      backgroundColor:
                                          session.id == _currentSessionId
                                              ? MobilePalette.primarySoft
                                              : MobilePalette.surface,
                                      child: Icon(
                                        Icons.chat_bubble_outline_rounded,
                                        color:
                                            session.id == _currentSessionId
                                                ? MobilePalette.primary
                                                : MobilePalette.textSecondary,
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.ios_share_rounded,
                                          ),
                                          tooltip:
                                              AppLocalizations.of(
                                                context,
                                              )!.exportToMarkdown,
                                          onPressed:
                                              () => _exportSession(session),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline_rounded,
                                          ),
                                          onPressed:
                                              () => _deleteSession(session),
                                        ),
                                      ],
                                    ),
                                    onTap: () {
                                      Navigator.pop(context);
                                      loadSession(session);
                                    },
                                  );
                                },
                              ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.sender == MessageSender.user;
    final bubbleColor =
        isUser ? MobilePalette.primary : MobilePalette.surfaceStrong;
    final textColor = isUser ? Colors.white : MobilePalette.textPrimary;

    Widget child;
    if (message.isLoading && message.text.isEmpty) {
      child = const SizedBox(
        width: 72,
        child: SpinKitThreeBounce(color: MobilePalette.primary, size: 16),
      );
    } else {
      child = ChatMarkdown(text: message.text, textColor: textColor);
    }

    child = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [ToolCallRecords(message: message), child],
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Align(
            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.8,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isUser ? 20 : 10),
                  topRight: Radius.circular(isUser ? 10 : 20),
                  bottomLeft: const Radius.circular(20),
                  bottomRight: const Radius.circular(20),
                ),
                border: isUser ? null : Border.all(color: MobilePalette.border),
              ),
              child: child,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            formatMobileClock(message.timestamp),
            style: const TextStyle(
              color: MobilePalette.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _useSuggestion(String prompt) {
    _textController.value = TextEditingValue(
      text: prompt,
      selection: TextSelection.collapsed(offset: prompt.length),
    );
    _composerFocus.requestFocus();
  }

  Widget _buildEmptyState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: (constraints.maxHeight - 48).clamp(0, double.infinity),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: MobilePalette.primarySoft,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: MobilePalette.primary,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      '让想法，从这里开始',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.8,
                        color: MobilePalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '一起探索问题、整理思路，或创造下一份作品。',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.6,
                        color: MobilePalette.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: [
                        _suggestion(
                          Icons.edit_note_rounded,
                          '帮我写作',
                          '请帮我写一段内容，主题是：',
                        ),
                        _suggestion(
                          Icons.lightbulb_outline_rounded,
                          '激发灵感',
                          '请和我一起头脑风暴，方向是：',
                        ),
                        _suggestion(Icons.code_rounded, '解决问题', '请帮我分析这个问题：'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _suggestion(IconData icon, String label, String prompt) {
    return OutlinedButton.icon(
      onPressed: () => _useSuggestion(prompt),
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: MobilePalette.textPrimary,
        backgroundColor: MobilePalette.surfaceStrong,
        side: const BorderSide(color: MobilePalette.border),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildComposer() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 840),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: MobileSurface(
            padding: const EdgeInsets.all(12),
            radius: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _textController,
                  focusNode: _composerFocus,
                  maxLines: 5,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  decoration: const InputDecoration(
                    hintText: '输入你的想法，或提出一个问题…',
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.fromLTRB(8, 10, 8, 16),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: widget.onOpenImages,
                      icon: const Icon(Icons.image_outlined),
                      tooltip: '创作图片',
                    ),
                    IconButton(
                      onPressed: widget.onOpenVideo,
                      icon: const Icon(Icons.smart_display_outlined),
                      tooltip: '创作视频',
                    ),
                    IconButton(
                      onPressed:
                          () => setState(
                            () => _enableWebSearch = !_enableWebSearch,
                          ),
                      isSelected: _enableWebSearch,
                      style: IconButton.styleFrom(
                        backgroundColor:
                            _enableWebSearch
                                ? MobilePalette.primarySoft
                                : Colors.transparent,
                        foregroundColor:
                            _enableWebSearch
                                ? MobilePalette.primary
                                : MobilePalette.textSecondary,
                      ),
                      icon: const Icon(Icons.public_rounded),
                      tooltip: _enableWebSearch ? '关闭网页搜索' : '开启网页搜索',
                    ),
                    const Spacer(),
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _textController,
                      builder:
                          (context, value, child) => IconButton.filled(
                            tooltip:
                                _isLoading
                                    ? AppLocalizations.of(context)!.stopToolRun
                                    : '发送消息',
                            onPressed:
                                _isLoading
                                    ? stopGeneration
                                    : value.text.trim().isNotEmpty
                                    ? _sendMessage
                                    : null,
                            icon:
                                _isLoading
                                    ? const Icon(Icons.stop_rounded)
                                    : const Icon(Icons.arrow_upward_rounded),
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _toolRun?.cancel();
    _composerFocus.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatModel = context.watch<ChatModelProvider>();
    return DecoratedBox(
      decoration: buildMobileBackgroundDecoration(),
      child: Column(
        children: [
          MobileTopBar(
            leading: MobileIconCircleButton(
              icon: Icons.menu_rounded,
              tooltip: widget.onOpenAppMenu != null ? '打开菜单' : '查看会话',
              onTap: widget.onOpenAppMenu ?? _showSessionSheet,
            ),
            title: '对话',
            subtitle: '思考、探索与创作',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.onOpenAppMenu != null) ...[
                  MobileIconCircleButton(
                    icon: Icons.view_list_rounded,
                    tooltip: '查看会话',
                    onTap: _showSessionSheet,
                  ),
                  const SizedBox(width: 10),
                ],
                MobileIconCircleButton(
                  icon: Icons.edit_note_rounded,
                  tooltip: '新建对话',
                  onTap: startNewChat,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _showModelSheet,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                label: Text(
                  '${chatModel.selectedModel} · ${chatModel.selectedProvider}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                style: TextButton.styleFrom(
                  foregroundColor: MobilePalette.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child:
                _messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(top: 6, bottom: 12),
                      itemCount: _messages.length,
                      itemBuilder:
                          (context, index) => Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 840),
                              child: _buildMessageBubble(_messages[index]),
                            ),
                          ),
                    ),
          ),
          _buildComposer(),
        ],
      ),
    );
  }
}
