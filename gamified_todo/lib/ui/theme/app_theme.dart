import 'package:flutter/material.dart';

class AppTheme {
  static final List<ThemeData> themes = [
    // 0: 薄荷微风 (Mint Breeze) - NOW DEFAULT
    ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.tealAccent.shade700, brightness: Brightness.light),
      scaffoldBackgroundColor: const Color(0xFFF0FAF8),
      cardColor: Colors.white.withOpacity(0.8),
      fontFamily: 'Inter',
      fontFamilyFallback: const ['Microsoft YaHei', 'PingFang SC', 'sans-serif'],
    ),
    // 1: 默认液态玻璃 (浅色基调)
    ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent, brightness: Brightness.light),
      scaffoldBackgroundColor: const Color(0xFFF3F4F6),
      cardColor: Colors.white.withOpacity(0.6),
      fontFamily: 'Inter',
      fontFamilyFallback: const ['Microsoft YaHei', 'PingFang SC', 'sans-serif'],
    ),
    // 2: 极夜黑
    ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.tealAccent, brightness: Brightness.dark),
      scaffoldBackgroundColor: const Color(0xFF121212),
      cardColor: Colors.black54,
      fontFamily: 'Inter',
      fontFamilyFallback: const ['Microsoft YaHei', 'PingFang SC', 'sans-serif'],
    ),
    // 3: 樱花粉
    ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.pinkAccent, brightness: Brightness.light),
      scaffoldBackgroundColor: const Color(0xFFFFF0F5),
      cardColor: Colors.white.withOpacity(0.7),
      fontFamily: 'Inter',
      fontFamilyFallback: const ['Microsoft YaHei', 'PingFang SC', 'sans-serif'],
    ),
    // 4: 森林绿
    ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.green, brightness: Brightness.light),
      scaffoldBackgroundColor: const Color(0xFFE8F5E9),
      cardColor: Colors.white.withOpacity(0.7),
      fontFamily: 'Inter',
      fontFamilyFallback: const ['Microsoft YaHei', 'PingFang SC', 'sans-serif'],
    ),
    // 5: 海洋蓝
    ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue, brightness: Brightness.light),
      scaffoldBackgroundColor: const Color(0xFFE1F5FE),
      cardColor: Colors.white.withOpacity(0.7),
      fontFamily: 'Inter',
      fontFamilyFallback: const ['Microsoft YaHei', 'PingFang SC', 'sans-serif'],
    ),
    // 6: 纯净白 (Pure White - Minimalist Apple Style)
    ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.black, brightness: Brightness.light),
      scaffoldBackgroundColor: const Color(0xFFF9F9FB),
      cardColor: Colors.white,
      fontFamily: 'Inter',
      fontFamilyFallback: const ['Microsoft YaHei', 'PingFang SC', 'sans-serif'],
    ),
    // 7: 高级暗紫 (Premium Dark Purple)
    ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurpleAccent, brightness: Brightness.dark),
      scaffoldBackgroundColor: const Color(0xFF140D1C),
      cardColor: const Color(0xFF251833),
      fontFamily: 'Inter',
      fontFamilyFallback: const ['Microsoft YaHei', 'PingFang SC', 'sans-serif'],
    ),
    // 8: 落日流金 (Sunset Gold)
    ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.orangeAccent.shade700, brightness: Brightness.light),
      scaffoldBackgroundColor: const Color(0xFFFFFDF5),
      cardColor: const Color(0xFFFFF8E1).withOpacity(0.8),
      fontFamily: 'Inter',
      fontFamilyFallback: const ['Microsoft YaHei', 'PingFang SC', 'sans-serif'],
    ),
    // 9: 赛博朋克 (Cyberpunk)
    ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.cyanAccent, brightness: Brightness.dark),
      scaffoldBackgroundColor: const Color(0xFF0D0518),
      cardColor: const Color(0xFF1A0A2E),
      fontFamily: 'Inter',
      fontFamilyFallback: const ['Microsoft YaHei', 'PingFang SC', 'sans-serif'],
    ),
  ];

  // Get background colors (glowing blobs and backdrop gradient base) for each theme
  static List<Color> getThemeBackgroundColors(int index) {
    switch (index) {
      case 0: // Mint Breeze (was 9)
        return [const Color(0xFF2DD4BF), const Color(0xFF0D9488), const Color(0xFFF0FDFA)];
      case 1: // Liquid Glass (was 0)
        return [const Color(0xFF818CF8), const Color(0xFF60A5FA), const Color(0xFFF472B6)];
      case 2: // Polar Night (was 1)
        return [const Color(0xFF0F172A), const Color(0xFF0F766E), const Color(0xFF312E81)];
      case 3: // Sakura Pink (was 2)
        return [const Color(0xFFF472B6), const Color(0xFFFB7185), const Color(0xFFFFF1F2)];
      case 4: // Forest Green (was 3)
        return [const Color(0xFF34D399), const Color(0xFF059669), const Color(0xFFECFDF5)];
      case 5: // Ocean Blue (was 4)
        return [const Color(0xFF38BDF8), const Color(0xFF0284C7), const Color(0xFFF0F9FF)];
      case 6: // Pure White (was 5)
        return [const Color(0xFFE2E8F0), const Color(0xFF94A3B8), const Color(0xFFF8FAFC)];
      case 7: // Premium Dark Purple (was 6)
        return [const Color(0xFF8B5CF6), const Color(0xFF6D28D9), const Color(0xFF311042)];
      case 8: // Sunset Gold (was 7)
        return [const Color(0xFFF59E0B), const Color(0xFFD97706), const Color(0xFFFFFBEB)];
      case 9: // Cyberpunk (was 8)
        return [const Color(0xFFFF007F), const Color(0xFF00F0FF), const Color(0xFF7F00FF)];
      default:
        return [Colors.blue, Colors.purple, Colors.pink];
    }
  }

  // Get beautiful gradient colors for the Floating Action Button based on theme
  static List<Color> getFabGradientColors(int index) {
    // Determine if the current theme is dark
    bool isDark = themes[index].brightness == Brightness.dark;
    
    if (isDark) {
      // Very stylish gradient for dark themes to stand out and look premium
      if (index == 7) { // Premium Dark Purple
        return [Colors.purpleAccent.shade400, Colors.deepPurpleAccent];
      }
      if (index == 9) { // Cyberpunk
        return [Colors.cyanAccent.shade700, Colors.blueAccent.shade700];
      }
      return [Colors.tealAccent.shade700, Colors.blueAccent.shade700]; // Default dark FAB
    }

    // Light themes
    switch (index) {
      case 0: // Mint Breeze
        return [const Color(0xFF2DD4BF), const Color(0xFF0D9488)];
      case 1: // Liquid Glass
        return [Colors.blueAccent, Colors.purpleAccent];
      case 3: // Sakura Pink
        return [Colors.pinkAccent, Colors.redAccent.shade100];
      case 4: // Forest Green
        return [Colors.green, Colors.teal];
      case 5: // Ocean Blue
        return [Colors.lightBlue, Colors.blue];
      case 6: // Pure White
        return [Colors.black87, Colors.black54];
      case 8: // Sunset Gold
        return [Colors.orangeAccent, Colors.deepOrangeAccent];
      default:
        return [Colors.blueAccent, Colors.lightBlueAccent];
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
