import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';

import '../models/video_message.dart';

class VideoPlayerWidget extends StatefulWidget {
  final VideoMessage videoMessage;
  final VoidCallback? onDownload;
  final VoidCallback? onShare;
  final VoidCallback? onDelete;

  const VideoPlayerWidget({
    Key? key,
    required this.videoMessage,
    this.onDownload,
    this.onShare,
    this.onDelete,
  }) : super(key: key);

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _isPlaying = false;
  bool _showControls = true;
  double _volume = 1.0;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      if (widget.videoMessage.localPath != null) {
        _controller = VideoPlayerController.file(
          File(widget.videoMessage.localPath!),
        );
      } else if (widget.videoMessage.videoUrl != null) {
        _controller = VideoPlayerController.networkUrl(
          Uri.parse(widget.videoMessage.videoUrl!),
        );
      } else {
        // No video source available
        return;
      }

      // Check if controller was successfully created
      if (_controller == null) {
        return;
      }

      await _controller!.initialize();
      _controller!.addListener(_videoListener);

      if (mounted) {
        setState(() {
          _initialized = true;
          _duration = _controller!.value.duration;
        });
      }
    } catch (e) {
      debugPrint('Error initializing video: $e');
    }
  }

  void _videoListener() {
    if (_controller == null) return;

    if (_controller!.value.position != _position) {
      setState(() {
        _position = _controller!.value.position;
      });
    }

    if (_controller!.value.isPlaying != _isPlaying) {
      setState(() {
        _isPlaying = _controller!.value.isPlaying;
      });
    }
  }

  @override
  void dispose() {
    if (_controller != null) {
      _controller!.removeListener(_videoListener);
      _controller!.dispose();
    }
    super.dispose();
  }

  void _togglePlayPause() {
    if (_controller == null) return;

    if (_controller!.value.isPlaying) {
      _controller!.pause();
    } else {
      _controller!.play();
    }
  }

  void _toggleMute() {
    if (_controller == null) return;

    setState(() {
      _volume = _volume > 0 ? 0 : 1.0;
      _controller!.setVolume(_volume);
    });
  }

  void _seekTo(Duration position) {
    if (_controller == null) return;

    _controller!.seekTo(position);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  Widget _buildLoadingState() {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.videoMessage.status == VideoStatus.processing)
            CircularProgressIndicator(
              value: widget.videoMessage.progress,
            )
          else
            const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            _getStatusMessage(),
            style: const TextStyle(fontSize: 14),
          ),
          if (widget.videoMessage.progress != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '${(widget.videoMessage.progress! * 100).toInt()}%',
                style: const TextStyle(fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  String _getStatusMessage() {
    switch (widget.videoMessage.status) {
      case VideoStatus.pending:
        return 'Preparing video generation...';
      case VideoStatus.processing:
        return 'Generating video...';
      case VideoStatus.downloading:
        return 'Downloading video...';
      case VideoStatus.failed:
        return 'Video generation failed';
      case VideoStatus.completed:
        return 'Loading video...';
    }
  }

  Widget _buildErrorState() {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red, width: 1),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Failed to generate video',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              widget.videoMessage.prompt,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (_controller == null) {
      return const Center(
        child: Text('No video source available'),
      );
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _showControls = !_showControls;
        });
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Video Player
          AspectRatio(
            aspectRatio: _controller!.value.aspectRatio,
            child: VideoPlayer(_controller!),
          ),

          // Controls Overlay
          if (_showControls)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.3),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withOpacity(0.5),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top Controls
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${widget.videoMessage.resolution.label} • ${widget.videoMessage.duration.label}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                          Row(
                            children: [
                              if (widget.onDownload != null)
                                IconButton(
                                  icon: const Icon(Icons.download, color: Colors.white),
                                  onPressed: widget.onDownload,
                                ),
                              if (widget.onShare != null)
                                IconButton(
                                  icon: const Icon(Icons.share, color: Colors.white),
                                  onPressed: widget.onShare,
                                ),
                              if (widget.onDelete != null)
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.white),
                                  onPressed: widget.onDelete,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Center Play/Pause Button
                    IconButton(
                      icon: Icon(
                        _isPlaying ? Icons.pause_circle : Icons.play_circle,
                        color: Colors.white,
                        size: 64,
                      ),
                      onPressed: _togglePlayPause,
                    ),

                    // Bottom Controls
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        children: [
                          // Progress Bar
                          Row(
                            children: [
                              Text(
                                _formatDuration(_position),
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                              Expanded(
                                child: Slider(
                                  value: _position.inMilliseconds.toDouble(),
                                  min: 0,
                                  max: _duration.inMilliseconds.toDouble(),
                                  onChanged: (value) {
                                    _seekTo(Duration(milliseconds: value.toInt()));
                                  },
                                  activeColor: Theme.of(context).primaryColor,
                                  inactiveColor: Colors.white.withOpacity(0.3),
                                ),
                              ),
                              Text(
                                _formatDuration(_duration),
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ],
                          ),

                          // Bottom Control Buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: Icon(
                                  _volume > 0 ? Icons.volume_up : Icons.volume_off,
                                  color: Colors.white,
                                ),
                                onPressed: _toggleMute,
                              ),
                              const SizedBox(width: 16),
                              IconButton(
                                icon: const Icon(Icons.replay_10, color: Colors.white),
                                onPressed: () {
                                  _seekTo(_position - const Duration(seconds: 10));
                                },
                              ),
                              IconButton(
                                icon: Icon(
                                  _isPlaying ? Icons.pause : Icons.play_arrow,
                                  color: Colors.white,
                                  size: 32,
                                ),
                                onPressed: _togglePlayPause,
                              ),
                              IconButton(
                                icon: const Icon(Icons.forward_10, color: Colors.white),
                                onPressed: () {
                                  _seekTo(_position + const Duration(seconds: 10));
                                },
                              ),
                              const SizedBox(width: 16),
                              IconButton(
                                icon: const Icon(Icons.fullscreen, color: Colors.white),
                                onPressed: () {
                                  // TODO: Implement fullscreen
                                },
                              ),
                            ],
                          ),
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

  @override
  Widget build(BuildContext context) {
    if (widget.videoMessage.status == VideoStatus.failed) {
      return _buildErrorState();
    }

    if (widget.videoMessage.status != VideoStatus.completed ||
        !_initialized) {
      return _buildLoadingState();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: _buildVideoPlayer(),
    );
  }
}