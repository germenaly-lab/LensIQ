import 'package:flutter/material.dart';

/**
 * Enterprise Semantic Color System for LensIQ.
 * Supports high-contrast, polished Dark Mode and true, professional Light Mode.
 */
class AppSemanticColors {
  final bool isDark;
  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color surfaceSubtle;
  final Color border;
  final Color borderSubtle;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color primary;
  final Color primaryDark;
  final Color primaryLight;
  final Color primaryContainer;
  final Color secondary;
  final Color accent;
  final Color success;
  final Color successContainer;
  final Color warning;
  final Color warningContainer;
  final Color error;
  final Color errorContainer;
  final Color info;
  final Color infoContainer;
  final Color severityCritical;
  final Color severityWarning;
  final Color severityInfo;
  final Color rtspBadge;
  final Color hikvisionBadge;
  final Color inputFill;
  final List<BoxShadow> cardShadow;

  const AppSemanticColors({
    required this.isDark,
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.surfaceSubtle,
    required this.border,
    required this.borderSubtle,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.primary,
    required this.primaryDark,
    required this.primaryLight,
    required this.primaryContainer,
    required this.secondary,
    required this.accent,
    required this.success,
    required this.successContainer,
    required this.warning,
    required this.warningContainer,
    required this.error,
    required this.errorContainer,
    required this.info,
    required this.infoContainer,
    required this.severityCritical,
    required this.severityWarning,
    required this.severityInfo,
    required this.rtspBadge,
    required this.hikvisionBadge,
    required this.inputFill,
    required this.cardShadow,
  });
}

class AppColors {
  // Legacy / Default Dark palette constants for backwards compatibility
  static const Color background = Color(0xFF0B0F19);      // Deep Slate Navy 950
  static const Color surface = Color(0xFF111827);         // Slate 900
  static const Color surfaceLight = Color(0xFF1F2937);    // Slate 800
  static const Color surfaceElevated = Color(0xFF1E293B); // Slate 800 Elevated
  static const Color border = Color(0xFF1F2937);          // Slate 800
  static const Color borderSubtle = Color(0xFF374151);    // Slate 700

  // Light Mode Surfaces
  static const Color lightBackground = Color(0xFFF8FAFC); // Slate 50
  static const Color lightSurface = Color(0xFFFFFFFF);    // Pure White
  static const Color lightSurfaceElevated = Color(0xFFF1F5F9); // Slate 100
  static const Color lightBorder = Color(0xFFE2E8F0);     // Slate 200
  static const Color lightBorderSubtle = Color(0xFFCBD5E1); // Slate 300

  // Brand Primaries & Accents
  static const Color primary = Color(0xFF6366F1);         // Indigo 500
  static const Color primaryDark = Color(0xFF4F46E5);     // Indigo 600
  static const Color primaryLight = Color(0xFF818CF8);    // Indigo 400
  static const Color secondary = Color(0xFF0EA5E9);       // Sky 500
  static const Color accent = Color(0xFF8B5CF6);          // Violet / Purple 500

  // Status & Severity Indicators
  static const Color success = Color(0xFF10B981);         // Emerald 500
  static const Color warning = Color(0xFFF59E0B);         // Amber 500
  static const Color error = Color(0xFFEF4444);           // Red 500
  static const Color info = Color(0xFF3B82F6);            // Blue 500

  // Severity specific
  static const Color severityCritical = Color(0xFFDC2626);
  static const Color severityWarning = Color(0xFFD97706);
  static const Color severityInfo = Color(0xFF2563EB);

  // Source Type Indicators
  static const Color rtspBadge = Color(0xFF6366F1);       // Indigo
  static const Color hikvisionBadge = Color(0xFFEC4899);  // Pink/Fuschia for Hikvision P2P

  // Typography
  static const Color textPrimary = Color(0xFFF9FAFB);     // Gray 50
  static const Color textSecondary = Color(0xFF9CA3AF);   // Gray 400
  static const Color textMuted = Color(0xFF6B7280);       // Gray 500

  static const Color lightTextPrimary = Color(0xFF0F172A);// Slate 900
  static const Color lightTextSecondary = Color(0xFF475569);// Slate 600
  static const Color lightTextMuted = Color(0xFF94A3B8);  // Slate 400

  // --------------------------------------------------------------------------
  // Semantic Token Sets
  // --------------------------------------------------------------------------
  static const AppSemanticColors dark = AppSemanticColors(
    isDark: true,
    background: Color(0xFF0B0F19),
    surface: Color(0xFF111827),
    surfaceElevated: Color(0xFF1F2937),
    surfaceSubtle: Color(0xFF182234),
    border: Color(0xFF1F2937),
    borderSubtle: Color(0xFF374151),
    textPrimary: Color(0xFFF9FAFB),
    textSecondary: Color(0xFF9CA3AF),
    textMuted: Color(0xFF6B7280),
    primary: Color(0xFF6366F1),
    primaryDark: Color(0xFF4F46E5),
    primaryLight: Color(0xFF818CF8),
    primaryContainer: Color(0xFF1E1B4B),
    secondary: Color(0xFF0EA5E9),
    accent: Color(0xFF8B5CF6),
    success: Color(0xFF10B981),
    successContainer: Color(0xFF064E3B),
    warning: Color(0xFFF59E0B),
    warningContainer: Color(0xFF78350F),
    error: Color(0xFFEF4444),
    errorContainer: Color(0xFF7F1D1D),
    info: Color(0xFF3B82F6),
    infoContainer: Color(0xFF1E3A8A),
    severityCritical: Color(0xFFEF4444),
    severityWarning: Color(0xFFF59E0B),
    severityInfo: Color(0xFF3B82F6),
    rtspBadge: Color(0xFF6366F1),
    hikvisionBadge: Color(0xFFEC4899),
    inputFill: Color(0xFF111827),
    cardShadow: [
      BoxShadow(
        color: Color(0x33000000),
        blurRadius: 10,
        offset: Offset(0, 4),
      ),
    ],
  );

  static const AppSemanticColors light = AppSemanticColors(
    isDark: false,
    background: Color(0xFFF8FAFC),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFFFFFFF),
    surfaceSubtle: Color(0xFFF1F5F9),
    border: Color(0xFFE2E8F0),
    borderSubtle: Color(0xFFCBD5E1),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF475569),
    textMuted: Color(0xFF94A3B8),
    primary: Color(0xFF4F46E5),
    primaryDark: Color(0xFF4338CA),
    primaryLight: Color(0xFF6366F1),
    primaryContainer: Color(0xFFEEF2FF),
    secondary: Color(0xFF0284C7),
    accent: Color(0xFF7C3AED),
    success: Color(0xFF059669),
    successContainer: Color(0xFFECFDF5),
    warning: Color(0xFFD97706),
    warningContainer: Color(0xFFFFFBEB),
    error: Color(0xFFDC2626),
    errorContainer: Color(0xFFFEF2F2),
    info: Color(0xFF2563EB),
    infoContainer: Color(0xFFEFF6FF),
    severityCritical: Color(0xFFDC2626),
    severityWarning: Color(0xFFD97706),
    severityInfo: Color(0xFF2563EB),
    rtspBadge: Color(0xFF4F46E5),
    hikvisionBadge: Color(0xFFDB2777),
    inputFill: Color(0xFFFFFFFF),
    cardShadow: [
      BoxShadow(
        color: Color(0x0A000000),
        blurRadius: 10,
        offset: Offset(0, 2),
      ),
      BoxShadow(
        color: Color(0x08000000),
        blurRadius: 4,
        offset: Offset(0, 1),
      ),
    ],
  );

  /// Resolves the semantic color token set according to active theme brightness
  static AppSemanticColors of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? dark : light;
  }
}

/// Convenience extension on BuildContext
extension AppColorsExtension on BuildContext {
  AppSemanticColors get colors => AppColors.of(this);
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
