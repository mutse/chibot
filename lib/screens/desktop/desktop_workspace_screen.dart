import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:chibot/models/chat_message.dart';
import 'package:chibot/models/chat_session.dart';
import 'package:chibot/models/image_message.dart';
import 'package:chibot/models/image_session.dart';
import 'package:chibot/models/video_message.dart';
import 'package:chibot/models/video_session.dart';
import 'package:chibot/providers/api_key_provider.dart';
import 'package:chibot/providers/chat_model_provider.dart';
import 'package:chibot/providers/image_model_provider.dart';
import 'package:chibot/providers/search_provider.dart';
import 'package:chibot/providers/video_model_provider.dart';
import 'package:chibot/screens/settings_screen.dart';
import 'package:chibot/services/chat_session_service.dart';
import 'package:chibot/services/image_generation_service.dart';
import 'package:chibot/services/image_session_service.dart';
import 'package:chibot/services/search_service_factory.dart';
import 'package:chibot/services/service_manager.dart';
import 'package:chibot/services/veo3_service.dart';
import 'package:chibot/services/video_generation_service.dart';
import 'package:chibot/services/video_session_service.dart';
import 'package:chibot/widgets/chat_markdown.dart';
import 'package:chibot/widgets/video_player_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum _WorkspaceSection { chat, image, video, models, history }

enum _HistoryFilter { all, chat, image, video }

enum _ModelHubTab { chat, image, video }

enum _HistoryAssetType { chat, image, video }

class _HistoryAsset {
  const _HistoryAsset({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    this.chatSession,
    this.imageSession,
    this.videoSession,
    this.imageMessage,
    this.videoMessage,
  });

  final _HistoryAssetType type;
  final String title;
  final String subtitle;
  final DateTime timestamp;
  final ChatSession? chatSession;
  final ImageSession? imageSession;
  final VideoSession? videoSession;
  final ImageMessage? imageMessage;
  final VideoMessage? videoMessage;
}

class DesktopWorkspaceScreen extends StatefulWidget {
  const DesktopWorkspaceScreen({super.key});

  @override
  State<DesktopWorkspaceScreen> createState() => _DesktopWorkspaceScreenState();
}

class _DesktopWorkspaceScreenState extends State<DesktopWorkspaceScreen> {
  static const Color _bgColor = Color(0xFFF7F1E8);
  static const Color _panelColor = Color(0xFFFCFAF6);
  static const Color _inkColor = Color(0xFF142033);
  static const Color _mutedColor = Color(0xFF667085);
  static const Color _lineColor = Color(0xFFE7DDD1);
  static const Color _teal = Color(0xFF0B7B7B);
  static const Color _coral = Color(0xFFE85D43);
  static const Color _amber = Color(0xFFB8831D);
  static const Color _chatSoft = Color(0xFFF3F7F8);
  static const Color _userBubble = Color(0xFFF7E8DE);
  static const List<String> _imageStyles = <String>[
    'Photorealistic',
    'Editorial',
    'Cinematic',
    'Illustration',
  ];
  static const List<String> _imageAspectRatios = <String>[
    '1:1',
    '16:9',
    '3:2',
    '3:4',
    '9:16',
  ];
  static const List<String> _videoMotions = <String>[
    'Cinematic Pan',
    'Slow Push',
    'Orbit Shot',
    'Static Composition',
  ];
  static const List<String> _videoCameras = <String>[
    'Wide Angle',
    'Eye Level',
    'Close Up',
    'Aerial',
  ];
  static const List<String> _videoAspectRatios = <String>[
    '16:9',
    '9:16',
    '1:1',
    '4:3',
  ];

  final ChatSessionService _chatSessionService = ChatSessionService();
  final ImageSessionService _imageSessionService = ImageSessionService();
  final VideoSessionService _videoSessionService = VideoSessionService();
  final ImageGenerationService _imageGenerationService =
      ImageGenerationService();

  final TextEditingController _chatInputController = TextEditingController();
  final TextEditingController _chatFilterController = TextEditingController();
  final TextEditingController _imagePromptController = TextEditingController();
  final TextEditingController _videoPromptController = TextEditingController();
  final TextEditingController _historySearchController =
      TextEditingController();

  final ScrollController _pageScrollController = ScrollController();
  final ScrollController _chatMessagesScrollController = ScrollController();
  final List<StreamSubscription<VideoGenerationProgress>> _videoSubscriptions =
      <StreamSubscription<VideoGenerationProgress>>[];
  late final Map<_WorkspaceSection, GlobalKey> _sectionKeys =
      <_WorkspaceSection, GlobalKey>{
        for (final section in _WorkspaceSection.values) section: GlobalKey(),
      };

  Veo3Service? _veo3Service;

  List<ChatSession> _chatSessions = <ChatSession>[];
  List<ChatMessage> _activeChatMessages = <ChatMessage>[];
  String? _currentChatSessionId;
  bool _isChatSending = false;
  bool _chatWebSearchEnabled = false;
  String _chatFilter = '';

  List<ImageSession> _imageSessions = <ImageSession>[];
  String? _currentImageSessionId;
  ImageMessage? _selectedImagePreview;
  bool _isImageGenerating = false;
  String _selectedImageStyle = _imageStyles.first;
  String _selectedImageAspectRatio = _imageAspectRatios.first;

  List<VideoSession> _videoSessions = <VideoSession>[];
  VideoSession? _currentVideoSession;
  VideoMessage? _selectedVideoPreview;
  bool _isVideoGenerating = false;
  VideoResolution _selectedVideoResolution = VideoResolution.res720p;
  VideoDuration _selectedVideoDuration = VideoDuration.seconds10;
  String _selectedVideoQuality = 'standard';
  String _selectedVideoAspectRatio = _videoAspectRatios.first;
  String _selectedVideoMotion = _videoMotions.first;
  String _selectedVideoCamera = _videoCameras.first;

  _HistoryFilter _historyFilter = _HistoryFilter.all;
  _ModelHubTab _modelHubTab = _ModelHubTab.chat;

  @override
  void initState() {
    super.initState();
    _chatFilterController.addListener(_handleChatFilterChanged);
    _historySearchController.addListener(_handleHistoryQueryChanged);
    _hydrateDesktopDefaults();
    _loadWorkspaceData();
    _initializeVeoService();
  }

  @override
  void dispose() {
    for (final subscription in _videoSubscriptions) {
      subscription.cancel();
    }
    _veo3Service?.dispose();
    _chatInputController.dispose();
    _chatFilterController
      ..removeListener(_handleChatFilterChanged)
      ..dispose();
    _imagePromptController.dispose();
    _videoPromptController.dispose();
    _historySearchController
      ..removeListener(_handleHistoryQueryChanged)
      ..dispose();
    _pageScrollController.dispose();
    _chatMessagesScrollController.dispose();
    super.dispose();
  }

  void _hydrateDesktopDefaults() {
    final imageModel = context.read<ImageModelProvider>();
    final videoModel = context.read<VideoModelProvider>();

    _selectedImageAspectRatio =
        imageModel.bflAspectRatio != null &&
                _imageAspectRatios.contains(imageModel.bflAspectRatio)
            ? imageModel.bflAspectRatio!
            : _imageAspectRatios.first;
    _selectedVideoAspectRatio =
        _videoAspectRatios.contains(videoModel.videoAspectRatio)
            ? videoModel.videoAspectRatio
            : _videoAspectRatios.first;
    _selectedVideoQuality = videoModel.videoQuality;
    _selectedVideoResolution = VideoResolution.fromString(
      videoModel.videoResolution,
    );
    _selectedVideoDuration = _parseVideoDuration(videoModel.videoDuration);
  }

  Future<void> _initializeVeoService() async {
    final apiKeys = context.read<ApiKeyProvider>();
    if (apiKeys.googleApiKey != null && apiKeys.googleApiKey!.isNotEmpty) {
      _veo3Service = Veo3Service(apiKey: apiKeys.googleApiKey!);
    }
  }

  void _handleChatFilterChanged() {
    if (_chatFilter == _chatFilterController.text.trim()) {
      return;
    }
    setState(() {
      _chatFilter = _chatFilterController.text.trim().toLowerCase();
    });
  }

  void _handleHistoryQueryChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  Future<void> _loadWorkspaceData() async {
    final results = await Future.wait<Object?>(<Future<Object?>>[
      _chatSessionService.loadSessions(),
      _imageSessionService.loadSessions(),
      _videoSessionService.getAllSessions(),
      _videoSessionService.getCurrentSessionId(),
    ]);

    final chatSessions = List<ChatSession>.from(results[0] as List<ChatSession>)
      ..sort(
        (ChatSession a, ChatSession b) => b.updatedAt.compareTo(a.updatedAt),
      );
    final imageSessions = List<ImageSession>.from(
      results[1] as List<ImageSession>,
    )..sort(
      (ImageSession a, ImageSession b) => b.updatedAt.compareTo(a.updatedAt),
    );
    final videoSessions = List<VideoSession>.from(
      results[2] as List<VideoSession>,
    );
    final currentVideoSessionId = results[3] as String?;

    final ChatSession? activeChatSession =
        _findChatSessionById(chatSessions, _currentChatSessionId) ??
        (chatSessions.isNotEmpty ? chatSessions.first : null);
    final VideoSession? activeVideoSession =
        _findVideoSessionById(
          videoSessions,
          _currentVideoSession?.id ?? currentVideoSessionId,
        ) ??
        (videoSessions.isNotEmpty ? videoSessions.first : null);
    final ImageMessage? latestImage = _pickInitialImagePreview(imageSessions);
    final VideoMessage? latestVideo = _pickInitialVideoPreview(videoSessions);

    if (!mounted) {
      return;
    }

    setState(() {
      _chatSessions = chatSessions;
      _imageSessions = imageSessions;
      _videoSessions = videoSessions;
      _currentChatSessionId = activeChatSession?.id;
      _activeChatMessages =
          activeChatSession?.messages.toList() ?? _activeChatMessages;
      _currentVideoSession = activeVideoSession;
      _selectedImagePreview = _selectedImagePreview ?? latestImage;
      _selectedVideoPreview = _selectedVideoPreview ?? latestVideo;
      if (_currentImageSessionId == null && latestImage != null) {
        final ImageSession? session = _findImageSessionForMessage(
          imageSessions,
          latestImage.id,
        );
        _currentImageSessionId = session?.id;
      }
    });

    _scrollChatToBottom();
  }

  ChatSession? _findChatSessionById(
    List<ChatSession> sessions,
    String? sessionId,
  ) {
    if (sessionId == null) {
      return null;
    }
    for (final ChatSession session in sessions) {
      if (session.id == sessionId) {
        return session;
      }
    }
    return null;
  }

  ImageSession? _findImageSessionById(
    List<ImageSession> sessions,
    String? sessionId,
  ) {
    if (sessionId == null) {
      return null;
    }
    for (final ImageSession session in sessions) {
      if (session.id == sessionId) {
        return session;
      }
    }
    return null;
  }

  VideoSession? _findVideoSessionById(
    List<VideoSession> sessions,
    String? sessionId,
  ) {
    if (sessionId == null) {
      return null;
    }
    for (final VideoSession session in sessions) {
      if (session.id == sessionId) {
        return session;
      }
    }
    return null;
  }

  ImageSession? _findImageSessionForMessage(
    List<ImageSession> sessions,
    String messageId,
  ) {
    for (final ImageSession session in sessions) {
      for (final ImageMessage message in session.messages) {
        if (message.id == messageId) {
          return session;
        }
      }
    }
    return null;
  }

  ImageMessage? _pickInitialImagePreview(List<ImageSession> sessions) {
    final List<ImageMessage> images = _recentImagesFromSessions(sessions);
    return images.isEmpty ? null : images.first;
  }

  VideoMessage? _pickInitialVideoPreview(List<VideoSession> sessions) {
    final List<VideoMessage> videos = _recentVideosFromSessions(sessions);
    return videos.isEmpty ? null : videos.first;
  }

  List<ImageMessage> _recentImagesFromSessions(List<ImageSession> sessions) {
    final List<ImageMessage> images = <ImageMessage>[];
    for (final ImageSession session in sessions) {
      images.addAll(
        session.messages.where(
          (ImageMessage message) =>
              message.hasImage ||
              message.imageData != null ||
              message.imageUrl != null,
        ),
      );
    }
    images.sort(
      (ImageMessage a, ImageMessage b) => b.timestamp.compareTo(a.timestamp),
    );
    return images;
  }

  List<VideoMessage> _recentVideosFromSessions(List<VideoSession> sessions) {
    final List<VideoMessage> videos = <VideoMessage>[];
    for (final VideoSession session in sessions) {
      videos.addAll(session.videos);
    }
    videos.sort(
      (VideoMessage a, VideoMessage b) => b.timestamp.compareTo(a.timestamp),
    );
    return videos;
  }

  VideoDuration _parseVideoDuration(String value) {
    switch (value) {
      case '5s':
        return VideoDuration.seconds5;
      case '15s':
        return VideoDuration.seconds15;
      case '30s':
        return VideoDuration.seconds30;
      default:
        return VideoDuration.seconds10;
    }
  }

  Future<void> _reloadChatSessions() async {
    final List<ChatSession> sessions = await _chatSessionService.loadSessions();
    sessions.sort(
      (ChatSession a, ChatSession b) => b.updatedAt.compareTo(a.updatedAt),
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _chatSessions = sessions;
    });
  }

  Future<void> _reloadImageSessions({
    String? focusSessionId,
    String? focusMessageId,
  }) async {
    final List<ImageSession> sessions =
        await _imageSessionService.loadSessions();
    sessions.sort(
      (ImageSession a, ImageSession b) => b.updatedAt.compareTo(a.updatedAt),
    );

    ImageMessage? selectedMessage = _selectedImagePreview;
    String? selectedSessionId = _currentImageSessionId;

    if (focusSessionId != null) {
      selectedSessionId = focusSessionId;
    }
    if (focusMessageId != null) {
      for (final ImageSession session in sessions) {
        for (final ImageMessage message in session.messages) {
          if (message.id == focusMessageId) {
            selectedMessage = message;
            selectedSessionId = session.id;
            break;
          }
        }
      }
    }

    selectedMessage ??= _pickInitialImagePreview(sessions);
    selectedSessionId ??=
        _findImageSessionForMessage(sessions, selectedMessage?.id ?? '')?.id;

    if (!mounted) {
      return;
    }
    setState(() {
      _imageSessions = sessions;
      _selectedImagePreview = selectedMessage;
      _currentImageSessionId = selectedSessionId;
    });
  }

  Future<void> _reloadVideoSessions({
    String? focusSessionId,
    String? focusVideoId,
  }) async {
    final List<VideoSession> sessions =
        await _videoSessionService.getAllSessions();
    final String? currentSessionId =
        focusSessionId ??
        _currentVideoSession?.id ??
        await _videoSessionService.getCurrentSessionId();
    VideoSession? session = _findVideoSessionById(sessions, currentSessionId);
    session ??= sessions.isNotEmpty ? sessions.first : null;

    VideoMessage? preview;
    if (focusVideoId != null && session != null) {
      for (final VideoMessage video in session.videos) {
        if (video.id == focusVideoId) {
          preview = video;
          break;
        }
      }
    }
    preview ??= _selectedVideoPreview;
    if (preview != null && session != null) {
      final bool stillExists = session.videos.any(
        (VideoMessage message) => message.id == preview!.id,
      );
      if (!stillExists) {
        preview = null;
      }
    }
    preview ??=
        session?.videos.isNotEmpty == true ? session!.videos.last : null;
    preview ??= _pickInitialVideoPreview(sessions);

    if (session != null) {
      await _videoSessionService.setCurrentSessionId(session.id);
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _videoSessions = sessions;
      _currentVideoSession = session;
      _selectedVideoPreview = preview;
    });
  }

  void _showInfo(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _scrollChatToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatMessagesScrollController.hasClients) {
        _chatMessagesScrollController.animateTo(
          _chatMessagesScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _scrollToSection(_WorkspaceSection section) async {
    final BuildContext? targetContext = _sectionKeys[section]?.currentContext;
    if (targetContext == null) {
      return;
    }
    await Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeInOutCubic,
      alignment: 0.04,
    );
  }

  void _startNewChat() {
    setState(() {
      _currentChatSessionId = null;
      _activeChatMessages = <ChatMessage>[];
      _isChatSending = false;
    });
  }

  void _openChatSession(ChatSession session) {
    setState(() {
      _currentChatSessionId = session.id;
      _activeChatMessages = session.messages.toList();
      _isChatSending = false;
    });
    _scrollChatToBottom();
  }

  Future<String?> _buildPromptWithSearch(String prompt) async {
    if (!_chatWebSearchEnabled) {
      return prompt;
    }

    final SearchProvider searchProvider = context.read<SearchProvider>();
    final ApiKeyProvider apiKeys = context.read<ApiKeyProvider>();

    if (!SearchServiceFactory.hasSearchEngineConfigured(
      search: searchProvider,
      apiKeys: apiKeys,
    )) {
      _showInfo('Search is not configured yet. Answering without web search.');
      return prompt;
    }

    try {
      final String searchContext =
          await SearchServiceFactory.searchWebAsPromptContext(
            search: searchProvider,
            apiKeys: apiKeys,
            query: prompt,
          );

      return '''
Use the following search context when it is relevant. Be explicit about uncertainty and avoid fabricating facts.

Search context:
$searchContext

User request:
$prompt
''';
    } catch (error) {
      _showInfo('Search failed: $error');
      return prompt;
    }
  }

  Future<void> _persistChatSession() async {
    final List<ChatMessage> savableMessages =
        _activeChatMessages
            .where((ChatMessage message) => !message.isLoading)
            .toList();
    if (savableMessages.isEmpty) {
      return;
    }

    final ChatModelProvider chatModel = context.read<ChatModelProvider>();
    final ChatSession? existing = _findChatSessionById(
      _chatSessions,
      _currentChatSessionId,
    );
    final String sessionId =
        _currentChatSessionId ??
        DateTime.now().microsecondsSinceEpoch.toString();
    final DateTime createdAt = existing?.createdAt ?? DateTime.now();
    final String title =
        existing?.title ??
        _titleFromText(
          savableMessages
              .firstWhere(
                (ChatMessage message) => message.sender == MessageSender.user,
                orElse: () => savableMessages.first,
              )
              .text,
        );

    final ChatSession session = ChatSession(
      id: sessionId,
      title: title,
      messages: savableMessages,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      modelUsed: chatModel.selectedModel,
      providerUsed: chatModel.selectedProvider,
    );

    await _chatSessionService.saveSession(session);
    _currentChatSessionId = sessionId;
    await _reloadChatSessions();
  }

  Future<void> _sendChatMessage() async {
    if (_isChatSending) {
      return;
    }
    final String rawText = _chatInputController.text.trim();
    if (rawText.isEmpty) {
      return;
    }

    final ChatModelProvider chatModel = context.read<ChatModelProvider>();
    final ApiKeyProvider apiKeys = context.read<ApiKeyProvider>();
    final String? apiKey = apiKeys.getApiKeyForProvider(
      chatModel.selectedProvider,
    );
    if (apiKey == null || apiKey.isEmpty) {
      _showInfo(
        'Please configure the ${chatModel.selectedProvider} API key first.',
      );
      return;
    }

    _chatInputController.clear();
    final String prompt = await _buildPromptWithSearch(rawText) ?? rawText;
    final List<ChatMessage> contextMessages = List<ChatMessage>.from(
      _activeChatMessages.where((ChatMessage message) => !message.isLoading),
    );
    final ChatMessage userMessage = ChatMessage.user(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: rawText,
    );
    final ChatMessage aiPlaceholder = ChatMessage.loading(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
    );

    setState(() {
      _isChatSending = true;
      _activeChatMessages = <ChatMessage>[
        ..._activeChatMessages,
        userMessage,
        aiPlaceholder,
      ];
    });
    _scrollChatToBottom();

    try {
      final chatService = ServiceManager.createChatService(
        chatModel: chatModel,
        apiKeys: apiKeys,
      );

      String fullResponse = '';
      await for (final String chunk in chatService.generateResponse(
        prompt: prompt,
        context: contextMessages,
        model: chatModel.selectedModel,
      )) {
        fullResponse += chunk;
        if (!mounted) {
          return;
        }
        setState(() {
          final int lastIndex = _activeChatMessages.length - 1;
          if (lastIndex >= 0) {
            _activeChatMessages[lastIndex] = ChatMessage.ai(
              id: _activeChatMessages[lastIndex].id,
              text: fullResponse,
              timestamp: _activeChatMessages[lastIndex].timestamp,
              isLoading: true,
            );
          }
        });
        _scrollChatToBottom();
      }

      if (!mounted) {
        return;
      }
      setState(() {
        final int lastIndex = _activeChatMessages.length - 1;
        if (lastIndex >= 0) {
          _activeChatMessages[lastIndex] = ChatMessage.ai(
            id: _activeChatMessages[lastIndex].id,
            text: fullResponse.isEmpty ? 'No response returned.' : fullResponse,
            timestamp: _activeChatMessages[lastIndex].timestamp,
          );
        }
        _isChatSending = false;
      });
      await _persistChatSession();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        final int lastIndex = _activeChatMessages.length - 1;
        if (lastIndex >= 0) {
          _activeChatMessages[lastIndex] = ChatMessage.ai(
            id: _activeChatMessages[lastIndex].id,
            text: 'Something went wrong: $error',
            timestamp: _activeChatMessages[lastIndex].timestamp,
          );
        }
        _isChatSending = false;
      });
      await _persistChatSession();
    } finally {
      if (mounted) {
        setState(() {
          _isChatSending = false;
        });
      }
      _scrollChatToBottom();
    }
  }

  Future<void> _startNewImageProject() async {
    setState(() {
      _currentImageSessionId = null;
      _selectedImagePreview = _pickInitialImagePreview(_imageSessions);
      _imagePromptController.clear();
      _isImageGenerating = false;
    });
  }

  Future<void> _openImageSession(
    ImageSession session, {
    ImageMessage? preview,
  }) async {
    setState(() {
      _currentImageSessionId = session.id;
      _selectedImagePreview =
          preview ??
          (session.messages.isNotEmpty ? session.messages.last : null);
    });
  }

  Future<void> _saveImageResult({
    required String rawPrompt,
    required ImageMessage message,
    required ImageModelProvider imageModel,
  }) async {
    final ImageSession? existing = _findImageSessionById(
      _imageSessions,
      _currentImageSessionId,
    );
    final String sessionId =
        _currentImageSessionId ??
        DateTime.now().microsecondsSinceEpoch.toString();
    final List<ImageMessage> messages = <ImageMessage>[
      ...(existing?.messages ?? <ImageMessage>[]),
      message,
    ];

    final ImageSession session = ImageSession(
      id: sessionId,
      title: existing?.title ?? _titleFromText(rawPrompt),
      messages: messages,
      createdAt: existing?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      model: imageModel.selectedImageModel,
      provider: imageModel.selectedImageProvider,
      settings: <String, dynamic>{
        'style': _selectedImageStyle,
        'aspectRatio': _selectedImageAspectRatio,
      },
    );

    await _imageSessionService.saveSession(session);
    _currentImageSessionId = sessionId;
    await _reloadImageSessions(
      focusSessionId: sessionId,
      focusMessageId: message.id,
    );
  }

  String _openAiImageSizeForAspect(String aspectRatio) {
    switch (aspectRatio) {
      case '16:9':
      case '3:2':
        return '1792x1024';
      case '9:16':
      case '3:4':
        return '1024x1792';
      default:
        return '1024x1024';
    }
  }

  String _buildImagePrompt(String rawPrompt) {
    return '$rawPrompt. Style: $_selectedImageStyle.';
  }

  Future<void> _generateImage() async {
    if (_isImageGenerating) {
      return;
    }
    final String rawPrompt = _imagePromptController.text.trim();
    if (rawPrompt.isEmpty) {
      return;
    }

    final ImageModelProvider imageModel = context.read<ImageModelProvider>();
    final ApiKeyProvider apiKeys = context.read<ApiKeyProvider>();
    final String? apiKey = apiKeys.getImageApiKeyForProvider(
      imageModel.selectedImageProvider,
    );
    if (apiKey == null || apiKey.isEmpty) {
      _showInfo(
        'Please configure the ${imageModel.selectedImageProvider} image API key.',
      );
      return;
    }

    await imageModel.setBflAspectRatio(_selectedImageAspectRatio);

    setState(() {
      _isImageGenerating = true;
    });

    try {
      final String? imageSource = await _imageGenerationService.generateImage(
        apiKey: apiKey,
        prompt: _buildImagePrompt(rawPrompt),
        model: imageModel.selectedImageModel,
        providerBaseUrl: imageModel.imageProviderUrl,
        openAISize: _openAiImageSizeForAspect(_selectedImageAspectRatio),
        aspectRatio: _selectedImageAspectRatio,
      );

      if (imageSource == null || imageSource.isEmpty) {
        throw Exception('No image returned.');
      }

      final ImageMessage message = ImageMessage.aiGenerated(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        prompt: rawPrompt,
        imageUrl: imageSource,
        timestamp: DateTime.now(),
        metadata: <String, dynamic>{
          'style': _selectedImageStyle,
          'aspectRatio': _selectedImageAspectRatio,
        },
      );

      await _saveImageResult(
        rawPrompt: rawPrompt,
        message: message,
        imageModel: imageModel,
      );
      _imagePromptController.clear();
    } catch (error) {
      _showInfo('Image generation failed: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isImageGenerating = false;
        });
      }
    }
  }

  Future<void> _startNewVideoProject() async {
    setState(() {
      _currentVideoSession = null;
      _selectedVideoPreview = _pickInitialVideoPreview(_videoSessions);
      _videoPromptController.clear();
      _isVideoGenerating = false;
    });
  }

  Future<void> _persistVideoDefaults() async {
    final VideoModelProvider videoModel = context.read<VideoModelProvider>();
    await videoModel.setVideoResolution(_selectedVideoResolution.label);
    if (_selectedVideoDuration != VideoDuration.seconds15) {
      await videoModel.setVideoDuration(_selectedVideoDuration.label);
    }
    await videoModel.setVideoQuality(_selectedVideoQuality);
    await videoModel.setVideoAspectRatio(_selectedVideoAspectRatio);
  }

  Future<VideoSession> _ensureVideoSession() async {
    if (_currentVideoSession != null) {
      return _currentVideoSession!;
    }

    final VideoSession session = await _videoSessionService.createSession(
      title: 'Video Project ${_videoSessions.length + 1}',
      settings: VideoSettings(
        resolution: _selectedVideoResolution,
        duration: _selectedVideoDuration,
        quality: _selectedVideoQuality,
        style: _selectedVideoMotion,
        aspectRatio: _selectedVideoAspectRatio,
      ),
    );

    _currentVideoSession = session;
    await _reloadVideoSessions(focusSessionId: session.id);
    return session;
  }

  String _buildVideoPrompt(String rawPrompt) {
    return '$rawPrompt. Motion: $_selectedVideoMotion. Camera: $_selectedVideoCamera.';
  }

  Future<String> _saveVideoBytes(String sessionId, String rawData) async {
    final String normalized =
        rawData.startsWith('data:video/') ? rawData.split(',').last : rawData;
    final Uint8List bytes = base64Decode(normalized);
    final String directory = await _videoSessionService.getVideoDirectory(
      sessionId,
    );
    final File file = File(
      '$directory/video_${DateTime.now().millisecondsSinceEpoch}.mp4',
    );
    await file.writeAsBytes(bytes);
    return file.path;
  }

  Future<void> _generateVideo() async {
    if (_isVideoGenerating) {
      return;
    }
    final String rawPrompt = _videoPromptController.text.trim();
    if (rawPrompt.isEmpty) {
      return;
    }

    final ApiKeyProvider apiKeys = context.read<ApiKeyProvider>();
    final String? apiKey = apiKeys.googleApiKey;
    if (apiKey == null || apiKey.isEmpty) {
      _showInfo('Please configure the Google / Veo API key first.');
      return;
    }

    _veo3Service ??= Veo3Service(apiKey: apiKey);
    await _persistVideoDefaults();

    setState(() {
      _isVideoGenerating = true;
    });

    try {
      final VideoSession session = await _ensureVideoSession();
      final VideoMessage placeholder = VideoMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        text: rawPrompt,
        prompt: rawPrompt,
        sender: MessageSender.user,
        timestamp: DateTime.now(),
        resolution: _selectedVideoResolution,
        duration: _selectedVideoDuration,
        status: VideoStatus.pending,
        isLoading: true,
      );

      _currentVideoSession = await _videoSessionService.addVideoToSession(
        session.id,
        placeholder,
      );
      _selectedVideoPreview = placeholder;
      await _reloadVideoSessions(
        focusSessionId: session.id,
        focusVideoId: placeholder.id,
      );

      final VideoGenerationResponse response = await _veo3Service!
          .generateVideo(
            VideoGenerationRequest(
              prompt: _buildVideoPrompt(rawPrompt),
              resolution: _selectedVideoResolution,
              duration: _selectedVideoDuration,
              quality: _selectedVideoQuality,
              aspectRatio: _selectedVideoAspectRatio,
              style: _selectedVideoMotion,
            ),
          );

      _videoPromptController.clear();
      if (response.jobId == null || response.jobId!.isEmpty) {
        throw Exception('Video job did not start.');
      }
      _trackVideoGeneration(response.jobId!, session.id, placeholder.id);
    } catch (error) {
      _showInfo('Video generation failed: $error');
      if (mounted) {
        setState(() {
          _isVideoGenerating = false;
        });
      }
    }
  }

  void _trackVideoGeneration(String jobId, String sessionId, String messageId) {
    final StreamSubscription<VideoGenerationProgress> subscription =
        _veo3Service!
            .getGenerationProgress(jobId)
            .listen(
              (VideoGenerationProgress progress) async {
                final VideoSession? session = await _videoSessionService
                    .getSession(sessionId);
                if (session == null) {
                  return;
                }

                final int index = session.videos.indexWhere(
                  (VideoMessage video) => video.id == messageId,
                );
                if (index == -1) {
                  return;
                }

                VideoMessage updatedMessage = session.videos[index].copyWith(
                  status: progress.status,
                  progress: progress.progress,
                  jobId: jobId,
                  isLoading: progress.status != VideoStatus.completed,
                );

                await _videoSessionService.updateVideoInSession(
                  session.id,
                  index,
                  updatedMessage,
                );

                if (progress.status == VideoStatus.completed) {
                  final VideoGenerationResponse finalResponse =
                      await _veo3Service!.checkGenerationStatus(jobId);
                  if (finalResponse.videoUrl != null &&
                      finalResponse.videoUrl!.isNotEmpty) {
                    String? localPath;
                    String? remoteUrl;
                    if (finalResponse.videoUrl!.startsWith('http')) {
                      remoteUrl = finalResponse.videoUrl;
                    } else {
                      localPath = await _saveVideoBytes(
                        session.id,
                        finalResponse.videoUrl!,
                      );
                    }

                    updatedMessage = updatedMessage.copyWith(
                      localPath: localPath,
                      videoUrl: remoteUrl,
                      thumbnail: finalResponse.thumbnail,
                      status: VideoStatus.completed,
                      isLoading: false,
                      progress: 1.0,
                    );

                    await _videoSessionService.updateVideoInSession(
                      session.id,
                      index,
                      updatedMessage,
                    );
                  }
                }

                await _reloadVideoSessions(
                  focusSessionId: session.id,
                  focusVideoId: messageId,
                );

                if (!mounted) {
                  return;
                }
                setState(() {
                  if (progress.status == VideoStatus.completed ||
                      progress.status == VideoStatus.failed) {
                    _isVideoGenerating = false;
                  }
                });
              },
              onError: (Object error) {
                _showInfo('Video generation failed: $error');
                if (mounted) {
                  setState(() {
                    _isVideoGenerating = false;
                  });
                }
              },
            );

    _videoSubscriptions.add(subscription);
  }

  String _titleFromText(String text) {
    final String trimmed = text.trim();
    if (trimmed.isEmpty) {
      return 'Untitled project';
    }
    return trimmed.length > 32 ? '${trimmed.substring(0, 32)}...' : trimmed;
  }

  String _relativeTimestamp(DateTime timestamp) {
    final Duration diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) {
      return 'Just now';
    }
    if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    }
    if (diff.inDays < 1) {
      return '${diff.inHours}h ago';
    }
    if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    }
    return '${timestamp.month}/${timestamp.day}';
  }

  String _formatPromptSnippet(String value, {int max = 72}) {
    final String singleLine = value.replaceAll('\n', ' ').trim();
    if (singleLine.length <= max) {
      return singleLine;
    }
    return '${singleLine.substring(0, max)}...';
  }

  bool _hasVideoSource(VideoMessage? video) {
    return video?.localPath != null || video?.videoUrl != null;
  }

  List<ChatSession> get _filteredChatSessions {
    if (_chatFilter.isEmpty) {
      return _chatSessions;
    }
    return _chatSessions.where((ChatSession session) {
      final String haystack =
          '${session.title} ${session.lastMessage?.text ?? ''}'.toLowerCase();
      return haystack.contains(_chatFilter);
    }).toList();
  }

  List<ImageMessage> get _recentImageAssets =>
      _recentImagesFromSessions(_imageSessions);

  List<VideoMessage> get _recentVideoAssets =>
      _recentVideosFromSessions(_videoSessions);

  List<_HistoryAsset> get _historyAssets {
    final List<_HistoryAsset> assets = <_HistoryAsset>[
      for (final ChatSession session in _chatSessions)
        _HistoryAsset(
          type: _HistoryAssetType.chat,
          title: session.title,
          subtitle: _formatPromptSnippet(
            session.lastMessage?.text ?? 'Empty chat',
          ),
          timestamp: session.updatedAt,
          chatSession: session,
        ),
      for (final ImageSession session in _imageSessions)
        for (final ImageMessage message in session.messages)
          _HistoryAsset(
            type: _HistoryAssetType.image,
            title: session.title,
            subtitle: _formatPromptSnippet(message.text),
            timestamp: message.timestamp,
            imageSession: session,
            imageMessage: message,
          ),
      for (final VideoSession session in _videoSessions)
        for (final VideoMessage message in session.videos)
          _HistoryAsset(
            type: _HistoryAssetType.video,
            title: session.title,
            subtitle: _formatPromptSnippet(message.prompt),
            timestamp: message.timestamp,
            videoSession: session,
            videoMessage: message,
          ),
    ];

    assets.sort(
      (_HistoryAsset a, _HistoryAsset b) => b.timestamp.compareTo(a.timestamp),
    );

    final String query = _historySearchController.text.trim().toLowerCase();
    return assets.where((_HistoryAsset asset) {
      final bool matchesFilter = switch (_historyFilter) {
        _HistoryFilter.all => true,
        _HistoryFilter.chat => asset.type == _HistoryAssetType.chat,
        _HistoryFilter.image => asset.type == _HistoryAssetType.image,
        _HistoryFilter.video => asset.type == _HistoryAssetType.video,
      };
      if (!matchesFilter) {
        return false;
      }
      if (query.isEmpty) {
        return true;
      }
      final String haystack = '${asset.title} ${asset.subtitle}'.toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  Future<void> _handleHistoryTap(_HistoryAsset asset) async {
    switch (asset.type) {
      case _HistoryAssetType.chat:
        if (asset.chatSession != null) {
          _openChatSession(asset.chatSession!);
          await _scrollToSection(_WorkspaceSection.chat);
        }
      case _HistoryAssetType.image:
        if (asset.imageSession != null) {
          await _openImageSession(
            asset.imageSession!,
            preview: asset.imageMessage,
          );
          await _scrollToSection(_WorkspaceSection.image);
        }
      case _HistoryAssetType.video:
        if (asset.videoSession != null) {
          await _videoSessionService.setCurrentSessionId(
            asset.videoSession!.id,
          );
          setState(() {
            _currentVideoSession = asset.videoSession;
            _selectedVideoPreview = asset.videoMessage;
          });
          await _scrollToSection(_WorkspaceSection.video);
        }
    }
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const SettingsScreen(),
      ),
    );
    _hydrateDesktopDefaults();
    await _initializeVeoService();
    await _loadWorkspaceData();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ChatModelProvider chatModel = context.watch<ChatModelProvider>();
    final ImageModelProvider imageModel = context.watch<ImageModelProvider>();
    final ApiKeyProvider apiKeys = context.watch<ApiKeyProvider>();

    return Scaffold(
      backgroundColor: _bgColor,
      body: Stack(
        children: <Widget>[
          _buildBackgroundDecor(),
          SafeArea(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final bool isWide = constraints.maxWidth >= 1440;
                final bool isCompact = constraints.maxWidth < 1180;
                final double contentWidth = constraints.maxWidth - 48;

                return SingleChildScrollView(
                  controller: _pageScrollController,
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1680),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          _buildTopBar(),
                          const SizedBox(height: 24),
                          _buildHeroHeader(theme),
                          const SizedBox(height: 28),
                          if (isWide)
                            _buildWideRows(chatModel, imageModel, apiKeys)
                          else
                            _buildStackedSections(
                              contentWidth: contentWidth,
                              isCompact: isCompact,
                              chatModel: chatModel,
                              imageModel: imageModel,
                              apiKeys: apiKeys,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundDecor() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: <Widget>[
            Positioned(
              left: -80,
              top: -60,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.72),
                ),
              ),
            ),
            Positioned(
              right: -120,
              top: -20,
              child: Container(
                width: 360,
                height: 360,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFFF8EE).withValues(alpha: 0.92),
                ),
              ),
            ),
            Positioned(
              left: 160,
              right: 160,
              top: 0,
              child: Container(
                height: 240,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[
                      Colors.white.withValues(alpha: 0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: _panelDecoration(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Image.asset('assets/images/logo.png', width: 34, height: 34),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const <Widget>[
                  Text(
                    'CHIBOT',
                    style: TextStyle(
                      color: _inkColor,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.6,
                    ),
                  ),
                  Text(
                    'Desktop AI Workspace',
                    style: TextStyle(
                      color: _teal,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Spacer(),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.end,
          children: <Widget>[
            _buildNavButton(
              icon: Icons.chat_bubble_outline,
              label: 'Chat',
              onTap: () => _scrollToSection(_WorkspaceSection.chat),
            ),
            _buildNavButton(
              icon: Icons.image_outlined,
              label: 'Create Image',
              onTap: () => _scrollToSection(_WorkspaceSection.image),
            ),
            _buildNavButton(
              icon: Icons.movie_creation_outlined,
              label: 'Create Video',
              onTap: () => _scrollToSection(_WorkspaceSection.video),
            ),
            _buildNavButton(
              icon: Icons.layers_outlined,
              label: 'Models',
              onTap: () => _scrollToSection(_WorkspaceSection.models),
            ),
            _buildNavButton(
              icon: Icons.history,
              label: 'History',
              onTap: () => _scrollToSection(_WorkspaceSection.history),
            ),
            _buildNavButton(
              icon: Icons.tune,
              label: 'Settings',
              onTap: _openSettings,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeroHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Text(
            'One AI. Any Modality.',
            style: theme.textTheme.displaySmall?.copyWith(
              color: _inkColor,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.4,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Chat • Image • Video — all your ideas, one desktop workspace.',
            style: TextStyle(
              color: _mutedColor,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWideRows(
    ChatModelProvider chatModel,
    ImageModelProvider imageModel,
    ApiKeyProvider apiKeys,
  ) {
    return Column(
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              flex: 12,
              child: SizedBox(
                key: _sectionKeys[_WorkspaceSection.chat],
                height: 560,
                child: _buildChatPanel(chatModel),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 11,
              child: SizedBox(
                key: _sectionKeys[_WorkspaceSection.image],
                height: 560,
                child: _buildImagePanel(imageModel),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 11,
              child: SizedBox(
                key: _sectionKeys[_WorkspaceSection.video],
                height: 560,
                child: _buildVideoPanel(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              flex: 12,
              child: SizedBox(
                key: _sectionKeys[_WorkspaceSection.models],
                height: 430,
                child: _buildModelHubPanel(chatModel, imageModel, apiKeys),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 13,
              child: SizedBox(
                key: _sectionKeys[_WorkspaceSection.history],
                height: 430,
                child: _buildHistoryPanel(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStackedSections({
    required double contentWidth,
    required bool isCompact,
    required ChatModelProvider chatModel,
    required ImageModelProvider imageModel,
    required ApiKeyProvider apiKeys,
  }) {
    final double panelHeight = isCompact ? 620 : 560;
    final double bottomHeight = isCompact ? 520 : 460;

    return Column(
      children: <Widget>[
        SizedBox(
          key: _sectionKeys[_WorkspaceSection.chat],
          width: contentWidth,
          height: panelHeight,
          child: _buildChatPanel(chatModel),
        ),
        const SizedBox(height: 24),
        SizedBox(
          key: _sectionKeys[_WorkspaceSection.image],
          width: contentWidth,
          height: panelHeight,
          child: _buildImagePanel(imageModel),
        ),
        const SizedBox(height: 24),
        SizedBox(
          key: _sectionKeys[_WorkspaceSection.video],
          width: contentWidth,
          height: panelHeight,
          child: _buildVideoPanel(),
        ),
        const SizedBox(height: 24),
        SizedBox(
          key: _sectionKeys[_WorkspaceSection.models],
          width: contentWidth,
          height: bottomHeight,
          child: _buildModelHubPanel(chatModel, imageModel, apiKeys),
        ),
        const SizedBox(height: 24),
        SizedBox(
          key: _sectionKeys[_WorkspaceSection.history],
          width: contentWidth,
          height: bottomHeight,
          child: _buildHistoryPanel(),
        ),
      ],
    );
  }

  BoxDecoration _panelDecoration({Color? tint}) {
    return BoxDecoration(
      color: tint ?? _panelColor,
      borderRadius: BorderRadius.circular(26),
      border: Border.all(color: _lineColor),
      boxShadow: <BoxShadow>[
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 34,
          offset: const Offset(0, 12),
        ),
      ],
    );
  }

  Widget _buildPanelShell({
    required int step,
    required String title,
    required Color accent,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      decoration: _panelDecoration(),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  '$step',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  color: accent,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 16),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _lineColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 18, color: _inkColor),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: _inkColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatPanel(ChatModelProvider chatModel) {
    return _buildPanelShell(
      step: 1,
      title: 'Chat',
      accent: _teal,
      trailing: IconButton(
        tooltip: 'New chat',
        onPressed: _startNewChat,
        icon: const Icon(Icons.add_comment_outlined, color: _inkColor),
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 220,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                FilledButton.icon(
                  onPressed: _startNewChat,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('New Chat'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _teal,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 44),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _chatFilterController,
                  decoration: const InputDecoration(
                    hintText: 'Search conversations...',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Recent',
                  style: TextStyle(
                    color: _mutedColor.withValues(alpha: 0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.separated(
                    itemCount: _filteredChatSessions.length,
                    separatorBuilder:
                        (BuildContext context, int index) =>
                            const SizedBox(height: 8),
                    itemBuilder: (BuildContext context, int index) {
                      final ChatSession session = _filteredChatSessions[index];
                      final bool selected = session.id == _currentChatSessionId;
                      return InkWell(
                        onTap: () => _openChatSession(session),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: selected ? _chatSoft : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: selected ? _teal : _lineColor,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                session.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: _inkColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _formatPromptSnippet(
                                  session.lastMessage?.text ??
                                      'No messages yet',
                                  max: 46,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: _mutedColor,
                                  fontSize: 12,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _relativeTimestamp(session.updatedAt),
                                style: TextStyle(
                                  color: _mutedColor.withValues(alpha: 0.8),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _buildDropdown<String>(
                        value: chatModel.selectedProvider,
                        items: chatModel.allProviderNames,
                        onChanged: (String? value) async {
                          if (value == null) {
                            return;
                          }
                          await chatModel.setSelectedProvider(value);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDropdown<String>(
                        value: chatModel.selectedModel,
                        items: chatModel.availableModels,
                        onChanged: (String? value) async {
                          if (value == null) {
                            return;
                          }
                          await chatModel.setSelectedModel(value);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilterChip(
                      selected: _chatWebSearchEnabled,
                      label: const Text('Web Search'),
                      onSelected: (bool value) {
                        setState(() {
                          _chatWebSearchEnabled = value;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.86),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: _lineColor),
                    ),
                    child:
                        _activeChatMessages.isEmpty
                            ? _buildEmptyState(
                              icon: Icons.forum_outlined,
                              title: 'Start a focused conversation',
                              subtitle:
                                  'Use the chat panel for quick ideation, model comparison, or research-assisted answers.',
                            )
                            : ListView.separated(
                              controller: _chatMessagesScrollController,
                              padding: const EdgeInsets.all(18),
                              itemCount: _activeChatMessages.length,
                              separatorBuilder:
                                  (BuildContext context, int index) =>
                                      const SizedBox(height: 12),
                              itemBuilder: (BuildContext context, int index) {
                                return _buildChatBubble(
                                  _activeChatMessages[index],
                                );
                              },
                            ),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.86),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: _lineColor),
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: TextField(
                          controller: _chatInputController,
                          minLines: 1,
                          maxLines: 4,
                          onSubmitted: (_) => _sendChatMessage(),
                          decoration: const InputDecoration(
                            hintText: 'Message Chibot...',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _isChatSending ? null : _sendChatMessage,
                        style: FilledButton.styleFrom(
                          backgroundColor: _teal,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(48, 48),
                          padding: EdgeInsets.zero,
                        ),
                        child:
                            _isChatSending
                                ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                : const Icon(Icons.arrow_upward_rounded),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage message) {
    final bool isUser = message.sender == MessageSender.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUser ? _userBubble : _chatSoft,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isUser ? _coral.withValues(alpha: 0.24) : _lineColor,
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: <Widget>[
            if (!isUser)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: _teal,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Chibot',
                    style: TextStyle(
                      color: _inkColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            if (!isUser) const SizedBox(height: 10),
            if (message.isLoading && message.text.isEmpty)
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Thinking...',
                    style: TextStyle(
                      color: _mutedColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            else if (isUser)
              Text(
                message.text,
                style: const TextStyle(
                  color: _inkColor,
                  fontSize: 14,
                  height: 1.5,
                ),
              )
            else
              ChatMarkdown(text: message.text, textColor: _inkColor),
            const SizedBox(height: 10),
            Text(
              _relativeTimestamp(message.timestamp),
              style: TextStyle(
                color: _mutedColor.withValues(alpha: 0.82),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePanel(ImageModelProvider imageModel) {
    return _buildPanelShell(
      step: 2,
      title: 'Create Image',
      accent: _teal,
      trailing: IconButton(
        tooltip: 'New image project',
        onPressed: _startNewImageProject,
        icon: const Icon(Icons.refresh_rounded, color: _inkColor),
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 290,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Prompt',
                  style: TextStyle(
                    color: _inkColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: TextField(
                    controller: _imagePromptController,
                    maxLines: null,
                    expands: true,
                    decoration: const InputDecoration(
                      hintText:
                          'Describe a concept, composition, lighting, or visual mood...',
                      alignLabelWithHint: true,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _buildDropdown<String>(
                  value: imageModel.selectedImageProvider,
                  items: imageModel.allImageProviderNames,
                  onChanged: (String? value) async {
                    if (value == null) {
                      return;
                    }
                    await imageModel.setSelectedImageProvider(value);
                  },
                ),
                const SizedBox(height: 12),
                _buildDropdown<String>(
                  value: imageModel.selectedImageModel,
                  items: imageModel.availableImageModels,
                  onChanged: (String? value) async {
                    if (value == null) {
                      return;
                    }
                    await imageModel.setSelectedImageModel(value);
                  },
                ),
                const SizedBox(height: 14),
                _buildChipGroup(
                  title: 'Style',
                  options: _imageStyles,
                  selectedValue: _selectedImageStyle,
                  onSelected: (String value) {
                    setState(() {
                      _selectedImageStyle = value;
                    });
                  },
                ),
                const SizedBox(height: 14),
                _buildChipGroup(
                  title: 'Aspect Ratio',
                  options: _imageAspectRatios,
                  selectedValue: _selectedImageAspectRatio,
                  onSelected: (String value) {
                    setState(() {
                      _selectedImageAspectRatio = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _isImageGenerating ? null : _generateImage,
                  style: FilledButton.styleFrom(
                    backgroundColor: _teal,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child:
                      _isImageGenerating
                          ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Text('Generate'),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Text(
                      'Results',
                      style: TextStyle(
                        color: _inkColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_recentImageAssets.length} assets',
                      style: const TextStyle(
                        color: _mutedColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: _lineColor),
                    ),
                    child:
                        _selectedImagePreview == null
                            ? _buildEmptyState(
                              icon: Icons.image_search_outlined,
                              title: 'Your generated artwork will appear here',
                              subtitle:
                                  'Choose a model, define a style, and generate a visual asset for the workspace.',
                            )
                            : ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: _buildImageWidget(
                                _selectedImagePreview!,
                                fit: BoxFit.cover,
                              ),
                            ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 86,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _recentImageAssets.length.clamp(0, 8),
                    separatorBuilder:
                        (BuildContext context, int index) =>
                            const SizedBox(width: 10),
                    itemBuilder: (BuildContext context, int index) {
                      final ImageMessage message = _recentImageAssets[index];
                      final bool selected =
                          message.id == _selectedImagePreview?.id;
                      return GestureDetector(
                        onTap: () async {
                          final ImageSession? session =
                              _findImageSessionForMessage(
                                _imageSessions,
                                message.id,
                              );
                          setState(() {
                            _selectedImagePreview = message;
                            _currentImageSessionId = session?.id;
                          });
                        },
                        child: Container(
                          width: 86,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: selected ? _teal : _lineColor,
                              width: selected ? 2 : 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(17),
                            child: _buildImageWidget(
                              message,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPanel() {
    return _buildPanelShell(
      step: 3,
      title: 'Create Video',
      accent: _coral,
      trailing: IconButton(
        tooltip: 'New video project',
        onPressed: _startNewVideoProject,
        icon: const Icon(Icons.refresh_rounded, color: _inkColor),
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 290,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Prompt',
                  style: TextStyle(
                    color: _inkColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 118,
                  child: TextField(
                    controller: _videoPromptController,
                    maxLines: null,
                    expands: true,
                    decoration: const InputDecoration(
                      hintText:
                          'Describe scene, subject, pacing, and mood for your video render...',
                      alignLabelWithHint: true,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _buildChipGroup(
                  title: 'Duration',
                  options:
                      VideoDuration.values
                          .map((VideoDuration value) => value.label)
                          .toList(),
                  selectedValue: _selectedVideoDuration.label,
                  onSelected: (String value) {
                    setState(() {
                      _selectedVideoDuration = VideoDuration.values.firstWhere(
                        (VideoDuration item) => item.label == value,
                      );
                    });
                  },
                ),
                const SizedBox(height: 14),
                _buildChipGroup(
                  title: 'Aspect Ratio',
                  options: _videoAspectRatios,
                  selectedValue: _selectedVideoAspectRatio,
                  onSelected: (String value) {
                    setState(() {
                      _selectedVideoAspectRatio = value;
                    });
                  },
                ),
                const SizedBox(height: 14),
                _buildDropdown<String>(
                  value: _selectedVideoMotion,
                  items: _videoMotions,
                  onChanged: (String? value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _selectedVideoMotion = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                _buildDropdown<String>(
                  value: _selectedVideoCamera,
                  items: _videoCameras,
                  onChanged: (String? value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _selectedVideoCamera = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _buildDropdown<String>(
                        value: _selectedVideoResolution.label,
                        items:
                            VideoResolution.values
                                .map((VideoResolution value) => value.label)
                                .toList(),
                        onChanged: (String? value) {
                          if (value == null) {
                            return;
                          }
                          setState(() {
                            _selectedVideoResolution =
                                VideoResolution.fromString(value);
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDropdown<String>(
                        value: _selectedVideoQuality,
                        items: const <String>['draft', 'standard', 'high'],
                        onChanged: (String? value) {
                          if (value == null) {
                            return;
                          }
                          setState(() {
                            _selectedVideoQuality = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                FilledButton(
                  onPressed: _isVideoGenerating ? null : _generateVideo,
                  style: FilledButton.styleFrom(
                    backgroundColor: _coral,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child:
                      _isVideoGenerating
                          ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Text('Generate'),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Video Preview',
                  style: TextStyle(
                    color: _inkColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: _lineColor),
                    ),
                    child:
                        _selectedVideoPreview == null
                            ? _buildEmptyState(
                              icon: Icons.smart_display_outlined,
                              title: 'Rendered clips will appear here',
                              subtitle:
                                  'Set motion and camera direction, then generate a storyboard-ready clip.',
                            )
                            : Padding(
                              padding: const EdgeInsets.all(12),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child:
                                    _hasVideoSource(_selectedVideoPreview)
                                        ? VideoPlayerWidget(
                                          key: ValueKey<String>(
                                            '${_selectedVideoPreview!.id}:${_selectedVideoPreview!.localPath ?? _selectedVideoPreview!.videoUrl ?? ''}',
                                          ),
                                          videoMessage: _selectedVideoPreview!,
                                        )
                                        : _buildVideoPreviewPlaceholder(
                                          _selectedVideoPreview!,
                                        ),
                              ),
                            ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    const Text(
                      'Storyboard',
                      style: TextStyle(
                        color: _inkColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_recentVideoAssets.length} renders',
                      style: const TextStyle(
                        color: _mutedColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 86,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _recentVideoAssets.length.clamp(0, 8),
                    separatorBuilder:
                        (BuildContext context, int index) =>
                            const SizedBox(width: 10),
                    itemBuilder: (BuildContext context, int index) {
                      final VideoMessage video = _recentVideoAssets[index];
                      final bool selected =
                          video.id == _selectedVideoPreview?.id;
                      return GestureDetector(
                        onTap: () async {
                          final VideoSession? session = _videoSessions
                              .where(
                                (VideoSession item) => item.videos.any(
                                  (VideoMessage candidate) =>
                                      candidate.id == video.id,
                                ),
                              )
                              .cast<VideoSession?>()
                              .firstWhere(
                                (VideoSession? item) => item != null,
                                orElse: () => null,
                              );
                          if (session != null) {
                            await _videoSessionService.setCurrentSessionId(
                              session.id,
                            );
                          }
                          setState(() {
                            _currentVideoSession =
                                session ?? _currentVideoSession;
                            _selectedVideoPreview = video;
                          });
                        },
                        child: Container(
                          width: 110,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: <Color>[
                                selected
                                    ? _coral.withValues(alpha: 0.95)
                                    : _inkColor.withValues(alpha: 0.92),
                                selected
                                    ? const Color(0xFFFFA07D)
                                    : const Color(0xFF32445F),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: selected ? _coral : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const Icon(
                                Icons.play_circle_fill_rounded,
                                color: Colors.white,
                                size: 26,
                              ),
                              const Spacer(),
                              Text(
                                video.duration.label,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatPromptSnippet(video.prompt, max: 20),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                _buildVideoStatusBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoStatusBar() {
    final VideoMessage? preview = _selectedVideoPreview;
    final double progress =
        preview?.progress ?? (_isVideoGenerating ? 0.12 : 0.0);
    final String statusText = switch (preview?.status) {
      VideoStatus.completed => 'Completed',
      VideoStatus.failed => 'Failed',
      VideoStatus.processing => 'Rendering',
      VideoStatus.pending => 'Queued',
      VideoStatus.downloading => 'Downloading',
      null => _isVideoGenerating ? 'Rendering' : 'Ready',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _lineColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                'Render Status',
                style: TextStyle(
                  color: _mutedColor.withValues(alpha: 0.92),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Text(
                statusText,
                style: TextStyle(
                  color: statusText == 'Completed' ? _teal : _coral,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress == 0 ? null : progress.clamp(0, 1),
              minHeight: 7,
              backgroundColor: _lineColor,
              valueColor: const AlwaysStoppedAnimation<Color>(_coral),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelHubPanel(
    ChatModelProvider chatModel,
    ImageModelProvider imageModel,
    ApiKeyProvider apiKeys,
  ) {
    final int completedVideos =
        _recentVideoAssets
            .where(
              (VideoMessage message) => message.status == VideoStatus.completed,
            )
            .length;

    return _buildPanelShell(
      step: 4,
      title: 'Settings / Model Hub',
      accent: _amber,
      trailing: TextButton.icon(
        onPressed: _openSettings,
        icon: const Icon(Icons.settings_suggest_outlined),
        label: const Text('Open Settings'),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 7,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Wrap(
                  spacing: 10,
                  children: <Widget>[
                    _buildTabChip(
                      label: 'Chat',
                      selected: _modelHubTab == _ModelHubTab.chat,
                      onTap: () {
                        setState(() {
                          _modelHubTab = _ModelHubTab.chat;
                        });
                      },
                    ),
                    _buildTabChip(
                      label: 'Image',
                      selected: _modelHubTab == _ModelHubTab.image,
                      onTap: () {
                        setState(() {
                          _modelHubTab = _ModelHubTab.image;
                        });
                      },
                    ),
                    _buildTabChip(
                      label: 'Video',
                      selected: _modelHubTab == _ModelHubTab.video,
                      onTap: () {
                        setState(() {
                          _modelHubTab = _ModelHubTab.video;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: switch (_modelHubTab) {
                    _ModelHubTab.chat => _buildChatModelTab(chatModel, apiKeys),
                    _ModelHubTab.image => _buildImageModelTab(
                      imageModel,
                      apiKeys,
                    ),
                    _ModelHubTab.video => _buildVideoModelTab(apiKeys),
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Usage Overview',
                  style: TextStyle(
                    color: _inkColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _buildMetricCard(
                        label: 'Chats',
                        value: _chatSessions.length.toString(),
                        accent: _teal,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildMetricCard(
                        label: 'Images',
                        value: _recentImageAssets.length.toString(),
                        accent: _amber,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildMetricCard(
                        label: 'Videos',
                        value: completedVideos.toString(),
                        accent: _coral,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildConnectionStatus(
                  label: 'Chat Provider',
                  value: chatModel.selectedProvider,
                  connected:
                      (apiKeys.getApiKeyForProvider(
                                chatModel.selectedProvider,
                              ) ??
                              '')
                          .isNotEmpty,
                ),
                const SizedBox(height: 10),
                _buildConnectionStatus(
                  label: 'Image Provider',
                  value: imageModel.selectedImageProvider,
                  connected:
                      (apiKeys.getImageApiKeyForProvider(
                                imageModel.selectedImageProvider,
                              ) ??
                              '')
                          .isNotEmpty,
                ),
                const SizedBox(height: 10),
                _buildConnectionStatus(
                  label: 'Video Provider',
                  value: 'Google Veo3',
                  connected: (apiKeys.googleApiKey ?? '').isNotEmpty,
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _chatSoft,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _lineColor),
                  ),
                  child: const Text(
                    'Desktop quick controls write directly into your existing provider settings, so any model changes here are shared with the rest of the app.',
                    style: TextStyle(color: _mutedColor, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatModelTab(
    ChatModelProvider chatModel,
    ApiKeyProvider apiKeys,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Pick the best chat model for ideation, research, or long-form reasoning.',
          style: TextStyle(color: _mutedColor, height: 1.5),
        ),
        const SizedBox(height: 16),
        _buildDropdown<String>(
          value: chatModel.selectedProvider,
          items: chatModel.allProviderNames,
          onChanged: (String? value) async {
            if (value == null) {
              return;
            }
            await chatModel.setSelectedProvider(value);
          },
        ),
        const SizedBox(height: 14),
        Expanded(
          child: ListView.separated(
            itemCount: chatModel.availableModels.length,
            separatorBuilder:
                (BuildContext context, int index) => const SizedBox(height: 10),
            itemBuilder: (BuildContext context, int index) {
              final String model = chatModel.availableModels[index];
              final bool selected = model == chatModel.selectedModel;
              return GestureDetector(
                onTap: () => chatModel.setSelectedModel(model),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: selected ? _chatSoft : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: selected ? _teal : _lineColor),
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              model,
                              style: const TextStyle(
                                color: _inkColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              apiKeys.getApiKeyForProvider(
                                        chatModel.selectedProvider,
                                      ) !=
                                      null
                                  ? 'Ready for desktop chat workflows'
                                  : 'Missing API key',
                              style: const TextStyle(
                                color: _mutedColor,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (selected)
                        const Icon(Icons.check_circle, color: _teal),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildImageModelTab(
    ImageModelProvider imageModel,
    ApiKeyProvider apiKeys,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Switch image providers quickly and keep aspect ratio preferences in sync with the desktop canvas.',
          style: TextStyle(color: _mutedColor, height: 1.5),
        ),
        const SizedBox(height: 16),
        _buildDropdown<String>(
          value: imageModel.selectedImageProvider,
          items: imageModel.allImageProviderNames,
          onChanged: (String? value) async {
            if (value == null) {
              return;
            }
            await imageModel.setSelectedImageProvider(value);
          },
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children:
              imageModel.availableImageModels.map((String model) {
                final bool selected = model == imageModel.selectedImageModel;
                return ChoiceChip(
                  label: Text(model),
                  selected: selected,
                  onSelected: (_) => imageModel.setSelectedImageModel(model),
                );
              }).toList(),
        ),
        const SizedBox(height: 16),
        _buildConnectionStatus(
          label: 'API Status',
          value: imageModel.selectedImageProvider,
          connected:
              (apiKeys.getImageApiKeyForProvider(
                        imageModel.selectedImageProvider,
                      ) ??
                      '')
                  .isNotEmpty,
        ),
        const SizedBox(height: 14),
        _buildChipGroup(
          title: 'Desktop Aspect Ratio',
          options: _imageAspectRatios,
          selectedValue: _selectedImageAspectRatio,
          onSelected: (String value) {
            setState(() {
              _selectedImageAspectRatio = value;
            });
            imageModel.setBflAspectRatio(value);
          },
        ),
      ],
    );
  }

  Widget _buildVideoModelTab(ApiKeyProvider apiKeys) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Tune Veo render defaults for the desktop studio. These settings feed directly into new video projects.',
          style: TextStyle(color: _mutedColor, height: 1.5),
        ),
        const SizedBox(height: 16),
        _buildConnectionStatus(
          label: 'Provider',
          value: 'Google Veo3',
          connected: (apiKeys.googleApiKey ?? '').isNotEmpty,
        ),
        const SizedBox(height: 14),
        _buildChipGroup(
          title: 'Resolution',
          options:
              VideoResolution.values
                  .map((VideoResolution value) => value.label)
                  .toList(),
          selectedValue: _selectedVideoResolution.label,
          onSelected: (String value) {
            setState(() {
              _selectedVideoResolution = VideoResolution.fromString(value);
            });
          },
        ),
        const SizedBox(height: 14),
        _buildChipGroup(
          title: 'Duration',
          options:
              VideoDuration.values
                  .map((VideoDuration value) => value.label)
                  .toList(),
          selectedValue: _selectedVideoDuration.label,
          onSelected: (String value) {
            setState(() {
              _selectedVideoDuration = VideoDuration.values.firstWhere(
                (VideoDuration duration) => duration.label == value,
              );
            });
          },
        ),
        const SizedBox(height: 14),
        _buildChipGroup(
          title: 'Aspect Ratio',
          options: _videoAspectRatios,
          selectedValue: _selectedVideoAspectRatio,
          onSelected: (String value) {
            setState(() {
              _selectedVideoAspectRatio = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildConnectionStatus({
    required String label,
    required String value,
    required bool connected,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _lineColor),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: connected ? _teal : _coral,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: TextStyle(
                    color: _mutedColor.withValues(alpha: 0.92),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: _inkColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Text(
            connected ? 'Connected' : 'Needs Key',
            style: TextStyle(
              color: connected ? _teal : _coral,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _lineColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: TextStyle(
              color: _mutedColor.withValues(alpha: 0.88),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: accent,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryPanel() {
    final List<_HistoryAsset> assets = _historyAssets;

    return _buildPanelShell(
      step: 5,
      title: 'Asset Library / History',
      accent: _amber,
      trailing: FilledButton.tonalIcon(
        onPressed: _startNewChat,
        icon: const Icon(Icons.add),
        label: const Text('New Project'),
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _historySearchController,
                  decoration: const InputDecoration(
                    hintText: 'Search assets...',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _buildTabChip(
                label: 'All',
                selected: _historyFilter == _HistoryFilter.all,
                onTap: () {
                  setState(() {
                    _historyFilter = _HistoryFilter.all;
                  });
                },
              ),
              const SizedBox(width: 8),
              _buildTabChip(
                label: 'Chats',
                selected: _historyFilter == _HistoryFilter.chat,
                onTap: () {
                  setState(() {
                    _historyFilter = _HistoryFilter.chat;
                  });
                },
              ),
              const SizedBox(width: 8),
              _buildTabChip(
                label: 'Images',
                selected: _historyFilter == _HistoryFilter.image,
                onTap: () {
                  setState(() {
                    _historyFilter = _HistoryFilter.image;
                  });
                },
              ),
              const SizedBox(width: 8),
              _buildTabChip(
                label: 'Videos',
                selected: _historyFilter == _HistoryFilter.video,
                onTap: () {
                  setState(() {
                    _historyFilter = _HistoryFilter.video;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child:
                assets.isEmpty
                    ? _buildEmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: 'No assets yet',
                      subtitle:
                          'Generated images, video renders, and recent chat sessions will gather here for quick recall.',
                    )
                    : LayoutBuilder(
                      builder: (
                        BuildContext context,
                        BoxConstraints constraints,
                      ) {
                        int crossAxisCount = 2;
                        if (constraints.maxWidth >= 920) {
                          crossAxisCount = 4;
                        } else if (constraints.maxWidth >= 640) {
                          crossAxisCount = 3;
                        }

                        return GridView.builder(
                          itemCount: assets.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.92,
                              ),
                          itemBuilder: (BuildContext context, int index) {
                            return _buildHistoryCard(assets[index]);
                          },
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(_HistoryAsset asset) {
    return InkWell(
      onTap: () => _handleHistoryTap(asset),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _lineColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(child: _buildHistoryCardPreview(asset)),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    asset.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _inkColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    asset.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _mutedColor,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: switch (asset.type) {
                            _HistoryAssetType.chat => _teal.withValues(
                              alpha: 0.12,
                            ),
                            _HistoryAssetType.image => _amber.withValues(
                              alpha: 0.14,
                            ),
                            _HistoryAssetType.video => _coral.withValues(
                              alpha: 0.14,
                            ),
                          },
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          switch (asset.type) {
                            _HistoryAssetType.chat => 'Chat',
                            _HistoryAssetType.image => 'Image',
                            _HistoryAssetType.video => 'Video',
                          },
                          style: TextStyle(
                            color: switch (asset.type) {
                              _HistoryAssetType.chat => _teal,
                              _HistoryAssetType.image => _amber,
                              _HistoryAssetType.video => _coral,
                            },
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _relativeTimestamp(asset.timestamp),
                        style: const TextStyle(
                          color: _mutedColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCardPreview(_HistoryAsset asset) {
    switch (asset.type) {
      case _HistoryAssetType.chat:
        return Container(
          decoration: const BoxDecoration(
            color: _chatSoft,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Icon(Icons.forum_outlined, color: _teal),
              const Spacer(),
              Text(
                asset.chatSession?.messageCount.toString() ?? '0',
                style: const TextStyle(
                  color: _inkColor,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Text(
                'messages',
                style: TextStyle(
                  color: _mutedColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      case _HistoryAssetType.image:
        if (asset.imageMessage == null) {
          return const SizedBox.shrink();
        }
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: _buildImageWidget(asset.imageMessage!, fit: BoxFit.cover),
        );
      case _HistoryAssetType.video:
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: <Color>[Color(0xFF152338), Color(0xFF32445F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: const Center(
            child: Icon(
              Icons.play_circle_fill_rounded,
              color: Colors.white,
              size: 44,
            ),
          ),
        );
    }
  }

  Widget _buildVideoPreviewPlaceholder(VideoMessage video) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[Color(0xFF152338), Color(0xFF32445F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(
              Icons.play_circle_fill_rounded,
              color: Colors.white,
              size: 72,
            ),
            const SizedBox(height: 18),
            Text(
              video.status == VideoStatus.completed
                  ? 'Preview Ready'
                  : 'Rendering',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _formatPromptSnippet(video.prompt, max: 80),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 52, color: _mutedColor.withValues(alpha: 0.72)),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _inkColor,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _mutedColor, height: 1.55),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      decoration: const InputDecoration(isDense: true),
      items:
          items
              .map(
                (T item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(item.toString(), overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildTabChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? _inkColor : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? _inkColor : _lineColor),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : _inkColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildChipGroup({
    required String title,
    required List<String> options,
    required String selectedValue,
    required ValueChanged<String> onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: const TextStyle(color: _inkColor, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              options.map((String option) {
                final bool selected = option == selectedValue;
                return ChoiceChip(
                  label: Text(option),
                  selected: selected,
                  onSelected: (_) => onSelected(option),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildImageWidget(ImageMessage message, {BoxFit fit = BoxFit.cover}) {
    final String? source = message.bestImageSource;
    if (source == null || source.isEmpty) {
      return Container(color: _chatSoft);
    }

    if (message.imagePath != null && File(message.imagePath!).existsSync()) {
      return Image.file(
        File(message.imagePath!),
        fit: fit,
        errorBuilder:
            (BuildContext context, Object error, StackTrace? stackTrace) =>
                Container(color: _chatSoft),
      );
    }

    if (source.startsWith('data:image')) {
      final List<String> parts = source.split(',');
      if (parts.length == 2) {
        return Image.memory(
          base64Decode(parts.last),
          fit: fit,
          errorBuilder:
              (BuildContext context, Object error, StackTrace? stackTrace) =>
                  Container(color: _chatSoft),
        );
      }
    }

    if (_looksLikeRawBase64(source)) {
      return Image.memory(
        base64Decode(source),
        fit: fit,
        errorBuilder:
            (BuildContext context, Object error, StackTrace? stackTrace) =>
                Container(color: _chatSoft),
      );
    }

    if (source.startsWith('http')) {
      return Image.network(
        source,
        fit: fit,
        errorBuilder:
            (BuildContext context, Object error, StackTrace? stackTrace) =>
                Container(color: _chatSoft),
      );
    }

    if (File(source).existsSync()) {
      return Image.file(
        File(source),
        fit: fit,
        errorBuilder:
            (BuildContext context, Object error, StackTrace? stackTrace) =>
                Container(color: _chatSoft),
      );
    }

    return Container(color: _chatSoft);
  }

  bool _looksLikeRawBase64(String value) {
    if (value.length < 24) {
      return false;
    }
    return RegExp(r'^[A-Za-z0-9+/=\s]+$').hasMatch(value);
  }
}
