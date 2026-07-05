import 'package:flutter/material.dart';

abstract final class AppColors {
  static const background = Color(0xFF0D0D0D);
  static const surface = Color(0xFF1A1A1C);
  static const surfaceElevated = Color(0xFF232325);

  static const primary = Color(0xFFE63946);
  static const primaryLight = Color(0xFFFF6B4A);
  static const primaryDark = Color(0xFF8B1E2B);

  static const accent = Color(0xFFFF3B30);
  static const textPrimary = Color(0xFFF5F5F7);
  static const textSecondary = Color(0xFF8E8E93);
  static const border = Color(0x14FFFFFF);
  static const success = Color(0xFF34C759);
  static const warning = Color(0xFFFF9500);

  static const gradientStops = [
    Color(0xFFFF3B30),
    Color(0xFFFF6B4A),
    Color(0xFF8B1E2B),
  ];

  static LinearGradient primaryGradient = const LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
