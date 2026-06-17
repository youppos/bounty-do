import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/task_model.dart';
import '../../controllers/task_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../controllers/skill_controller.dart';
import '../../utils/snackbar_utils.dart';

class TaskCard extends StatefulWidget {
  final TaskModel task;
  final Function(Offset tapPosition) onComplete;
  final VoidCallback? onEdit;
  final bool isGrid;
  final int index;

  const TaskCard({
    super.key,
    required this.task,
    required this.onComplete,
    this.onEdit,
    this.isGrid = false,
    this.index = 0,
  });

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> with SingleTickerProviderStateMixin {
  Timer? _timer;
  final TaskController taskController = Get.find();
  final SettingsController settingsController = Get.find();
  final SkillController skillController = Get.find<SkillController>();
  late AnimationController _effectController;

  @override
  void initState() {
    super.initState();
    _startTimerIfNeeded();
    _effectController = AnimationController(vsync: this, duration: const Duration(seconds: 3));
    if (settingsController.taskLightEffect.value != 0) {
      _effectController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant TaskCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.task.deadline != oldWidget.task.deadline) {
      _timer?.cancel();
      _startTimerIfNeeded();
    }
  }

  void _startTimerIfNeeded() {
    if (widget.task.deadline != null) {
      _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
        if (mounted) {
          setState(() {});
        }
      });
    }
  }

  @override
  void dispose() {
    _effectController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  String _formatCountdown(DateTime deadline) {
    final difference = deadline.difference(DateTime.now());
    if (difference.isNegative) {
      return 'overdue'.tr;
    }
    final days = difference.inDays;
    final hours = difference.inHours % 24;
    final minutes = difference.inMinutes % 60;
    
    return 'remaining_time'.trParams({
      'days': days.toString().padLeft(2, '0'),
      'hours': hours.toString().padLeft(2, '0'),
      'minutes': minutes.toString().padLeft(2, '0'),
    });
  }

  String _formatDeadline(DateTime deadline) {
    final year = deadline.year.toString();
    final month = deadline.month.toString().padLeft(2, '0');
    final day = deadline.day.toString().padLeft(2, '0');
    final hour = deadline.hour.toString().padLeft(2, '0');
    final minute = deadline.minute.toString().padLeft(2, '0');
    
    return 'deadline_format'.trParams({
      'year': year,
      'month': month,
      'day': day,
      'hour': hour,
      'minute': minute,
    });
  }

  String _getCoinRewardHint() {
    if (widget.task.deadline == null || widget.task.isCompleted) return "";
    final now = DateTime.now();
    if (now.isAfter(widget.task.deadline!)) {
      return "";
    }
    
    final totalDurationMs = widget.task.deadline!.difference(widget.task.createdAt).inMilliseconds;
    final elapsedMs = now.difference(widget.task.createdAt).inMilliseconds;
    
    if (elapsedMs <= totalDurationMs * 0.25) {
      final maxCoins = TaskModel.getMaxCoinsForLevel(widget.task.levelIndex);
      final thresholdTime = widget.task.createdAt.add(Duration(milliseconds: (totalDurationMs * 0.25).toInt()));
      final timeStr = "${thresholdTime.hour.toString().padLeft(2, '0')}:${thresholdTime.minute.toString().padLeft(2, '0')}";
      return 'coin_decay_warning'.trParams({
        'time': timeStr,
        'coins': maxCoins.toString(),
      });
    } else {
      final currentCoins = widget.task.calculateRewardAt(now);
      return 'coin_current_warning'.trParams({
        'coins': currentCoins.toString(),
      });
    }
  }

  // Helper to get task level badge properties using presets Custom names
  Widget _buildLevelBadge(int levelIndex) {
    String label = settingsController.getLevelName(levelIndex);
    IconData icon = Icons.circle;
    Color color = widget.task.levelColor;

    switch (levelIndex) {
      case 0:
        icon = Icons.radio_button_unchecked;
        break;
      case 1:
        icon = Icons.grade;
        break;
      case 2:
        icon = Icons.shield;
        break;
      case 3:
        icon = Icons.offline_bolt;
        break;
      case 4:
        icon = Icons.emoji_events;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold, fontFamily: 'Inter'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color priorityColor = widget.task.levelColor;
    
    double width = MediaQuery.of(context).size.width - 32;
    double height = widget.isGrid ? (width / 2 - 4) : width / 2.5; // Increased slightly for hints

    return Obx(() {
      final effect = settingsController.taskLightEffect.value;
      if (effect == 0) {
        if (_effectController.isAnimating) _effectController.stop();
      } else {
        if (!_effectController.isAnimating) _effectController.repeat();
      }

      // Check overdue and calculate rewards
      final now = DateTime.now();
      final isOverdue = widget.task.deadline != null && widget.task.deadline!.isBefore(now) && !widget.task.isCompleted;
      final isShieldActive = skillController.isShieldActive;
      final doubleGoldMultiplier = skillController.doubleGoldCharges.value > 0 ? 2 : 1;
      
      // Calculate dynamic current reward (frozen if task is completed)
      int displayReward;
      if (widget.task.isCompleted) {
        displayReward = widget.task.coinReward;
      } else {
        displayReward = widget.task.calculateRewardAt(now);
        if (isOverdue && isShieldActive) {
          displayReward = TaskModel.getMinCoinsForLevel(widget.task.levelIndex);
        }
      }
      
      int finalDisplayReward = displayReward * doubleGoldMultiplier;
      final hintText = _getCoinRewardHint();

      return AnimatedBuilder(
        animation: _effectController,
        builder: (context, child) {
          double animValue = _effectController.value;
          
          double baseThickness = 3.0;
          int thicknessIndex = settingsController.taskBorderThickness.value;
          if (thicknessIndex == 0) baseThickness = 1.5;
          else if (thicknessIndex == 2) baseThickness = 5.0;

          double borderOpacity = 0.5;
          double shadowOpacity = 0.1;
          double blurRadius = 10.0;
          double spreadRadius = 2.0;
          Gradient? borderGradient;

          if (effect == 1) { // Breathing
            double phaseOffset = (widget.index % 2 == 1) ? 0.5 : 0.0;
            double breathVal = (math.sin((animValue + phaseOffset) * 2 * math.pi) + 1) / 2;
            borderOpacity = 0.2 + 0.6 * breathVal;
            shadowOpacity = 0.05 + 0.2 * breathVal;
            blurRadius = 10.0 + 10.0 * breathVal;
          } else if (effect == 2) { // Marquee
            borderGradient = SweepGradient(
              colors: [priorityColor.withOpacity(0.1), priorityColor, priorityColor.withOpacity(0.1)],
              stops: const [0.0, 0.5, 1.0],
              transform: GradientRotation(animValue * 2 * math.pi),
            );
          } else if (effect == 3) { // Shimmer
            borderGradient = LinearGradient(
              colors: [priorityColor.withOpacity(0.2), priorityColor, priorityColor.withOpacity(0.2)],
              stops: [animValue - 0.2, animValue, animValue + 0.2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            );
          } else if (effect == 4) { // Pulse
            double pulse = (math.sin(animValue * 4 * math.pi) + 1) / 2;
            spreadRadius = 1.0 + 4.0 * pulse;
            borderOpacity = 0.3 + 0.5 * pulse;
          }

          final innerChild = ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  _buildLevelBadge(widget.task.levelIndex),
                                  if (isOverdue) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isShieldActive ? Colors.blue.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isShieldActive ? Colors.blue.withOpacity(0.5) : Colors.red.withOpacity(0.5),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            isShieldActive ? Icons.shield : Icons.warning_amber_rounded,
                                            size: 10,
                                            color: isShieldActive ? Colors.blue : Colors.red,
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            isShieldActive ? 'buff_shield'.tr : 'overdue'.tr,
                                            style: TextStyle(
                                              color: isShieldActive ? Colors.blue : Colors.red,
                                              fontSize: 8,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Inter',
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  ]
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                widget.task.title,
                                style: TextStyle(
                                  fontSize: widget.isGrid ? 14 : 16,
                                  fontWeight: FontWeight.bold,
                                  color: widget.task.isCompleted 
                                      ? Colors.grey 
                                      : (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87),
                                  decoration: widget.task.isCompleted ? TextDecoration.lineThrough : null,
                                  fontFamily: 'Inter',
                                ),
                                maxLines: widget.isGrid ? 1 : 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Obx(() {
                                final showCountdown = taskController.showAsCountdown.value;
                                String timeText = "";
                                if (widget.task.deadline != null) {
                                  timeText = showCountdown
                                      ? _formatCountdown(widget.task.deadline!)
                                      : _formatDeadline(widget.task.deadline!);
                                }
                                
                                if (timeText.isEmpty) return const SizedBox.shrink();

                                return Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Row(
                                    children: [
                                      Icon(
                                        showCountdown ? Icons.timer_outlined : Icons.calendar_today_outlined,
                                        size: 11,
                                        color: isOverdue 
                                            ? (isShieldActive ? Colors.blue : Colors.red) 
                                            : (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        timeText,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isOverdue 
                                              ? (isShieldActive ? Colors.blue : Colors.red) 
                                              : (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54),
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Inter',
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                              if (hintText.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.flash_on, size: 11, color: Colors.amber),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          hintText,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Theme.of(context).brightness == Brightness.dark ? Colors.amber.shade200 : Colors.amber.shade900,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Inter',
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.monetization_on, color: Theme.of(context).brightness == Brightness.light ? Colors.orange.shade800 : Colors.amber, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                "+$finalDisplayReward",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).brightness == Brightness.light ? Colors.orange.shade800 : Colors.amber,
                                  fontFamily: 'Inter',
                                ),
                              ),
                              if (doubleGoldMultiplier > 1) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    "x2",
                                    style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.w900),
                                  ),
                                )
                              ]
                            ],
                          )
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTapDown: (details) {
                            widget.onComplete(details.globalPosition);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Icon(
                              widget.task.isCompleted ? Icons.check_circle : Icons.check_circle_outline,
                              color: widget.task.isCompleted ? Colors.grey : priorityColor,
                              size: 26,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            taskController.toggleAlarm(widget.task.id);
                            if (!widget.task.hasAlarm) {
                              SnackbarUtils.showSuccess(title: 'alarm_set'.tr, message: 'alarm_set_msg'.tr);
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Icon(
                              widget.task.hasAlarm ? Icons.alarm_on : Icons.alarm,
                              color: widget.task.isCompleted 
                                  ? Colors.grey 
                                  : (widget.task.hasAlarm ? priorityColor : (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54)),
                              size: 22,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            taskController.toggleReminder(widget.task.id);
                            if (!widget.task.hasReminder) {
                              SnackbarUtils.showSuccess(title: 'reminder_set'.tr, message: 'reminder_set_msg'.tr);
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Icon(
                              widget.task.hasReminder ? Icons.notifications_active : Icons.notifications_none,
                              color: widget.task.isCompleted 
                                  ? Colors.grey 
                                  : (widget.task.hasReminder ? priorityColor : (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54)),
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              ),
            ),
          );

          if (effect == 2 || effect == 3) {
            return Container(
              constraints: BoxConstraints(
                minHeight: height,
                minWidth: widget.isGrid ? height : width,
                maxWidth: widget.isGrid ? height : width,
              ),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(21.5),
                gradient: borderGradient,
                boxShadow: [
                  BoxShadow(
                    color: priorityColor.withOpacity(0.2),
                    blurRadius: 15,
                    spreadRadius: 1,
                  )
                ]
              ),
              child: Padding(
                padding: EdgeInsets.all(baseThickness),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Theme.of(context).cardColor.withOpacity(0.2),
                  ),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: widget.onEdit,
                    child: innerChild,
                  ),
                ),
              ),
            );
          } else {
            return Container(
              constraints: BoxConstraints(
                minHeight: height,
                minWidth: widget.isGrid ? height : width,
                maxWidth: widget.isGrid ? height : width,
              ),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Theme.of(context).cardColor.withOpacity(0.2),
                border: Border.all(color: priorityColor.withOpacity(borderOpacity), width: baseThickness),
                boxShadow: [
                  BoxShadow(
                    color: priorityColor.withOpacity(shadowOpacity),
                    blurRadius: blurRadius,
                    spreadRadius: spreadRadius,
                  )
                ]
              ),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onEdit,
                child: innerChild,
              ),
            );
          }
        },
      );
    });
  }
}
