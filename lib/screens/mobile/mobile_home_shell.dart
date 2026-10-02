import 'dart:io';

import 'package:chibot/models/available_model.dart' as available_model;
import 'package:chibot/models/chat_session.dart';
import 'package:chibot/models/image_session.dart';
import 'package:chibot/models/video_session.dart';
import 'package:chibot/providers/unified_settings_provider.dart';
import 'package:chibot/screens/mobile/mobile_chat_page.dart';
import 'package:chibot/screens/mobile/mobile_history_page.dart';
import 'package:chibot/screens/mobile/mobile_image_studio_page.dart';
import 'package:chibot/screens/mobile/mobile_ui.dart';
import 'package:chibot/screens/mobile/mobile_video_studio_page.dart';
import 'package:chibot/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MobileHomeShell extends StatefulWidget {
  const MobileHomeShell({super.key});

  @override
  State<MobileHomeShell> createState() => _MobileHomeShellState();
}

class _MobileHomeShellState extends State<MobileHomeShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<MobileChatPageState> _chatKey =
      GlobalKey<MobileChatPageState>();
  final GlobalKey<MobileImageStudioPageState> _imageKey =
      GlobalKey<MobileImageStudioPageState>();
  final GlobalKey<MobileVideoStudioPageState> _videoKey =
      GlobalKey<MobileVideoStudioPageState>();
  final GlobalKey<MobileHistoryPageState> _historyKey =
      GlobalKey<MobileHistoryPageState>();

  // IndexedStack slots. Settings sits before history for historical reasons;
  // always refer to pages through these names.
  static const int _chatPage = 0;
  static const int _imagePage = 1;
  static const int _videoPage = 2;
  static const int _settingsPage = 3;
  static const int _historyPage = 4;

  static const List<_ShellDestination> _workspaceDestinations = [
    _ShellDestination(
      index: _chatPage,
      label: '聊天',
      icon: Icons.chat_bubble_outline_rounded,
    ),
    _ShellDestination(
      index: _imagePage,
      label: '图片',
      icon: Icons.image_outlined,
    ),
    _ShellDestination(
      index: _videoPage,
      label: '视频',
      icon: Icons.smart_display_outlined,
    ),
    _ShellDestination(
      index: _historyPage,
      label: '历史',
      icon: Icons.history_rounded,
    ),
  ];
  static const _ShellDestination _settingsDestination = _ShellDestination(
    index: _settingsPage,
    label: '设置',
    icon: Icons.settings_outlined,
  );

  int _currentIndex = _chatPage;
  bool _sidebarCollapsed = false;

  /// Desktop platforms get a persistent sidebar when the window is wide
  /// enough; everything else navigates through the drawer.
  bool get _usesDesktopSidebar =>
      (Platform.isWindows || Platform.isMacOS || Platform.isLinux) &&
      MediaQuery.sizeOf(context).width >= 900;

  void _syncSelectedMode(int index) {
    final settings = context.read<UnifiedSettingsProvider>();
    if (index == _chatPage) {
      settings.setSelectedModelType(available_model.ModelType.text);
    } else if (index == _imagePage) {
      settings.setSelectedModelType(available_model.ModelType.image);
    } else if (index == _videoPage) {
      settings.setSelectedModelType(available_model.ModelType.video);
    }
  }

  void _switchTo(int index) {
    if (index != _chatPage) _chatKey.currentState?.stopGeneration();
    if (!mounted) return;
    setState(() {
      _currentIndex = index;
    });
    _syncSelectedMode(index);
    if (index == _historyPage) {
      _historyKey.currentState?.refreshData();
    }
  }

  void _openChatSession(ChatSession session) {
    _switchTo(_chatPage);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chatKey.currentState?.loadSession(session);
    });
  }

  void _openImageSession(ImageSession session) {
    _switchTo(_imagePage);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _imageKey.currentState?.loadSession(session);
    });
  }

  void _openVideoSession(VideoSession session) {
    _switchTo(_videoPage);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _videoKey.currentState?.loadSession(session);
    });
  }

  void _refreshHistory() {
    _historyKey.currentState?.refreshData();
  }

  void _openSettingsSection(SettingsScreenSection section) {
    _chatKey.currentState?.stopGeneration();
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => SettingsScreen(section: section)));
  }

  void _openAppMenu() {
    _scaffoldKey.currentState?.openDrawer();
  }

  void _selectDrawerDestination(int index) {
    Navigator.of(context).pop();
    // On compact layouts settings is a pushed page so system back returns to
    // the current workspace with its drafts intact.
    if (index == _settingsPage) {
      _openSettingsSection(SettingsScreenSection.overview);
      return;
    }
    _switchTo(index);
  }

  Widget _buildDrawer() {
    Widget item(_ShellDestination d) => _DrawerItem(
      label: d.label,
      icon: d.icon,
      selected: _currentIndex == d.index,
      onTap: () => _selectDrawerDestination(d.index),
    );

    return Drawer(
      backgroundColor: MobilePalette.surfaceStrong,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Chibot',
                style: TextStyle(
                  color: MobilePalette.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                '快捷入口',
                style: TextStyle(
                  color: MobilePalette.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 28),
              for (final d in _workspaceDestinations) ...[
                item(d),
                const SizedBox(height: 8),
              ],
              const Spacer(),
              const Divider(height: 1, color: MobilePalette.border),
              const SizedBox(height: 18),
              item(_settingsDestination),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopSidebar() {
    final width = _sidebarCollapsed ? 80.0 : 224.0;
    final toggleButton = IconButton(
      tooltip: _sidebarCollapsed ? '展开侧边栏' : '收起侧边栏',
      onPressed:
          () => setState(() {
            _sidebarCollapsed = !_sidebarCollapsed;
          }),
      icon: Icon(
        _sidebarCollapsed
            ? Icons.chevron_right_rounded
            : Icons.chevron_left_rounded,
      ),
    );

    Widget sidebarItem(_ShellDestination d) => _DesktopSidebarItem(
      label: d.label,
      icon: d.icon,
      selected: _currentIndex == d.index,
      collapsed: _sidebarCollapsed,
      onTap: () => _switchTo(d.index),
    );

    void startNewChat() {
      _switchTo(_chatPage);
      _chatKey.currentState?.startNewChat();
    }

    return AnimatedContainer(
      width: width,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOutCubic,
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(),
      // Lay out at the target width so labels cannot overflow during animation.
      child: OverflowBox(
        alignment: Alignment.topLeft,
        minWidth: width,
        maxWidth: width,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            _sidebarCollapsed ? 12 : 16,
            24,
            _sidebarCollapsed ? 12 : 16,
            16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 48,
                child:
                    _sidebarCollapsed
                        ? Center(child: toggleButton)
                        : Row(
                          children: [
                            const Icon(
                              Icons.auto_awesome_rounded,
                              color: MobilePalette.primary,
                              size: 26,
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Chibot',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.8,
                                ),
                              ),
                            ),
                            toggleButton,
                          ],
                        ),
              ),
              const SizedBox(height: 32),
              if (_sidebarCollapsed)
                SizedBox(
                  height: 48,
                  child: IconButton.filled(
                    tooltip: '新建对话',
                    onPressed: startNewChat,
                    icon: const Icon(Icons.add_rounded, size: 20),
                  ),
                )
              else
                FilledButton.icon(
                  onPressed: startNewChat,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text('新建对话'),
                ),
              const SizedBox(height: 28),
              SizedBox(
                height: 16,
                child:
                    _sidebarCollapsed
                        ? null
                        : const _DesktopSidebarLabel('工作空间'),
              ),
              const SizedBox(height: 12),
              for (final d in _workspaceDestinations)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: sidebarItem(d),
                ),
              const Spacer(),
              const Divider(),
              const SizedBox(height: 12),
              sidebarItem(_settingsDestination),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopShell(List<Widget> pages) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: MobilePalette.background,
      body: SafeArea(
        child: Row(
          children: [
            _buildDesktopSidebar(),
            const VerticalDivider(width: 1),
            Expanded(
              child: IndexedStack(index: _currentIndex, children: pages),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usesDesktopSidebar = _usesDesktopSidebar;
    final VoidCallback? openAppMenu = usesDesktopSidebar ? null : _openAppMenu;
    // Order must match the _xxxPage index constants.
    final pages = [
      MobileChatPage(
        key: _chatKey,
        onOpenAppMenu: openAppMenu,
        onOpenImages: () => _switchTo(_imagePage),
        onOpenVideo: () => _switchTo(_videoPage),
        onOpenModels: () => _openSettingsSection(SettingsScreenSection.models),
        onOpenHistory: () => _switchTo(_historyPage),
        onDataChanged: _refreshHistory,
      ),
      MobileImageStudioPage(
        key: _imageKey,
        onOpenAppMenu: openAppMenu,
        onOpenModels: () => _openSettingsSection(SettingsScreenSection.models),
        onDataChanged: _refreshHistory,
      ),
      MobileVideoStudioPage(
        key: _videoKey,
        onOpenAppMenu: openAppMenu,
        onOpenModels: () => _openSettingsSection(SettingsScreenSection.models),
        onDataChanged: _refreshHistory,
      ),
      SettingsScreen(onOpenAppMenu: openAppMenu),
      MobileHistoryPage(
        key: _historyKey,
        onOpenAppMenu: openAppMenu,
        onOpenChatSession: _openChatSession,
        onOpenImageSession: _openImageSession,
        onOpenVideoSession: _openVideoSession,
      ),
    ];

    if (usesDesktopSidebar) {
      return _buildDesktopShell(pages);
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: MobilePalette.background,
      drawer: _buildDrawer(),
      body: SafeArea(
        child: IndexedStack(index: _currentIndex, children: pages),
      ),
    );
  }
}

class _ShellDestination {
  final int index;
  final String label;
  final IconData icon;

  const _ShellDestination({
    required this.index,
    required this.label,
    required this.icon,
  });
}

class _DrawerItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final foreground =
        selected ? MobilePalette.primary : MobilePalette.textPrimary;
    final background =
        selected ? MobilePalette.primarySoft : Colors.transparent;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(18),
          border:
              selected
                  ? Border.all(
                    color: MobilePalette.primary.withValues(alpha: 0.2),
                  )
                  : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: foreground, size: 22),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: foreground,
                fontSize: 15,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DesktopSidebarLabel extends StatelessWidget {
  final String label;

  const _DesktopSidebarLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: MobilePalette.textSecondary,
          fontSize: 11,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _DesktopSidebarItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final bool collapsed;
  final VoidCallback onTap;

  const _DesktopSidebarItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.collapsed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor =
        selected ? MobilePalette.primary : MobilePalette.textSecondary;
    final labelColor =
        selected ? MobilePalette.textPrimary : MobilePalette.textSecondary;
    final background =
        selected
            ? MobilePalette.primarySoft.withValues(alpha: 0.96)
            : Colors.transparent;

    return Semantics(
      button: true,
      selected: selected,
      label: collapsed ? label : null,
      child: Tooltip(
        message: collapsed ? label : '',
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            padding: EdgeInsets.symmetric(
              horizontal: collapsed ? 0 : 12,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(18),
              border:
                  selected
                      ? Border.all(
                        color: MobilePalette.primary.withValues(alpha: 0.18),
                      )
                      : null,
            ),
            child: Row(
              mainAxisAlignment:
                  collapsed
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color:
                        selected
                            ? Colors.white.withValues(alpha: 0.86)
                            : MobilePalette.surface.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 19),
                ),
                if (!collapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: labelColor,
                        fontSize: 14,
                        fontWeight:
                            selected ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                  ),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 160),
                    opacity: selected ? 1 : 0,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: MobilePalette.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
