import 'package:flutter/material.dart';

/**
 * Enterprise Color Palette for LensIQ.
 * Designed for corporate management, retail operations, and 24/7 security NOC dashboards.
 * High contrast, legible, authoritative.
 */
class AppColors {
  // Backgrounds & Surfaces (Dark Slate Enterprise Default)
  static const Color background = Color(0xFF0F172A);      // Slate 900
  static const Color surface = Color(0xFF1E293B);         // Slate 800
  static const Color surfaceLight = Color(0xFF334155);    // Slate 700
  static const Color surfaceElevated = Color(0xFF1E293B); // Elevation 1
  static const Color border = Color(0xFF334155);          // Slate 700

  // Light Mode Surfaces
  static const Color lightBackground = Color(0xFFF8FAFC); // Slate 50
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE2E8F0);      // Slate 200

  // Brand Primaries & Accents
  static const Color primary = Color(0xFF6366F1);         // Indigo 500
  static const Color primaryDark = Color(0xFF4F46E5);     // Indigo 600
  static const Color primaryLight = Color(0xFF818CF8);    // Indigo 400
  static const Color secondary = Color(0xFF0EA5E9);       // Sky 500
  static const Color accent = Color(0xFF8B5CF6);          // Violet / Purple 500

  // Status & Severity Indicators
  static const Color success = Color(0xFF10B981);         // Emerald 500 (Online / Healthy)
  static const Color warning = Color(0xFFF59E0B);         // Amber 500 (Degraded / Empty Timer)
  static const Color error = Color(0xFFEF4444);           // Red 500 (Offline / Critical Alert)
  static const Color info = Color(0xFF3B82F6);            // Blue 500 (Info Notice)

  // Severity specific
  static const Color severityCritical = Color(0xFFDC2626);
  static const Color severityWarning = Color(0xFFD97706);
  static const Color severityInfo = Color(0xFF2563EB);

  // Source Type Indicators
  static const Color rtspBadge = Color(0xFF6366F1);       // Indigo
  static const Color hikvisionBadge = Color(0xFFEC4899);  // Pink/Fuschia for Hikvision P2P

  // Typography & Content
  static const Color textPrimary = Color(0xFFF8FAFC);     // Slate 50
  static const Color textSecondary = Color(0xFF94A3B8);   // Slate 400
  static const Color textMuted = Color(0xFF64748B);       // Slate 500

  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF475569);
  static const Color lightTextMuted = Color(0xFF94A3B8);
}
