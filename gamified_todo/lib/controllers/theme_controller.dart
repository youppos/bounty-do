import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends GetxController {
  final _prefs = SharedPreferences.getInstance();
  late final Future<void> initialization;

  // 0: 默认液态玻璃, 1: 极夜黑, 2: 樱花粉, 3: 森林绿, 4: 海洋蓝
  var currentThemeIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    initialization = _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await _prefs;
    currentThemeIndex.value = prefs.getInt('currentThemeIndex') ?? 0;
  }

  void changeTheme(int index) {
    if (index >= 0 && index < 10) {
      currentThemeIndex.value = index;
      _saveTheme(index);
    }
  }

  Future<void> _saveTheme(int index) async {
    final prefs = await _prefs;
    await prefs.setInt('currentThemeIndex', index);
  }
}
