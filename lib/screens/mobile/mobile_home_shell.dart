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

  int _currentIndex = 0;

  bool get _usesDrawerMenu => Platform.isAndroid || Platform.isIOS;
  bool get _usesDesktopSidebar =>
      Platform.isWindows || Platform.isMacOS || Platform.isLinux;

  List<_ShellDestination> get _destinations => const [
    _ShellDestination(
      index: 0,
      label: '聊天',
      icon: Icons.chat_bubble_outline_rounded,
    ),
    _ShellDestination(index: 1, label: '图片', icon: Icons.image_outlined),
    _ShellDestination(
      index: 2,
      label: '视频',
      icon: Icons.smart_display_outlined,
    ),
    _ShellDestination(index: 4, label: '历史', icon: Icons.history_rounded),
    _ShellDestination(index: 3, label: '设置', icon: Icons.settings_outlined),
  ];

  void _syncSelectedMode(int index) {
    final settings = context.read<UnifiedSettingsProvider>();
    if (index == 0) {
      settings.setSelectedModelType(available_model.ModelType.text);
    } else if (index == 1) {
      settings.setSelectedModelType(available_model.ModelType.image);
    } else if (index == 2) {
      settings.setSelectedModelType(available_model.ModelType.video);
    }
  }

  void _switchTo(int index) {
    if (!mounted) return;
    setState(() {
      _currentIndex = index;
    });
    _syncSelectedMode(index);
    if (index == 4) {
      _historyKey.currentState?.refreshData();
    }
  }

  void _openChatSession(ChatSession session) {
    _switchTo(0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chatKey.currentState?.loadSession(session);
    });
  }

  void _openImageSession(ImageSession session) {
    _switchTo(1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _imageKey.currentState?.loadSession(session);
    });
  }

  void _openVideoSession(VideoSession session) {
    _switchTo(2);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _videoKey.currentState?.loadSession(session);
    });
  }

  void _refreshHistory() {
    _historyKey.currentState?.refreshData();
  }

  void _openSettingsSection(SettingsScreenSection section) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => SettingsScreen(section: section)));
  }

  void _openAppMenu() {
    _scaffoldKey.currentState?.openDrawer();
  }

  void _selectDrawerDestination(int index) {
    Navigator.of(context).pop();
    _switchTo(index);
  }

  Widget _buildDrawer() {
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
              _DrawerItem(
                label: '聊天',
                icon: Icons.chat_bubble_outline_rounded,
                selected: _currentIndex == 0,
                onTap: () => _selectDrawerDestination(0),
              ),
              const SizedBox(height: 8),
              _DrawerItem(
                label: '图片',
                icon: Icons.image_outlined,
                selected: _currentIndex == 1,
                onTap: () => _selectDrawerDestination(1),
              ),
              const SizedBox(height: 8),
              _DrawerItem(
                label: '视频',
                icon: Icons.smart_display_outlined,
                selected: _currentIndex == 2,
                onTap: () => _selectDrawerDestination(2),
              ),
              const SizedBox(height: 8),
              _DrawerItem(
                label: '历史',
                icon: Icons.history_rounded,
                selected: _currentIndex == 4,
                onTap: () => _selectDrawerDestination(4),
              ),
              const Spacer(),
              const Divider(height: 1, color: MobilePalette.border),
              const SizedBox(height: 18),
              _DrawerItem(
                label: '设置',
                icon: Icons.settings_outlined,
                selected: _currentIndex == 3,
                onTap: () => _selectDrawerDestination(3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopSidebar() {
    final primaryDestinations =
        _destinations.where((destination) => destination.index != 3).toList();
    final settingsDestination = _destinations.firstWhere(
      (destination) => destination.index == 3,
    );

    return Container(
      width: 236,
      decoration: BoxDecoration(
        color: MobilePalette.surfaceStrong.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: MobilePalette.border),
        boxShadow: const [
          BoxShadow(
            color: MobilePalette.shadow,
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
              decoration: BoxDecoration(
                color: MobilePalette.surface.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: MobilePalette.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: MobilePalette.primarySoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: MobilePalette.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chibot',
                          style: TextStyle(
                            color: MobilePalette.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Desktop Workspace',
                          style: TextStyle(
                            color: MobilePalette.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const _DesktopSidebarLabel('Workspace'),
            const SizedBox(height: 10),
            ...primaryDestinations.map(
              (destination) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _DesktopSidebarItem(
                  label: destination.label,
                  icon: destination.icon,
                  selected: _currentIndex == destination.index,
                  onTap: () => _switchTo(destination.index),
                ),
              ),
            ),
            const Spacer(),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: MobilePalette.surface.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: MobilePalette.border),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Desktop navigation',
                    style: TextStyle(
                      color: MobilePalette.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '仅调整左侧菜单样式，页面功能与会话状态保持原样。',
                    style: TextStyle(
                      color: MobilePalette.textSecondary,
                      fontSize: 12,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const _DesktopSidebarLabel('System'),
            const SizedBox(height: 10),
            _DesktopSidebarItem(
              label: settingsDestination.label,
              icon: settingsDestination.icon,
              selected: _currentIndex == settingsDestination.index,
              onTap: () => _switchTo(settingsDestination.index),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopShell(List<Widget> pages) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: MobilePalette.background,
      body: DecoratedBox(
        decoration: buildMobileBackgroundDecoration(),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final sidebarWidth =
                  constraints.maxWidth >= 1260
                      ? 244.0
                      : constraints.maxWidth >= 980
                      ? 236.0
                      : 216.0;
              return Padding(
                padding: EdgeInsets.fromLTRB(
                  12,
                  Platform.isMacOS ? 10 : 12,
                  12,
                  12,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: sidebarWidth,
                      child: _buildDesktopSidebar(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: Container(
                          decoration: BoxDecoration(
                            color: MobilePalette.surfaceStrong.withValues(
                              alpha: 0.72,
                            ),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: MobilePalette.border),
                            boxShadow: const [
                              BoxShadow(
                                color: MobilePalette.shadow,
                                blurRadius: 30,
                                offset: Offset(0, 16),
                              ),
                            ],
                          ),
                          child: IndexedStack(
                            index: _currentIndex,
                            children: pages,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      MobileChatPage(
        key: _chatKey,
        onOpenAppMenu: _usesDrawerMenu ? _openAppMenu : null,
        onOpenImages: () => _switchTo(1),
        onOpenVideo: () => _switchTo(2),
        onOpenModels: () => _openSettingsSection(SettingsScreenSection.models),
        onOpenHistory: () => _switchTo(4),
        onDataChanged: _refreshHistory,
      ),
      MobileImageStudioPage(
        key: _imageKey,
        onOpenAppMenu: _usesDrawerMenu ? _openAppMenu : null,
        onOpenModels: () => _openSettingsSection(SettingsScreenSection.models),
        onDataChanged: _refreshHistory,
      ),
      MobileVideoStudioPage(
        key: _videoKey,
        onOpenAppMenu: _usesDrawerMenu ? _openAppMenu : null,
        onOpenModels: () => _openSettingsSection(SettingsScreenSection.models),
        onDataChanged: _refreshHistory,
      ),
      const SettingsScreen(),
      MobileHistoryPage(
        key: _historyKey,
        onOpenAppMenu: _usesDrawerMenu ? _openAppMenu : null,
        onOpenChatSession: _openChatSession,
        onOpenImageSession: _openImageSession,
        onOpenVideoSession: _openVideoSession,
      ),
    ];

    if (_usesDesktopSidebar) {
      return _buildDesktopShell(pages);
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: MobilePalette.background,
      drawer: _usesDrawerMenu ? _buildDrawer() : null,
      body: IndexedStack(index: _currentIndex, children: pages),
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
  final VoidCallback onTap;

  const _DesktopSidebarItem({
    required this.label,
    required this.icon,
    required this.selected,
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

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: labelColor,
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
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
        ),
      ),
    );
  }
}
