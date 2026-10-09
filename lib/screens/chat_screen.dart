import 'package:chibot/widgets/tool_chat_run.dart';
import 'package:chibot/widgets/tool_call_records.dart';
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
import 'package:chibot/services/chat_service_factory.dart';
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
part 'chat_parts/sidebar.dart';
part 'chat_parts/message_bubbles.dart';
part 'chat_parts/composer.dart';
part 'chat_parts/sessions.dart';
part 'chat_parts/messaging.dart';

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
  ToolChatRun? _toolRun;
  int _conversationGeneration = 0;
  bool _isLoading = false;
  bool _enableWebSearch = false;

  @override
  void initState() {
    super.initState();
    _loadChatSessions();
    _loadImageSessions();
  }

  ChatMessage _createAiPlaceholderMessage() {
    return ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: '',
      sender: MessageSender.ai,
      timestamp: DateTime.now(),
      isLoading: true,
    );
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

  @override
  void dispose() {
    _toolRun?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
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
              _stopGeneration();
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

}
