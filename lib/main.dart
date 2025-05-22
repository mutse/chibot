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
          primaryColor: const Color(0xFF2D2F3E), // A dark color, can be used for accents or sidebar
          scaffoldBackgroundColor: Colors.white, // Main chat area background
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.black54), // For icons like settings
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide.none, // No border by default, or a very light one
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(color: Colors.grey[300] ?? Colors.grey), // Light border
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: Color(0xFF2D2F3E), width: 1.5), // Accent color on focus
            ),
          ),
          iconTheme: IconThemeData(
            color: Colors.grey[700], // Default icon color
          ),
          colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blueGrey).copyWith(
            secondary: const Color(0xFF2D2F3E), // Accent color for buttons, etc.
            primary: const Color(0xFF2D2F3E),
            background: Colors.white,
            surface: Colors.white, // Cards, dialogs background
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
