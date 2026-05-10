import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../models/video_message.dart';
import '../models/video_session.dart';
import '../models/chat_message.dart';
import '../providers/api_key_provider.dart';
import '../services/veo3_service.dart';
import '../services/video_session_service.dart';
import '../services/video_generation_service.dart';
import '../widgets/video_player_widget.dart';
import '../utils/snackbar_utils.dart';
import 'video_generation_settings_screen.dart';

class VideoGenerationScreen extends StatefulWidget {
  const VideoGenerationScreen({Key? key}) : super(key: key);

  @override
  State<VideoGenerationScreen> createState() => _VideoGenerationScreenState();
}

class _VideoGenerationScreenState extends State<VideoGenerationScreen> {
  final TextEditingController _promptController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final VideoSessionService _sessionService = VideoSessionService();

  VideoSession? _currentSession;
  List<VideoSession> _sessions = [];
  Veo3Service? _veo3Service;
  bool _isGenerating = false;
  bool _showSettings = false;
  bool _showSidebar = true;

  VideoResolution _selectedResolution = VideoResolution.res720p;
  VideoDuration _selectedDuration = VideoDuration.seconds10;
  String _selectedQuality = 'standard';
  String _selectedAspectRatio = '16:9';

  @override
  void initState() {
    super.initState();
    _loadSessions();
    _initializeService();
  }

  Future<void> _initializeService() async {
    final apiKeys = Provider.of<ApiKeyProvider>(context, listen: false);
    final veo3ApiKey =
        apiKeys.googleApiKey; // Video generation uses Google API key
    if (veo3ApiKey != null && veo3ApiKey.isNotEmpty) {
      _veo3Service = Veo3Service(apiKey: veo3ApiKey);
    }
  }

  Future<void> _loadSessions() async {
    final sessions = await _sessionService.getAllSessions();
    final currentSessionId = await _sessionService.getCurrentSessionId();

    setState(() {
      _sessions = sessions;
      if (currentSessionId != null && sessions.isNotEmpty) {
        try {
          _currentSession = sessions.firstWhere(
            (s) => s.id == currentSessionId,
          );
        } catch (_) {
          _currentSession = sessions.first;
        }
      } else if (sessions.isNotEmpty) {
        _currentSession = sessions.first;
      }
    });

    if (_currentSession == null && sessions.isEmpty) {
      await _createNewSession();
    }
  }

  Future<void> _createNewSession() async {
    final settings = VideoSettings(
      resolution: _selectedResolution,
      duration: _selectedDuration,
      quality: _selectedQuality,
      aspectRatio: _selectedAspectRatio,
    );

    final session = await _sessionService.createSession(
      title: '视频会话 ${_sessions.length + 1}',
      settings: settings,
    );

    setState(() {
      _sessions.insert(0, session);
      _currentSession = session;
    });
  }

  Future<void> _generateVideo() async {
    if (_promptController.text.trim().isEmpty) {
      SnackBarUtils.showError(context, '请输入视频提示词');
      return;
    }

    final apiKeys = Provider.of<ApiKeyProvider>(context, listen: false);
    final veo3ApiKey =
        apiKeys.googleApiKey; // Video generation uses Google API key
    if (veo3ApiKey == null || veo3ApiKey.isEmpty) {
      SnackBarUtils.showError(context, '请先在设置中配置 Veo3 API Key');
      return;
    }

    if (_veo3Service == null) {
      _veo3Service = Veo3Service(apiKey: veo3ApiKey);
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      // Create a placeholder video message
      final videoMessage = VideoMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: _promptController.text,
        sender: MessageSender.user,
        timestamp: DateTime.now(),
        resolution: _selectedResolution,
        duration: _selectedDuration,
        status: VideoStatus.pending,
        isLoading: true,
        prompt: _promptController.text,
      );

      // Add to current session
      if (_currentSession != null) {
        _currentSession = await _sessionService.addVideoToSession(
          _currentSession!.id,
          videoMessage,
        );
        setState(() {});
      }

      // Create generation request
      final request = VideoGenerationRequest(
        prompt: _promptController.text,
        resolution: _selectedResolution,
        duration: _selectedDuration,
        quality: _selectedQuality,
        aspectRatio: _selectedAspectRatio,
      );

      // Start video generation
      final response = await _veo3Service!.generateVideo(request);

      if (response.jobId != null) {
        // Start monitoring progress
        _monitorVideoGeneration(response.jobId!, videoMessage);
      }

      _promptController.clear();
    } catch (e) {
      SnackBarUtils.showError(context, '视频生成失败：$e');
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  void _monitorVideoGeneration(String jobId, VideoMessage initialMessage) {
    final progressStream = _veo3Service!.getGenerationProgress(jobId);

    progressStream.listen(
      (progress) async {
        if (_currentSession != null) {
          final videoIndex = _currentSession!.videos.length - 1;
          if (videoIndex >= 0) {
            final updatedMessage = _currentSession!.videos[videoIndex].copyWith(
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
              // Fetch the final video URL
              final finalResponse = await _veo3Service!.checkGenerationStatus(
                jobId,
              );
              if (finalResponse.videoUrl != null) {
                final completedMessage = updatedMessage.copyWith(
                  videoUrl: finalResponse.videoUrl,
                  thumbnail: finalResponse.thumbnail,
                  status: VideoStatus.completed,
                  isLoading: false,
                );

                _currentSession = await _sessionService.updateVideoInSession(
                  _currentSession!.id,
                  videoIndex,
                  completedMessage,
                );
              }
            }

            setState(() {});
          }
        }
      },
      onError: (error) {
        SnackBarUtils.showError(context, '视频生成失败：$error');
      },
    );
  }

  Future<void> _downloadVideo(VideoMessage video) async {
    if (video.videoUrl == null) return;

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'video_$timestamp.mp4';
      final localPath = await _veo3Service!.downloadVideo(
        video.videoUrl!,
        fileName,
      );

      if (localPath != null) {
        SnackBarUtils.showSuccess(context, '视频下载成功');

        // Update video message with local path
        final videoIndex = _currentSession!.videos.indexOf(video);
        if (videoIndex >= 0) {
          final updatedMessage = video.copyWith(localPath: localPath);
          _currentSession = await _sessionService.updateVideoInSession(
            _currentSession!.id,
            videoIndex,
            updatedMessage,
          );
          setState(() {});
        }
      }
    } catch (e) {
      SnackBarUtils.showError(context, '视频下载失败：$e');
    }
  }

  Widget _buildSidebar() {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          right: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        children: [
          // New Session Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: _createNewSession,
              icon: const Icon(Icons.add),
              label: const Text('新建视频会话'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 40),
              ),
            ),
          ),

          const Divider(height: 1),

          // Sessions List
          Expanded(
            child: ListView.builder(
              itemCount: _sessions.length,
              itemBuilder: (context, index) {
                final session = _sessions[index];
                final isSelected = session.id == _currentSession?.id;

                return ListTile(
                  selected: isSelected,
                  leading: Icon(
                    Icons.videocam,
                    color: isSelected ? Theme.of(context).primaryColor : null,
                  ),
                  title: Text(
                    session.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${session.videoCount} 个视频 • ${session.totalDuration} 秒',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: PopupMenuButton(
                    itemBuilder:
                        (context) => [
                          const PopupMenuItem(
                            value: 'rename',
                            child: Text('重命名'),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('删除'),
                          ),
                        ],
                    onSelected: (value) async {
                      if (value == 'delete') {
                        await _sessionService.deleteSession(session.id);
                        await _loadSessions();
                      }
                    },
                  ),
                  onTap: () {
                    setState(() {
                      _currentSession = session;
                    });
                    _sessionService.setCurrentSessionId(session.id);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '视频设置',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.settings),
                    tooltip: '打开详细设置',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  const VideoGenerationSettingsScreen(),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _showSettings = false;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          const Divider(),

          // Resolution
          const Text('分辨率', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children:
                VideoResolution.values.map((res) {
                  return ChoiceChip(
                    label: Text(res.label),
                    selected: _selectedResolution == res,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedResolution = res;
                        });
                      }
                    },
                  );
                }).toList(),
          ),
          const SizedBox(height: 16),

          // Duration
          const Text('时长', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children:
                VideoDuration.values.map((dur) {
                  return ChoiceChip(
                    label: Text(dur.label),
                    selected: _selectedDuration == dur,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedDuration = dur;
                        });
                      }
                    },
                  );
                }).toList(),
          ),
          const SizedBox(height: 16),

          // Quality
          const Text('质量', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children:
                ['standard', 'high'].map((quality) {
                  return ChoiceChip(
                    label: Text(quality == 'standard' ? '标准' : '高质量'),
                    selected: _selectedQuality == quality,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedQuality = quality;
                        });
                      }
                    },
                  );
                }).toList(),
          ),
          const SizedBox(height: 16),

          // Aspect Ratio
          const Text('画面比例', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children:
                ['16:9', '9:16', '1:1', '4:3'].map((ratio) {
                  return ChoiceChip(
                    label: Text(ratio),
                    selected: _selectedAspectRatio == ratio,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedAspectRatio = ratio;
                        });
                      }
                    },
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoList() {
    if (_currentSession == null || _currentSession!.videos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.video_library_outlined,
              size: 64,
              color: Theme.of(context).disabledColor,
            ),
            const SizedBox(height: 16),
            Text(
              '还没有生成视频',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).disabledColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '在下方输入提示词，开始生成第一个视频',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).disabledColor,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _currentSession!.videos.length,
      itemBuilder: (context, index) {
        final video = _currentSession!.videos[index];

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Prompt
                  Text(
                    video.prompt,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Video Player or Status
                  VideoPlayerWidget(
                    videoMessage: video,
                    onDownload:
                        video.status == VideoStatus.completed
                            ? () => _downloadVideo(video)
                            : null,
                    onShare: null, // Implement share functionality if needed
                    onDelete: null, // Implement delete functionality if needed
                  ),

                  // Timestamp
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '生成时间：${_formatTimestamp(video.timestamp)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).disabledColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('视频生成'),
        actions: [
          IconButton(
            icon: Icon(_showSidebar ? Icons.menu_open : Icons.menu),
            onPressed: () {
              setState(() {
                _showSidebar = !_showSidebar;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              setState(() {
                _showSettings = !_showSettings;
              });
            },
          ),
        ],
      ),
      body: Row(
        children: [
          // Sidebar
          if (_showSidebar) _buildSidebar(),

          // Main Content
          Expanded(
            child: Column(
              children: [
                // Settings Panel
                if (_showSettings)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildSettingsPanel(),
                  ),

                // Video List
                Expanded(child: _buildVideoList()),

                // Input Area
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    border: Border(
                      top: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _promptController,
                          maxLines: null,
                          decoration: InputDecoration(
                            hintText: '描述你想生成的视频...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.all(12),
                          ),
                          enabled: !_isGenerating,
                          onSubmitted: (_) => _generateVideo(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _isGenerating ? null : _generateVideo,
                        icon:
                            _isGenerating
                                ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: SpinKitRing(
                                    color: Theme.of(context).disabledColor,
                                    lineWidth: 2,
                                    size: 20,
                                  ),
                                )
                                : const Icon(Icons.video_call),
                        label: Text(_isGenerating ? '生成中...' : '开始生成'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
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
    );
  }

  @override
  void dispose() {
    _promptController.dispose();
    _scrollController.dispose();
    _veo3Service?.dispose();
    super.dispose();
  }
}
