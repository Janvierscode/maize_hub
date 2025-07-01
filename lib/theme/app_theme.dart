import 'package:flutter/material.dart';

class AppTheme {
  // Primary colors - Maize/Agriculture themed
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color secondaryGreen = Color(0xFF81C784);
  static const Color lightGreen = Color(0xFFE8F5E8);
  static const Color darkGreen = Color(0xFF2E7D32);

  // Accent colors
  static const Color accentOrange = Color(0xFFFF9800);
  static const Color accentBlue = Color(0xFF2196F3);
  static const Color warningRed = Color(0xFFF44336);

  // Neutral colors
  static const Color surfaceWhite = Color(0xFFFAFAFA);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textHint = Color(0xFF999999);
  static const Color divider = Color(0xFFE0E0E0);

  // Chat-specific colors
  static const Color chatBackground = Color(0xFFF5F5F5);
  static const Color myMessageBubble = Color(0xFF4CAF50);
  static const Color otherMessageBubble = Color(0xFFFFFFFF);
  static const Color onlineIndicator = Color(0xFF4CAF50);
  static const Color messageStatus = Color(0xFF666666);
  static const Color messageStatusRead = Color(0xFF4CAF50);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        brightness: Brightness.light,
        primary: primaryGreen,
        secondary: secondaryGreen,
        surface: surfaceWhite,
        error: warningRed,
      ),

      // AppBar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),

      // Card theme
      cardTheme: CardThemeData(
        color: cardWhite,
        elevation: 2,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // Elevated Button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryGreen, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        hintStyle: const TextStyle(color: textHint),
      ),

      // Bottom Navigation Bar theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: cardWhite,
        selectedItemColor: primaryGreen,
        unselectedItemColor: textSecondary,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),

      // Icon theme
      iconTheme: const IconThemeData(color: textSecondary, size: 24),

      // Text theme
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: textPrimary,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: TextStyle(
          color: textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        titleSmall: TextStyle(
          color: textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: TextStyle(
          color: textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        bodySmall: TextStyle(
          color: textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        labelLarge: TextStyle(
          color: textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        labelMedium: TextStyle(
          color: textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        labelSmall: TextStyle(
          color: textHint,
          fontSize: 11,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}

// Chat-specific theme extensions
class ChatTheme {
  static const double messageBorderRadius = 16.0;
  static const double avatarRadius = 20.0;
  static const EdgeInsets messagePadding = EdgeInsets.symmetric(
    horizontal: 16.0,
    vertical: 10.0,
  );
  static const EdgeInsets messageMargin = EdgeInsets.symmetric(
    horizontal: 8.0,
    vertical: 2.0,
  );

  static BoxDecoration myMessageDecoration = BoxDecoration(
    color: AppTheme.myMessageBubble,
    borderRadius: const BorderRadius.only(
      topLeft: Radius.circular(messageBorderRadius),
      topRight: Radius.circular(4),
      bottomLeft: Radius.circular(messageBorderRadius),
      bottomRight: Radius.circular(messageBorderRadius),
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.1),
        blurRadius: 2,
        offset: const Offset(0, 1),
      ),
    ],
  );

  static BoxDecoration otherMessageDecoration = BoxDecoration(
    color: AppTheme.otherMessageBubble,
    borderRadius: const BorderRadius.only(
      topLeft: Radius.circular(4),
      topRight: Radius.circular(messageBorderRadius),
      bottomLeft: Radius.circular(messageBorderRadius),
      bottomRight: Radius.circular(messageBorderRadius),
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.1),
        blurRadius: 2,
        offset: const Offset(0, 1),
      ),
    ],
    border: Border.all(color: AppTheme.divider, width: 0.5),
  );

  static BoxDecoration continuingMyMessageDecoration = BoxDecoration(
    color: AppTheme.myMessageBubble,
    borderRadius: const BorderRadius.only(
      topLeft: Radius.circular(messageBorderRadius),
      topRight: Radius.circular(messageBorderRadius),
      bottomLeft: Radius.circular(messageBorderRadius),
      bottomRight: Radius.circular(4),
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 2,
        offset: const Offset(0, 1),
      ),
    ],
  );

  static BoxDecoration continuingOtherMessageDecoration = BoxDecoration(
    color: AppTheme.otherMessageBubble,
    borderRadius: const BorderRadius.only(
      topLeft: Radius.circular(messageBorderRadius),
      topRight: Radius.circular(messageBorderRadius),
      bottomLeft: Radius.circular(4),
      bottomRight: Radius.circular(messageBorderRadius),
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 2,
        offset: const Offset(0, 1),
      ),
    ],
    border: Border.all(color: AppTheme.divider, width: 0.5),
  );
}
