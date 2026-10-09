part of '../mobile_chat_page.dart';

/// messaging.dart - MobileChatPageState 的拆分方法（extension 形式，与主文件同一 library，可访问私有成员）
extension _MessagingExt on MobileChatPageState {
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
      final chatService = ChatServiceFactory.createFromProviders(
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

  void _useSuggestion(String prompt) {
    _textController.value = TextEditingValue(
      text: prompt,
      selection: TextSelection.collapsed(offset: prompt.length),
    );
    _composerFocus.requestFocus();
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
}
