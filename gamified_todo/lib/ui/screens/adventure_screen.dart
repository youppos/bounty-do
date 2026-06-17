import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/task_controller.dart';
import '../../controllers/skill_controller.dart';
import '../theme/app_theme.dart';

class AdventureScreen extends StatelessWidget {
  const AdventureScreen({super.key});

  double _getLevelProgress(int coins) {
    if (coins < 100) return coins / 100.0;
    if (coins < 500) return (coins - 100) / 400.0;
    if (coins < 1000) return (coins - 500) / 500.0;
    int base = 1000 + ((coins - 1000) ~/ 2000) * 2000;
    return (coins - base) / 2000.0;
  }

  int _getCoinsForNextLevel(int coins) {
    if (coins < 100) return 100;
    if (coins < 500) return 500;
    if (coins < 1000) return 1000;
    return 1000 + (((coins - 1000) ~/ 2000) + 1) * 2000;
  }

  int _getCoinsForCurrentLevel(int coins) {
    if (coins < 100) return 0;
    if (coins < 500) return 100;
    if (coins < 1000) return 500;
    return 1000 + ((coins - 1000) ~/ 2000) * 2000;
  }

  String _formatExpiry(DateTime expiry) {
    final diff = expiry.difference(DateTime.now());
    if (diff.isNegative) return "0h 0m";
    final hours = diff.inHours;
    final mins = diff.inMinutes % 60;
    return 'buff_expires'.trParams({
      'hours': hours.toString().padLeft(2, '0'),
      'minutes': mins.toString().padLeft(2, '0'),
    });
  }

  @override
  Widget build(BuildContext context) {
    final taskController = Get.find<TaskController>();
    final skillController = Get.find<SkillController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final coins = taskController.totalCoins.value;
      final level = taskController.userLevel;
      final title = taskController.userTitle;
      
      final currentLevelCoins = _getCoinsForCurrentLevel(coins);
      final nextLevelCoins = _getCoinsForNextLevel(coins);
      final progress = _getLevelProgress(coins);
      final progressPercent = (progress * 100).toInt();

      final completedTasks = taskController.tasks.where((t) => t.isCompleted).toList();
      // Sort completed tasks by last modified/created or default order
      // Let's sort so latest completed appears first (mocking completion time, or just default)
      completedTasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      final hasDoubleGold = skillController.doubleGoldCharges.value > 0;
      final hasShield = skillController.isShieldActive;

      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Player Card (Level & Experience)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? Colors.black26 : Colors.white54,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 60, height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.amber, Colors.orange.shade700],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                          )
                        ]
                      ),
                      child: const Center(
                        child: Icon(Icons.person, color: Colors.white, size: 36),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18, 
                              fontWeight: FontWeight.bold, 
                              color: Colors.amber, 
                              fontStyle: FontStyle.italic
                            ),
                          ),
                          Text(
                            "${'player_level'.tr} $level",
                            style: TextStyle(
                              fontSize: 22, 
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : Colors.black87,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'xp_to_next'.tr,
                      style: TextStyle(
                        fontSize: 12, 
                        fontWeight: FontWeight.w600, 
                        color: isDark ? Colors.white60 : Colors.black54
                      ),
                    ),
                    Text(
                      "$coins / $nextLevelCoins Gold ($progressPercent%)",
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Inter'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 12,
                    backgroundColor: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // 2. Active Buffs Container
          Text(
            'active_buffs'.tr.toUpperCase(),
            style: TextStyle(
              fontSize: 13, 
              fontWeight: FontWeight.bold, 
              color: isDark ? Colors.white.withOpacity(0.5) : Colors.black54,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.black26 : Colors.white54,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: (!hasDoubleGold && !hasShield)
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'no_quests'.tr,
                        style: TextStyle(color: isDark ? Colors.white38 : Colors.grey),
                      ),
                    ),
                  )
                : Column(
                    children: [
                      if (hasDoubleGold)
                        _buildBuffRow(
                          icon: Icons.auto_awesome,
                          color: Colors.amber,
                          title: 'buff_double_gold'.tr,
                          subtitle: "x${skillController.doubleGoldCharges.value} ${'remaining_time'.trParams({'days': '00', 'hours': '00', 'minutes': '00'}) == 'overdue'.tr ? '' : 'charges'}",
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.amber.withOpacity(0.3)),
                            ),
                            child: Text(
                              'buff_active'.tr,
                              style: const TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      if (hasDoubleGold && hasShield) const Divider(height: 16, color: Colors.white12),
                      if (hasShield)
                        _buildBuffRow(
                          icon: Icons.shield,
                          color: Colors.blue,
                          title: 'buff_shield'.tr,
                          subtitle: _formatExpiry(skillController.shieldExpiry.value!),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.blue.withOpacity(0.3)),
                            ),
                            child: Text(
                              'buff_active'.tr,
                              style: const TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
          
          const SizedBox(height: 24),
          
          // 3. Completed Quest Log (History)
          Text(
            'completed_quests'.tr.toUpperCase(),
            style: TextStyle(
              fontSize: 13, 
              fontWeight: FontWeight.bold, 
              color: isDark ? Colors.white.withOpacity(0.5) : Colors.black54,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          
          if (completedTasks.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? Colors.black26 : Colors.white54,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Center(
                child: Text(
                  'no_quests'.tr,
                  style: TextStyle(color: isDark ? Colors.white38 : Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: completedTasks.length,
              itemBuilder: (context, index) {
                final task = completedTasks[index];
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black12 : Colors.white38,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: task.levelColor.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.check, color: task.levelColor, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.title,
                              style: TextStyle(
                                fontSize: 15, 
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.lineThrough,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'quest_completed_at'.trParams({
                                'time': "${task.createdAt.month.toString().padLeft(2, '0')}-${task.createdAt.day.toString().padLeft(2, '0')} ${task.createdAt.hour.toString().padLeft(2, '0')}:${task.createdAt.minute.toString().padLeft(2, '0')}",
                              }),
                              style: TextStyle(
                                fontSize: 11, 
                                color: isDark ? Colors.white.withOpacity(0.38) : Colors.black38
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        children: [
                          const Icon(Icons.monetization_on, color: Colors.amber, size: 14),
                          const SizedBox(width: 2),
                          Text(
                            "+${task.coinReward}",
                            style: const TextStyle(
                              fontSize: 13, 
                              fontWeight: FontWeight.bold, 
                              color: Colors.amber,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                );
              },
            ),
        ],
      );
    });
  }

  Widget _buildBuffRow({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        trailing,
      ],
    );
  }
}
