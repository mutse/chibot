import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'providers/settings_provider.dart';
import 'package:chibot/screens/chat_screen.dart';
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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(modelRegistry: modelRegistry),
        ),
        ChangeNotifierProvider(
          create: (_) => SettingsModelsProvider(modelRegistry),
        ),
        Provider.value(value: modelRegistry),
      ],
      child: MaterialApp(
        title: "Chi AI Chatbot",
        home: const ChatScreen(),
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
    const seedColor = Color(0xFF6750A4); // Material 3 purple
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      visualDensity: VisualDensity.adaptivePlatformDensity,

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
        backgroundColor:
            Platform.isMacOS
                ? colorScheme.surface.withValues(alpha: 0.8)
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
          borderRadius: BorderRadius.circular(Platform.isMacOS ? 8 : 12),
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
          borderRadius: BorderRadius.circular(Platform.isMacOS ? 8 : 24),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Platform.isMacOS ? 8 : 24),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Platform.isMacOS ? 8 : 24),
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

  Future<void> _initTrayAndWindow(BuildContext context) async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      windowManager.addListener(this);
      await trayManager.setIcon('assets/images/icon.png');
      final localizations = AppLocalizations.of(context);
      await trayManager.setContextMenu(
        Menu(
          items: [
            MenuItem(
              key: 'show',
              label: localizations?.trayShowHide ?? 'Show/Hide',
            ),
            MenuItem.separator(),
            MenuItem(key: 'exit', label: localizations?.trayExit ?? 'Exit'),
          ],
        ),
      );
      trayManager.addListener(this);
    }
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
