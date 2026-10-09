part of '../chat_screen.dart';

/// sidebar.dart - _ChatScreenState 的拆分方法（extension 形式，与主文件同一 library，可访问私有成员）
extension _SidebarExt on _ChatScreenState {
  Widget _buildSidebarSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildChatSessionsSection(BuildContext context, ThemeData theme) {
    if (_chatSessions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSidebarSectionHeader(context, '最近聊天'),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _chatSessions.length,
              itemBuilder: (context, index) {
                final session = _chatSessions[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: _buildSidebarItem(
                    context,
                    Icons.chat_outlined,
                    session.title,
                    isSelected: _currentSessionId == session.id,
                    onTap: () => _loadSession(session),
                    onExport: () async {
                      await MarkdownExportService.exportToMarkdown(
                        session,
                        context,
                      );
                    },
                    onDelete: () => _deleteChatSession(session, theme),
                    exportLabel: AppLocalizations.of(context)!.exportToMarkdown,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSessionsSection(BuildContext context, ThemeData theme) {
    if (_imageSessions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSidebarSectionHeader(context, '图片会话'),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _imageSessions.length,
              itemBuilder: (context, index) {
                final session = _imageSessions[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: _buildSidebarItem(
                    context,
                    Icons.image_outlined,
                    session.title,
                    isSelected: _currentImageSessionId == session.id,
                    onTap: () => _loadImageSession(session),
                    onExport: () async {
                      await ImageSaveService.exportImageHistory(
                        session,
                        context,
                      );
                    },
                    onDelete: () => _deleteImageSession(session, theme),
                    exportLabel: AppLocalizations.of(context)!.exportToImg,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: _sidebarWidth,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border:
            Platform.isMacOS
                ? Border(right: BorderSide(color: theme.dividerColor, width: 1))
                : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Header section
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App title
                Text(
                  'Chibot AI',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                // Search bar
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(
                      Platform.isMacOS ? 8 : 12,
                    ),
                  ),
                  child: TextField(
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.search,
                      hintStyle: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.6,
                        ),
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: theme.colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Navigation section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _buildSidebarItem(
                  context,
                  Icons.chat_bubble_outline,
                  '聊天',
                  isSelected: true,
                ),
                const SizedBox(height: 8),
                _buildSidebarItem(
                  context,
                  Icons.add_comment_outlined,
                  AppLocalizations.of(context)!.newChat,
                  onTap: _startNewChat,
                ),
                const SizedBox(height: 8),
                _buildSidebarItem(
                  context,
                  Icons.add_photo_alternate_outlined,
                  AppLocalizations.of(context)!.newImageSession,
                  onTap: _startNewImageSession,
                ),
                const SizedBox(height: 8),
                _buildSidebarItem(
                  context,
                  Icons.videocam_outlined,
                  '视频生成',
                  onTap: () {
                    _stopGeneration();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const VideoGenerationScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                _buildSidebarItem(
                  context,
                  Icons.download_outlined,
                  AppLocalizations.of(context)!.exportAllChats,
                  onTap: () async {
                    if (_chatSessions.isNotEmpty) {
                      await MarkdownExportService.exportMultipleToMarkdown(
                        _chatSessions,
                        context,
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            AppLocalizations.of(
                              context,
                            )!.noChatSessionsToExport,
                          ),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Chat sessions section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildChatSessionsSection(context, theme),
                _buildImageSessionsSection(context, theme),
              ],
            ),
          ),

          // Bottom section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: theme.dividerColor, width: 1),
              ),
            ),
            child: Column(
              children: [
                _buildSidebarItem(
                  context,
                  Icons.info_outline,
                  AppLocalizations.of(context)!.about,
                  onTap: () {
                    _stopGeneration();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AboutScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                // Removed settings item from sidebar
                _buildSidebarItem(
                  context,
                  Icons.system_update,
                  '检查更新',
                  onTap: () async {
                    final release = await UpdateService.fetchLatestRelease();
                    if (!context.mounted) return;
                    if (release == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('检查更新失败，请稍后重试')),
                      );
                      return;
                    }
                    final latestVersion = release['tag_name'] ?? '';
                    final downloadUrl = UpdateService.getDownloadUrl(release);
                    if (downloadUrl == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('未找到适用于当前平台的安装包')),
                      );
                      return;
                    }
                    final fileName = downloadUrl.split('/').last;
                    final releaseNotes = release['body'] ?? '';
                    showDialog(
                      context: context,
                      builder:
                          (_) => UpdateDialog(
                            latestVersion: latestVersion,
                            releaseNotes: releaseNotes,
                            downloadUrl: downloadUrl,
                            fileName: fileName,
                          ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(
    BuildContext context,
    IconData icon,
    String text, {
    bool isSelected = false,
    VoidCallback? onTap,
    VoidCallback? onDelete,
    VoidCallback? onExport,
    String? exportLabel, // 新增参数
  }) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap ?? () {},
        borderRadius: BorderRadius.circular(Platform.isMacOS ? 6 : 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? theme.colorScheme.primaryContainer.withValues(alpha: 0.8)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(Platform.isMacOS ? 6 : 12),
            border:
                isSelected
                    ? Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      width: 1,
                    )
                    : null,
          ),
          child: Row(
            children: <Widget>[
              Icon(
                icon,
                color:
                    isSelected
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Text(
                  text,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color:
                        isSelected
                            ? theme.colorScheme.onPrimaryContainer
                            : theme.colorScheme.onSurfaceVariant,
                    fontWeight:
                        isSelected ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ),
              if (onDelete != null)
                Builder(
                  builder:
                      (itemContext) => IconButton(
                        icon: Icon(
                          Icons.more_horiz,
                          size: 18,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        tooltip: '更多操作',
                        onPressed: () async {
                          // Show context menu for delete option
                          final renderObject = itemContext.findRenderObject();
                          if (renderObject is RenderBox) {
                            final RenderBox renderBox = renderObject;
                            final Offset position = renderBox.localToGlobal(
                              Offset.zero,
                            );
                            final exportAction = onExport;

                            await showMenu(
                              context: itemContext,
                              position: RelativeRect.fromLTRB(
                                position.dx,
                                position.dy + renderBox.size.height,
                                position.dx + renderBox.size.width,
                                position.dy + renderBox.size.height + 100,
                              ),
                              items: [
                                if (onExport != null)
                                  PopupMenuItem<String>(
                                    value: 'export',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.download_outlined,
                                          size: 18,
                                          color: theme.colorScheme.primary,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          exportLabel ??
                                              AppLocalizations.of(
                                                context,
                                              )!.exportToImg,
                                        ),
                                      ],
                                    ),
                                  ),
                                PopupMenuItem<String>(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.delete_outline,
                                        size: 18,
                                        color: theme.colorScheme.error,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        '删除',
                                        style: TextStyle(
                                          color: theme.colorScheme.error,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ).then((value) {
                              if (value == 'delete') {
                                onDelete();
                              } else if (value == 'export' &&
                                  exportAction != null) {
                                exportAction();
                              }
                            });
                          } else {
                            // 不是 RenderBox，无法显示菜单，可选：弹出提示或忽略
                          }
                        },
                      ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
