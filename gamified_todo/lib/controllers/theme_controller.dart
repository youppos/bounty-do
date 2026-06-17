import 'package:get/get.dart';

class ThemeController extends GetxController {
  // 0: 默认液态玻璃, 1: 极夜黑, 2: 樱花粉, 3: 森林绿, 4: 海洋蓝
  var currentThemeIndex = 0.obs;

  void changeTheme(int index) {
    if (index >= 0 && index < 10) {
      currentThemeIndex.value = index;
    }
  }
}
