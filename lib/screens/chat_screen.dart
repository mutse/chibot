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
import 'package:chibot/providers/settings_provider.dart';
import 'package:chibot/services/service_manager.dart';
import 'package:chibot/models/image_message.dart'; // Added for image messages
import 'package:chibot/services/image_generation_service.dart'
    as image_service; // Added for image generation
import 'package:chibot/services/image_save_service.dart';
import 'package:chibot/services/markdown_export_service.dart';
import 'package:chibot/l10n/app_localizations.dart';
import 'settings_screen.dart';
import 'about_screen.dart';
import 'package:chibot/services/web_search_service.dart' as web_service;
import 'update_dialog.dart';
import '../services/update_service.dart';
import 'package:flutter/services.dart'; // For Clipboard
import 'package:chibot/services/search_service_manager.dart';
import 'package:chibot/models/available_model.dart' as available_model;

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
    final settings = Provider.of<SettingsProvider>(context, listen: false);
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
    final settings = Provider.of<SettingsProvider>(context, listen: false);
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

  void _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final settings = Provider.of<SettingsProvider>(context, listen: false);
    if (settings.selectedModelType == available_model.ModelType.image) {
      _generateImage(text);
      _textController.clear();
      return;
    }

    _textController.clear();

    String prompt = text;
    if (_enableWebSearch) {
      bool didSearch = false;
      // 1. Tavily
      if (settings.tavilySearchEnabled &&
          (settings.tavilyApiKey != null &&
              settings.tavilyApiKey!.isNotEmpty)) {
        try {
          final webResult = await web_service.WebSearchService(
            apiKey: settings.tavilyApiKey!,
          ).searchWeb(text);
          prompt = AppLocalizations.of(
            context,
          )!.webSearchPrompt(webResult, text);
          didSearch = true;
        } catch (e) {
          setState(() {
            _messages.add(
              ChatMessage(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                text: AppLocalizations.of(
                  context,
                )!.webSearchFailed(e.toString()),
                sender: MessageSender.ai,
                timestamp: DateTime.now(),
              ),
            );
            _isLoading = false;
          });
          _scrollToBottom();
          return;
        }
      }
      // 2. Google
      else if (settings.googleSearchEnabled &&
          (settings.googleSearchApiKey != null &&
              settings.googleSearchApiKey!.isNotEmpty) &&
          (settings.googleSearchEngineId != null &&
              settings.googleSearchEngineId!.isNotEmpty)) {
        try {
          final googleService = await SearchServiceManager.getSearchService(
            settings,
          );
          if (googleService == null) {
            setState(() {
              _messages.add(
                ChatMessage(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  text:
                      'Google 搜索服务配置不完整。请检查 API Key 和 Search Engine ID 是否正确配置。',
                  sender: MessageSender.ai,
                  timestamp: DateTime.now(),
                ),
              );
              _isLoading = false;
            });
            _scrollToBottom();
            return;
          }
          final result = await googleService.search(
            text,
            count: settings.googleSearchResultCount,
          );
          // 格式化结果为字符串
          String webResult = '';
          for (var i = 0; i < result.items.length; i++) {
            final item = result.items[i];
            webResult +=
                '${i + 1}. ${item.title}\n${item.snippet}\n${item.link}\n\n';
          }
          if (webResult.isEmpty) {
            webResult = '未找到相关搜索结果。';
          }
          prompt = AppLocalizations.of(
            context,
          )!.webSearchPrompt(webResult, text);
          didSearch = true;
        } catch (e) {
          setState(() {
            _messages.add(
              ChatMessage(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                text: 'Google 搜索失败：${e.toString()}',
                sender: MessageSender.ai,
                timestamp: DateTime.now(),
              ),
            );
            _isLoading = false;
          });
          _scrollToBottom();
          return;
        }
      }
      // 3. Neither enabled
      else {
        setState(() {
          _messages.add(
            ChatMessage(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              text: '未启用任何网络搜索功能，请在设置中开启 Tavily 或 Google 搜索。',
              sender: MessageSender.ai,
              timestamp: DateTime.now(),
            ),
          );
          _isLoading = false;
        });
        _scrollToBottom();
        return;
      }
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

    // If it's a new chat, create a session ID and save the initial message
    if (_currentSessionId == null) {
      _currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();
      final newSession = ChatSession(
        id: _currentSessionId!,
        title:
            prompt.length > 30
                ? '${prompt.substring(0, 30)}...'
                : prompt, // Use first part of message as title
        messages: [userMessage],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _sessionService.saveSession(newSession);
      _loadChatSessions(); // Reload sessions to update sidebar
    }
    _scrollToBottom();

    final settings1 = Provider.of<SettingsProvider>(context, listen: false);
    if (settings1.apiKey == null || settings1.apiKey!.isEmpty) {
      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessage(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              text: AppLocalizations.of(context)!.apiKeyNotSetError,
              sender: MessageSender.ai,
              timestamp: DateTime.now(),
            ),
          );
          _isLoading = false;
        });
      }
      _scrollToBottom();
      return;
    }

    // Create a placeholder for the AI's message
    final aiMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: "", // Start with empty text
      sender: MessageSender.ai,
      timestamp: DateTime.now(),
      isLoading: true, // Add a flag to indicate this message is loading
    );

    if (mounted) {
      setState(() {
        _messages.add(aiMessage);
      });
    }
    _scrollToBottom();

    try {
      final aiUserMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: prompt,
        sender: MessageSender.user,
        timestamp: DateTime.now(),
      );
      final List<ChatMessage> aiMessages = List.from(_messages);
      if (_enableWebSearch) {
        aiMessages.removeLast(); // Remove the original user message
        aiMessages.add(aiUserMessage); // Add the prompt with web search
      }
      final chatService = ServiceManager.createChatService(settings);
      final stream = chatService.generateResponse(
        prompt: prompt,
        context:
            aiMessages
                .where((msg) => msg.sender != MessageSender.user)
                .toList(),
        model: settings.selectedModel,
      );

      String fullResponse = "";
      await for (final chunk in stream) {
        fullResponse += chunk;
        if (mounted) {
          setState(() {
            // Update the last message (which is the AI's message placeholder)
            final lastMessageIndex = _messages.length - 1;
            if (lastMessageIndex >= 0 &&
                _messages[lastMessageIndex].sender == MessageSender.ai) {
              _messages[lastMessageIndex] = ChatMessage(
                id: _messages[lastMessageIndex].id,
                text: fullResponse,
                sender: MessageSender.ai,
                timestamp:
                    _messages[lastMessageIndex]
                        .timestamp, // Keep original timestamp
                isLoading: true, // Still loading until stream is done
              );
            }
          });
        }
        _scrollToBottom();
      }

      // Stream finished, update the isLoading flag for the AI message
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
            // Save the updated session
            if (_currentSessionId != null) {
              final updatedSession = ChatSession(
                id: _currentSessionId!,
                title:
                    _chatSessions
                        .firstWhere((s) => s.id == _currentSessionId!)
                        .title, // Keep original title
                messages: List.from(_messages),
                createdAt:
                    _chatSessions
                        .firstWhere((s) => s.id == _currentSessionId!)
                        .createdAt,
                updatedAt: DateTime.now(),
              );
              _sessionService.saveSession(updatedSession);
            }
          }
          _isLoading = false; // Overall loading state for the input field
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          // Update the AI message placeholder with the error
          final lastMessageIndex = _messages.length - 1;
          if (lastMessageIndex >= 0 &&
              _messages[lastMessageIndex].sender == MessageSender.ai) {
            _messages[lastMessageIndex] = ChatMessage(
              id: _messages[lastMessageIndex].id,
              text: "Error: \\${e.toString()}",
              sender: MessageSender.ai,
              timestamp: _messages[lastMessageIndex].timestamp,
              isLoading: false,
            );
          } else {
            // If for some reason the placeholder wasn't added, add a new error message
            _messages.add(
              ChatMessage(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                text: "Error: \\${e.toString()}",
                sender: MessageSender.ai,
                timestamp: DateTime.now(),
              ),
            );
          }
          _isLoading = false;
        });
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
    // After sending message, save the session
    if (_currentSessionId != null) {
      final currentSession = ChatSession(
        id: _currentSessionId!,
        title:
            _chatSessions
                .firstWhere((s) => s.id == _currentSessionId!)
                .title, // Keep original title
        messages: List.from(_messages),
        createdAt:
            _chatSessions
                .firstWhere((s) => s.id == _currentSessionId!)
                .createdAt,
        updatedAt: DateTime.now(),
      );
      await _sessionService.saveSession(currentSession);
      _loadChatSessions(); // Reload sessions to update sidebar
    }
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
                if (_chatSessions.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Text(
                      'Recent Chats',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
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
                            onDelete: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder:
                                    (ctx) => AlertDialog(
                                      title: const Text('Delete'),
                                      content: const Text(
                                        'Delete this chat history?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () =>
                                                  Navigator.of(ctx).pop(false),
                                          child: Text(
                                            AppLocalizations.of(
                                                  context,
                                                )?.cancel ??
                                                'Cancel',
                                          ),
                                        ),
                                        FilledButton(
                                          onPressed:
                                              () => Navigator.of(ctx).pop(true),
                                          style: FilledButton.styleFrom(
                                            backgroundColor:
                                                theme.colorScheme.error,
                                            foregroundColor:
                                                theme.colorScheme.onError,
                                          ),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                              );
                              if (confirm == true) {
                                await _sessionService.deleteSession(session.id);
                                if (_currentSessionId == session.id) {
                                  setState(() {
                                    _messages.clear();
                                    _currentSessionId = null;
                                  });
                                }
                                _loadChatSessions();
                              }
                            },
                            exportLabel:
                                AppLocalizations.of(context)!.exportToMarkdown,
                          ),
                        );
                      },
                    ),
                  ),
                ],

                // Image sessions section
                if (_imageSessions.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Text(
                      'Image Sessions',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
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
                            onDelete: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder:
                                    (ctx) => AlertDialog(
                                      title: const Text('Delete'),
                                      content: const Text(
                                        'Delete this image session?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () =>
                                                  Navigator.of(ctx).pop(false),
                                          child: Text(
                                            AppLocalizations.of(
                                                  context,
                                                )?.cancel ??
                                                'Cancel',
                                          ),
                                        ),
                                        FilledButton(
                                          onPressed:
                                              () => Navigator.of(ctx).pop(true),
                                          style: FilledButton.styleFrom(
                                            backgroundColor:
                                                theme.colorScheme.error,
                                            foregroundColor:
                                                theme.colorScheme.onError,
                                          ),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                              );
                              if (confirm == true) {
                                await _imageSessionService.deleteSession(
                                  session.id,
                                );
                                if (_currentImageSessionId == session.id) {
                                  setState(() {
                                    _messages.clear();
                                    _currentImageSessionId = null;
                                  });
                                }
                                _loadImageSessions();
                              }
                            },
                            exportLabel:
                                AppLocalizations.of(context)!.exportToImg,
                          ),
                        );
                      },
                    ),
                  ),
                ],
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
      messageContent = SelectableText(
        message.text,
        style: theme.textTheme.bodyLarge?.copyWith(
          color:
              isUserMessage
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.onSurfaceVariant,
        ),
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
              child:
                  message.imageUrl?.startsWith('data:image') == true
                      ? Image.memory(
                        base64Decode(message.imageUrl!.split(',').last),
                        width: 250,
                        height: 250,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 250,
                            height: 250,
                            color: Colors.grey[200],
                            child: Center(
                              child: Text(
                                localizations.errorLoadingImage,
                                style: TextStyle(color: Colors.red[700]),
                              ),
                            ),
                          );
                        },
                      )
                      : Image.network(
                        message.imageUrl!,
                        width: 250,
                        height: 250,
                        fit: BoxFit.cover,
                        loadingBuilder: (
                          BuildContext context,
                          Widget child,
                          ImageChunkEvent? loadingProgress,
                        ) {
                          if (loadingProgress == null) return child;
                          return SizedBox(
                            width: 250,
                            height: 250,
                            child: Center(
                              child: CircularProgressIndicator(
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 250,
                            height: 250,
                            color: Colors.grey[200],
                            child: Center(
                              child: Text(
                                localizations.errorLoadingImage,
                                style: TextStyle(color: Colors.red[700]),
                              ),
                            ),
                          );
                        },
                      ),
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
                    if (message.imageUrl != null &&
                        message.imageUrl!.isNotEmpty) {
                      await ImageSaveService.saveImage(
                        message.imageUrl!,
                        context,
                      );
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
                      child: Consumer<SettingsProvider>(
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
    if (mounted) {
      setState(() {
        // Add user's /imagine message first
        _messages.add(
          ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            text: '/imagine $prompt',
            sender: MessageSender.user,
            timestamp: DateTime.now(),
          ),
        );
        // Then add the AI's placeholder message for the image
        _messages.add(
          ImageMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            text: prompt, // Assign prompt to text
            imageUrl: '',
            sender: MessageSender.ai,
            timestamp: DateTime.now(),
            isLoading: true,
          ),
        );
        _isLoading = true; // For the general input field loader
      });
    }
    _scrollToBottom();

    final settings = Provider.of<SettingsProvider>(context, listen: false);
    // Check for both general and image-specific API keys
    if (settings.apiKey == null ||
        settings.apiKey!.isEmpty ||
        settings.imageApiKey == null ||
        settings.imageApiKey!.isEmpty) {
      if (mounted) {
        setState(() {
          // Try to update the loading ImageMessage with an error
          int imageMessageIndex = -1;
          for (int i = _messages.length - 1; i >= 0; i--) {
            if (_messages[i] is ImageMessage &&
                (_messages[i] as ImageMessage).text == prompt &&
                ((_messages[i] as ImageMessage).isLoading ?? false)) {
              imageMessageIndex = i;
              break;
            }
          }

          if (imageMessageIndex != -1) {
            _messages[imageMessageIndex] = ImageMessage(
              id: (_messages[imageMessageIndex] as ImageMessage).id,
              text: prompt, // Assign prompt to text
              imageUrl: '',
              sender: MessageSender.ai,
              timestamp:
                  (_messages[imageMessageIndex] as ImageMessage).timestamp,
              isLoading: false,
              error:
                  AppLocalizations.of(
                    context,
                  )!.apiKeyNotSetError, // More specific error
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
        apiKey: settings.imageApiKey!, // Use image API key
        prompt: prompt,
        model: settings.selectedImageModel,
        providerBaseUrl: settings.imageProviderUrl,
      );

      if (mounted) {
        setState(() {
          // Find the correct ImageMessage to update
          int imageMessageIndex = -1;
          for (int i = _messages.length - 1; i >= 0; i--) {
            if (_messages[i] is ImageMessage &&
                (_messages[i] as ImageMessage).text == prompt &&
                ((_messages[i] as ImageMessage).isLoading ?? false)) {
              imageMessageIndex = i;
              break;
            }
          }

          if (imageMessageIndex != -1) {
            if (imageUrl == null || imageUrl.isEmpty) {
              _messages[imageMessageIndex] = ImageMessage(
                id: (_messages[imageMessageIndex] as ImageMessage).id,
                text: prompt, // Assign prompt to text
                imageUrl: '',
                sender: MessageSender.ai,
                timestamp:
                    (_messages[imageMessageIndex] as ImageMessage).timestamp,
                isLoading: false,
                error: AppLocalizations.of(context)!.failedToGenerateImageNoUrl,
              );
            } else {
              _messages[imageMessageIndex] = ImageMessage(
                id: (_messages[imageMessageIndex] as ImageMessage).id,
                text: prompt, // Assign prompt to text
                imageUrl: imageUrl,
                sender: MessageSender.ai,
                timestamp:
                    (_messages[imageMessageIndex] as ImageMessage).timestamp,
                isLoading: false,
                error: null,
              );
              // Corrected session saving logic
              if (_currentImageSessionId == null) {
                // This is the first message in a new image session
                _currentImageSessionId =
                    DateTime.now().millisecondsSinceEpoch.toString();
                final newSession = ImageSession(
                  id: _currentImageSessionId!,
                  title:
                      prompt.length > 30
                          ? '${prompt.substring(0, 30)}...'
                          : prompt,
                  messages: _messages.whereType<ImageMessage>().toList(),
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                  model: settings.selectedImageModel,
                );
                _imageSessionService.saveSession(newSession);
                _loadImageSessions(); // Reload sidebar
              } else {
                // Update existing image session
                // Find the existing session to preserve its original title and creation time
                ImageSession? existingSession;
                try {
                  existingSession = _imageSessions.firstWhere(
                    (s) => s.id == _currentImageSessionId,
                  );
                } catch (e) {
                  // If for some reason the session is not found (e.g., deleted externally),
                  // treat it as a new session. This is a fallback.
                  print(
                    "Warning: Existing image session with ID $_currentImageSessionId not found. Creating a new session: $e",
                  );
                  _currentImageSessionId =
                      DateTime.now().millisecondsSinceEpoch
                          .toString(); // Generate a new ID for the new session
                }

                final updatedSession = ImageSession(
                  id: _currentImageSessionId!, // Use the current or newly generated ID
                  title:
                      existingSession?.title ??
                      (prompt.length > 30
                          ? '${prompt.substring(0, 30)}...'
                          : prompt), // Keep original title or use prompt
                  messages: _messages.whereType<ImageMessage>().toList(),
                  createdAt:
                      existingSession?.createdAt ??
                      DateTime.now(), // Keep original creation time or use now
                  updatedAt: DateTime.now(),
                  model: settings.selectedImageModel,
                );
                _imageSessionService.saveSession(updatedSession);
                _loadImageSessions(); // Reload sidebar
              }
            }
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          int imageMessageIndex = -1;
          for (int i = _messages.length - 1; i >= 0; i--) {
            if (_messages[i] is ImageMessage &&
                (_messages[i] as ImageMessage).text == prompt &&
                ((_messages[i] as ImageMessage).isLoading ?? false)) {
              imageMessageIndex = i;
              break;
            }
          }
          if (imageMessageIndex != -1) {
            _messages[imageMessageIndex] = ImageMessage(
              id: (_messages[imageMessageIndex] as ImageMessage).id,
              text: prompt,
              imageUrl: '',
              sender: MessageSender.ai,
              timestamp:
                  (_messages[imageMessageIndex] as ImageMessage).timestamp,
              isLoading: false,
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
}
