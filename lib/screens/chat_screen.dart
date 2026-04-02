import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart';
import 'dart:convert'; // For base64 decoding
import 'dart:io';
import 'package:chibot/models/chat_message.dart';
import 'package:chibot/models/chat_session.dart';
import 'package:chibot/models/image_session.dart';
import 'package:chibot/services/chat_session_service.dart';
import 'package:chibot/services/image_session_service.dart';
import 'package:chibot/providers/unified_settings_provider.dart';
import 'package:chibot/providers/api_key_provider.dart';
import 'package:chibot/providers/chat_model_provider.dart';
import 'package:chibot/providers/image_model_provider.dart';
import 'package:chibot/providers/search_provider.dart';
import 'package:chibot/services/service_manager.dart';
import 'package:chibot/models/image_message.dart'; // Added for image messages
import 'package:chibot/services/image_generation_service.dart'
    as image_service; // Added for image generation
import 'package:chibot/services/image_save_service.dart';
import 'package:chibot/services/markdown_export_service.dart';
import 'package:chibot/l10n/app_localizations.dart';
import 'package:chibot/widgets/chat_markdown.dart';
import 'settings_screen.dart';
import 'about_screen.dart';
import 'video_generation_screen.dart';
import 'update_dialog.dart';
import '../services/update_service.dart';
import 'package:flutter/services.dart'; // For Clipboard
import 'package:chibot/services/search_service_factory.dart';
import 'package:chibot/models/available_model.dart' as available_model;
import 'package:chibot/services/exceptions/missing_api_key_exception.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // Sidebar width - can be adjusted
  final double _sidebarWidth = 260.0;
  final List<ChatMessage> _messages = [];
  final ChatSessionService _sessionService = ChatSessionService();
  List<ChatSession> _chatSessions = [];
  String? _currentSessionId;
  final ImageSessionService _imageSessionService = ImageSessionService();
  List<ImageSession> _imageSessions = [];
  String? _currentImageSessionId;
  final TextEditingController _textController = TextEditingController();
  final image_service.ImageGenerationService _imageGenerationService =
      image_service.ImageGenerationService(); // Added
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _enableWebSearch = false;

  @override
  void initState() {
    super.initState();
    _loadChatSessions();
    _loadImageSessions();
  }

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
    setState(() {
      _messages.clear();
      _messages.addAll(session.messages);
      _currentSessionId = session.id;
      _isLoading = false;
    });
    _scrollToBottom();
  }

  void _startNewImageSession() {
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
    setState(() {
      _messages.clear();
      _messages.addAll(session.messages);
      _currentImageSessionId = session.id;
      _isLoading = false;
    });
    _scrollToBottom();
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
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: text,
          sender: MessageSender.ai,
          timestamp: DateTime.now(),
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

  ChatMessage _createAiPlaceholderMessage() {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: '',
      sender: MessageSender.ai,
      timestamp: DateTime.now(),
      isLoading: true,
    );
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
          isLoading: isLoading,
        );
      }
    });
  }

  ChatSession? _buildCurrentSessionSnapshot() {
    if (_currentSessionId == null) {
      return null;
    }

    final existingSession = _chatSessions.firstWhere(
      (s) => s.id == _currentSessionId!,
    );

    return ChatSession(
      id: _currentSessionId!,
      title: existingSession.title,
      messages: List.from(_messages),
      createdAt: existingSession.createdAt,
      updatedAt: DateTime.now(),
    );
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

  List<ChatMessage> _buildAiContextMessages(String prompt) {
    final aiMessages = List<ChatMessage>.from(_messages);
    if (_enableWebSearch && aiMessages.isNotEmpty) {
      aiMessages.removeLast();
      aiMessages.add(
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: prompt,
          sender: MessageSender.user,
          timestamp: DateTime.now(),
        ),
      );
    }

    return aiMessages.where((msg) => msg.sender != MessageSender.user).toList();
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
          text: 'Error: ${error.toString()}',
          sender: MessageSender.ai,
          timestamp: _messages[lastMessageIndex].timestamp,
          isLoading: false,
        );
      } else {
        _messages.add(
          ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            text: 'Error: ${error.toString()}',
            sender: MessageSender.ai,
            timestamp: DateTime.now(),
          ),
        );
      }
      _isLoading = false;
    });
  }

  int _findLoadingImageMessageIndex(String prompt) {
    for (int i = _messages.length - 1; i >= 0; i--) {
      if (_messages[i] is ImageMessage &&
          (_messages[i] as ImageMessage).text == prompt &&
          ((_messages[i] as ImageMessage).isLoading ?? false)) {
        return i;
      }
    }
    return -1;
  }

  void _updateLoadingImageMessage({
    required String prompt,
    required String imageUrl,
    String? error,
  }) {
    final imageMessageIndex = _findLoadingImageMessageIndex(prompt);
    if (imageMessageIndex == -1) {
      return;
    }

    final currentMessage = _messages[imageMessageIndex] as ImageMessage;
    _messages[imageMessageIndex] = ImageMessage(
      id: currentMessage.id,
      text: prompt,
      imageUrl: imageUrl,
      sender: MessageSender.ai,
      timestamp: currentMessage.timestamp,
      isLoading: false,
      error: error,
    );
  }

  Future<void> _saveImageSession({
    required String prompt,
    required ImageModelProvider imageModelProvider,
  }) async {
    if (_currentImageSessionId == null) {
      _currentImageSessionId = DateTime.now().millisecondsSinceEpoch.toString();
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
      print(
        'Warning: Existing image session with ID $_currentImageSessionId not found. Creating a new session: $e',
      );
      _currentImageSessionId = DateTime.now().millisecondsSinceEpoch.toString();
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

  void _addImageGenerationPlaceholders(String prompt) {
    if (!mounted) return;

    setState(() {
      _messages.add(
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: '/imagine $prompt',
          sender: MessageSender.user,
          timestamp: DateTime.now(),
        ),
      );
      _messages.add(
        ImageMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: prompt,
          imageUrl: '',
          sender: MessageSender.ai,
          timestamp: DateTime.now(),
          isLoading: true,
        ),
      );
      _isLoading = true;
    });
  }

  void _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

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
    final prompt = await _buildPromptWithWebSearch(
      text: text,
      searchProvider: searchProvider,
      apiKeys: apiKeys,
    );
    if (prompt == null) {
      return;
    }

    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
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
    _scrollToBottom();

    if (apiKeys.apiKey == null || apiKeys.apiKey!.isEmpty) {
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
      final chatModelProvider = Provider.of<ChatModelProvider>(
        context,
        listen: false,
      );

      final chatService = ServiceManager.createChatService(
        chatModel: chatModelProvider,
        apiKeys: apiKeys,
      );
      final stream = chatService.generateResponse(
        prompt: prompt,
        context: _buildAiContextMessages(prompt),
        model: chatModelProvider.selectedModel,
      );

      String fullResponse = "";
      await for (final chunk in stream) {
        fullResponse += chunk;
        _replaceLastAiMessage(text: fullResponse, isLoading: true);
        _scrollToBottom();
      }

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
              isLoading: false, // Done loading
            );
          }
          _isLoading = false; // Overall loading state for the input field
        });
      }
      await _saveCurrentSessionSnapshot();
    } catch (e) {
      if (mounted) {
        if (e is MissingApiKeyException) {
          _handleMissingApiKeyError();
          _showMissingApiKeyDialog(e);
        } else {
          _handleGenericStreamError(e);
        }
      }
      print("Error receiving stream: $e");
    } finally {
      // Ensure isLoading is false if not already set by success/error blocks
      if (mounted && _isLoading) {
        setState(() {
          _isLoading = false;
        });
      }
      _scrollToBottom();
    }
    await _saveCurrentSessionSnapshot(reloadSessions: true);
  }

  /// 显示 API 密钥缺失错误对话框
  void _showMissingApiKeyDialog(MissingApiKeyException exception) {
    showDialog(
      context: context,
      builder:
          (BuildContext context) => AlertDialog(
            title: const Text('API Key Not Configured'),
            content: SingleChildScrollView(
              child: Text(exception.userFriendlyMessage),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Dismiss'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Navigate to settings screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
                child: const Text('Go to Settings'),
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
            title: const Text('Delete'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(AppLocalizations.of(context)?.cancel ?? 'Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: errorColor,
                  foregroundColor: onErrorColor,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    return confirmed == true;
  }

  Future<void> _deleteChatSession(ChatSession session, ThemeData theme) async {
    final confirmed = await _confirmDelete(
      message: 'Delete this chat history?',
      errorColor: theme.colorScheme.error,
      onErrorColor: theme.colorScheme.onError,
    );
    if (!confirmed) {
      return;
    }

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
      message: 'Delete this image session?',
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

  Widget _buildSidebarSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildChatSessionsSection(BuildContext context, ThemeData theme) {
    if (_chatSessions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSidebarSectionHeader(context, 'Recent Chats'),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _chatSessions.length,
              itemBuilder: (context, index) {
                final session = _chatSessions[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: _buildSidebarItem(
                    context,
                    Icons.chat_outlined,
                    session.title,
                    isSelected: _currentSessionId == session.id,
                    onTap: () => _loadSession(session),
                    onExport: () async {
                      await MarkdownExportService.exportToMarkdown(
                        session,
                        context,
                      );
                    },
                    onDelete: () => _deleteChatSession(session, theme),
                    exportLabel: AppLocalizations.of(context)!.exportToMarkdown,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSessionsSection(BuildContext context, ThemeData theme) {
    if (_imageSessions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSidebarSectionHeader(context, 'Image Sessions'),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _imageSessions.length,
              itemBuilder: (context, index) {
                final session = _imageSessions[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: _buildSidebarItem(
                    context,
                    Icons.image_outlined,
                    session.title,
                    isSelected: _currentImageSessionId == session.id,
                    onTap: () => _loadImageSession(session),
                    onExport: () async {
                      await ImageSaveService.exportImageHistory(
                        session,
                        context,
                      );
                    },
                    onDelete: () => _deleteImageSession(session, theme),
                    exportLabel: AppLocalizations.of(context)!.exportToImg,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: _sidebarWidth,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border:
            Platform.isMacOS
                ? Border(right: BorderSide(color: theme.dividerColor, width: 1))
                : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Header section
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App title
                Text(
                  'Chibot AI',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                // Search bar
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(
                      Platform.isMacOS ? 8 : 12,
                    ),
                  ),
                  child: TextField(
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.search,
                      hintStyle: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant.withOpacity(
                          0.6,
                        ),
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: theme.colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Navigation section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _buildSidebarItem(
                  context,
                  Icons.chat_bubble_outline,
                  'Chi Chat',
                  isSelected: true,
                ),
                const SizedBox(height: 8),
                _buildSidebarItem(
                  context,
                  Icons.add_comment_outlined,
                  AppLocalizations.of(context)!.newChat,
                  onTap: _startNewChat,
                ),
                const SizedBox(height: 8),
                _buildSidebarItem(
                  context,
                  Icons.add_photo_alternate_outlined,
                  AppLocalizations.of(context)!.newImageSession,
                  onTap: _startNewImageSession,
                ),
                const SizedBox(height: 8),
                _buildSidebarItem(
                  context,
                  Icons.videocam_outlined,
                  'Video Generation',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const VideoGenerationScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                _buildSidebarItem(
                  context,
                  Icons.download_outlined,
                  AppLocalizations.of(context)!.exportAllChats,
                  onTap: () async {
                    if (_chatSessions.isNotEmpty) {
                      await MarkdownExportService.exportMultipleToMarkdown(
                        _chatSessions,
                        context,
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            AppLocalizations.of(
                              context,
                            )!.noChatSessionsToExport,
                          ),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Chat sessions section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildChatSessionsSection(context, theme),
                _buildImageSessionsSection(context, theme),
              ],
            ),
          ),

          // Bottom section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: theme.dividerColor, width: 1),
              ),
            ),
            child: Column(
              children: [
                _buildSidebarItem(
                  context,
                  Icons.info_outline,
                  AppLocalizations.of(context)!.about,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AboutScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                // Removed settings item from sidebar
                _buildSidebarItem(
                  context,
                  Icons.system_update,
                  '检查更新',
                  onTap: () async {
                    final release = await UpdateService.fetchLatestRelease();
                    if (release == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('检查更新失败，请稍后重试')),
                      );
                      return;
                    }
                    final latestVersion = release['tag_name'] ?? '';
                    final downloadUrl = UpdateService.getDownloadUrl(release);
                    if (downloadUrl == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('未找到适用于当前平台的安装包')),
                      );
                      return;
                    }
                    final fileName = downloadUrl.split('/').last;
                    final releaseNotes = release['body'] ?? '';
                    showDialog(
                      context: context,
                      builder:
                          (_) => UpdateDialog(
                            latestVersion: latestVersion,
                            releaseNotes: releaseNotes,
                            downloadUrl: downloadUrl,
                            fileName: fileName,
                          ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(
    BuildContext context,
    IconData icon,
    String text, {
    bool isSelected = false,
    VoidCallback? onTap,
    VoidCallback? onDelete,
    VoidCallback? onExport,
    String? exportLabel, // 新增参数
  }) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap ?? () {},
        borderRadius: BorderRadius.circular(Platform.isMacOS ? 6 : 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? theme.colorScheme.primaryContainer.withOpacity(0.8)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(Platform.isMacOS ? 6 : 12),
            border:
                isSelected
                    ? Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                      width: 1,
                    )
                    : null,
          ),
          child: Row(
            children: <Widget>[
              Icon(
                icon,
                color:
                    isSelected
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Text(
                  text,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color:
                        isSelected
                            ? theme.colorScheme.onPrimaryContainer
                            : theme.colorScheme.onSurfaceVariant,
                    fontWeight:
                        isSelected ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ),
              if (onDelete != null)
                Builder(
                  builder:
                      (itemContext) => IconButton(
                        icon: Icon(
                          Icons.more_horiz,
                          size: 18,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        tooltip: 'More options',
                        onPressed: () async {
                          // Show context menu for delete option
                          final renderObject = itemContext.findRenderObject();
                          if (renderObject is RenderBox) {
                            final RenderBox renderBox = renderObject;
                            final Offset position = renderBox.localToGlobal(
                              Offset.zero,
                            );

                            await showMenu(
                              context: itemContext,
                              position: RelativeRect.fromLTRB(
                                position.dx,
                                position.dy + renderBox.size.height,
                                position.dx + renderBox.size.width,
                                position.dy + renderBox.size.height + 100,
                              ),
                              items: [
                                if (onExport != null)
                                  PopupMenuItem<String>(
                                    value: 'export',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.download_outlined,
                                          size: 18,
                                          color: theme.colorScheme.primary,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          exportLabel ??
                                              AppLocalizations.of(
                                                context,
                                              )!.exportToImg,
                                        ),
                                      ],
                                    ),
                                  ),
                                PopupMenuItem<String>(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.delete_outline,
                                        size: 18,
                                        color: theme.colorScheme.error,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Delete',
                                        style: TextStyle(
                                          color: theme.colorScheme.error,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ).then((value) {
                              if (value == 'delete') {
                                onDelete?.call();
                              } else if (value == 'export') {
                                onExport?.call();
                              }
                            });
                          } else {
                            // 不是 RenderBox，无法显示菜单，可选：弹出提示或忽略
                          }
                        },
                      ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine if we should show the sidebar based on screen width
    // For simplicity, we'll always show it here, but in a real app, you might hide it on smaller screens.

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 1,
        title: Row(
          children: [
            Image.asset('assets/images/logo.png', height: 24.0, width: 24.0),
            const SizedBox(width: 8.0),
            Text(
              AppLocalizations.of(context)!.chatGPTTitle,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.normal,
                fontSize: 18,
              ),
            ),
          ],
        ),
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu, color: Colors.black87),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.black87),
            tooltip: AppLocalizations.of(context)!.settings,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(width: _sidebarWidth, child: _buildSidebar(context)),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(8.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message, index); // Pass index
              },
            ),
          ),
          if (_isLoading)
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(strokeWidth: 2),
                  SizedBox(width: 10),
                  Text(AppLocalizations.of(context)!.aiIsThinking),
                ],
              ),
            ),
          _buildInputField(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, int index) {
    // Added index
    final bool isUserMessage = message.sender == MessageSender.user;
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;

    if (message is ImageMessage) {
      return _buildImageMessageBubble(
        message,
        isUserMessage,
        index == _messages.length - 1,
        localizations,
      );
    }

    final bool isAiLoading =
        message.sender == MessageSender.ai && (message.isLoading ?? false);
    Widget messageContent;
    if (isAiLoading && message.text.isEmpty) {
      messageContent = SizedBox(
        width: 80,
        height: 20,
        child: Center(
          child: SpinKitThreeBounce(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
            size: 18.0,
          ),
        ),
      );
    } else {
      messageContent = ChatMarkdown(
        text: message.text,
        textColor:
            isUserMessage
                ? theme.colorScheme.onPrimaryContainer
                : theme.colorScheme.onSurfaceVariant,
      );
    }

    return Align(
      alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth:
              MediaQuery.of(context).size.width * 0.7 -
              _sidebarWidth *
                  (MediaQuery.of(context).size.width > 600 ? 0.7 : 0),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 16.0),
        child: Material(
          elevation: Platform.isMacOS ? 1 : 2,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isUserMessage ? 20.0 : 8.0),
            topRight: Radius.circular(isUserMessage ? 8.0 : 20.0),
            bottomLeft: const Radius.circular(20.0),
            bottomRight: const Radius.circular(20.0),
          ),
          surfaceTintColor: theme.colorScheme.surfaceTint,
          color:
              isUserMessage
                  ? theme.colorScheme.primaryContainer
                  : theme.colorScheme.surfaceVariant,
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: 12.0,
              horizontal: 16.0,
            ),
            child: messageContent,
          ),
        ),
      ),
    );
  }

  Widget _buildImageMessageBubble(
    ImageMessage message,
    bool isUser,
    bool isLastMessage,
    AppLocalizations localizations,
  ) {
    final imageModel = Provider.of<ImageModelProvider>(context, listen: false);
    // Determine aspect ratio
    String aspectRatio =
        imageModel.selectedImageProvider == 'Black Forest Labs'
            ? (imageModel.bflAspectRatio ?? '1:1')
            : '1:1';
    double width = 250;
    double height = 250;
    switch (aspectRatio) {
      case '16:9':
        width = 280;
        height = 158;
        break;
      case '9:16':
        width = 158;
        height = 280;
        break;
      case '4:3':
        width = 266;
        height = 200;
        break;
      case '3:2':
        width = 270;
        height = 180;
        break;
      case '1:1':
      default:
        width = 250;
        height = 250;
        break;
    }
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          GestureDetector(
            onLongPress: () {
              if (Platform.isIOS || Platform.isAndroid) {
                _showImageOptionsBottomSheet(message, localizations);
              }
            },
            onSecondaryTapDown: (details) {
              if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
                showContextMenu(
                  context,
                  contextMenu: ContextMenu(
                    entries: [
                      MenuItem(
                        label: localizations.saveImage,
                        onSelected: () {
                          if (message.imageUrl != null &&
                              message.imageUrl!.isNotEmpty) {
                            ImageSaveService.saveImage(
                              message.imageUrl!,
                              context,
                            );
                          }
                        },
                      ),
                      MenuItem(
                        label: localizations.saveToDirectory,
                        onSelected: () {
                          if (message.imageUrl != null &&
                              message.imageUrl!.isNotEmpty) {
                            ImageSaveService.saveImageToDirectory(
                              message.imageUrl!,
                              context,
                            );
                          }
                        },
                      ),
                    ],
                    position: details.globalPosition,
                  ),
                );
              }
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: _buildImageWidget(message, width, height, localizations),
            ),
          ),
          // 右上角按钮
          Positioned(
            top: 4,
            right: 4,
            child: Material(
              color: Colors.transparent,
              child: PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, size: 22, color: Colors.black54),
                onSelected: (value) async {
                  if (value == 'save_image') {
                    final imageSource = message.bestImageSource;
                    if (imageSource != null && imageSource.isNotEmpty) {
                      await ImageSaveService.saveImage(imageSource, context);
                    }
                  } else if (value == 'save_prompt') {
                    await Clipboard.setData(
                      ClipboardData(text: message.text ?? ''),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(localizations.promptCopied)),
                    );
                  }
                },
                itemBuilder:
                    (context) => [
                      PopupMenuItem<String>(
                        value: 'save_image',
                        child: Row(
                          children: [
                            Icon(Icons.download, size: 18),
                            SizedBox(width: 8),
                            Text(localizations.saveImage),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'save_prompt',
                        child: Row(
                          children: [
                            Icon(Icons.text_snippet, size: 18),
                            SizedBox(width: 8),
                            Text(localizations.savePrompt),
                          ],
                        ),
                      ),
                    ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border:
            Platform.isMacOS
                ? Border(top: BorderSide(color: theme.dividerColor, width: 1))
                : null,
        boxShadow:
            Platform.isMacOS
                ? null
                : [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withOpacity(0.1),
                    spreadRadius: 0,
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
      ),
      child: SafeArea(
        child: Row(
          children: <Widget>[
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(
                    Platform.isMacOS ? 8 : 24,
                  ),
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.2),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                        decoration: InputDecoration(
                          hintText:
                              AppLocalizations.of(context)!.askAnyQuestion,
                          hintStyle: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant
                                .withOpacity(0.7),
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20.0,
                            vertical: Platform.isMacOS ? 12.0 : 16.0,
                          ),
                        ),
                        onSubmitted: (_) => _isLoading ? null : _sendMessage(),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                      ),
                    ),
                    // Add web search toggle
                    Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: Consumer<UnifiedSettingsProvider>(
                        builder: (context, settings, _) {
                          final isTextModel =
                              settings.selectedModelType ==
                              available_model.ModelType.text;
                          final isActive = isTextModel && _enableWebSearch;
                          return Ink(
                            decoration: BoxDecoration(
                              color:
                                  isActive
                                      ? theme.colorScheme.primary
                                      : Colors.blueGrey,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              onPressed:
                                  isTextModel
                                      ? () {
                                        setState(() {
                                          _enableWebSearch = !_enableWebSearch;
                                        });
                                      }
                                      : null,
                              icon: Icon(
                                Icons.public,
                                size: 20,
                                color:
                                    isActive
                                        ? Colors.blue
                                        : isTextModel
                                        ? theme.colorScheme.onSurfaceVariant
                                        : theme.colorScheme.onSurfaceVariant
                                            .withOpacity(0.4),
                              ),
                              tooltip: 'Web Search',
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12.0),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _textController,
              builder: (context, value, child) {
                final bool isEmpty = value.text.isEmpty;
                return FilledButton(
                  onPressed: _isLoading || isEmpty ? null : _sendMessage,
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        _isLoading || isEmpty
                            ? theme.colorScheme.surfaceVariant
                            : theme.colorScheme.primary,
                    foregroundColor:
                        _isLoading || isEmpty
                            ? theme.colorScheme.onSurfaceVariant
                            : theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.all(12.0),
                    minimumSize: const Size(48, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        Platform.isMacOS ? 6 : 24,
                      ),
                    ),
                  ),
                  child: Icon(Icons.arrow_upward_rounded, size: 20),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showImageOptionsBottomSheet(
    ImageMessage message,
    AppLocalizations localizations,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.download),
                title: Text(localizations.saveImage),
                onTap: () {
                  Navigator.pop(context);
                  if (message.imageUrl != null &&
                      message.imageUrl!.isNotEmpty) {
                    ImageSaveService.saveImage(message.imageUrl!, context);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.folder),
                title: Text(localizations.saveToDirectory),
                onTap: () {
                  Navigator.pop(context);
                  if (message.imageUrl != null &&
                      message.imageUrl!.isNotEmpty) {
                    ImageSaveService.saveImageToDirectory(
                      message.imageUrl!,
                      context,
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _generateImage(String prompt) async {
    final apiKeys = Provider.of<ApiKeyProvider>(context, listen: false);
    final imageModelProvider = Provider.of<ImageModelProvider>(
      context,
      listen: false,
    );
    final unifiedSettings = Provider.of<UnifiedSettingsProvider>(
      context,
      listen: false,
    );

    _addImageGenerationPlaceholders(prompt);
    _scrollToBottom();

    final imageApiKey = apiKeys.getImageApiKeyForProvider(
      imageModelProvider.selectedImageProvider,
    );
    if (imageApiKey == null || imageApiKey.isEmpty) {
      if (mounted) {
        setState(() {
          final imageMessageIndex = _findLoadingImageMessageIndex(prompt);
          if (imageMessageIndex != -1) {
            _updateLoadingImageMessage(
              prompt: prompt,
              imageUrl: '',
              error: AppLocalizations.of(context)!.apiKeyNotSetError,
            );
          } else {
            _messages.add(
              ChatMessage(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                text: AppLocalizations.of(context)!.apiKeyNotSetError,
                sender: MessageSender.ai,
                timestamp: DateTime.now(),
              ),
            );
          }
          _isLoading = false;
        });
      }
      _scrollToBottom();
      return;
    }

    try {
      final imageUrl = await _imageGenerationService.generateImage(
        apiKey: imageApiKey, // Use correct image API key for selected provider
        prompt: prompt,
        model: imageModelProvider.selectedImageModel,
        providerBaseUrl: imageModelProvider.imageProviderUrl,
        aspectRatio:
            imageModelProvider.selectedImageProvider == 'Black Forest Labs'
                ? imageModelProvider.bflAspectRatio
                : null,
      );

      if (mounted) {
        setState(() {
          final imageMessageIndex = _findLoadingImageMessageIndex(prompt);
          if (imageMessageIndex != -1) {
            if (imageUrl == null || imageUrl.isEmpty) {
              _updateLoadingImageMessage(
                prompt: prompt,
                imageUrl: '',
                error: AppLocalizations.of(context)!.failedToGenerateImageNoUrl,
              );
            } else {
              _updateLoadingImageMessage(prompt: prompt, imageUrl: imageUrl);
            }
          }
          _isLoading = false;
        });
      }
      if (imageUrl != null && imageUrl.isNotEmpty) {
        await _saveImageSession(
          prompt: prompt,
          imageModelProvider: imageModelProvider,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          final imageMessageIndex = _findLoadingImageMessageIndex(prompt);
          if (imageMessageIndex != -1) {
            _updateLoadingImageMessage(
              prompt: prompt,
              imageUrl: '',
              error: AppLocalizations.of(
                context,
              )!.errorGeneratingImage(e.toString()),
            );
          } else {
            _messages.add(
              ChatMessage(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                text: AppLocalizations.of(
                  context,
                )!.errorGeneratingImage(e.toString()),
                sender: MessageSender.ai,
                timestamp: DateTime.now(),
              ),
            );
          }
          _isLoading = false;
        });
      }
      print("Error generating image: $e");
    } finally {
      if (mounted && _isLoading) {
        setState(() {
          _isLoading = false;
        });
      }
      _scrollToBottom();
    }
  }

  Widget _buildImageWidget(
    ImageMessage message,
    double width,
    double height,
    AppLocalizations localizations,
  ) {
    // Use the bestImageSource to get the most appropriate image source
    final imageSource = message.bestImageSource;

    if (imageSource == null) {
      return Container(
        width: width,
        height: height,
        color: Colors.grey[200],
        child: Center(
          child: Text(
            localizations.errorLoadingImage,
            style: TextStyle(color: Colors.red[700]),
          ),
        ),
      );
    }

    // Handle local file path
    if (message.imagePath != null) {
      return Image.file(
        File(message.imagePath!),
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width,
            height: height,
            color: Colors.grey[200],
            child: Center(
              child: Text(
                localizations.errorLoadingImage,
                style: TextStyle(color: Colors.red[700]),
              ),
            ),
          );
        },
      );
    }

    // Handle base64 data URLs (data:image/...)
    if (message.imageUrl?.startsWith('data:image') == true) {
      return Image.memory(
        base64Decode(message.imageUrl!.split(',').last),
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width,
            height: height,
            color: Colors.grey[200],
            child: Center(
              child: Text(
                localizations.errorLoadingImage,
                style: TextStyle(color: Colors.red[700]),
              ),
            ),
          );
        },
      );
    }

    // Handle direct base64 image data
    if (message.imageData != null) {
      return Image.memory(
        base64Decode(message.imageData!),
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width,
            height: height,
            color: Colors.grey[200],
            child: Center(
              child: Text(
                localizations.errorLoadingImage,
                style: TextStyle(color: Colors.red[700]),
              ),
            ),
          );
        },
      );
    }

    // Handle network URLs
    if (message.imageUrl != null) {
      return Image.network(
        message.imageUrl!,
        width: width,
        height: height,
        fit: BoxFit.cover,
        loadingBuilder: (
          BuildContext context,
          Widget child,
          ImageChunkEvent? loadingProgress,
        ) {
          if (loadingProgress == null) return child;
          return SizedBox(
            width: width,
            height: height,
            child: Center(
              child: CircularProgressIndicator(
                value:
                    loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width,
            height: height,
            color: Colors.grey[200],
            child: Center(
              child: Text(
                localizations.errorLoadingImage,
                style: TextStyle(color: Colors.red[700]),
              ),
            ),
          );
        },
      );
    }

    // Fallback if no valid image source found
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: Center(
        child: Text(
          localizations.errorLoadingImage,
          style: TextStyle(color: Colors.red[700]),
        ),
      ),
    );
  }
}
