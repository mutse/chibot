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
import 'package:chibot/widgets/mobile_ui.dart';
import 'package:chibot/screens/settings_screen.dart';
import 'package:chibot/services/chat_session_service.dart';
import 'package:chibot/services/exceptions/missing_api_key_exception.dart';
import 'package:chibot/services/markdown_export_service.dart';
import 'package:chibot/services/search_service_factory.dart';
import 'package:chibot/services/chat_service_factory.dart';
import 'package:chibot/widgets/chat_markdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
part 'chat_parts/sessions.dart';
part 'chat_parts/messaging.dart';
part 'chat_parts/message_widgets.dart';
part 'chat_parts/composer.dart';

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
