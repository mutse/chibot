import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primaryColor = Color(0xFF2D2F3E);
  static const Color primaryLight = Color(0xFF4A4D5E);
  static const Color primaryDark = Color(0xFF1A1C28);
  
  // Background Colors
  static const Color backgroundColor = Colors.white;
  static const Color backgroundSecondary = Color(0xFFF9FAFB);
  static const Color backgroundTertiary = Color(0xFFF3F4F6);
  
  // Text Colors
  static const Color textPrimary = Colors.black87;
  static const Color textSecondary = Colors.black54;
  static const Color textTertiary = Colors.grey;
  static const Color textOnPrimary = Colors.white;
  
  // Message Colors
  static const Color userMessageBackground = Color(0xFF2B7FFF);
  static const Color aiMessageBackground = Color(0xFFF1F5F9);
  static const Color userMessageText = Colors.white;
  static const Color aiMessageText = Colors.black87;
  
  // Status Colors
  static const Color successColor = Color(0xFF10B981);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color infoColor = Color(0xFF3B82F6);
  
  // Border Colors
  static const Color borderColor = Color(0xFFE5E7EB);
  static const Color focusedBorderColor = Color(0xFF2D2F3E);
  
  // Input Colors
  static const Color inputFillColor = Color(0xFFF9FAFB);
  static const Color inputBorderColor = Color(0xFFE5E7EB);
  static const Color inputFocusedBorderColor = Color(0xFF2D2F3E);
  
  // Loading Colors
  static const Color loadingColor = Color(0xFF6B7280);
  static const Color shimmerBaseColor = Color(0xFFE5E7EB);
  static const Color shimmerHighlightColor = Color(0xFFF3F4F6);
}

class AppTextStyles {
  // Headings
  static const TextStyle h1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle h2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle h3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );
  
  // Body Text
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    color: AppColors.textSecondary,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    color: AppColors.textTertiary,
  );
  
  // Message Styles
  static const TextStyle userMessage = TextStyle(
    fontSize: 16,
    color: AppColors.userMessageText,
  );
  
  static const TextStyle aiMessage = TextStyle(
    fontSize: 16,
    color: AppColors.aiMessageText,
  );
  
  // Button Styles
  static const TextStyle buttonText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textOnPrimary,
  );
  
  // Input Styles
  static const TextStyle inputText = TextStyle(
    fontSize: 16,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle inputHint = TextStyle(
    fontSize: 16,
    color: AppColors.textTertiary,
  );
}