import 'package:flutter/material.dart';

class AppTheme {
  static final List<ThemeData> themes = [
    // 0: 默认液态玻璃 (浅色基调)
    ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent, brightness: Brightness.light),
      scaffoldBackgroundColor: const Color(0xFFF3F4F6),
      cardColor: Colors.white.withOpacity(0.6),
      fontFamily: 'Inter',
      fontFamilyFallback: const ['Microsoft YaHei', 'PingFang SC', 'sans-serif'],
    ),
    // 1: 极夜黑
    ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.tealAccent, brightness: Brightness.dark),
      scaffoldBackgroundColor: const Color(0xFF121212),
      cardColor: Colors.black54,
      fontFamily: 'Inter',
      fontFamilyFallback: const ['Microsoft YaHei', 'PingFang SC', 'sans-serif'],
    ),
    // 2: 樱花粉
    ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.pinkAccent, brightness: Brightness.light),
      scaffoldBackgroundColor: const Color(0xFFFFF0F5),
      cardColor: Colors.white.withOpacity(0.7),
      fontFamily: 'Inter',
      fontFamilyFallback: const ['Microsoft YaHei', 'PingFang SC', 'sans-serif'],
    ),
    // 3: 森林绿
    ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.green, brightness: Brightness.light),
      scaffoldBackgroundColor: const Color(0xFFE8F5E9),
      cardColor: Colors.white.withOpacity(0.7),
      fontFamily: 'Inter',
      fontFamilyFallback: const ['Microsoft YaHei', 'PingFang SC', 'sans-serif'],
    ),
    // 4: 海洋蓝
    ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue, brightness: Brightness.light),
      scaffoldBackgroundColor: const Color(0xFFE1F5FE),
      cardColor: Colors.white.withOpacity(0.7),
      fontFamily: 'Inter',
      fontFamilyFallback: const ['Microsoft YaHei', 'PingFang SC', 'sans-serif'],
    ),
    // 5: 纯净白 (Pure White - Minimalist Apple Style)
    ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.black, brightness: Brightness.light),
      scaffoldBackgroundColor: const Color(0xFFF9F9FB),
      cardColor: Colors.white,
      fontFamily: 'Inter',
      fontFamilyFallback: const ['Microsoft YaHei', 'PingFang SC', 'sans-serif'],
    ),
    // 6: 高级暗紫 (Premium Dark Purple)
    ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurpleAccent, brightness: Brightness.dark),
      scaffoldBackgroundColor: const Color(0xFF140D1C),
      cardColor: const Color(0xFF251833),
      fontFamily: 'Inter',
      fontFamilyFallback: const ['Microsoft YaHei', 'PingFang SC', 'sans-serif'],
    ),
    // 7: 落日流金 (Sunset Gold)
    ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.orangeAccent.shade700, brightness: Brightness.light),
      scaffoldBackgroundColor: const Color(0xFFFFFDF5),
      cardColor: const Color(0xFFFFF8E1).withOpacity(0.8),
      fontFamily: 'Inter',
      fontFamilyFallback: const ['Microsoft YaHei', 'PingFang SC', 'sans-serif'],
    ),
    // 8: 赛博朋克 (Cyberpunk)
    ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.cyanAccent, brightness: Brightness.dark),
      scaffoldBackgroundColor: const Color(0xFF0D0518),
      cardColor: const Color(0xFF1A0A2E),
      fontFamily: 'Inter',
      fontFamilyFallback: const ['Microsoft YaHei', 'PingFang SC', 'sans-serif'],
    ),
    // 9: 薄荷微风 (Mint Breeze)
    ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.tealAccent.shade700, brightness: Brightness.light),
      scaffoldBackgroundColor: const Color(0xFFF0FAF8),
      cardColor: Colors.white.withOpacity(0.8),
      fontFamily: 'Inter',
      fontFamilyFallback: const ['Microsoft YaHei', 'PingFang SC', 'sans-serif'],
    ),
  ];

  // Get background colors (glowing blobs and backdrop gradient base) for each theme
  static List<Color> getThemeBackgroundColors(int index) {
    switch (index) {
      case 0: // Liquid Glass
        return [const Color(0xFF818CF8), const Color(0xFF60A5FA), const Color(0xFFF472B6)];
      case 1: // Polar Night
        return [const Color(0xFF0F172A), const Color(0xFF0F766E), const Color(0xFF312E81)];
      case 2: // Sakura Pink
        return [const Color(0xFFF472B6), const Color(0xFFFB7185), const Color(0xFFFFF1F2)];
      case 3: // Forest Green
        return [const Color(0xFF34D399), const Color(0xFF059669), const Color(0xFFECFDF5)];
      case 4: // Ocean Blue
        return [const Color(0xFF38BDF8), const Color(0xFF0284C7), const Color(0xFFF0F9FF)];
      case 5: // Pure White
        return [const Color(0xFFE2E8F0), const Color(0xFF94A3B8), const Color(0xFFF8FAFC)];
      case 6: // Premium Dark Purple
        return [const Color(0xFF8B5CF6), const Color(0xFF6D28D9), const Color(0xFF311042)];
      case 7: // Sunset Gold
        return [const Color(0xFFF59E0B), const Color(0xFFD97706), const Color(0xFFFFFBEB)];
      case 8: // Cyberpunk
        return [const Color(0xFFFF007F), const Color(0xFF00F0FF), const Color(0xFF7F00FF)];
      case 9: // Mint Breeze
        return [const Color(0xFF2DD4BF), const Color(0xFF0D9488), const Color(0xFFF0FDFA)];
      default:
        return [Colors.blue, Colors.purple, Colors.pink];
    }
  }

  // 任务权重映射颜色
  static Color getPriorityColor(int priorityIndex) {
    switch (priorityIndex) {
      case 0:
        return Colors.greenAccent; // low
      case 1:
        return Colors.blueAccent;  // medium
      case 2:
        return Colors.orangeAccent; // high
      default:
        return Colors.grey;
    }
  }
}
