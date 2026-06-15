import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/settings_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../controllers/task_controller.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsController = Get.find<SettingsController>();
    final themeController = Get.find<ThemeController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
        title: Text('settings'.tr, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontFamily: 'Inter')),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          _buildSectionTitle('change_theme'.tr, context),
          _buildGroupContainer(
            context: context,
            child: Obx(() => Column(
              children: List.generate(10, (index) {
                return _buildRadioRow(
                  context: context,
                  title: 'theme_$index'.tr,
                  isSelected: themeController.currentThemeIndex.value == index,
                  onTap: () => themeController.changeTheme(index),
                  isLast: index == 9,
                  leading: Container(
                    width: 20, height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.themes[index].primaryColor,
                      border: Border.all(color: Colors.grey.shade300)
                    ),
                  )
                );
              }),
            )),
          ),
          
          const SizedBox(height: 24),
          _buildSectionTitle('thickness_title'.tr, context),
          _buildGroupContainer(
            context: context,
            child: Obx(() => Column(
              children: List.generate(3, (index) {
                return _buildRadioRow(
                  context: context,
                  title: 'thickness_$index'.tr,
                  isSelected: settingsController.taskBorderThickness.value == index,
                  onTap: () => settingsController.changeTaskBorderThickness(index),
                  isLast: index == 2,
                );
              }),
            )),
          ),
          
          const SizedBox(height: 24),
          _buildSectionTitle('effect_title'.tr, context),
          _buildGroupContainer(
            context: context,
            child: Obx(() => Column(
              children: List.generate(5, (index) {
                return _buildRadioRow(
                  context: context,
                  title: 'effect_$index'.tr,
                  isSelected: settingsController.taskLightEffect.value == index,
                  onTap: () => settingsController.changeTaskLightEffect(index),
                  isLast: index == 4,
                );
              }),
            )),
          ),

          const SizedBox(height: 24),
          _buildSectionTitle('time_setting'.tr, context),
          _buildGroupContainer(
            context: context,
            child: Obx(() {
              final taskController = Get.find<TaskController>();
              return Column(
                children: [
                  _buildRadioRow(
                    context: context,
                    title: 'time_countdown'.tr,
                    isSelected: taskController.showAsCountdown.value,
                    onTap: () {
                      if (!taskController.showAsCountdown.value) taskController.toggleTimeDisplayMode();
                    },
                    isLast: false,
                  ),
                  _buildRadioRow(
                    context: context,
                    title: 'time_deadline'.tr,
                    isSelected: !taskController.showAsCountdown.value,
                    onTap: () {
                      if (taskController.showAsCountdown.value) taskController.toggleTimeDisplayMode();
                    },
                    isLast: true,
                  ),
                ],
              );
            }),
          ),
          
          const SizedBox(height: 24),
          _buildSectionTitle('language'.tr, context),
          _buildGroupContainer(
            context: context,
            child: Obx(() => Column(
              children: [
                _buildRadioRow(
                  context: context,
                  title: 'system_default'.tr,
                  isSelected: settingsController.selectedLanguage.value == 'system',
                  onTap: () => settingsController.changeLanguage('system'),
                  isLast: false,
                ),
                _buildRadioRow(
                  context: context,
                  title: 'english'.tr,
                  isSelected: settingsController.selectedLanguage.value == 'en_US',
                  onTap: () => settingsController.changeLanguage('en_US'),
                  isLast: false,
                ),
                _buildRadioRow(
                  context: context,
                  title: 'chinese'.tr,
                  isSelected: settingsController.selectedLanguage.value == 'zh_CN',
                  onTap: () => settingsController.changeLanguage('zh_CN'),
                  isLast: true,
                ),
              ],
            )),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6) ?? Colors.grey.shade600,
          fontFamily: 'Inter',
        ),
      ),
    );
  }

  Widget _buildGroupContainer({required BuildContext context, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ]
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: child,
      ),
    );
  }

  Widget _buildRadioRow({
    required BuildContext context,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isLast,
    Widget? leading,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dividerColor = isDark ? Colors.white12 : Colors.black.withOpacity(0.05);
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: isLast ? null : Border(bottom: BorderSide(color: dividerColor, width: 1)),
          ),
          child: Row(
            children: [
              if (leading != null) ...[
                leading,
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
              if (isSelected)
                Icon(CupertinoIcons.checkmark_alt, color: Theme.of(context).primaryColor, size: 22)
            ],
          ),
        ),
      ),
    );
  }
}
