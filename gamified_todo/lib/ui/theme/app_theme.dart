import 'package:flutter/material.dart';

class AppTheme {
  static final List<ThemeData> themes = [
    // 0: 默认液态玻璃 (浅色基调)
    ThemeData(
      brightness: Brightness.light,
      primaryColor: Colors.blueAccent,
      scaffoldBackgroundColor: const Color(0xFFF3F4F6),
      cardColor: Colors.white.withOpacity(0.6),
      fontFamily: 'Inter',
    ),
    // 1: 极夜黑
    ThemeData(
      brightness: Brightness.dark,
      primaryColor: Colors.tealAccent,
      scaffoldBackgroundColor: const Color(0xFF121212),
      cardColor: Colors.black54,
      fontFamily: 'Inter',
    ),
    // 2: 樱花粉
    ThemeData(
      brightness: Brightness.light,
      primaryColor: Colors.pinkAccent,
      scaffoldBackgroundColor: const Color(0xFFFFF0F5),
      cardColor: Colors.white.withOpacity(0.7),
      fontFamily: 'Inter',
    ),
    // 3: 森林绿
    ThemeData(
      brightness: Brightness.light,
      primaryColor: Colors.green,
      scaffoldBackgroundColor: const Color(0xFFE8F5E9),
      cardColor: Colors.white.withOpacity(0.7),
      fontFamily: 'Inter',
    ),
    // 4: 海洋蓝
    ThemeData(
      brightness: Brightness.light,
      primaryColor: Colors.lightBlue,
      scaffoldBackgroundColor: const Color(0xFFE1F5FE),
      cardColor: Colors.white.withOpacity(0.7),
      fontFamily: 'Inter',
    ),
  ];

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
