import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import '../models/chat_message.dart';
import '../providers/settings_provider.dart';
import '../services/openai_service.dart';
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
  final TextEditingController _textController = TextEditingController();
  final OpenAIService _openAIService = OpenAIService();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;


  void _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

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
    _scrollToBottom();

    final settings = Provider.of<SettingsProvider>(context, listen: false);
    if (settings.apiKey == null || settings.apiKey!.isEmpty) {
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
          _buildSidebarItem(context, Icons.chat_bubble_outline, 'ChatGPT', isSelected: true), // Keep 'ChatGPT' as it's a model name
          _buildSidebarItem(context, Icons.search, 'GTP search'), // Keep 'GTP search' as it's a model name
          _buildSidebarItem(context, Icons.code, 'SwiftUI GPT'), // Keep 'SwiftUI GPT' as it's a model name
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
      color: Colors.white,
      child: InkWell(
        onTap: onTap ?? () {},
        borderRadius: BorderRadius.circular(12.0),
        hoverColor: const Color.fromARGB(255, 218, 222, 252),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          decoration: BoxDecoration(
            color: isSelected ? const Color.fromARGB(255, 250, 245, 245) : Colors.white10,
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
                color: isSelected ? Colors.blue : Colors.white70,
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
                return _buildMessageBubble(message);
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

  Widget _buildMessageBubble(ChatMessage message) {
    final bool isUserMessage = message.sender == MessageSender.user;
    final theme = Theme.of(context);
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
}
