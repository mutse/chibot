import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'providers/settings_provider.dart';
import 'screens/chat_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => SettingsProvider(),
      child: MaterialApp(
        title: "Chi AI Chatbot",
        theme: ThemeData(
          brightness: Brightness.light,
          primaryColor: CupertinoColors.activeBlue,
          scaffoldBackgroundColor: CupertinoColors.systemGrey6, // Or Color(0xFFF2F2F7)
          appBarTheme: const AppBarTheme(
            backgroundColor: CupertinoColors.systemGrey6, // Or a slightly lighter/whiter color
            elevation: 0,
            iconTheme: IconThemeData(color: CupertinoColors.activeBlue),
            titleTextStyle: TextStyle(
              color: CupertinoColors.black,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: CupertinoColors.white, // Or CupertinoColors.systemGrey5
            hintStyle: const TextStyle(color: CupertinoColors.placeholderText),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: CupertinoColors.systemGrey3, width: 0.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: CupertinoColors.activeBlue, width: 1.0),
            ),
          ),
          iconTheme: const IconThemeData(
            color: CupertinoColors.activeBlue,
          ),
          colorScheme: ColorScheme.light(
            primary: CupertinoColors.activeBlue,
            secondary: CupertinoColors.activeOrange,
            background: CupertinoColors.systemGrey6,
            surface: CupertinoColors.white, // Or CupertinoColors.systemGrey6
            error: CupertinoColors.destructiveRed,
          ),
          textTheme: const TextTheme(
            bodyLarge: TextStyle(fontFamilyFallback: ['SFUI']), // Added SFUI
            bodyMedium: TextStyle(fontFamilyFallback: ['SFUI']),
            titleMedium: TextStyle(fontFamilyFallback: ['SFUI']), // Added SFUI
            // Define other text styles like headline, body, caption as needed
            // with iOS-like sizes and weights.
            // Example:
            // headlineSmall: TextStyle(fontFamilyFallback: ['SFUI'], fontSize: 22, fontWeight: FontWeight.bold),
            // caption: TextStyle(fontFamilyFallback: ['SFUI'], fontSize: 12, color: CupertinoColors.secondaryLabel),
          ),
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const ChatScreen(),
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
}
