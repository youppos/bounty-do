import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gamified_todo/controllers/task_controller.dart';
import 'package:gamified_todo/controllers/settings_controller.dart';
import 'package:gamified_todo/controllers/theme_controller.dart';
import 'package:gamified_todo/controllers/skill_controller.dart';
import 'package:gamified_todo/ui/screens/home_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Get.reset();
    TaskController.isTesting = true;
    SettingsController.isTesting = true;
  });

  testWidgets('Flying Coin Animation Test', (WidgetTester tester) async {
    Get.put(SettingsController());
    Get.put(ThemeController());
    Get.put(SkillController());
    Get.put(TaskController());

    await tester.pumpWidget(const GetMaterialApp(
      home: HomeScreen(),
    ));

    await tester.pumpAndSettle();

    // Verify HomeScreen is rendered
    expect(find.byType(HomeScreen), findsOneWidget);

    // Find the check icon of a task and tap it
    final checkIconFinder = find.byIcon(Icons.check_circle_outline).first;
    expect(checkIconFinder, findsOneWidget);

    print('Tapping check icon to complete task...');
    await tester.tap(checkIconFinder);
    
    // Pump frames to let the animation run
    for (int i = 0; i < 15; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  });
}
