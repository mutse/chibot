import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat_message.dart';
import '../providers/settings_provider.dart';
import '../services/openai_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
    final theme = Theme.of(context);
    return Container(
      width: _sidebarWidth,
      color: theme.scaffoldBackgroundColor, // Use theme color
      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 10.0),
      decoration: BoxDecoration( // Add subtle border
        border: Border(right: BorderSide(color: CupertinoColors.systemGrey4, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding( // Wrap search field with padding
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: CupertinoSearchTextField(
              placeholder: AppLocalizations.of(context)!.search,
              style: TextStyle(color: theme.colorScheme.onSurface),
              backgroundColor: CupertinoColors.systemGrey5,
              // onChanged: (value) { /* Handle search query changes */ },
              // onSubmitted: (value) { /* Handle search submission */ },
            ),
          ),
          const SizedBox(height: 20),
          // List of chats (example items)
          _buildSidebarItem(context, CupertinoIcons.chat_bubble, 'ChatGPT', isSelected: true), // Keep 'ChatGPT' as it's a model name
          _buildSidebarItem(context, CupertinoIcons.search, 'GTP search'), // Keep 'GTP search' as it's a model name
          _buildSidebarItem(context, CupertinoIcons.device_laptop, 'SwiftUI GPT'), // Example: Using a different Cupertino icon
          // Add more items or a ListView for scrollable content
          const Spacer(), // Pushes settings to the bottom

          _buildSidebarItem(context, CupertinoIcons.info, AppLocalizations.of(context)!.about, onTap: () { // Use l10n here and CupertinoIcons.info
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
              },);
          }),
          _buildSidebarItem(context, CupertinoIcons.settings, AppLocalizations.of(context)!.settings, onTap: () { // Use l10n here and CupertinoIcons.settings
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
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap ?? () {},
        borderRadius: BorderRadius.circular(8.0), // iOS style rounding
        hoverColor: theme.colorScheme.primary.withOpacity(0.05), // More subtle hover
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150), // Faster animation
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0), // Adjusted padding
          margin: const EdgeInsets.symmetric(vertical: 2.0), // Reduced margin
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.primary.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8.0), // Consistent rounding
            // No border for selected items in typical iOS sidebars
          ),
          child: Row(
            children: <Widget>[
              Icon(
                icon,
                color: isSelected ? theme.colorScheme.primary : CupertinoColors.secondaryLabel,
                size: 22, // Slightly larger icons for iOS feel
              ),
              const SizedBox(width: 10.0), // Adjusted spacing
              Expanded( // Ensure text doesn't overflow
                child: Text(
                  text,
                  style: TextStyle(
                    color: isSelected ? theme.colorScheme.primary : CupertinoColors.label.resolveFrom(context),
                    fontSize: 15, // Standard iOS sidebar font size
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis, // Prevent overflow
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
    final theme = Theme.of(context); // Define theme here
    final settings = Provider.of<SettingsProvider>(context);
    bool isApiKeySet = settings.apiKey != null && settings.apiKey!.isNotEmpty;
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
                  backgroundColor: theme.appBarTheme.backgroundColor, // Use theme
                  elevation: theme.appBarTheme.elevation ?? 0, // Use theme
                  title: Text(
                    AppLocalizations.of(context)!.chatGPTTitle, // Updated title
                    style: theme.appBarTheme.titleTextStyle, // Use theme
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
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0), // Reduced margin for a tighter iOS feel
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 14.0), // Adjusted padding
        decoration: BoxDecoration(
          color: isUserMessage ? theme.colorScheme.primary : CupertinoColors.systemGrey5,
          borderRadius: BorderRadius.all(Radius.circular(18.0)), // General roundedness
            // Tail like effect can be achieved by different means or kept simple for now
            // For instance, a more complex shape could be drawn with a CustomPainter or by using a nine-patch image.
            // For simplicity, we'll use uniform rounding, common in many modern UIs.
            // If specific tail is needed, it would be:
            // topLeft: Radius.circular(isUserMessage ? 18.0 : 4.0),
            // topRight: Radius.circular(isUserMessage ? 4.0 : 18.0),
            // bottomLeft: const Radius.circular(18.0),
            // bottomRight: const Radius.circular(18.0),
          border: !isUserMessage ? Border.all(color: CupertinoColors.systemGrey4, width: 0.5) : null,
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: isUserMessage ? Colors.white : CupertinoColors.black,
            fontSize: 15, // Standard iOS message font size
            height: 1.3, // Standard iOS line height
          ),
        ),
      ),
    );
  }

  Widget _buildInputField() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0), // Adjusted padding
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor, // Or CupertinoColors.systemGrey5
        border: Border(top: BorderSide(color: CupertinoColors.systemGrey4, width: 0.5)),
      ),
      child: SafeArea(
        child: Row(
          children: <Widget>[
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4.0), // Inner padding for the text field container
                decoration: BoxDecoration(
                  color: CupertinoColors.white, // Or CupertinoColors.systemGrey5
                  borderRadius: BorderRadius.circular(20.0),
                  border: Border.all(color: CupertinoColors.systemGrey4, width: 0.5), // Subtle border for the text field itself
                ),
                child: TextField(
                  controller: _textController,
                  style: TextStyle( // Ensure text style matches iOS
                    fontSize: 16,
                    color: theme.colorScheme.onSurface,
                    height: 1.4,
                  ),
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.askAnyQuestion,
                    hintStyle: TextStyle(
                      color: CupertinoColors.placeholderText,
                      fontSize: 16,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16.0, // Horizontal padding inside the text field
                      vertical: 10.0,  // Vertical padding inside the text field
                    ),
                  ),
                  onSubmitted: (_) => _isLoading ? null : _sendMessage(),
                  maxLines: null, // Allows multiline input
                  textInputAction: TextInputAction.send,
                  // For a more native feel, consider CupertinoTextField, but TextField can be styled
                ),
              ),
            ),
            const SizedBox(width: 8.0), // Reduced spacing
            CupertinoButton(
              padding: const EdgeInsets.all(10.0),
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(20.0),
              onPressed: _isLoading || _textController.text.isEmpty ? null : _sendMessage,
              child: const Icon(CupertinoIcons.arrow_up, color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
