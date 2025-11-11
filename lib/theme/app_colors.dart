import 'package:flutter/material.dart';

/// App Color Palette
/// Matches the Next.js frontend (Tailwind CSS configuration)
/// Colors are exact match with web frontend design system
class AppColors {
  // Prevent instantiation
  AppColors._();

  // ==================== LIGHT MODE COLORS ====================
  
  /// Primary color - Emerald 500
  /// Matches: --primary: #10b981
  static const Color primary = Color(0xFF10B981);
  
  /// Primary foreground - White
  /// Matches: --primary-foreground: #ffffff
  static const Color primaryForeground = Color(0xFFFFFFFF);
  
  /// Primary light - Emerald 400
  /// Matches: --primary-light: #34d399
  static const Color primaryLight = Color(0xFF34D399);
  
  /// Primary dark - Emerald 600
  /// Matches: --primary-dark: #059669
  static const Color primaryDark = Color(0xFF059669);
  
  /// Secondary - Gray 100
  /// Matches: --secondary: #f3f4f6
  static const Color secondary = Color(0xFFF3F4F6);
  
  /// Secondary foreground - Gray 700
  /// Matches: --secondary-foreground: #374151
  static const Color secondaryForeground = Color(0xFF374151);
  
  /// Accent - Emerald 100
  /// Matches: --accent: #d1fae5
  static const Color accent = Color(0xFFD1FAE5);
  
  /// Accent foreground - Emerald 800
  /// Matches: --accent-foreground: #065f46
  static const Color accentForeground = Color(0xFF065F46);
  
  /// Muted - Gray 50
  /// Matches: --muted: #f9fafb
  static const Color muted = Color(0xFFF9FAFB);
  
  /// Muted foreground - Gray 500
  /// Matches: --muted-foreground: #6b7280
  static const Color mutedForeground = Color(0xFF6B7280);
  
  /// Border - Gray 200
  /// Matches: --border: #e5e7eb
  static const Color border = Color(0xFFE5E7EB);
  
  /// Input background - Gray 50
  /// Matches: --input: #f9fafb
  static const Color input = Color(0xFFF9FAFB);
  
  /// Ring/Focus color - Emerald 500
  /// Matches: --ring: #10b981
  static const Color ring = Color(0xFF10B981);
  
  /// Destructive - Red 500
  /// Matches: --destructive: #ef4444
  static const Color destructive = Color(0xFFEF4444);
  
  /// Destructive foreground - White
  /// Matches: --destructive-foreground: #ffffff
  static const Color destructiveForeground = Color(0xFFFFFFFF);
  
  /// Card background - White
  /// Matches: --card: #ffffff
  static const Color card = Color(0xFFFFFFFF);
  
  /// Card foreground - Near black
  /// Matches: --card-foreground: #171717
  static const Color cardForeground = Color(0xFF171717);
  
  /// Background - White
  /// Matches: --background: #ffffff
  static const Color background = Color(0xFFFFFFFF);
  
  /// Foreground - Near black
  /// Matches: --foreground: #171717
  static const Color foreground = Color(0xFF171717);

  // ==================== DARK MODE COLORS ====================
  
  /// Dark mode - Background
  /// Matches: dark mode --background: #0a0a0a
  static const Color darkBackground = Color(0xFF0A0A0A);
  
  /// Dark mode - Foreground
  /// Matches: dark mode --foreground: #ededed
  static const Color darkForeground = Color(0xFFEDEDED);
  
  /// Dark mode - Primary dark
  /// Matches: dark mode --primary-dark: #065f46
  static const Color darkPrimaryDark = Color(0xFF065F46);
  
  /// Dark mode - Secondary
  /// Matches: dark mode --secondary: #1f2937 (gray-800)
  static const Color darkSecondary = Color(0xFF1F2937);
  
  /// Dark mode - Secondary foreground
  /// Matches: dark mode --secondary-foreground: #d1d5db (gray-300)
  static const Color darkSecondaryForeground = Color(0xFFD1D5DB);
  
  /// Dark mode - Accent
  /// Matches: dark mode --accent: #064e3b (emerald-900)
  static const Color darkAccent = Color(0xFF064E3B);
  
  /// Dark mode - Accent foreground
  /// Matches: dark mode --accent-foreground: #d1fae5 (emerald-100)
  static const Color darkAccentForeground = Color(0xFFD1FAE5);
  
  /// Dark mode - Muted
  /// Matches: dark mode --muted: #111827 (gray-900)
  static const Color darkMuted = Color(0xFF111827);
  
  /// Dark mode - Muted foreground
  /// Matches: dark mode --muted-foreground: #9ca3af (gray-400)
  static const Color darkMutedForeground = Color(0xFF9CA3AF);
  
  /// Dark mode - Border
  /// Matches: dark mode --border: #374151 (gray-700)
  static const Color darkBorder = Color(0xFF374151);
  
  /// Dark mode - Input
  /// Matches: dark mode --input: #1f2937 (gray-800)
  static const Color darkInput = Color(0xFF1F2937);
  
  /// Dark mode - Card
  /// Matches: dark mode --card: #111827 (gray-900)
  static const Color darkCard = Color(0xFF111827);
  
  /// Dark mode - Card foreground
  /// Matches: dark mode --card-foreground: #ededed
  static const Color darkCardForeground = Color(0xFFEDEDED);

  // ==================== SEMANTIC COLORS ====================
  
  /// Success color - Green 500
  static const Color success = Color(0xFF22C55E);
  
  /// Success foreground
  static const Color successForeground = Color(0xFFFFFFFF);
  
  /// Warning color - Yellow 500
  static const Color warning = Color(0xFFF59E0B);
  
  /// Warning foreground
  static const Color warningForeground = Color(0xFF000000);
  
  /// Info color - Blue 500
  static const Color info = Color(0xFF3B82F6);
  
  /// Info foreground
  static const Color infoForeground = Color(0xFFFFFFFF);

  // ==================== STATUS COLORS ====================
  
  /// Online status
  static const Color statusOnline = Color(0xFF10B981);
  
  /// Away status
  static const Color statusAway = Color(0xFFF59E0B);
  
  /// Busy status
  static const Color statusBusy = Color(0xFFEF4444);
  
  /// Offline status
  static const Color statusOffline = Color(0xFF6B7280);

  // ==================== GRADIENT COLORS ====================
  
  /// Primary gradient colors
  static const List<Color> primaryGradient = [
    Color(0xFF10B981), // primary
    Color(0xFF34D399), // primaryLight
  ];
  
  /// Card gradient overlay
  static const List<Color> cardGradient = [
    Color(0x00000000), // transparent
    Color(0x40000000), // 25% black
  ];

  // ==================== SHADOW COLORS ====================
  
  /// Light shadow
  static Color get shadowLight => Colors.black.withOpacity(0.05);
  
  /// Medium shadow
  static Color get shadowMedium => Colors.black.withOpacity(0.1);
  
  /// Heavy shadow
  static Color get shadowHeavy => Colors.black.withOpacity(0.2);

  // ==================== OPACITY HELPERS ====================
  
  /// Get primary color with opacity
  static Color primaryWithOpacity(double opacity) => primary.withOpacity(opacity);
  
  /// Get foreground color with opacity
  static Color foregroundWithOpacity(double opacity) => foreground.withOpacity(opacity);
  
  /// Get white with opacity
  static Color whiteWithOpacity(double opacity) => Colors.white.withOpacity(opacity);
  
  /// Get black with opacity
  static Color blackWithOpacity(double opacity) => Colors.black.withOpacity(opacity);

  // ==================== UTILITY METHODS ====================
  
  /// Check if color is light
  static bool isLight(Color color) {
    return ThemeData.estimateBrightnessForColor(color) == Brightness.light;
  }
  
  /// Get contrasting text color
  static Color getContrastingColor(Color backgroundColor) {
    return isLight(backgroundColor) ? foreground : Colors.white;
  }
}

/// Extension on BuildContext for easy theme color access
extension AppColorsExtension on BuildContext {
  /// Get primary color from theme
  Color get primaryColor => Theme.of(this).colorScheme.primary;
  
  /// Get background color from theme
  Color get backgroundColor => Theme.of(this).scaffoldBackgroundColor;
  
  /// Get text color from theme
  Color get textColor => Theme.of(this).textTheme.bodyLarge?.color ?? AppColors.foreground;
  
  /// Get card color from theme
  Color get cardColor => Theme.of(this).cardTheme.color ?? AppColors.card;
}

