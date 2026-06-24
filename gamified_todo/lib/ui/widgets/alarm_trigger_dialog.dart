import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/task_model.dart';
import '../../controllers/task_controller.dart';
import '../../controllers/settings_controller.dart';

class AlarmTriggerDialog extends StatefulWidget {
  final TaskModel task;

  const AlarmTriggerDialog({
    super.key,
    required this.task,
  });

  @override
  State<AlarmTriggerDialog> createState() => _AlarmTriggerDialogState();
}

class _AlarmTriggerDialogState extends State<AlarmTriggerDialog> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  final TaskController taskController = Get.find();
  final SettingsController settingsController = Get.find();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = widget.task.levelColor;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              width: 320,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? Colors.black.withOpacity(0.65) : Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: color.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.15),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Pulsing Alarm Icon
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      final scale = 1.0 + (_pulseController.value * 0.12);
                      final opacity = 0.5 + (_pulseController.value * 0.5);
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color.withOpacity(0.15 * opacity),
                            border: Border.all(color: color.withOpacity(0.4 * opacity), width: 2),
                          ),
                          child: Icon(
                            Icons.alarm,
                            color: color,
                            size: 40,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  
                  // Title Header
                  Text(
                    Get.locale?.languageCode == 'zh' ? '⏰ 时间到啦！' : '⏰ Time\'s Up!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Task Details Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
                    ),
                    child: Column(
                      children: [
                        // Rarity Tag
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            settingsController.getLevelName(widget.task.levelIndex),
                            style: TextStyle(
                              color: color,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Task Title
                        Text(
                          widget.task.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                            fontFamily: 'Inter',
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        // Coins Reward
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.monetization_on,
                              color: isDark ? Colors.amber : Colors.orange.shade800,
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "+${widget.task.coinReward}",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.amber : Colors.orange.shade800,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Action Buttons
                  // Button 1: Complete Now (Gamer Theme Style)
                  Container(
                    width: double.infinity,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color, color.withOpacity(0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        taskController.completeAlarmTask(widget.task.id);
                      },
                      child: Text(
                        Get.locale?.languageCode == 'zh' ? '🏆 立即去完成' : '🏆 Complete Now',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'Inter'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Button 2: Snooze 10 Minutes
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: color,
                        side: BorderSide(color: color.withOpacity(0.5), width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        taskController.snoozeAlarm(widget.task.id);
                      },
                      child: Text(
                        Get.locale?.languageCode == 'zh' ? '⏰ 延时 10 分钟' : '⏰ Snooze 10m',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Inter'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Button 3: Dismiss
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: isDark ? Colors.white54 : Colors.black45,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        taskController.dismissAlarm();
                      },
                      child: Text(
                        Get.locale?.languageCode == 'zh' ? '直接关闭声音' : 'Dismiss Sound',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, fontFamily: 'Inter'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
