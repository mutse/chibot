part of '../chat_screen.dart';

/// sessions.dart - _ChatScreenState 的拆分方法（extension 形式，与主文件同一 library，可访问私有成员）
extension _SessionsExt on _ChatScreenState {
  Future<void> _loadChatSessions() async {
    final sessions = await _sessionService.loadSessions();
    setState(() {
      _chatSessions = sessions;
      if (_chatSessions.isNotEmpty) {
        // Optionally load the last active session or start a new one
        // For now, we'll just ensure the list is loaded.
      }
    });
  }

  Future<void> _loadImageSessions() async {
    final sessions = await _imageSessionService.loadSessions();
    setState(() {
      _imageSessions = sessions;
    });
  }

  void _startNewChat() {
    _stopGeneration();
    final settings = Provider.of<UnifiedSettingsProvider>(
      context,
      listen: false,
    );
    settings.setSelectedModelType(available_model.ModelType.text);
    setState(() {
      _messages.clear();
      _currentSessionId = null;
      _isLoading = false;
    });
  }

  void _loadSession(ChatSession session) {
    _stopGeneration();
    setState(() {
      _messages.clear();
      _messages.addAll(session.messages);
      _currentSessionId = session.id;
      _isLoading = false;
    });
    _scrollToBottom();
  }

  void _startNewImageSession() {
    _stopGeneration();
    final settings = Provider.of<UnifiedSettingsProvider>(
      context,
      listen: false,
    );
    settings.setSelectedModelType(available_model.ModelType.image);
    setState(() {
      _messages.clear();
      _currentImageSessionId = null;
      _isLoading = false;
    });
  }

  void _loadImageSession(ImageSession session) {
    _stopGeneration();
    setState(() {
      _messages.clear();
      _messages.addAll(session.messages);
      _currentImageSessionId = session.id;
      _isLoading = false;
    });
    _scrollToBottom();
  }

  Future<void> _deleteChatSession(ChatSession session, ThemeData theme) async {
    final confirmed = await _confirmDelete(
      message: '要删除这段聊天记录吗？',
      errorColor: theme.colorScheme.error,
      onErrorColor: theme.colorScheme.onError,
    );
    if (!confirmed) {
      return;
    }

    if (_currentSessionId == session.id) _stopGeneration();
    await _sessionService.deleteSession(session.id);
    if (_currentSessionId == session.id) {
      setState(() {
        _messages.clear();
        _currentSessionId = null;
      });
    }
    _loadChatSessions();
  }

  Future<void> _deleteImageSession(
    ImageSession session,
    ThemeData theme,
  ) async {
    final confirmed = await _confirmDelete(
      message: '要删除这个图片会话吗？',
      errorColor: theme.colorScheme.error,
      onErrorColor: theme.colorScheme.onError,
    );
    if (!confirmed) {
      return;
    }

    await _imageSessionService.deleteSession(session.id);
    if (_currentImageSessionId == session.id) {
      setState(() {
        _messages.clear();
        _currentImageSessionId = null;
      });
    }
    _loadImageSessions();
  }

  Future<void> _ensureCurrentSession(
    ChatMessage userMessage,
    String prompt,
  ) async {
    if (_currentSessionId != null) {
      return;
    }

    _currentSessionId = DateTime.now().microsecondsSinceEpoch.toString();
    final newSession = ChatSession(
      id: _currentSessionId!,
      title: prompt.length > 30 ? '${prompt.substring(0, 30)}...' : prompt,
      messages: [userMessage],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _sessionService.saveSession(newSession);
    _loadChatSessions();
  }

  Future<void> _saveCurrentSessionSnapshot({
    bool reloadSessions = false,
  }) async {
    final currentSession = _buildCurrentSessionSnapshot();
    if (currentSession == null) {
      return;
    }

    await _sessionService.saveSession(currentSession);
    if (reloadSessions) {
      _loadChatSessions();
    }
  }

  Future<void> _saveImageSession({
    required String prompt,
    required ImageModelProvider imageModelProvider,
  }) async {
    if (_currentImageSessionId == null) {
      _currentImageSessionId = DateTime.now().microsecondsSinceEpoch.toString();
      final newSession = ImageSession(
        id: _currentImageSessionId!,
        title: prompt.length > 30 ? '${prompt.substring(0, 30)}...' : prompt,
        messages: _messages.whereType<ImageMessage>().toList(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        model: imageModelProvider.selectedImageModel,
      );
      await _imageSessionService.saveSession(newSession);
      _loadImageSessions();
      return;
    }

    ImageSession? existingSession;
    try {
      existingSession = _imageSessions.firstWhere(
        (s) => s.id == _currentImageSessionId,
      );
    } catch (e) {
      debugPrint(
        'Warning: Existing image session with ID $_currentImageSessionId not found. Creating a new session: $e',
      );
      _currentImageSessionId = DateTime.now().microsecondsSinceEpoch.toString();
    }

    final updatedSession = ImageSession(
      id: _currentImageSessionId!,
      title:
          existingSession?.title ??
          (prompt.length > 30 ? '${prompt.substring(0, 30)}...' : prompt),
      messages: _messages.whereType<ImageMessage>().toList(),
      createdAt: existingSession?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      model: imageModelProvider.selectedImageModel,
    );
    await _imageSessionService.saveSession(updatedSession);
    _loadImageSessions();
  }
}
