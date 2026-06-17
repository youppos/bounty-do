import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/settings_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../controllers/task_controller.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showGameplayGuide(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade900.withOpacity(0.95) : Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 10),
                )
              ]
            ),
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.sports_esports_rounded, color: Theme.of(context).primaryColor, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'gameplay_guide_title'.tr,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: isDark ? Colors.white60 : Colors.black54, size: 20),
                        onPressed: () => Navigator.pop(context),
                      )
                    ],
                  ),
                  const Divider(height: 20, color: Colors.white24),
                  Text(
                    'gameplay_guide'.tr,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: isDark ? Colors.white70 : Colors.black87,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

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
          _buildSectionTitle('gameplay_guide_title'.tr, context),
          _buildGroupContainer(
            context: context,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showGameplayGuide(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Row(
                    children: [
                      Icon(Icons.help_center_rounded, color: Theme.of(context).primaryColor, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'gameplay_guide_title'.tr,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          _buildSectionTitle('preset_title'.tr, context),
          _buildGroupContainer(
            context: context,
            child: Obx(() {
              List<Widget> children = [];
              final presetNames = [
                '一般/重要/紧急/重要且紧急/极其重要紧急', // Eisenhower
                '普通/优秀/稀有/史诗/传说', // RPG
                '微耗能/轻度专注/深度专注/核心挑战/极限突破', // Focus
                '日常琐事/自我提升/工作学习/关键里程碑/终极挑战', // Life Pillars
                '★☆☆☆☆/★★☆☆☆/★★★☆☆/★★★★☆/★★★★★', // Stars
                'preset_custom'.tr // Custom
              ];
              
              for (int i = 0; i < presetNames.length; i++) {
                children.add(_buildRadioRow(
                  context: context,
                  title: presetNames[i],
                  isSelected: settingsController.selectedPresetIndex.value == i,
                  onTap: () => settingsController.changePresetIndex(i),
                  isLast: i == presetNames.length - 1 && settingsController.selectedPresetIndex.value != 5,
                ));
              }
              
              if (settingsController.selectedPresetIndex.value == 5) {
                children.add(
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.01),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'preset_custom'.tr,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...List.generate(5, (levelIdx) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Text('${levelIdx + 1}: ', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontFamily: 'Inter')),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: settingsController.customNameControllers[levelIdx],
                                    style: const TextStyle(fontSize: 15, fontFamily: 'Inter'),
                                    decoration: InputDecoration(
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  )
                );
              }
              
              return Column(children: children);
            }),
          ),

          const SizedBox(height: 24),
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
