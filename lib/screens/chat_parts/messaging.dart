part of '../chat_screen.dart';

/// messaging.dart - _ChatScreenState 的拆分方法（extension 形式，与主文件同一 library，可访问私有成员）
extension _MessagingExt on _ChatScreenState {
  void _sendMessage() async {
    final generation = _conversationGeneration;
    bool isCurrent() => mounted && generation == _conversationGeneration;
    final text = _textController.text.trim();
    if (text.isEmpty || _isLoading) return;

    final unifiedSettings = Provider.of<UnifiedSettingsProvider>(
      context,
      listen: false,
    );
    final searchProvider = Provider.of<SearchProvider>(context, listen: false);
    final apiKeys = Provider.of<ApiKeyProvider>(context, listen: false);

    if (unifiedSettings.selectedModelType == available_model.ModelType.image) {
      _generateImage(text);
      _textController.clear();
      return;
    }

    _textController.clear();
    setState(() => _isLoading = true);
    final prompt = await _buildPromptWithWebSearch(
      text: text,
      searchProvider: searchProvider,
      apiKeys: apiKeys,
    );
    if (!mounted || !isCurrent()) return;
    if (prompt == null) {
      setState(() => _isLoading = false);
      return;
    }

    final history = List<ChatMessage>.from(_messages);
    final userMessage = ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: prompt,
      sender: MessageSender.user,
      timestamp: DateTime.now(),
    );

    if (mounted) {
      setState(() {
        _messages.add(userMessage);
        _isLoading = true;
      });
    }

    await _ensureCurrentSession(userMessage, prompt);
    if (!mounted || !isCurrent()) return;
    _scrollToBottom();

    final chatModelProvider = Provider.of<ChatModelProvider>(
      context,
      listen: false,
    );
    final providerApiKey = apiKeys.getApiKeyForProvider(
      chatModelProvider.selectedProvider,
    );
    if (providerApiKey == null || providerApiKey.isEmpty) {
      _appendAiMessage(AppLocalizations.of(context)!.apiKeyNotSetError);
      return;
    }

    final aiMessage = _createAiPlaceholderMessage();

    if (mounted) {
      setState(() {
        _messages.add(aiMessage);
      });
    }
    _scrollToBottom();

    try {
      final chatService = ChatServiceFactory.createFromProviders(
        chatModel: chatModelProvider,
        apiKeys: apiKeys,
      );
      await _saveCurrentSessionSnapshot();
      if (!mounted || !isCurrent()) return;
      final messageId = aiMessage.id;
      final run = ToolChatRun(
        context: context,
        sessionId: _currentSessionId!,
        messageId: messageId,
        onMetadata: (metadata) {
          if (!mounted) return;
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

      String fullResponse = "";
      await for (final chunk in stream) {
        if (!mounted || !isCurrent()) return;
        fullResponse += chunk;
        _replaceLastAiMessage(text: fullResponse, isLoading: true);
        _scrollToBottom();
      }

      if (!mounted || !isCurrent()) return;
      if (mounted) {
        setState(() {
          final lastMessageIndex = _messages.length - 1;
          if (lastMessageIndex >= 0 &&
              _messages[lastMessageIndex].sender == MessageSender.ai) {
            _messages[lastMessageIndex] = ChatMessage(
              id: _messages[lastMessageIndex].id,
              text:
                  fullResponse.isEmpty
                      ? AppLocalizations.of(context)!.noResponseFromAI
                      : fullResponse, // Handle empty response
              sender: MessageSender.ai,
              timestamp: _messages[lastMessageIndex].timestamp,
              metadata: _messages[lastMessageIndex].metadata,
              isLoading: false, // Done loading
            );
          }
          _isLoading = false; // Overall loading state for the input field
        });
      }
      await _saveCurrentSessionSnapshot();
    } catch (e) {
      if (!mounted || !isCurrent()) return;
      if (mounted) {
        if (e is MissingApiKeyException) {
          _handleMissingApiKeyError();
          _showMissingApiKeyDialog(e);
        } else {
          _handleGenericStreamError(e);
        }
      }
      debugPrint('Error receiving stream: $e');
    } finally {
      // Ensure isLoading is false if not already set by success/error blocks
      if (isCurrent() && _isLoading) {
        setState(() {
          _isLoading = false;
        });
      }
      _scrollToBottom();
    }
    if (isCurrent()) await _saveCurrentSessionSnapshot(reloadSessions: true);
  }

  Future<String?> _buildPromptWithWebSearch({
    required String text,
    required SearchProvider searchProvider,
    required ApiKeyProvider apiKeys,
  }) async {
    if (!_enableWebSearch) {
      return text;
    }

    if (!SearchServiceFactory.isSearchFunctionalityAvailable(
      search: searchProvider,
      apiKeys: apiKeys,
    )) {
      _appendAiMessage('未启用任何网络搜索功能，请在设置中开启 Tavily 或 Google 搜索。');
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
        ChatMessage(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          text: text,
          sender: MessageSender.ai,
          timestamp: DateTime.now(),
        ),
      );
      _isLoading = false;
    });
    _scrollToBottom();
  }

  void _replaceLastAiMessage({required String text, required bool isLoading}) {
    if (!mounted) return;

    setState(() {
      final lastMessageIndex = _messages.length - 1;
      if (lastMessageIndex >= 0 &&
          _messages[lastMessageIndex].sender == MessageSender.ai) {
        _messages[lastMessageIndex] = ChatMessage(
          id: _messages[lastMessageIndex].id,
          text: text,
          sender: MessageSender.ai,
          timestamp: _messages[lastMessageIndex].timestamp,
          metadata: _messages[lastMessageIndex].metadata,
          isLoading: isLoading,
        );
      }
    });
  }

  void _stopGeneration() {
    _toolRun?.cancel();
    _conversationGeneration++;
    if (mounted && _isLoading) {
      setState(() {
        _isLoading = false;
        if (_messages.isNotEmpty && _messages.last.isAI) {
          _messages[_messages.length - 1] = _messages.last.copyWith(
            isLoading: false,
          );
        }
      });
      _saveCurrentSessionSnapshot();
    }
  }

  void _handleMissingApiKeyError() {
    if (!mounted) return;

    setState(() {
      final lastMessageIndex = _messages.length - 1;
      if (lastMessageIndex >= 0 &&
          _messages[lastMessageIndex].sender == MessageSender.ai) {
        _messages.removeAt(lastMessageIndex);
      }
      _isLoading = false;
    });
  }

  void _handleGenericStreamError(Object error) {
    if (!mounted) return;

    setState(() {
      final lastMessageIndex = _messages.length - 1;
      if (lastMessageIndex >= 0 &&
          _messages[lastMessageIndex].sender == MessageSender.ai) {
        _messages[lastMessageIndex] = ChatMessage(
          id: _messages[lastMessageIndex].id,
          text: '错误：${error.toString()}',
          sender: MessageSender.ai,
          timestamp: _messages[lastMessageIndex].timestamp,
          metadata: _messages[lastMessageIndex].metadata,
          isLoading: false,
        );
      } else {
        _messages.add(
          ChatMessage(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            text: '错误：${error.toString()}',
            sender: MessageSender.ai,
            timestamp: DateTime.now(),
          ),
        );
      }
      _isLoading = false;
    });
  }

  /// 显示 API 密钥缺失错误对话框
  void _showMissingApiKeyDialog(MissingApiKeyException exception) {
    showDialog(
      context: context,
      builder:
          (BuildContext context) => AlertDialog(
            title: const Text('API Key 未配置'),
            content: SingleChildScrollView(
              child: Text(exception.userFriendlyMessage),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('关闭'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Navigate to settings screen
                  _stopGeneration();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
                child: const Text('前往设置'),
              ),
            ],
          ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<bool> _confirmDelete({
    required String message,
    required Color errorColor,
    required Color onErrorColor,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('删除'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(AppLocalizations.of(context)?.cancel ?? '取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: errorColor,
                  foregroundColor: onErrorColor,
                ),
                child: const Text('删除'),
              ),
            ],
          ),
    );

    return confirmed == true;
  }
}
