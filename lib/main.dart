import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'providers/settings_provider.dart';
import 'package:chibot/screens/chat_screen.dart';
import 'package:chibot/l10n/app_localizations.dart';
import 'dart:io';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

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
    _initTrayAndWindow(context);
    return ChangeNotifierProvider(
      create: (context) => SettingsProvider(),
      child: MaterialApp(
        title: "Chi AI Chatbot",
        home: const ChatScreen(),
        theme: ThemeData(
          brightness: Brightness.light,
          primaryColor: const Color(
            0xFF2D2F3E,
          ), // A dark color, can be used for accents or sidebar
          scaffoldBackgroundColor: Colors.white, // Main chat area background
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: IconThemeData(
              color: Colors.black54,
            ), // For icons like settings
            titleTextStyle: TextStyle(
              color: Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.grey[100], // Light background for text field
            hintStyle: TextStyle(color: Colors.grey[500]),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide:
                  BorderSide.none, // No border by default, or a very light one
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(
                color: Colors.grey[300] ?? Colors.grey,
              ), // Light border
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(
                color: Color(0xFF2D2F3E),
                width: 1.5,
              ), // Accent color on focus
            ),
          ),
          iconTheme: IconThemeData(
            color: Colors.grey[700], // Default icon color
          ),
          colorScheme: ColorScheme.fromSwatch(
            primarySwatch: Colors.blueGrey,
          ).copyWith(
            secondary: const Color(
              0xFF2D2F3E,
            ), // Accent color for buttons, etc.
            primary: const Color(0xFF2D2F3E),
            surface: Colors.white, // Cards, dialogs background
          ),
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          AppLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en', ''), // English, no country code
          Locale('zh', ''), // Chinese, no country code
        ],
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
