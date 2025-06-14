import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'dart:convert'; // For base64 decoding
import 'dart:io';
import '../models/chat_message.dart';
import '../models/chat_session.dart';
import '../models/image_session.dart';
import '../services/chat_session_service.dart';
import '../services/image_session_service.dart';
import '../providers/settings_provider.dart';
import '../services/openai_service.dart';
import '../models/image_message.dart'; // Added for image messages
import '../services/image_generation_service.dart'; // Added for image generation
import '../services/image_save_service.dart';
import '../l10n/app_localizations.dart';
import 'settings_screen.dart';


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
  final OpenAIService _openAIService = OpenAIService();
  final ImageGenerationService _imageGenerationService = ImageGenerationService(); // Added
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

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
    if (settings.selectedModelType == ModelType.image) {
      _generateImage(text);
      _textController.clear();
      return;
    }

    _textController.clear();

    _textController.clear();
    final userMessage = ChatMessage(
      text: text,
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
        title: text.length > 30 ? '${text.substring(0, 30)}...' : text, // Use first part of message as title
        messages: [userMessage],
        createdAt: DateTime.now(),
      );
      await _sessionService.saveSession(newSession);
      _loadChatSessions(); // Reload sessions to update sidebar
    }
    _scrollToBottom();

    final settings1 = Provider.of<SettingsProvider>(context, listen: false);
    if (settings1.apiKey == null || settings1.apiKey!.isEmpty) {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text: AppLocalizations.of(context)!.apiKeyNotSetError,
            sender: MessageSender.ai,
            timestamp: DateTime.now(),
          ));
          _isLoading = false;
        });
      }
      _scrollToBottom();
      return;
    }

    // Create a placeholder for the AI's message
    final aiMessage = ChatMessage(
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
      final stream = _openAIService.getChatResponse(
        apiKey: settings.apiKey!,
        model: settings.selectedModel,
        messages: List.from(_messages),
        providerBaseUrl: settings.providerUrl, // 传递 Provider URL
      );

      String fullResponse = "";
      await for (final chunk in stream) {
        fullResponse += chunk;
        if (mounted) {
          setState(() {
            // Update the last message (which is the AI's message placeholder)
            final lastMessageIndex = _messages.length - 1;
            if (lastMessageIndex >= 0 && _messages[lastMessageIndex].sender == MessageSender.ai) {
              _messages[lastMessageIndex] = ChatMessage(
                text: fullResponse,
                sender: MessageSender.ai,
                timestamp: _messages[lastMessageIndex].timestamp, // Keep original timestamp
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
          if (lastMessageIndex >= 0 && _messages[lastMessageIndex].sender == MessageSender.ai) {
             _messages[lastMessageIndex] = ChatMessage(
                text: fullResponse.isEmpty ? AppLocalizations.of(context)!.noResponseFromAI : fullResponse, // Handle empty response
                sender: MessageSender.ai,
                timestamp: _messages[lastMessageIndex].timestamp,
                isLoading: false, // Done loading
              );
            // Save the updated session
            if (_currentSessionId != null) {
              final updatedSession = ChatSession(
                id: _currentSessionId!,
                title: _chatSessions.firstWhere((s) => s.id == _currentSessionId!).title, // Keep original title
                messages: List.from(_messages),
                createdAt: _chatSessions.firstWhere((s) => s.id == _currentSessionId!).createdAt,
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
          if (lastMessageIndex >= 0 && _messages[lastMessageIndex].sender == MessageSender.ai) {
            _messages[lastMessageIndex] = ChatMessage(
              text: "Error: ${e.toString()}",
              sender: MessageSender.ai,
              timestamp: _messages[lastMessageIndex].timestamp,
              isLoading: false,
            );
          } else {
            // If for some reason the placeholder wasn't added, add a new error message
             _messages.add(ChatMessage(
              text: "Error: ${e.toString()}",
              sender: MessageSender.ai,
              timestamp: DateTime.now(),
            ));
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
        title: _chatSessions.firstWhere((s) => s.id == _currentSessionId!).title, // Keep original title
        messages: List.from(_messages),
        createdAt: _chatSessions.firstWhere((s) => s.id == _currentSessionId!).createdAt,
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
    // Placeholder for sidebar content, matching the image's style
    return Container(
      width: _sidebarWidth,
      color: Colors.white12,
      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Search bar (mimicking the image)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 227, 229, 249), // Darker input field background
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: TextField(
              style: TextStyle(color: Colors.black87),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.search,
                hintStyle: TextStyle(color: Colors.black12),
                icon: Icon(Icons.search, color: Colors.white54, size: 20),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // List of chats (example items)
          _buildSidebarItem(context, Icons.chat_bubble_outline, 'Chi Chat', isSelected: true), // Keep 'ChatGPT' as it's a model name
          _buildSidebarItem(context, Icons.search, 'Chi Search'), // Keep 'GTP search' as it's a model name
          _buildSidebarItem(context, Icons.code, 'Chi Code'), // Keep 'SwiftUI GPT' as it's a model name
          const SizedBox(height: 20),
          _buildSidebarItem(context, Icons.add_comment_outlined, AppLocalizations.of(context)!.newChat, onTap: _startNewChat),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: _chatSessions.length,
              itemBuilder: (context, index) {
                final session = _chatSessions[index];
                return _buildSidebarItem(
                  context,
                  Icons.history,
                  session.title,
                  isSelected: _currentSessionId == session.id,
                  onTap: () => _loadSession(session),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          _buildSidebarItem(context, Icons.add_photo_alternate_outlined, AppLocalizations.of(context)!.newImageSession, onTap: _startNewImageSession),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: _imageSessions.length,
              itemBuilder: (context, index) {
                final session = _imageSessions[index];
                return _buildSidebarItem(
                  context,
                  Icons.image,
                  session.title,
                  isSelected: _currentImageSessionId == session.id,
                  onTap: () => _loadImageSession(session),
                );
              },
            ),
          ),
          // Add more items or a ListView for scrollable content
          const Spacer(), // Pushes settings to the bottom

          _buildSidebarItem(context, Icons.info_outlined, AppLocalizations.of(context)!.about, onTap: () { // Use l10n here
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AboutDialog(
                  applicationName: 'Chibot',
                  applicationVersion: '1.0.0',
                  applicationIcon: Image.asset(
                    'assets/images/logo.png',
                    height: 64,
                    width: 64,
                  ),
                  applicationLegalese: '© 2025 Mutse Young. All rights reserved.',
                );
              },);
          }),
          _buildSidebarItem(context, Icons.settings_outlined, AppLocalizations.of(context)!.settings, onTap: () { // Use l10n here
             Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
          }),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(BuildContext context, IconData icon, String text, {bool isSelected = false, VoidCallback? onTap}) {
    return Material(
      child: InkWell(
        onTap: onTap ?? () {},
        borderRadius: BorderRadius.circular(12.0),
        hoverColor: const Color.fromARGB(255, 218, 222, 252),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          decoration: BoxDecoration(
            color: isSelected ? const Color.fromARGB(255, 250, 245, 245) : Colors.transparent,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: isSelected ? Colors.blue.withOpacity(0.5) : Colors.white10,
              width: 1.0,
            ),
          ),
          child: Row(
            children: <Widget>[
              Icon(
                icon,
                color: isSelected ? Colors.blue : Colors.black87,
                size: 20,
              ),
              const SizedBox(width: 12.0),
              Text(
                text,
                style: TextStyle(
                  color: isSelected ? Colors.blue : Colors.black87,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
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

    final settings = Provider.of<SettingsProvider>(context);
    bool isApiKeySet = settings.apiKey != null && settings.apiKey!.isNotEmpty;
    // Determine if we should show the sidebar based on screen width
    // For simplicity, we'll always show it here, but in a real app, you might hide it on smaller screens.
    bool showSidebar = MediaQuery.of(context).size.width > 600; // Example breakpoint

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 1,
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 24.0,
              width: 24.0,
            ),
            const SizedBox(width: 8.0),
            Text(
              AppLocalizations.of(context)!.chatGPTTitle,
              style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.normal, fontSize: 18),
            ),
          ],
        ),
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu, color: Colors.black87),
              onPressed: () { Scaffold.of(context).openDrawer(); },
            );
          },
        ),
      ),
      drawer: Drawer(
        width: _sidebarWidth,
        child: _buildSidebar(context),
      ),
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

  void _showImageContextMenu(Offset position, String imageUrl, AppLocalizations localizations) {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        position & const Size(40, 40), // Smaller rectangle around the tapped position
        Offset.zero & overlay.size, // Full screen size
      ),
      items: <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'save',
          child: Text(localizations.saveImage),
        ),
      ],
    ).then((String? value) {
      if (value == 'save') {
        ImageSaveService.saveImage(imageUrl, context);
      }
    });
  }

  Widget _buildMessageBubble(ChatMessage message, int index) { // Added index
    final bool isUserMessage = message.sender == MessageSender.user;
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;

    if (message is ImageMessage) {
      return _buildImageMessageBubble(message, isUserMessage, index == _messages.length - 1, localizations);
    }

    final bool isAiLoading = message.sender == MessageSender.ai && (message.isLoading ?? false);
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
          color: isUserMessage
              ? theme.colorScheme.onPrimary
              : theme.colorScheme.onSurface,
        ),
      );
    }

    return Align(
      alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7 - _sidebarWidth * (MediaQuery.of(context).size.width > 600 ? 0.7 : 0)),
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        decoration: BoxDecoration(
          color: isUserMessage ? const Color(0xFF2B7FFF) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isUserMessage ? 20.0 : 4.0),
            topRight: Radius.circular(isUserMessage ? 4.0 : 20.0),
            bottomLeft: const Radius.circular(20.0),
            bottomRight: const Radius.circular(20.0),
          ),
          boxShadow: [
            BoxShadow(
              color: isUserMessage 
                ? const Color(0xFF2B7FFF).withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
              spreadRadius: 0,
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
          border: !isUserMessage ? Border.all(
            color: Colors.grey.withOpacity(0.1),
            width: 1.0,
          ) : null,
        ),
        child: messageContent,
      ),
      );
    }

  Widget _buildImageMessageBubble(ImageMessage message, bool isUser, bool isLastMessage, AppLocalizations localizations) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onSecondaryTapDown: (details) {
          if (message.imageUrl != null) {
            _showImageContextMenu(details.globalPosition, message.imageUrl!, localizations);
          }
        },
        child: Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7 - _sidebarWidth * (MediaQuery.of(context).size.width > 600 ? 0.7 : 0)),
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          decoration: BoxDecoration(
            color: isUser ? const Color(0xFF2B7FFF) : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(isUser ? 20.0 : 4.0),
              topRight: Radius.circular(isUser ? 4.0 : 20.0),
              bottomLeft: const Radius.circular(20.0),
            bottomRight: const Radius.circular(20.0),
          ),
          boxShadow: [
            BoxShadow(
              color: isUser 
                ? const Color(0xFF2B7FFF).withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
              spreadRadius: 0,
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
          border: !isUser ? Border.all(
            color: Colors.grey.withOpacity(0.1),
            width: 1.0,
          ) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.text?.isNotEmpty == true && (isUser || (message.isLoading != true && message.imageUrl?.isNotEmpty == true)))
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text(
                  isUser ? '/imagine ${message.text}' : message.text,
                   style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isUser 
                        ? Theme.of(context).colorScheme.onPrimary 
                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
              ),
            if (message.isLoading ?? false)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: SpinKitThreeBounce(
                  color: isUser ? Colors.white : Theme.of(context).colorScheme.primary,
                  size: 20.0,
                ),
              )
            else if (message.error?.isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  message.error!,
                  style: TextStyle(color: Colors.red[700], fontStyle: FontStyle.italic),
                ),
              )
            else if (message.imageUrl?.isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
                child: GestureDetector(
                  onLongPress: () {
                    if ((Platform.isAndroid || Platform.isIOS) && message.imageUrl != null) {
                      ImageSaveService.saveImage(message.imageUrl!, context);
                    }
                  },
                  onSecondaryTapDown: (details) {
                    if (!kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux) && message.imageUrl != null) {
                      _showImageContextMenu(details.globalPosition, message.imageUrl!, localizations);
                    }
                  },
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: ClipRRect(
                        borderRadius: BorderRadius.circular(12.0),
                        child: message.imageUrl?.startsWith('data:image') == true
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
                                    child: Center(child: Text(localizations.errorLoadingImage, style: TextStyle(color: Colors.red[700]))),
                                  );
                                },
                              )
                            : Image.network(
                                message.imageUrl!,
                                width: 250,
                                height: 250,
                                fit: BoxFit.cover,
                                loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return SizedBox(
                                    width: 250,
                                    height: 250,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
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
                                    child: Center(child: Text(localizations.errorLoadingImage, style: TextStyle(color: Colors.red[700]))),
                                  );
                                },
                              ),
                      ),
                    ),
                  ),
                )
          else if (!isUser)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  localizations.noImageGenerated,
                  style: TextStyle(color: Colors.orange[700], fontStyle: FontStyle.italic),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 5.0),
              child: Text(
                '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 10,
                  color: isUser ? Colors.white70 : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    ));
  }

  Widget _buildInputField() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: <Widget>[
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(24.0),
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.2),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.4,
                        ),
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context)!.askAnyQuestion,
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 15,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20.0,
                            vertical: 14.0,
                          ),
                        ),
                        onSubmitted: (_) => _isLoading ? null : _sendMessage(),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
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
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: Material(
                    color: _isLoading || isEmpty
                        ? Colors.grey[300]
                        : const Color(0xFF2B7FFF),
                    borderRadius: BorderRadius.circular(20.0),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20.0),
                      onTap: _isLoading || isEmpty ? null : _sendMessage,
                      child: Container(
                        padding: const EdgeInsets.all(12.0),
                        child: Icon(
                          Icons.arrow_upward_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _generateImage(String prompt) async {
    if (mounted) {
      setState(() {
        // Add user's /imagine message first
        _messages.add(ChatMessage(
          text: '/imagine $prompt', 
          sender: MessageSender.user, 
          timestamp: DateTime.now()
));
        // Then add the AI's placeholder message for the image
        _messages.add(ImageMessage(
          text: prompt, // Assign prompt to text
          imageUrl: '', 
          sender: MessageSender.ai, 
          timestamp: DateTime.now(), 
          isLoading: true
        ));
        _isLoading = true; // For the general input field loader
      });
    }
    _scrollToBottom();

    final settings = Provider.of<SettingsProvider>(context, listen: false);
    // Check for both general and image-specific API keys
    if (settings.apiKey == null || settings.apiKey!.isEmpty || settings.imageApiKey == null || settings.imageApiKey!.isEmpty) {
      if (mounted) {
        setState(() {
          // Try to update the loading ImageMessage with an error
          int imageMessageIndex = -1;
          for (int i = _messages.length - 1; i >= 0; i--) {
            if (_messages[i] is ImageMessage && (_messages[i] as ImageMessage).text == prompt && ((_messages[i] as ImageMessage).isLoading ?? false)) {
              imageMessageIndex = i;
              break;
            }
          }

          if (imageMessageIndex != -1) {
            _messages[imageMessageIndex] = ImageMessage(
              text: prompt, // Assign prompt to text
              imageUrl: '',
              sender: MessageSender.ai,
              timestamp: (_messages[imageMessageIndex] as ImageMessage).timestamp,
              isLoading: false,
              error: AppLocalizations.of(context)!.apiKeyNotSetError, // More specific error
            );
          } else {
             _messages.add(ChatMessage(
              text: AppLocalizations.of(context)!.apiKeyNotSetError,
              sender: MessageSender.ai,
              timestamp: DateTime.now(),
            ));
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
            if (_messages[i] is ImageMessage && (_messages[i] as ImageMessage).text == prompt && ((_messages[i] as ImageMessage).isLoading ?? false)) {
              imageMessageIndex = i;
              break;
            }
          }

          if (imageMessageIndex != -1) {
            _messages[imageMessageIndex] = ImageMessage(
              text: prompt, // Assign prompt to text
              imageUrl: imageUrl ?? '', 
              sender: MessageSender.ai,
              timestamp: (_messages[imageMessageIndex] as ImageMessage).timestamp,
              isLoading: false,
              error: imageUrl == null ? AppLocalizations.of(context)!.failedToGenerateImageNoUrl : null,
            );
            // Corrected session saving logic
            if (_currentImageSessionId == null) {
              // This is the first message in a new image session
              _currentImageSessionId = DateTime.now().millisecondsSinceEpoch.toString();
              final newSession = ImageSession(
                id: _currentImageSessionId!,
                title: prompt.length > 30 ? '${prompt.substring(0, 30)}...' : prompt,
                messages: _messages.whereType<ImageMessage>().toList(),
                createdAt: DateTime.now(),
                model: settings.selectedImageModel,
              );
              _imageSessionService.saveSession(newSession);
              _loadImageSessions(); // Reload sidebar
            } else {
              // Update existing image session
              // Find the existing session to preserve its original title and creation time
              ImageSession? existingSession;
              try {
                existingSession = _imageSessions.firstWhere((s) => s.id == _currentImageSessionId);
              } catch (e) {
                // If for some reason the session is not found (e.g., deleted externally),
                // treat it as a new session. This is a fallback.
                print("Warning: Existing image session with ID $_currentImageSessionId not found. Creating a new session: $e");
                _currentImageSessionId = DateTime.now().millisecondsSinceEpoch.toString(); // Generate a new ID for the new session
              }

              final updatedSession = ImageSession(
                id: _currentImageSessionId!, // Use the current or newly generated ID
                title: existingSession?.title ?? (prompt.length > 30 ? '${prompt.substring(0, 30)}...' : prompt), // Keep original title or use prompt
                messages: _messages.whereType<ImageMessage>().toList(),
                createdAt: existingSession?.createdAt ?? DateTime.now(), // Keep original creation time or use now
                model: settings.selectedImageModel,
              );
              _imageSessionService.saveSession(updatedSession);
              _loadImageSessions(); // Reload sidebar
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
            if (_messages[i] is ImageMessage && (_messages[i] as ImageMessage).text == prompt && ((_messages[i] as ImageMessage).isLoading ?? false)) {
              imageMessageIndex = i;
              break;
            }
          }
          if (imageMessageIndex != -1) {
            _messages[imageMessageIndex] = ImageMessage(
              text: prompt,
              imageUrl: '',
              sender: MessageSender.ai,
              timestamp: (_messages[imageMessageIndex] as ImageMessage).timestamp,
              isLoading: false,
              error: AppLocalizations.of(context)!.errorGeneratingImage(e.toString()),
            );
          } else {
            _messages.add(ChatMessage(
              text: AppLocalizations.of(context)!.errorGeneratingImage(e.toString()),
              sender: MessageSender.ai,
              timestamp: DateTime.now(),
            ));
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
