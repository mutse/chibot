import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'providers/settings_provider.dart';
import 'providers/api_key_provider.dart';
import 'providers/chat_model_provider.dart';
import 'providers/image_model_provider.dart';
import 'providers/video_model_provider.dart';
import 'providers/search_provider.dart';
import 'providers/unified_settings_provider.dart';
import 'package:chibot/screens/chat_screen.dart';
import 'package:chibot/screens/desktop/desktop_workspace_screen.dart';
import 'package:chibot/screens/mobile/mobile_home_shell.dart';
import 'package:chibot/l10n/app_localizations.dart';
import 'dart:io';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import 'models/model_registry.dart';
import 'providers/settings_models_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    final bool desktopWorkspaceTarget = Platform.isWindows || Platform.isMacOS;
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = WindowOptions(
      size:
          desktopWorkspaceTarget ? const Size(1520, 980) : const Size(900, 700),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget with TrayListener, WindowListener {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final modelRegistry = ModelRegistry();
    return MultiProvider(
      providers: [
        // Legacy SettingsProvider for backward compatibility
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(modelRegistry: modelRegistry),
        ),

        // New specialized providers (Phase 1 refactoring)
        ChangeNotifierProvider(create: (_) => ApiKeyProvider()),
        ChangeNotifierProvider(
          create: (_) => ChatModelProvider(modelRegistry: modelRegistry),
        ),
        ChangeNotifierProvider(
          create: (_) => ImageModelProvider(modelRegistry: modelRegistry),
        ),
        ChangeNotifierProvider(create: (_) => VideoModelProvider()),
        ChangeNotifierProvider(
          create:
              (context) => SearchProvider(
                apiKeyProvider: context.read<ApiKeyProvider>(),
              ),
        ),

        // Unified Settings Provider (backward compatibility bridge)
        ChangeNotifierProvider(
          create:
              (context) => UnifiedSettingsProvider(
                apiKeyProvider: context.read<ApiKeyProvider>(),
                chatModelProvider: context.read<ChatModelProvider>(),
                imageModelProvider: context.read<ImageModelProvider>(),
                videoModelProvider: context.read<VideoModelProvider>(),
                searchProvider: context.read<SearchProvider>(),
              ),
        ),

        // Additional legacy providers
        ChangeNotifierProvider(
          create: (_) => SettingsModelsProvider(modelRegistry),
        ),
        Provider.value(value: modelRegistry),
      ],
      child: MaterialApp(
        title: "Chi AI Chatbot",
        home:
            Platform.isAndroid || Platform.isIOS
                ? const MobileHomeShell()
                : Platform.isWindows || Platform.isMacOS
                ? const DesktopWorkspaceScreen()
                : const ChatScreen(),
        theme: _buildModernTheme(),
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          AppLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('de', ''),
          Locale('en', ''), // English, no country code
          Locale('fr', ''),
          Locale('ja', ''),
          Locale('zh', ''), // Chinese, no country code
        ],
      ),
    );
  }

  ThemeData _buildModernTheme() {
    final bool desktopWorkspaceTarget = Platform.isWindows || Platform.isMacOS;
    final Color seedColor =
        desktopWorkspaceTarget
            ? const Color(0xFF0B7B7B)
            : const Color(0xFF6750A4);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      scaffoldBackgroundColor:
          desktopWorkspaceTarget
              ? const Color(0xFFF7F1E8)
              : colorScheme.surface,

      // Typography
      textTheme: TextTheme(
        displayLarge: const TextStyle(
          fontSize: 57,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.25,
        ),
        displaySmall:
            desktopWorkspaceTarget
                ? const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.2,
                  color: Color(0xFF142033),
                )
                : null,
        headlineLarge: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
        ),
        titleLarge: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
        ),
        bodyLarge: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
        ),
        bodyMedium: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.25,
        ),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor:
            Platform.isMacOS
                ? colorScheme.surface.withValues(alpha: 0.8)
                : desktopWorkspaceTarget
                ? const Color(0xFFF7F1E8)
                : colorScheme.surface,
        elevation: Platform.isMacOS ? 0 : 1,
        surfaceTintColor: colorScheme.surfaceTint,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 22,
          fontWeight: FontWeight.w500,
        ),
        systemOverlayStyle: Platform.isMacOS ? SystemUiOverlayStyle.dark : null,
      ),

      // Cards and Surfaces
      cardTheme: CardThemeData(
        elevation: Platform.isMacOS ? 1 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            desktopWorkspaceTarget ? 24 : (Platform.isMacOS ? 8 : 12),
          ),
        ),
        surfaceTintColor: colorScheme.surfaceTint,
      ),

      // Input Fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 16.0,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            desktopWorkspaceTarget ? 18 : (Platform.isMacOS ? 8 : 24),
          ),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            desktopWorkspaceTarget ? 18 : (Platform.isMacOS ? 8 : 24),
          ),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            desktopWorkspaceTarget ? 18 : (Platform.isMacOS ? 8 : 24),
          ),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),

      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: Platform.isMacOS ? 1 : 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Platform.isMacOS ? 6 : 20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Platform.isMacOS ? 6 : 20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      // Icon buttons
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Platform.isMacOS ? 6 : 12),
          ),
        ),
      ),

      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: Platform.isMacOS ? 2 : 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Platform.isMacOS ? 8 : 16),
        ),
      ),

      // List Tiles
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Platform.isMacOS ? 6 : 12),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),

      // Drawer
      drawerTheme: DrawerThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        elevation: Platform.isMacOS ? 1 : 16,
        shape:
            Platform.isMacOS
                ? null
                : const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Platform.isMacOS ? 8 : 12),
        ),
        elevation: Platform.isMacOS ? 2 : 6,
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
    );
  }

  @override
  void onTrayIconMouseDown() async {
    if (await windowManager.isVisible()) {
      windowManager.hide();
    } else {
      windowManager.show();
      windowManager.focus();
    }
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) async {
    if (menuItem.key == 'show') {
      if (await windowManager.isVisible()) {
        windowManager.hide();
      } else {
        windowManager.show();
        windowManager.focus();
      }
    } else if (menuItem.key == 'exit') {
      await trayManager.destroy();
      windowManager.destroy();
    }
  }

  @override
  Future<bool> onWindowClose() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      windowManager.hide();
      return false;
    }
    return true;
  }
}
