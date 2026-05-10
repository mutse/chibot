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
import 'package:chibot/screens/mobile/mobile_home_shell.dart';
import 'package:chibot/screens/mobile/mobile_ui.dart';
import 'package:chibot/l10n/app_localizations.dart';
import 'dart:io';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import 'models/model_registry.dart';
import 'providers/settings_models_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      size: Size(900, 700),
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
    final usesMobileShell =
        Platform.isAndroid ||
        Platform.isIOS ||
        Platform.isWindows ||
        Platform.isMacOS;

    return MultiProvider(
      providers: [
        // Legacy SettingsProvider for backward compatibility
        ChangeNotifierProvider(create: (_) => SettingsProvider()),

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
        title: "Chibot AI 助手",
        home: usesMobileShell ? const MobileHomeShell() : const ChatScreen(),
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
    final colorScheme = ColorScheme.fromSeed(
      seedColor: MobilePalette.primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: MobilePalette.primary,
      secondary: MobilePalette.secondary,
      surface: MobilePalette.surfaceStrong,
      surfaceContainerHighest: MobilePalette.surface,
      onSurface: MobilePalette.textPrimary,
      onSurfaceVariant: MobilePalette.textSecondary,
      outline: MobilePalette.border,
      outlineVariant: const Color(0xFFE9E2D8),
      surfaceTint: Colors.transparent,
      error: const Color(0xFFD95C45),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      scaffoldBackgroundColor: MobilePalette.background,

      // Typography
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 57,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.25,
        ),
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.25,
        ),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
        systemOverlayStyle: Platform.isMacOS ? SystemUiOverlayStyle.dark : null,
      ),

      // Cards and Surfaces
      cardTheme: CardThemeData(
        color: MobilePalette.surfaceStrong,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        surfaceTintColor: Colors.transparent,
      ),

      // Input Fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: MobilePalette.surface,
        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 16.0,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
      ),

      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: MobilePalette.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      // Icon buttons
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),

      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: MobilePalette.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),

      // List Tiles
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),

      // Drawer
      drawerTheme: DrawerThemeData(
        backgroundColor: MobilePalette.surfaceStrong,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
        ),
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: MobilePalette.textPrimary,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: 0,
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
