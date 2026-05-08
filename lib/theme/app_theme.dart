// lib/theme/app_theme.dart
// Neumorphism 新拟态设计系统
// 与 Web 端保持一致的视觉风格

import 'package:flutter/material.dart';

/// Neumorphism 设计 Token
class NeuTheme {
  NeuTheme._();

  // ── 底色 ──
  static const Color bg = Color(0xFFE0E5EC);
  static const Color card = Color(0xFFE4E9F0);
  static const Color shadowLight = Color(0xFFFFFFFF);
  static const Color shadowDark = Color(0xFFA3B1C6);
  static const Color shadowMd = Color(0xFFB8C4D4);

  // ── 强调色 ──
  static const Color accent = Color(0xFF6C5CE7);
  static const Color accentHover = Color(0xFF5A4BD1);
  static const Color accentLight = Color(0x1F6C5CE7);

  // ── 文字色 ──
  static const Color textPrimary = Color(0xFF2D3436);
  static const Color textSecondary = Color(0xFF636E72);
  static const Color textMuted = Color(0xFF9098A0);
  static const Color textOnAccent = Color(0xFFFFFFFF);

  // ── 状态色 ──
  static const Color success = Color(0xFF00B894);
  static const Color successBg = Color(0x1A00B894);
  static const Color error = Color(0xFFE17055);
  static const Color errorBg = Color(0x14E17055);
  static const Color warning = Color(0xFFE5A100);
  static const Color warningBg = Color(0x1AE5A100);
  static const Color info = Color(0xFF6C5CE7);

  // ── 圆角 ──
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;
  static const double radiusFull = 999;

  // ── 间距 ──
  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space5 = 20;
  static const double space6 = 24;
  static const double space8 = 32;

  // ── 字号 ──
  static const double textXs = 11;
  static const double textSm = 13;
  static const double textBase = 14;
  static const double textLg = 16;
  static const double textXl = 20;
  static const double text2xl = 26;

  // ── 新拟态阴影 ──
  static List<BoxShadow> shadowRaisedSm = [
    BoxShadow(
      color: shadowDark,
      offset: const Offset(4, 4),
      blurRadius: 8,
    ),
    BoxShadow(
      color: shadowLight,
      offset: const Offset(-4, -4),
      blurRadius: 8,
    ),
  ];

  static List<BoxShadow> shadowRaisedMd = [
    BoxShadow(
      color: shadowDark,
      offset: const Offset(6, 6),
      blurRadius: 12,
    ),
    BoxShadow(
      color: shadowLight,
      offset: const Offset(-6, -6),
      blurRadius: 12,
    ),
  ];

  static List<BoxShadow> shadowRaisedLg = [
    BoxShadow(
      color: shadowDark,
      offset: const Offset(8, 8),
      blurRadius: 16,
    ),
    BoxShadow(
      color: shadowLight,
      offset: const Offset(-8, -8),
      blurRadius: 16,
    ),
  ];

  static List<BoxShadow> shadowInsetSm = [
    BoxShadow(
      color: shadowDark,
      offset: const Offset(3, 3),
      blurRadius: 6,
      spreadRadius: -1,
    ),
    BoxShadow(
      color: shadowLight,
      offset: const Offset(-3, -3),
      blurRadius: 6,
      spreadRadius: -1,
    ),
  ];

  static List<BoxShadow> shadowFlat = [
    BoxShadow(
      color: shadowDark.withValues(alpha: 0),
    ),
    BoxShadow(
      color: shadowLight.withValues(alpha: 0),
    ),
  ];

  // ── 凹陷阴影（用于输入框、选中态） ──
  static List<BoxShadow> get shadowPressed => shadowFlat;

  // ── 凸起卡片装饰 ──
  static BoxDecoration cardDecoration({double radius = radiusMd}) {
    return BoxDecoration(
      color: card,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: shadowRaisedSm,
    );
  }

  /// 凹陷装饰（输入框/选中态）
  static BoxDecoration insetDecoration({double radius = radiusMd}) {
    return BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: shadowDark,
          offset: const Offset(3, 3),
          blurRadius: 6,
          spreadRadius: -1,
        ),
        BoxShadow(
          color: shadowLight,
          offset: const Offset(-3, -3),
          blurRadius: 6,
          spreadRadius: -1,
        ),
      ],
    );
  }
}

/// Flutter 主题
class NeuThemeData {
  NeuThemeData._();

  static ThemeData get light => ThemeData(
        scaffoldBackgroundColor: NeuTheme.bg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: NeuTheme.accent,
          brightness: Brightness.light,
          primary: NeuTheme.accent,
          onPrimary: NeuTheme.textOnAccent,
          surface: NeuTheme.card,
          onSurface: NeuTheme.textPrimary,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: NeuTheme.bg,
          foregroundColor: NeuTheme.textPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        cardTheme: CardThemeData(
          color: NeuTheme.card,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NeuTheme.radiusMd),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: NeuTheme.bg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NeuTheme.radiusLg),
          ),
          elevation: 0,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: NeuTheme.textPrimary,
          contentTextStyle: const TextStyle(color: Colors.white),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NeuTheme.radiusMd),
          ),
          behavior: SnackBarBehavior.floating,
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: NeuTheme.text2xl,
            fontWeight: FontWeight.w700,
            color: NeuTheme.textPrimary,
          ),
          titleLarge: TextStyle(
            fontSize: NeuTheme.textXl,
            fontWeight: FontWeight.w600,
            color: NeuTheme.textPrimary,
          ),
          titleMedium: TextStyle(
            fontSize: NeuTheme.textLg,
            fontWeight: FontWeight.w600,
            color: NeuTheme.textPrimary,
          ),
          bodyLarge: TextStyle(
            fontSize: NeuTheme.textBase,
            color: NeuTheme.textPrimary,
          ),
          bodyMedium: TextStyle(
            fontSize: NeuTheme.textSm,
            color: NeuTheme.textSecondary,
          ),
          bodySmall: TextStyle(
            fontSize: NeuTheme.textXs,
            color: NeuTheme.textMuted,
          ),
        ),
      );
}
