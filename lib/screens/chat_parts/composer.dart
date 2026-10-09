part of '../chat_screen.dart';

/// composer.dart - _ChatScreenState 的拆分方法（extension 形式，与主文件同一 library，可访问私有成员）
extension _ComposerExt on _ChatScreenState {
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
                    color: theme.colorScheme.shadow.withValues(alpha: 0.1),
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
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.3,
                  ),
                  borderRadius: BorderRadius.circular(
                    Platform.isMacOS ? 8 : 24,
                  ),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
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
                                .withValues(alpha: 0.7),
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
                                            .withValues(alpha: 0.4),
                              ),
                              tooltip: '网页搜索',
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
                  onPressed:
                      _isLoading
                          ? _stopGeneration
                          : isEmpty
                          ? null
                          : _sendMessage,
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        _isLoading || isEmpty
                            ? theme.colorScheme.surfaceContainerHighest
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
                  child: Icon(
                    _isLoading
                        ? Icons.stop_rounded
                        : Icons.arrow_upward_rounded,
                    size: 20,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
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
                id: DateTime.now().microsecondsSinceEpoch.toString(),
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
                id: DateTime.now().microsecondsSinceEpoch.toString(),
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
      debugPrint('Error generating image: $e');
    } finally {
      if (mounted && _isLoading) {
        setState(() {
          _isLoading = false;
        });
      }
      _scrollToBottom();
    }
  }

  void _addImageGenerationPlaceholders(String prompt) {
    if (!mounted) return;

    setState(() {
      _messages.add(
        ChatMessage(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          text: '/imagine $prompt',
          sender: MessageSender.user,
          timestamp: DateTime.now(),
        ),
      );
      _messages.add(
        ImageMessage(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
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
}
