import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat_message.dart';
import '../providers/settings_provider.dart';
import '../services/openai_service.dart';
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
            text: "Error: API Key not set. Please set it in settings.",
            sender: MessageSender.ai,
            timestamp: DateTime.now(),
          ));
          _isLoading = false;
        });
      }
      _scrollToBottom();
      return;
    }

    try {
      final aiResponseText = await _openAIService.getChatResponse(
        apiKey: settings.apiKey!,
        model: settings.selectedModel,
        messages: List.from(_messages),
        providerBaseUrl: settings.providerUrl, // 传递 Provider URL
      );

      final aiMessage = ChatMessage(
        text: aiResponseText,
        sender: MessageSender.ai,
        timestamp: DateTime.now(),
      );
      if (mounted) {
        setState(() {
          _messages.add(aiMessage);
        });
      }
    } catch (e) {
      final errorMessage = ChatMessage(
        text: "Error: ${e.toString()}",
        sender: MessageSender.ai,
        timestamp: DateTime.now(),
      );
      if (mounted) {
        setState(() {
          _messages.add(errorMessage);
        });
      }
      print("Error sending message: $e");
    } finally {
      if (mounted) {
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
      color: const Color(0xFF202123), // Dark background for sidebar
      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Search bar (mimicking the image)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: const Color(0xFF343541), // Darker input field background
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: const TextField(
              style: TextStyle(color: Colors.white70),
              decoration: InputDecoration(
                hintText: '搜索',
                hintStyle: TextStyle(color: Colors.white54),
                icon: Icon(Icons.search, color: Colors.white54, size: 20),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // List of chats (example items)
          _buildSidebarItem(context, Icons.chat_bubble_outline, 'ChatGPT', isSelected: true),
          _buildSidebarItem(context, Icons.search, 'GTP search'),
          _buildSidebarItem(context, Icons.code, 'SwiftUI GPT'),
          // Add more items or a ListView for scrollable content
          const Spacer(), // Pushes settings to the bottom

          _buildSidebarItem(context, Icons.info_outlined, 'About', onTap: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return const AboutDialog(
                  applicationName: 'Chibot',
                  applicationVersion: '1.0.0',
                  applicationLegalese: '© 2025 Mutse Young. All rights reserved.',
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.only(top: 15),
                      child: Text('Author: Mutse Young'),
                    )
                  ],
                );
              },
            );
          }),
          _buildSidebarItem(context, Icons.settings_outlined, 'Settings', onTap: () {
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
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap ?? () {},
        borderRadius: BorderRadius.circular(12.0),
        hoverColor: const Color(0xFF2D2F3E),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF343541) : Colors.transparent,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: isSelected ? Colors.blue.withOpacity(0.5) : Colors.transparent,
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
                  color: isSelected ? Colors.blue : Colors.white,
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
    // Determine if we should show the sidebar based on screen width
    // For simplicity, we'll always show it here, but in a real app, you might hide it on smaller screens.
    bool showSidebar = MediaQuery.of(context).size.width > 600; // Example breakpoint

    return Scaffold(
      // The AppBar is now part of the main content area to allow the sidebar to be on its left.
      // If you want a global AppBar above the sidebar and chat, structure it differently.
      body: Row(
        children: <Widget>[
          // Sidebar (conditionally shown or always shown based on your design)
          // For this example, let's assume it's always shown for simplicity matching the image.
          _buildSidebar(context),
          // Main chat content
          Expanded(
            child: Column(
              children: <Widget>[
                // Custom AppBar for the chat area
                AppBar(
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  elevation: 1, // Subtle shadow for separation
                  title: const Text(
                    'ChatGPT', // Updated title
                    style: TextStyle(color: Colors.black87, fontWeight: FontWeight.normal, fontSize: 18),
                  ),
                  automaticallyImplyLeading: false, // Remove back button if sidebar is present
                ), 
                // The rest of the chat screen content
                Expanded(
                  child: Column( // Added Column widget
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
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(strokeWidth: 2),
                              SizedBox(width: 10),
                              Text("AI is thinking..."),
                            ],
                          ),
                        ),
                      _buildInputField(),
                    ], // This closes the new Column's children
                  ), // This closes the new Column
                ), // This closes the Expanded for 'the rest of the chat screen content'
              ], // This closes the Expanded (main chat content)
            ), // This closes the Row children (sidebar + main content)
           ), // This closes the Scaffold body's Row
        ],
      ),
    ); // This closes the Scaffold body's Row
  } // This closes the build method

  Widget _buildMessageBubble(ChatMessage message) {
    final bool isUserMessage = message.sender == MessageSender.user;
    final theme = Theme.of(context);
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
        child: Text(
          message.text,
          style: TextStyle(
            color: isUserMessage ? Colors.white : Colors.black87,
            fontSize: 15,
            height: 1.4,
          ),
        ),
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
                          hintText: '询问任何问题',
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
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: Material(
                color: _isLoading || _textController.text.isEmpty
                    ? Colors.grey[300]
                    : const Color(0xFF2B7FFF),
                borderRadius: BorderRadius.circular(20.0),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20.0),
                  onTap: _isLoading || _textController.text.isEmpty ? null : _sendMessage,
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
            ),
          ],
        ),
      ),
    );
  }
}
