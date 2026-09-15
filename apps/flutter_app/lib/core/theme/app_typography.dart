import 'package:flutter/material.dart';
import 'app_colors.dart';

/**
 * Enterprise Typography System.
 * Clean, readable, dense information layout with responsive context-aware contrast.
 */
class AppTypography {
  static const String fontFamily = 'Roboto';

  // Headlines (Static defaults for backward compatibility)
  static const TextStyle h1 = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    color: AppColors.textPrimary,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // Body text
  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySecondary = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.3,
  );

  static const TextStyle bodySmall = bodySecondary;

  // Captions & Labels
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
  );

  static const TextStyle badge = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );

  // Code / Mono
  static const TextStyle code = TextStyle(
    fontFamily: 'monospace',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  // --------------------------------------------------------------------------
  // Theme & Context-Aware Dynamic Styles
  // Automatically adjust color and line height based on light/dark mode
  // --------------------------------------------------------------------------
  static TextStyle h1Of(BuildContext context, {Color? color}) {
    final colors = context.colors;
    return TextStyle(
      fontSize: 26,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      color: color ?? colors.textPrimary,
      height: 1.25,
    );
  }

  static TextStyle h2Of(BuildContext context, {Color? color}) {
    final colors = context.colors;
    return TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.3,
      color: color ?? colors.textPrimary,
      height: 1.3,
    );
  }

  static TextStyle h3Of(BuildContext context, {Color? color}) {
    final colors = context.colors;
    return TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: color ?? colors.textPrimary,
      height: 1.35,
    );
  }

  static TextStyle bodyOf(BuildContext context, {Color? color, FontWeight? fontWeight}) {
    final colors = context.colors;
    return TextStyle(
      fontSize: 14,
      fontWeight: fontWeight ?? FontWeight.w400,
      color: color ?? colors.textPrimary,
      height: 1.45,
    );
  }

  static TextStyle bodyMediumOf(BuildContext context, {Color? color}) {
    return bodyOf(context, color: color, fontWeight: FontWeight.w500);
  }

  static TextStyle bodySecondaryOf(BuildContext context, {Color? color}) {
    final colors = context.colors;
    return TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      color: color ?? colors.textSecondary,
      height: 1.35,
    );
  }

  static TextStyle bodySmallOf(BuildContext context, {Color? color}) {
    return bodySecondaryOf(context, color: color);
  }

  static TextStyle captionOf(BuildContext context, {Color? color, FontWeight? fontWeight}) {
    final colors = context.colors;
    return TextStyle(
      fontSize: 12,
      fontWeight: fontWeight ?? FontWeight.w400,
      color: color ?? colors.textMuted,
      height: 1.3,
    );
  }

  static TextStyle badgeOf(BuildContext context, {Color? color}) {
    return TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.4,
      color: color ?? context.colors.textPrimary,
    );
  }

  static TextStyle codeOf(BuildContext context, {Color? color}) {
    final colors = context.colors;
    return TextStyle(
      fontFamily: 'monospace',
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: color ?? colors.textSecondary,
    );
  }
}
