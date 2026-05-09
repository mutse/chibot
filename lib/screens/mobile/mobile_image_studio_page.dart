import 'dart:convert';
import 'dart:io';

import 'package:chibot/models/image_message.dart';
import 'package:chibot/models/image_session.dart';
import 'package:chibot/providers/api_key_provider.dart';
import 'package:chibot/providers/image_model_provider.dart';
import 'package:chibot/screens/mobile/mobile_ui.dart';
import 'package:chibot/services/image_generation_service.dart';
import 'package:chibot/services/image_save_service.dart';
import 'package:chibot/services/image_session_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MobileImageStudioPage extends StatefulWidget {
  final VoidCallback? onOpenAppMenu;
  final VoidCallback? onOpenModels;
  final VoidCallback? onDataChanged;

  const MobileImageStudioPage({
    super.key,
    this.onOpenAppMenu,
    this.onOpenModels,
    this.onDataChanged,
  });

  @override
  State<MobileImageStudioPage> createState() => MobileImageStudioPageState();
}

class MobileImageStudioPageState extends State<MobileImageStudioPage> {
  static const List<String> _styles = [
    'Photorealistic',
    'Digital Art',
    'Minimal',
    'Cinematic',
    'Illustration',
    'Product',
  ];

  static const Map<String, String> _stylePrompts = {
    'Photorealistic': 'photorealistic, natural lighting, intricate details',
    'Digital Art': 'digital art, polished concept art, vibrant rendering',
    'Minimal': 'minimal composition, clean forms, refined palette',
    'Cinematic': 'cinematic lighting, dramatic composition, rich atmosphere',
    'Illustration': 'editorial illustration, expressive shapes, clean outlines',
    'Product': 'premium product photography, crisp detail, studio lighting',
  };

  static const List<String> _aspectRatios = [
    '1:1',
    '16:9',
    '4:3',
    '3:2',
    '9:16',
  ];

  final TextEditingController _promptController = TextEditingController();
  final ImageSessionService _sessionService = ImageSessionService();
  final ImageGenerationService _imageService = ImageGenerationService();

  List<ImageSession> _sessions = [];
  List<ImageMessage> _messages = [];
  String? _currentSessionId;
  String _selectedStyle = _styles.first;
  String _selectedAspectRatio = '16:9';
  int _selectedPreviewIndex = 0;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    final sessions = await _sessionService.loadSessions();
    sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    if (!mounted) return;
    setState(() {
      _sessions = sessions;
    });
  }

  void startNewSession() {
    setState(() {
      _currentSessionId = null;
      _messages = [];
      _selectedPreviewIndex = 0;
      _promptController.clear();
      _isGenerating = false;
    });
  }

  void loadSession(ImageSession session) {
    setState(() {
      _currentSessionId = session.id;
      _messages = List<ImageMessage>.from(session.messages);
      _selectedPreviewIndex =
          _previewImages.isEmpty ? 0 : _previewImages.length - 1;
    });
  }

  List<ImageMessage> get _previewImages =>
      _messages.where((message) => message.hasImage).toList();

  Future<void> _saveSession({
    required String prompt,
    required ImageModelProvider imageModel,
  }) async {
    _currentSessionId ??= DateTime.now().millisecondsSinceEpoch.toString();

    final existing =
        _sessions.where((item) => item.id == _currentSessionId).isNotEmpty
            ? _sessions.firstWhere((item) => item.id == _currentSessionId)
            : null;

    final session = ImageSession(
      id: _currentSessionId!,
      title:
          existing?.title ??
          (prompt.length > 34 ? '${prompt.substring(0, 34)}...' : prompt),
      messages: List<ImageMessage>.from(_messages),
      createdAt: existing?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      model: imageModel.selectedImageModel,
      provider: imageModel.selectedImageProvider,
      settings: {'style': _selectedStyle, 'aspectRatio': _selectedAspectRatio},
    );
    await _sessionService.saveSession(session);
    await _loadSessions();
    widget.onDataChanged?.call();
  }

  String _buildStyledPrompt(String prompt) {
    final stylePrompt = _stylePrompts[_selectedStyle];
    if (stylePrompt == null || stylePrompt.isEmpty) {
      return prompt;
    }
    return '$prompt, $stylePrompt';
  }

  String _openAiSizeForAspectRatio(String aspectRatio) {
    switch (aspectRatio) {
      case '9:16':
        return '1024x1792';
      case '16:9':
      case '4:3':
      case '3:2':
        return '1792x1024';
      case '1:1':
      default:
        return '1024x1024';
    }
  }

  Future<void> _generateImage() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty || _isGenerating) {
      return;
    }

    final apiKeys = context.read<ApiKeyProvider>();
    final imageModel = context.read<ImageModelProvider>();
    final imageApiKey = apiKeys.getImageApiKeyForProvider(
      imageModel.selectedImageProvider,
    );

    if (imageApiKey == null || imageApiKey.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请先配置图片模型对应的 API Key')));
      return;
    }

    if (imageModel.selectedImageProvider == 'Black Forest Labs') {
      await imageModel.setBflAspectRatio(_selectedAspectRatio);
    }

    setState(() {
      _isGenerating = true;
      _messages.add(
        ImageMessage.loading(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          prompt: prompt,
        ),
      );
      _selectedPreviewIndex = _previewImages.length;
    });

    try {
      final source = await _imageService.generateImage(
        apiKey: imageApiKey,
        prompt: _buildStyledPrompt(prompt),
        model: imageModel.selectedImageModel,
        providerBaseUrl: imageModel.imageProviderUrl,
        openAISize: _openAiSizeForAspectRatio(_selectedAspectRatio),
        aspectRatio:
            imageModel.selectedImageProvider == 'OpenAI'
                ? null
                : _selectedAspectRatio,
      );

      if (!mounted) return;
      setState(() {
        final lastIndex = _messages.length - 1;
        _messages[lastIndex] = ImageMessage.aiGenerated(
          id: _messages[lastIndex].id,
          prompt: prompt,
          imageUrl: source,
          timestamp: _messages[lastIndex].timestamp,
          metadata: {
            'style': _selectedStyle,
            'aspectRatio': _selectedAspectRatio,
          },
        );
        _selectedPreviewIndex =
            _previewImages.isEmpty ? 0 : _previewImages.length - 1;
      });
      await _saveSession(prompt: prompt, imageModel: imageModel);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        final lastIndex = _messages.length - 1;
        _messages[lastIndex] = ImageMessage.error(
          id: _messages[lastIndex].id,
          prompt: prompt,
          error: '$error',
          timestamp: _messages[lastIndex].timestamp,
        );
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('生成失败: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  Future<void> _deleteSession(ImageSession session) async {
    await _sessionService.deleteSession(session.id);
    if (!mounted) return;
    if (_currentSessionId == session.id) {
      startNewSession();
    }
    await _loadSessions();
    widget.onDataChanged?.call();
  }

  Future<void> _exportSession(ImageSession session) async {
    await ImageSaveService.exportImageHistory(session, context);
  }

  void _showSessionSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: MobileSurface(
              padding: const EdgeInsets.all(18),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.74,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Image Sessions',
                          style: TextStyle(
                            color: MobilePalette.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        MobileIconCircleButton(
                          icon: Icons.add_rounded,
                          onTap: () {
                            Navigator.pop(context);
                            startNewSession();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child:
                          _sessions.isEmpty
                              ? const Center(
                                child: Text(
                                  'No image sessions yet.',
                                  style: TextStyle(
                                    color: MobilePalette.textSecondary,
                                  ),
                                ),
                              )
                              : ListView.separated(
                                itemCount: _sessions.length,
                                separatorBuilder:
                                    (context, index) =>
                                        const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final session = _sessions[index];
                                  final preview =
                                      session.messages
                                              .where((item) => item.hasImage)
                                              .isNotEmpty
                                          ? session.messages
                                              .where((item) => item.hasImage)
                                              .last
                                          : null;
                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: _buildThumbnail(
                                      preview?.bestImageSource,
                                      size: 52,
                                    ),
                                    title: Text(
                                      session.displayTitle,
                                      style: const TextStyle(
                                        color: MobilePalette.textPrimary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${formatMobileDate(session.updatedAt)} • ${session.generatedImagesCount} images',
                                      style: const TextStyle(
                                        color: MobilePalette.textSecondary,
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.ios_share_rounded,
                                          ),
                                          tooltip: 'Export history',
                                          onPressed:
                                              () => _exportSession(session),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline_rounded,
                                          ),
                                          onPressed:
                                              () => _deleteSession(session),
                                        ),
                                      ],
                                    ),
                                    onTap: () {
                                      Navigator.pop(context);
                                      loadSession(session);
                                    },
                                  );
                                },
                              ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPreviewImage(String? source) {
    if (source == null || source.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: MobilePalette.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: MobilePalette.border),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                size: 42,
                color: MobilePalette.textSecondary,
              ),
              SizedBox(height: 12),
              Text(
                'Your latest image will appear here',
                style: TextStyle(color: MobilePalette.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    if (source.startsWith('data:image/')) {
      final bytes = base64Decode(source.split(',').last);
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.memory(bytes, fit: BoxFit.cover),
      );
    }

    if (source.startsWith('/') || source.startsWith('file://')) {
      final path =
          source.startsWith('file://')
              ? Uri.parse(source).toFilePath()
              : source;
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.file(File(path), fit: BoxFit.cover),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Image.network(source, fit: BoxFit.cover),
    );
  }

  Widget _buildThumbnail(String? source, {double size = 68}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: MobilePalette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MobilePalette.border),
      ),
      clipBehavior: Clip.antiAlias,
      child:
          source == null || source.isEmpty
              ? const Icon(
                Icons.image_outlined,
                color: MobilePalette.textSecondary,
              )
              : _buildPreviewImage(source),
    );
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imageModel = context.watch<ImageModelProvider>();
    final previews = _previewImages;
    final selectedImage =
        previews.isEmpty
            ? null
            : previews[_selectedPreviewIndex.clamp(0, previews.length - 1)];

    return DecoratedBox(
      decoration: buildMobileBackgroundDecoration(),
      child: Column(
        children: [
          MobileTopBar(
            leading: MobileIconCircleButton(
              icon:
                  widget.onOpenAppMenu != null
                      ? Icons.menu_rounded
                      : Icons.arrow_back_ios_new_rounded,
              onTap: widget.onOpenAppMenu ?? _showSessionSheet,
            ),
            title: 'Create Image',
            subtitle: '${imageModel.selectedImageProvider} creative workspace',
            trailing: MobileIconCircleButton(
              icon: Icons.history_toggle_off_rounded,
              onTap: _showSessionSheet,
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
              children: [
                MobileSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const MobileSectionLabel(title: 'Prompt'),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _promptController,
                        minLines: 3,
                        maxLines: 6,
                        decoration: const InputDecoration(
                          hintText: 'Describe the image you want to create...',
                          border: InputBorder.none,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _promptController,
                          builder: (context, value, child) {
                            return Text(
                              '${value.text.trim().length}/1000',
                              style: const TextStyle(
                                color: MobilePalette.textSecondary,
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                MobileSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MobileSectionLabel(
                        title: 'Style',
                        actionLabel: 'Models',
                        onAction: widget.onOpenModels,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children:
                            _styles
                                .map(
                                  (style) => MobilePill(
                                    label: style,
                                    selected: style == _selectedStyle,
                                    onTap: () {
                                      setState(() {
                                        _selectedStyle = style;
                                      });
                                    },
                                  ),
                                )
                                .toList(),
                      ),
                      const SizedBox(height: 18),
                      const MobileSectionLabel(title: 'Aspect Ratio'),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children:
                            _aspectRatios
                                .map(
                                  (ratio) => MobilePill(
                                    label: ratio,
                                    selected: ratio == _selectedAspectRatio,
                                    onTap: () {
                                      setState(() {
                                        _selectedAspectRatio = ratio;
                                      });
                                    },
                                  ),
                                )
                                .toList(),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: MobilePalette.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: MobilePalette.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.auto_mode_rounded,
                              color: MobilePalette.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    imageModel.selectedImageModel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: MobilePalette.textPrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    imageModel.selectedImageProvider,
                                    style: const TextStyle(
                                      color: MobilePalette.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                MobileSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const MobileSectionLabel(title: 'Preview'),
                      const SizedBox(height: 12),
                      AspectRatio(
                        aspectRatio:
                            _selectedAspectRatio == '9:16'
                                ? 9 / 16
                                : _selectedAspectRatio == '1:1'
                                ? 1
                                : _selectedAspectRatio == '4:3'
                                ? 4 / 3
                                : _selectedAspectRatio == '3:2'
                                ? 3 / 2
                                : 16 / 9,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: _buildPreviewImage(
                                selectedImage?.bestImageSource,
                              ),
                            ),
                            if (selectedImage != null)
                              Positioned(
                                top: 12,
                                right: 12,
                                child: MobileIconCircleButton(
                                  icon: Icons.download_rounded,
                                  onTap: () async {
                                    final source =
                                        selectedImage.bestImageSource;
                                    if (source == null || source.isEmpty) {
                                      return;
                                    }
                                    await ImageSaveService.saveImage(
                                      source,
                                      context,
                                    );
                                  },
                                ),
                              ),
                            if (_isGenerating)
                              Positioned.fill(
                                child: Container(
                                  color: Colors.black.withValues(alpha: 0.16),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (selectedImage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          selectedImage.displayText,
                          style: const TextStyle(
                            color: MobilePalette.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      if (previews.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 74,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: previews.length,
                            separatorBuilder:
                                (context, index) => const SizedBox(width: 10),
                            itemBuilder: (context, index) {
                              final preview = previews[index];
                              final selected = index == _selectedPreviewIndex;
                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedPreviewIndex = index;
                                  });
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color:
                                          selected
                                              ? MobilePalette.primary
                                              : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                  child: _buildThumbnail(
                                    preview.bestImageSource,
                                    size: 70,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                MobilePrimaryButton(
                  label: _isGenerating ? 'Generating...' : 'Generate',
                  icon: Icons.auto_awesome_rounded,
                  onPressed: _isGenerating ? null : _generateImage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
