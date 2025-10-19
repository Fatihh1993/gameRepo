import 'package:flutter/material.dart';

/// Centralized color palette to keep the visual language consistent
/// across the application.
class AppColors {
  AppColors._();

  // Brand colors
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryDark = Color(0xFF4F46D1);
  static const Color secondary = Color(0xFF8C74FF);

  // Functional colors
  static const Color success = Color(0xFF06D6A0);
  static const Color danger = Color(0xFFEF476F);
  static const Color warning = Color(0xFFFFC43D);

  // Surfaces
  static const Color backgroundLight = Color(0xFFF4F6FB);
  static const Color backgroundDark = Color(0xFF0F1121);
  static const Color surfaceLight = Colors.white;
  static const Color surfaceDark = Color(0xFF181A2A);

  // Neutrals
  static const Color neutral600 = Color(0xFF7B7F91);
  static const Color neutral500 = Color(0xFF9BA0B5);
}
