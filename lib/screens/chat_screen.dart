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

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });
    _scrollToBottom();

    final settings = Provider.of<SettingsProvider>(context, listen: false);
    if (settings.apiKey == null || settings.apiKey!.isEmpty) {
      setState(() {
        _messages.add(ChatMessage(
          text: "Error: API Key not set. Please set it in settings.",
          sender: MessageSender.ai,
          timestamp: DateTime.now(),
        ));
        _isLoading = false;
      });
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
      setState(() {
        _messages.add(aiMessage);
      });
    } catch (e) {
      final errorMessage = ChatMessage(
        text: "Error: ${e.toString()}",
        sender: MessageSender.ai,
        timestamp: DateTime.now(),
      );
      setState(() {
        _messages.add(errorMessage);
      });
      print("Error sending message: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi AI Chat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
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
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final bool isUserMessage = message.sender == MessageSender.user;
    return Align(
      alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: isUserMessage ? Colors.blue[100] : Colors.grey[300],
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Text(message.text),
      ),
    );
  }

  Widget _buildInputField() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: const InputDecoration(
                hintText: 'Type your message...',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _isLoading ? null : _sendMessage(),
            ),
          ),
          const SizedBox(width: 8.0),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _isLoading ? null : _sendMessage,
            color: Theme.of(context).primaryColor,
          ),
        ],
      ),
    );
  }
}
