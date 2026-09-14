import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Backgrounds & Surfaces
  static const Color background = Color(0xFF070B14);
  static const Color backgroundSecondary = Color(0xFF0D1424);
  static const Color surfaceGlass = Color(0x12FFFFFF);
  static const Color surfaceGlassHigh = Color(0x22FFFFFF);
  static const Color surfaceCard = Color(0xFF11192C);
  static const Color borderGlass = Color(0x1EFFFFFF);
  static const Color borderGlassHighlight = Color(0x38FFFFFF);

  // Brand & Accents (matching iOS Liquid Glass mockup)
  static const Color primary = Color(0xFF3B82F6); // Electric Blue
  static const Color primaryLight = Color(0xFF60A5FA);
  static const Color accentCyan = Color(0xFF8DE2C5); // Neon Mint/Cyan
  static const Color accentPurple = Color(0xFFA78BFA); // Soft Violet
  static const Color accentAmber = Color(0xFFFBBF24); // Warm Gold / Streak flame
  static const Color accentRose = Color(0xFFF43F5E); // Coral Red / Delete
  static const Color accentGreen = Color(0xFF10B981); // Improvement / Completed

  // Text colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  // Gradients
  static const LinearGradient liquidBackgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF070C16),
      Color(0xFF0B1325),
      Color(0xFF070B14),
      Color(0xFF0E172E),
    ],
  );

  static const LinearGradient heroCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x2B3B82F6),
      Color(0x151D4ED8),
      Color(0x0D0B1325),
    ],
  );

  static const LinearGradient buttonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF3B82F6),
      Color(0xFF2563EB),
    ],
  );

  static const LinearGradient accentGlowGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF8DE2C5),
      Color(0xFF3B82F6),
    ],
  );
}
