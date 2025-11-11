import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Authentication Theme
/// Uses AppColors for consistency with the main theme
class AuthTheme {
  const AuthTheme._();

  // Use AppColors for consistency
  static Color get primary => AppColors.primary;
  static Color get primaryDark => AppColors.primaryDark;
  static Color get primaryLight => AppColors.primaryLight;
  static Color get surface => AppColors.card;
  static Color get surfaceTint => AppColors.muted;
  static Color get neutral => AppColors.mutedForeground;
  static Color get neutralStrong => AppColors.foreground;
  static Color get border => AppColors.border;
  static const Color borderEmphasis = Color(0xFFBBF7D0);
  static Color get accent => AppColors.accent;
  static Color get accentStrong => AppColors.accentForeground;
  static Color get destructive => AppColors.destructive;
  static Color get warning => AppColors.warning;

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFFEFFCF5), Colors.white],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static LinearGradient get primaryGradient => LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const EdgeInsets cardPadding = EdgeInsets.symmetric(
    horizontal: 24,
    vertical: 28,
  );

  static BoxDecoration cardDecoration({double borderRadius = 24}) {
    return BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: borderEmphasis.withOpacity(0.7)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x14065F46),
          blurRadius: 32,
          offset: Offset(0, 18),
        ),
        BoxShadow(
          color: Color(0x100F172A),
          blurRadius: 14,
          offset: Offset(0, 8),
        ),
      ],
    );
  }

  static OutlineInputBorder outlineBorder({Color? color}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: color ?? border, width: 1.1),
    );
  }

  static InputDecoration inputDecoration({
    required String label,
    String? hint,
    Widget? leading,
    Widget? trailing,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: leading,
      suffixIcon: trailing,
      border: outlineBorder(),
      enabledBorder: outlineBorder(),
      focusedBorder: outlineBorder(color: primary),
      errorBorder: outlineBorder(color: destructive),
      focusedErrorBorder: outlineBorder(color: destructive),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      labelStyle: TextStyle(color: neutral),
      hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
    );
  }

  static TextStyle subtitle({bool strong = false}) {
    return TextStyle(
      color: strong ? neutralStrong : neutral,
      fontSize: strong ? 16 : 14,
      height: 1.4,
    );
  }
}



