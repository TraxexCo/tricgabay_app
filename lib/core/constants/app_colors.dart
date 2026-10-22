import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary palette
  // Philippine flag-inspired brand palette. Blue is the navigation and
  // trust colour; red is reserved for safety, SOS, and destructive actions.
  static const Color primary = Color(0xFF0038A8);
  static const Color primaryLight = Color(0xFF2F5EB9);
  static const Color primaryDark = Color(0xFF002776);

  // Secondary palette
  static const Color secondary = Color(0xFFFCD116);
  static const Color secondaryLight = Color(0xFFFFE36B);
  static const Color secondaryDark = Color(0xFFC99A00);

  // Status colors
  static const Color success = Color(0xFF27AE60);
  static const Color successLight = Color(0xFFD4EFDF);
  static const Color danger = Color(0xFFCE1126);
  static const Color dangerLight = Color(0xFFFFE8EA);
  static const Color warning = Color(0xFFF39C12);
  static const Color warningLight = Color(0xFFFEF3CD);
  static const Color info = Color(0xFF2980B9);
  static const Color infoLight = Color(0xFFD6EAF8);

  // Driver status
  static const Color online = Color(0xFF27AE60);
  static const Color offline = Color(0xFF95A5A6);
  static const Color busy = Color(0xFFE67E22);

  // Booking status
  static const Color pending = Color(0xFFF39C12);
  static const Color accepted = Color(0xFF27AE60);
  static const Color ongoing = Color(0xFF1B6CA8);
  static const Color completed = Color(0xFF8E44AD);
  static const Color cancelled = Color(0xFFE74C3C);

  // Neutrals
  static const Color background = Color(0xFFF5F7FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFEAF0FA);
  static const Color border = Color(0xFFDCE5F2);
  static const Color divider = Color(0xFFE8EEF7);

  // Dark tones
  static const Color darkBg = Color(0xFF001F5C);
  static const Color darkSurface = Color(0xFF002C7F);
  static const Color darkCard = Color(0xFF0A3B95);

  // Text
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnSecondary = Color(0xFF1A1A2E);

  // Map pin colors
  static const Color spotPin = Color(0xFFCE1126);
  static const Color driverPin = Color(0xFF0038A8);
  static const Color userPin = Color(0xFF27AE60);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0038A8), Color(0xFF002776)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [Color(0xFFFCD116), Color(0xFFC99A00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF001F5C), Color(0xFF0038A8)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF0038A8), Color(0xFFCE1126)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
