import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';
import 'package:gamified_todo/controllers/settings_controller.dart';
import 'package:gamified_todo/controllers/theme_controller.dart';
import 'package:gamified_todo/controllers/task_controller.dart';
import 'package:gamified_todo/controllers/skill_controller.dart';
import 'package:gamified_todo/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Get.reset();
  });

  testWidgets('App smoke test initializes and loads home screen', (WidgetTester tester) async {
    TaskController.isTesting = true;

    final settingsController = Get.put(SettingsController());
    await settingsController.initialization;
    final themeController = Get.put(ThemeController());
    await themeController.initialization;
    final taskController = Get.put(TaskController());
    await taskController.initialization;
    final skillController = Get.put(SkillController());
    await skillController.initialization;

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.byType(MyApp), findsOneWidget);
  });
}
