import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'ui/theme/app_theme.dart';
import 'controllers/theme_controller.dart';
import 'controllers/task_controller.dart';
import 'controllers/skill_controller.dart';
import 'ui/screens/home_screen.dart';
import 'controllers/settings_controller.dart';
import 'translations/app_translations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Controllers
  Get.put(SettingsController());
  Get.put(ThemeController());
  Get.put(SkillController());
  Get.put(TaskController());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    
    return Obx(() {
      return GetMaterialApp(
        title: 'Bounty-Do',
        theme: AppTheme.themes[themeController.currentThemeIndex.value],
        debugShowCheckedModeBanner: false,
        translations: AppTranslations(),
        locale: Get.deviceLocale, // Automatically picks up the system language
        fallbackLocale: const Locale('en', 'US'), // Fallback to English
        home: const HomeScreen(),
      );
    });
  }
}
