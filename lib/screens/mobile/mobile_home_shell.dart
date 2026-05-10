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
                'Quick access',
                style: TextStyle(
                  color: MobilePalette.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 28),
              _DrawerItem(
                label: 'Chat',
                icon: Icons.chat_bubble_outline_rounded,
                selected: _currentIndex == 0,
                onTap: () => _selectDrawerDestination(0),
              ),
              const SizedBox(height: 8),
              _DrawerItem(
                label: 'Images',
                icon: Icons.image_outlined,
                selected: _currentIndex == 1,
                onTap: () => _selectDrawerDestination(1),
              ),
              const SizedBox(height: 8),
              _DrawerItem(
                label: 'Video',
                icon: Icons.smart_display_outlined,
                selected: _currentIndex == 2,
                onTap: () => _selectDrawerDestination(2),
              ),
              const SizedBox(height: 8),
              _DrawerItem(
                label: 'History',
                icon: Icons.history_rounded,
                selected: _currentIndex == 4,
                onTap: () => _selectDrawerDestination(4),
              ),
              const Spacer(),
              const Divider(height: 1, color: MobilePalette.border),
              const SizedBox(height: 18),
              _DrawerItem(
                label: 'Settings',
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

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: MobilePalette.background,
      drawer: _usesDrawerMenu ? _buildDrawer() : null,
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar:
          _usesDrawerMenu
              ? null
              : SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: MobilePalette.surfaceStrong.withValues(
                        alpha: 0.96,
                      ),
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: MobilePalette.border),
                      boxShadow: const [
                        BoxShadow(
                          color: MobilePalette.shadow,
                          blurRadius: 26,
                          offset: Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        _NavItem(
                          label: 'Chat',
                          icon: Icons.chat_bubble_outline_rounded,
                          selected: _currentIndex == 0,
                          onTap: () => _switchTo(0),
                        ),
                        _NavItem(
                          label: 'Images',
                          icon: Icons.image_outlined,
                          selected: _currentIndex == 1,
                          onTap: () => _switchTo(1),
                        ),
                        _NavItem(
                          label: 'Video',
                          icon: Icons.smart_display_outlined,
                          selected: _currentIndex == 2,
                          onTap: () => _switchTo(2),
                        ),
                        _NavItem(
                          label: 'Settings',
                          icon: Icons.settings_outlined,
                          selected: _currentIndex == 3,
                          onTap: () => _switchTo(3),
                        ),
                        _NavItem(
                          label: 'History',
                          icon: Icons.history_rounded,
                          selected: _currentIndex == 4,
                          onTap: () => _switchTo(4),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }
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

class _NavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        selected ? MobilePalette.primary : MobilePalette.textSecondary;
    final background =
        selected ? MobilePalette.primarySoft : Colors.transparent;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 21),
              const SizedBox(height: 5),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
