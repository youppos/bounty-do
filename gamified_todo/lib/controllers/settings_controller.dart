import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsController extends GetxController {
  final _prefs = SharedPreferences.getInstance();
  
  // 'system', 'en_US', 'zh_CN'
  var selectedLanguage = 'system'.obs;

  @override
  void onInit() {
    super.onInit();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await _prefs;
    String? lang = prefs.getString('language');
    if (lang != null) {
      selectedLanguage.value = lang;
      _applyLanguage(lang);
    }
  }

  Future<void> changeLanguage(String lang) async {
    selectedLanguage.value = lang;
    final prefs = await _prefs;
    await prefs.setString('language', lang);
    _applyLanguage(lang);
  }

  void _applyLanguage(String lang) {
    if (lang == 'system') {
      Get.updateLocale(Get.deviceLocale ?? const Locale('en', 'US'));
    } else if (lang == 'en_US') {
      Get.updateLocale(const Locale('en', 'US'));
    } else if (lang == 'zh_CN') {
      Get.updateLocale(const Locale('zh', 'CN'));
    }
  }
}
