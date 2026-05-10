import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:chibot/models/chat_message.dart';
import 'package:chibot/models/video_message.dart';
import 'package:chibot/models/video_session.dart';
import 'package:chibot/providers/api_key_provider.dart';
import 'package:chibot/providers/video_model_provider.dart';
import 'package:chibot/screens/mobile/mobile_ui.dart';
import 'package:chibot/services/veo3_service.dart';
import 'package:chibot/services/video_generation_service.dart';
import 'package:chibot/services/video_session_service.dart';
import 'package:chibot/widgets/video_player_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MobileVideoStudioPage extends StatefulWidget {
  final VoidCallback? onOpenAppMenu;
  final VoidCallback? onOpenModels;
  final VoidCallback? onDataChanged;

  const MobileVideoStudioPage({
    super.key,
    this.onOpenAppMenu,
    this.onOpenModels,
    this.onDataChanged,
  });

  @override
  State<MobileVideoStudioPage> createState() => MobileVideoStudioPageState();
}

class MobileVideoStudioPageState extends State<MobileVideoStudioPage> {
  static const List<String> _motions = ['电影级平移', '缓慢推进', '环绕镜头', '静态构图'];

  static const List<String> _cameras = ['广角', '平视', '特写', '航拍'];

  static const List<String> _aspectRatios = ['16:9', '9:16', '1:1', '4:3'];

  final TextEditingController _promptController = TextEditingController();
  final VideoSessionService _sessionService = VideoSessionService();

  List<VideoSession> _sessions = [];
  VideoSession? _currentSession;
  Veo3Service? _veo3Service;
  bool _isGenerating = false;
  int _selectedPreviewIndex = 0;

  VideoResolution _selectedResolution = VideoResolution.res720p;
  VideoDuration _selectedDuration = VideoDuration.seconds10;
  String _selectedQuality = 'standard';
  String _selectedAspectRatio = '16:9';
  String _selectedMotion = _motions.first;
  String _selectedCamera = _cameras.first;

  @override
  void initState() {
    super.initState();
    _hydrateDefaults();
    _loadSessions();
    _initializeService();
  }

  void _hydrateDefaults() {
    final videoModel = context.read<VideoModelProvider>();
    _selectedAspectRatio = videoModel.videoAspectRatio;
    _selectedQuality = videoModel.videoQuality;
    _selectedResolution = VideoResolution.fromString(
      videoModel.videoResolution,
    );
    _selectedDuration =
        videoModel.videoDuration == '5s'
            ? VideoDuration.seconds5
            : videoModel.videoDuration == '30s'
            ? VideoDuration.seconds30
            : VideoDuration.seconds10;
  }

  Future<void> _initializeService() async {
    final apiKeys = context.read<ApiKeyProvider>();
    if (apiKeys.googleApiKey != null && apiKeys.googleApiKey!.isNotEmpty) {
      _veo3Service = Veo3Service(apiKey: apiKeys.googleApiKey!);
    }
  }

  Future<void> _loadSessions() async {
    final sessions = await _sessionService.getAllSessions();
    if (!mounted) return;
    setState(() {
      _sessions = sessions;
      if (_currentSession != null) {
        final refreshed = sessions.where(
          (item) => item.id == _currentSession!.id,
        );
        if (refreshed.isNotEmpty) {
          _currentSession = refreshed.first;
        }
      }
    });
  }

  void startNewSession() {
    setState(() {
      _currentSession = null;
      _selectedPreviewIndex = 0;
      _promptController.clear();
      _isGenerating = false;
    });
  }

  void loadSession(VideoSession session) {
    setState(() {
      _currentSession = session;
      _selectedPreviewIndex =
          session.videos.isEmpty ? 0 : session.videos.length - 1;
    });
  }

  Future<VideoSession> _ensureSession() async {
    if (_currentSession != null) {
      return _currentSession!;
    }

    final session = await _sessionService.createSession(
      title: '视频 ${_sessions.length + 1}',
      settings: VideoSettings(
        resolution: _selectedResolution,
        duration: _selectedDuration,
        quality: _selectedQuality,
        style: _selectedMotion,
        aspectRatio: _selectedAspectRatio,
      ),
    );
    _currentSession = session;
    await _loadSessions();
    widget.onDataChanged?.call();
    return session;
  }

  String _buildPrompt() {
    final prompt = _promptController.text.trim();
    return '$prompt。运镜：$_selectedMotion。镜头：$_selectedCamera。';
  }

  Future<String> _saveVideoBytes(String sessionId, String rawData) async {
    final normalized =
        rawData.startsWith('data:video/') ? rawData.split(',').last : rawData;
    final Uint8List bytes = base64Decode(normalized);

    final directory = await _sessionService.getVideoDirectory(sessionId);
    final file = File(
      '$directory/video_${DateTime.now().millisecondsSinceEpoch}.mp4',
    );
    await file.writeAsBytes(bytes);
    return file.path;
  }

  Future<void> _generateVideo() async {
    if (_promptController.text.trim().isEmpty || _isGenerating) {
      return;
    }

    final apiKeys = context.read<ApiKeyProvider>();
    final videoModel = context.read<VideoModelProvider>();

    if (apiKeys.googleApiKey == null || apiKeys.googleApiKey!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先配置 Google / Veo API Key')),
      );
      return;
    }

    _veo3Service ??= Veo3Service(apiKey: apiKeys.googleApiKey!);

    final session = await _ensureSession();
    final prompt = _promptController.text.trim();
    final videoMessage = VideoMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: prompt,
      prompt: prompt,
      sender: MessageSender.user,
      timestamp: DateTime.now(),
      resolution: _selectedResolution,
      duration: _selectedDuration,
      status: VideoStatus.pending,
      isLoading: true,
    );

    _currentSession = await _sessionService.addVideoToSession(
      session.id,
      videoMessage,
    );
    await _loadSessions();
    widget.onDataChanged?.call();

    setState(() {
      _isGenerating = true;
      _selectedPreviewIndex =
          _currentSession!.videos.isEmpty
              ? 0
              : _currentSession!.videos.length - 1;
    });

    await videoModel.setVideoAspectRatio(_selectedAspectRatio);
    await videoModel.setVideoQuality(_selectedQuality);
    await videoModel.setVideoResolution(_selectedResolution.label);
    if (_selectedDuration == VideoDuration.seconds5 ||
        _selectedDuration == VideoDuration.seconds10 ||
        _selectedDuration == VideoDuration.seconds30) {
      await videoModel.setVideoDuration(_selectedDuration.label);
    }

    try {
      final response = await _veo3Service!.generateVideo(
        VideoGenerationRequest(
          prompt: _buildPrompt(),
          resolution: _selectedResolution,
          duration: _selectedDuration,
          quality: _selectedQuality,
          aspectRatio: _selectedAspectRatio,
          style: _selectedMotion,
        ),
      );

      if (response.jobId != null) {
        _monitorVideoGeneration(response.jobId!, videoMessage.id);
      }
      _promptController.clear();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isGenerating = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('视频生成失败: $error')));
    }
  }

  void _monitorVideoGeneration(String jobId, String messageId) {
    _veo3Service!
        .getGenerationProgress(jobId)
        .listen(
          (progress) async {
            if (_currentSession == null) {
              return;
            }

            final videoIndex = _currentSession!.videos.indexWhere(
              (video) => video.id == messageId,
            );
            if (videoIndex == -1) {
              return;
            }

            var updatedMessage = _currentSession!.videos[videoIndex].copyWith(
              status: progress.status,
              progress: progress.progress,
              jobId: jobId,
              isLoading: progress.status != VideoStatus.completed,
            );

            _currentSession = await _sessionService.updateVideoInSession(
              _currentSession!.id,
              videoIndex,
              updatedMessage,
            );

            if (progress.status == VideoStatus.completed) {
              final finalResponse = await _veo3Service!.checkGenerationStatus(
                jobId,
              );
              if (finalResponse.videoUrl != null &&
                  finalResponse.videoUrl!.isNotEmpty) {
                String? localPath;
                String? remoteUrl;
                if (finalResponse.videoUrl!.startsWith('http')) {
                  remoteUrl = finalResponse.videoUrl;
                } else {
                  localPath = await _saveVideoBytes(
                    _currentSession!.id,
                    finalResponse.videoUrl!,
                  );
                }

                updatedMessage = updatedMessage.copyWith(
                  localPath: localPath,
                  videoUrl: remoteUrl,
                  thumbnail: finalResponse.thumbnail,
                  status: VideoStatus.completed,
                  isLoading: false,
                );
                _currentSession = await _sessionService.updateVideoInSession(
                  _currentSession!.id,
                  videoIndex,
                  updatedMessage,
                );
              }
            }

            await _loadSessions();
            widget.onDataChanged?.call();
            if (!mounted) return;
            setState(() {
              if (progress.status == VideoStatus.completed ||
                  progress.status == VideoStatus.failed) {
                _isGenerating = false;
              }
              _selectedPreviewIndex =
                  _currentSession!.videos.isEmpty
                      ? 0
                      : _currentSession!.videos.length - 1;
            });
          },
          onError: (error) async {
            if (!mounted) return;
            setState(() {
              _isGenerating = false;
            });
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('视频生成失败: $error')));
          },
        );
  }

  Future<void> _deleteSession(VideoSession session) async {
    await _sessionService.deleteSession(session.id);
    if (!mounted) return;
    if (_currentSession?.id == session.id) {
      startNewSession();
    }
    await _loadSessions();
    widget.onDataChanged?.call();
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
                          '视频会话',
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
                                  '还没有视频会话。',
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
                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: Container(
                                      width: 52,
                                      height: 52,
                                      decoration: BoxDecoration(
                                        color: MobilePalette.surface,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: MobilePalette.border,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.movie_creation_outlined,
                                        color: MobilePalette.secondary,
                                      ),
                                    ),
                                    title: Text(
                                      session.title,
                                      style: const TextStyle(
                                        color: MobilePalette.textPrimary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${formatMobileDate(session.updatedAt ?? session.createdAt)} • ${session.videoCount} 个视频',
                                      style: const TextStyle(
                                        color: MobilePalette.textSecondary,
                                      ),
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                      ),
                                      onPressed: () => _deleteSession(session),
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

  VideoMessage? get _selectedVideo {
    final videos = _currentSession?.videos ?? const <VideoMessage>[];
    if (videos.isEmpty) {
      return null;
    }
    return videos[_selectedPreviewIndex.clamp(0, videos.length - 1)];
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final videoModel = context.watch<VideoModelProvider>();
    final selectedVideo = _selectedVideo;
    final videos = _currentSession?.videos ?? const <VideoMessage>[];

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
            title: '创作视频',
            subtitle: videoModel.selectedVideoProvider,
            trailing: MobileIconCircleButton(
              icon: Icons.history_rounded,
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
                      const MobileSectionLabel(title: '提示词'),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _promptController,
                        minLines: 3,
                        maxLines: 6,
                        decoration: const InputDecoration(
                          hintText: '描述主体、运镜和整体氛围...',
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
                        title: '设置',
                        actionLabel: '模型',
                        onAction: widget.onOpenModels,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '时长',
                        style: TextStyle(
                          color: MobilePalette.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children:
                            VideoDuration.values
                                .where(
                                  (duration) =>
                                      duration == VideoDuration.seconds5 ||
                                      duration == VideoDuration.seconds10 ||
                                      duration == VideoDuration.seconds15 ||
                                      duration == VideoDuration.seconds30,
                                )
                                .map(
                                  (duration) => MobilePill(
                                    label: duration.label,
                                    selected: duration == _selectedDuration,
                                    onTap: () {
                                      setState(() {
                                        _selectedDuration = duration;
                                      });
                                    },
                                  ),
                                )
                                .toList(),
                      ),
                      const SizedBox(height: 18),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedMotion,
                        decoration: const InputDecoration(labelText: '运镜'),
                        items:
                            _motions
                                .map(
                                  (motion) => DropdownMenuItem(
                                    value: motion,
                                    child: Text(motion),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _selectedMotion = value;
                          });
                        },
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedCamera,
                        decoration: const InputDecoration(labelText: '镜头'),
                        items:
                            _cameras
                                .map(
                                  (camera) => DropdownMenuItem(
                                    value: camera,
                                    child: Text(camera),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _selectedCamera = value;
                          });
                        },
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        '画面比例',
                        style: TextStyle(
                          color: MobilePalette.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
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
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                MobileSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const MobileSectionLabel(title: '视频预览'),
                      const SizedBox(height: 12),
                      AspectRatio(
                        aspectRatio:
                            _selectedAspectRatio == '9:16'
                                ? 9 / 16
                                : _selectedAspectRatio == '1:1'
                                ? 1
                                : _selectedAspectRatio == '4:3'
                                ? 4 / 3
                                : 16 / 9,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child:
                              selectedVideo == null
                                  ? const Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.movie_filter_outlined,
                                          color: Colors.white54,
                                          size: 40,
                                        ),
                                        SizedBox(height: 12),
                                        Text(
                                          '最新生成的视频会显示在这里',
                                          style: TextStyle(
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                  : VideoPlayerWidget(
                                    videoMessage: selectedVideo,
                                  ),
                        ),
                      ),
                      if (videos.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text(
                          '分镜',
                          style: TextStyle(
                            color: MobilePalette.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 80,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: videos.length,
                            separatorBuilder:
                                (context, index) => const SizedBox(width: 10),
                            itemBuilder: (context, index) {
                              final video = videos[index];
                              final selected = index == _selectedPreviewIndex;
                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedPreviewIndex = index;
                                  });
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  width: 92,
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color:
                                          selected
                                              ? MobilePalette.secondary
                                              : MobilePalette.border,
                                      width: selected ? 2 : 1,
                                    ),
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: MobilePalette.surface,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Stack(
                                      children: [
                                        const Positioned.fill(
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  Color(0xFF10293B),
                                                  Color(0xFF193B54),
                                                  Color(0xFF2F5B76),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        const Positioned.fill(
                                          child: Center(
                                            child: Icon(
                                              Icons.play_circle_fill_rounded,
                                              color: Colors.white70,
                                              size: 28,
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          left: 8,
                                          bottom: 8,
                                          child: Text(
                                            video.duration.label,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
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
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                MobilePrimaryButton(
                  label: _isGenerating ? '视频生成中...' : '开始生成视频',
                  icon: Icons.auto_awesome_rounded,
                  color: MobilePalette.secondary,
                  onPressed: _isGenerating ? null : _generateVideo,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
