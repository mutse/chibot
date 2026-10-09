part of '../mobile_chat_page.dart';

/// sessions.dart - MobileChatPageState 的拆分方法（extension 形式，与主文件同一 library，可访问私有成员）
extension _SessionsExt on MobileChatPageState {
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

  Future<void> _saveCurrentSnapshot() async {
    final snapshot = _buildCurrentSnapshot();
    if (snapshot == null) {
      return;
    }
    await _sessionService.saveSession(snapshot);
    await _loadSessions();
    widget.onDataChanged?.call();
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
}
