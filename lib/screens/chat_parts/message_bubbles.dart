part of '../chat_screen.dart';

/// message_bubbles.dart - _ChatScreenState 的拆分方法（extension 形式，与主文件同一 library，可访问私有成员）
extension _MessageBubblesExt on _ChatScreenState {
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
        message.sender == MessageSender.ai && message.isLoading;
    Widget messageContent;
    if (isAiLoading && message.text.isEmpty) {
      messageContent = SizedBox(
        width: 80,
        height: 20,
        child: Center(
          child: SpinKitThreeBounce(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
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

    messageContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [ToolCallRecords(message: message), messageContent],
    );
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
                  : theme.colorScheme.surfaceContainerHighest,
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
                    await Clipboard.setData(ClipboardData(text: message.text));
                    if (!context.mounted) return;
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

  int _findLoadingImageMessageIndex(String prompt) {
    for (int i = _messages.length - 1; i >= 0; i--) {
      if (_messages[i] is ImageMessage &&
          (_messages[i] as ImageMessage).text == prompt &&
          (_messages[i] as ImageMessage).isLoading) {
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
}
