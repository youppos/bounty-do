import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
  final settingsController = Get.put(SettingsController());
  await settingsController.initialization;
  final themeController = Get.put(ThemeController());
  await themeController.initialization;
  final taskController = Get.put(TaskController());
  await taskController.initialization;
  final skillController = Get.put(SkillController());
  await skillController.initialization;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final settingsController = Get.find<SettingsController>();
    
    return Obx(() {
      Locale? targetLocale;
      final lang = settingsController.selectedLanguage.value;
      if (lang == 'zh_CN') {
        targetLocale = const Locale('zh', 'CN');
      } else if (lang == 'en_US') {
        targetLocale = const Locale('en', 'US');
      } else {
        targetLocale = Get.deviceLocale;
      }

      return GetMaterialApp(
        title: 'Bounty-Do',
        theme: AppTheme.themes[themeController.currentThemeIndex.value],
        debugShowCheckedModeBanner: false,
        translations: AppTranslations(),
        locale: targetLocale,
        fallbackLocale: const Locale('en', 'US'),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('zh', 'CN'),
          Locale('en', 'US'),
        ],
        home: const HomeScreen(),
      );
    });
  }
}
