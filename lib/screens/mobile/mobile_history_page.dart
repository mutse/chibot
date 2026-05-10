import 'dart:convert';
import 'dart:io';

import 'package:chibot/models/chat_session.dart';
import 'package:chibot/models/image_session.dart';
import 'package:chibot/models/video_message.dart';
import 'package:chibot/models/video_session.dart';
import 'package:chibot/screens/mobile/mobile_ui.dart';
import 'package:chibot/services/chat_session_service.dart';
import 'package:chibot/services/image_session_service.dart';
import 'package:chibot/services/video_session_service.dart';
import 'package:flutter/material.dart';

enum MobileHistoryFilter { all, images, videos, chats, projects }

class MobileHistoryPage extends StatefulWidget {
  final VoidCallback? onOpenAppMenu;
  final ValueChanged<ChatSession> onOpenChatSession;
  final ValueChanged<ImageSession> onOpenImageSession;
  final ValueChanged<VideoSession> onOpenVideoSession;

  const MobileHistoryPage({
    super.key,
    this.onOpenAppMenu,
    required this.onOpenChatSession,
    required this.onOpenImageSession,
    required this.onOpenVideoSession,
  });

  @override
  State<MobileHistoryPage> createState() => MobileHistoryPageState();
}

class MobileHistoryPageState extends State<MobileHistoryPage> {
  final ChatSessionService _chatSessionService = ChatSessionService();
  final ImageSessionService _imageSessionService = ImageSessionService();
  final VideoSessionService _videoSessionService = VideoSessionService();

  MobileHistoryFilter _filter = MobileHistoryFilter.all;
  List<ChatSession> _chatSessions = [];
  List<ImageSession> _imageSessions = [];
  List<VideoSession> _videoSessions = [];

  @override
  void initState() {
    super.initState();
    refreshData();
  }

  Future<void> refreshData() async {
    final chats = await _chatSessionService.loadSessions();
    final images = await _imageSessionService.loadSessions();
    final videos = await _videoSessionService.getAllSessions();

    chats.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    images.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    if (!mounted) return;
    setState(() {
      _chatSessions = chats;
      _imageSessions = images;
      _videoSessions = videos;
    });
  }

  List<_HistoryEntry> get _entries {
    final items = <_HistoryEntry>[];

    if (_filter == MobileHistoryFilter.all ||
        _filter == MobileHistoryFilter.images) {
      for (final session in _imageSessions) {
        final images = session.messages.where((message) => message.hasImage);
        if (images.isEmpty) {
          continue;
        }
        final latest = images.last;
        items.add(
          _HistoryEntry.image(
            session: session,
            timestamp: session.updatedAt,
            source: latest.bestImageSource,
            subtitle: session.modelDisplayName,
          ),
        );
      }
    }

    if (_filter == MobileHistoryFilter.all ||
        _filter == MobileHistoryFilter.videos) {
      for (final session in _videoSessions) {
        if (session.videos.isEmpty) {
          continue;
        }
        final latest = session.videos.last;
        items.add(
          _HistoryEntry.video(
            session: session,
            timestamp: session.updatedAt ?? session.createdAt,
            video: latest,
          ),
        );
      }
    }

    if (_filter == MobileHistoryFilter.all ||
        _filter == MobileHistoryFilter.chats) {
      for (final session in _chatSessions) {
        items.add(
          _HistoryEntry.chat(
            session: session,
            timestamp: session.updatedAt,
            preview:
                session.lastMessage?.text.isNotEmpty == true
                    ? session.lastMessage!.text
                    : session.firstMessage?.text ?? '打开聊天',
          ),
        );
      }
    }

    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return items;
  }

  Map<String, List<_HistoryEntry>> get _groupedEntries {
    final grouped = <String, List<_HistoryEntry>>{};
    for (final entry in _entries) {
      final key = formatMobileDate(entry.timestamp);
      grouped.putIfAbsent(key, () => []).add(entry);
    }
    return grouped;
  }

  Widget _buildFilterChip(MobileHistoryFilter filter, String label) {
    return MobilePill(
      label: label,
      selected: _filter == filter,
      onTap: () {
        setState(() {
          _filter = filter;
        });
      },
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    );
  }

  Widget _buildImageThumb(String? source) {
    if (source == null || source.isEmpty) {
      return const DecoratedBox(
        decoration: BoxDecoration(color: MobilePalette.surface),
        child: Center(
          child: Icon(Icons.image_outlined, color: MobilePalette.textSecondary),
        ),
      );
    }

    if (source.startsWith('data:image/')) {
      final bytes = base64Decode(source.split(',').last);
      return Image.memory(bytes, fit: BoxFit.cover);
    }

    if (source.startsWith('/') || source.startsWith('file://')) {
      final path =
          source.startsWith('file://')
              ? Uri.parse(source).toFilePath()
              : source;
      return Image.file(File(path), fit: BoxFit.cover);
    }

    return Image.network(source, fit: BoxFit.cover);
  }

  Widget _buildCard(_HistoryEntry entry, double cardWidth) {
    final borderRadius = BorderRadius.circular(20);
    final content = switch (entry.kind) {
      _HistoryKind.image => _buildImageCard(entry, borderRadius),
      _HistoryKind.video => _buildVideoCard(entry, borderRadius),
      _HistoryKind.chat => _buildChatCard(entry, borderRadius),
      _HistoryKind.project => _buildProjectCard(entry, borderRadius),
    };

    return InkWell(
      onTap: () {
        switch (entry.kind) {
          case _HistoryKind.image:
            widget.onOpenImageSession(entry.imageSession!);
            break;
          case _HistoryKind.video:
            widget.onOpenVideoSession(entry.videoSession!);
            break;
          case _HistoryKind.chat:
            widget.onOpenChatSession(entry.chatSession!);
            break;
          case _HistoryKind.project:
            break;
        }
      },
      borderRadius: borderRadius,
      child: SizedBox(width: cardWidth, child: content),
    );
  }

  Widget _buildImageCard(_HistoryEntry entry, BorderRadius borderRadius) {
    return Container(
      decoration: BoxDecoration(
        color: MobilePalette.surfaceStrong,
        borderRadius: borderRadius,
        border: Border.all(color: MobilePalette.border),
        boxShadow: const [
          BoxShadow(
            color: MobilePalette.shadow,
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: AspectRatio(
              aspectRatio: 0.92,
              child: _buildImageThumb(entry.imageSource),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Text(
                  '图片',
                  style: TextStyle(
                    color: MobilePalette.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Text(
                  formatMobileClock(entry.timestamp),
                  style: const TextStyle(
                    color: MobilePalette.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoCard(_HistoryEntry entry, BorderRadius borderRadius) {
    final video = entry.video!;
    return Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: Border.all(color: MobilePalette.border),
        boxShadow: const [
          BoxShadow(
            color: MobilePalette.shadow,
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF182A39), Color(0xFF1E4256), Color(0xFF2D607A)],
        ),
      ),
      child: AspectRatio(
        aspectRatio: 0.92,
        child: Stack(
          children: [
            const Positioned.fill(
              child: Center(
                child: Icon(
                  Icons.play_circle_fill_rounded,
                  color: Colors.white70,
                  size: 42,
                ),
              ),
            ),
            Positioned(
              left: 12,
              bottom: 12,
              child: Row(
                children: [
                  const Text(
                    '视频',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    video.duration.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 12,
              bottom: 12,
              child: Text(
                formatMobileClock(entry.timestamp),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatCard(_HistoryEntry entry, BorderRadius borderRadius) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MobilePalette.surfaceStrong,
        borderRadius: borderRadius,
        border: Border.all(color: MobilePalette.border),
        boxShadow: const [
          BoxShadow(
            color: MobilePalette.shadow,
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: AspectRatio(
        aspectRatio: 0.92,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: MobilePalette.primarySoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    '聊天',
                    style: TextStyle(
                      color: MobilePalette.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  formatMobileClock(entry.timestamp),
                  style: const TextStyle(
                    color: MobilePalette.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              entry.chatSession?.displayTitle ?? '对话',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: MobilePalette.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Text(
                entry.chatPreview ?? '打开聊天',
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: MobilePalette.textSecondary,
                  height: 1.45,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${entry.chatSession?.messageCount ?? 0} 条消息',
              style: const TextStyle(
                color: MobilePalette.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectCard(_HistoryEntry entry, BorderRadius borderRadius) {
    return Container(
      decoration: BoxDecoration(
        color: MobilePalette.surfaceStrong,
        borderRadius: borderRadius,
        border: Border.all(color: MobilePalette.border),
      ),
      child: const AspectRatio(
        aspectRatio: 0.92,
        child: Center(
          child: Text(
            '项目功能即将上线',
            style: TextStyle(color: MobilePalette.textSecondary),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupedEntries;
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 420 ? 3 : 2;
    final gap = 12.0;
    final cardWidth =
        (screenWidth - 32 - (crossAxisCount - 1) * gap) / crossAxisCount;

    return DecoratedBox(
      decoration: buildMobileBackgroundDecoration(),
      child: Column(
        children: [
          MobileTopBar(
            leading: MobileIconCircleButton(
              icon:
                  widget.onOpenAppMenu != null
                      ? Icons.menu_rounded
                      : Icons.folder_open_outlined,
              onTap: widget.onOpenAppMenu,
            ),
            title: '历史记录',
            subtitle: '查看你的聊天、图片和视频',
            trailing: MobileIconCircleButton(
              icon: Icons.refresh_rounded,
              onTap: refreshData,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: MobileSurface(
              padding: const EdgeInsets.all(14),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildFilterChip(MobileHistoryFilter.all, '全部'),
                  _buildFilterChip(MobileHistoryFilter.images, '图片'),
                  _buildFilterChip(MobileHistoryFilter.videos, '视频'),
                  _buildFilterChip(MobileHistoryFilter.chats, '聊天'),
                  _buildFilterChip(MobileHistoryFilter.projects, '项目'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child:
                grouped.isEmpty
                    ? const Center(
                      child: Text(
                        '这里还没有内容。',
                        style: TextStyle(color: MobilePalette.textSecondary),
                      ),
                    )
                    : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                      children:
                          grouped.entries.map((group) {
                            final entries = group.value;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 4,
                                      bottom: 10,
                                    ),
                                    child: Text(
                                      group.key,
                                      style: const TextStyle(
                                        color: MobilePalette.textPrimary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  Wrap(
                                    spacing: gap,
                                    runSpacing: gap,
                                    children:
                                        entries
                                            .map(
                                              (entry) =>
                                                  _buildCard(entry, cardWidth),
                                            )
                                            .toList(),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                    ),
          ),
        ],
      ),
    );
  }
}

enum _HistoryKind { image, video, chat, project }

class _HistoryEntry {
  final _HistoryKind kind;
  final DateTime timestamp;
  final ImageSession? imageSession;
  final VideoSession? videoSession;
  final ChatSession? chatSession;
  final String? imageSource;
  final VideoMessage? video;
  final String? chatPreview;
  final String? subtitle;

  const _HistoryEntry._({
    required this.kind,
    required this.timestamp,
    this.imageSession,
    this.videoSession,
    this.chatSession,
    this.imageSource,
    this.video,
    this.chatPreview,
    this.subtitle,
  });

  factory _HistoryEntry.image({
    required ImageSession session,
    required DateTime timestamp,
    required String? source,
    String? subtitle,
  }) {
    return _HistoryEntry._(
      kind: _HistoryKind.image,
      timestamp: timestamp,
      imageSession: session,
      imageSource: source,
      subtitle: subtitle,
    );
  }

  factory _HistoryEntry.video({
    required VideoSession session,
    required DateTime timestamp,
    required VideoMessage video,
  }) {
    return _HistoryEntry._(
      kind: _HistoryKind.video,
      timestamp: timestamp,
      videoSession: session,
      video: video,
    );
  }

  factory _HistoryEntry.chat({
    required ChatSession session,
    required DateTime timestamp,
    required String preview,
  }) {
    return _HistoryEntry._(
      kind: _HistoryKind.chat,
      timestamp: timestamp,
      chatSession: session,
      chatPreview: preview,
    );
  }
}
