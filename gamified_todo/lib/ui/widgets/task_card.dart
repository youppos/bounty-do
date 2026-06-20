import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/task_model.dart';
import '../../controllers/task_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../controllers/skill_controller.dart';

class TaskCard extends StatefulWidget {
  final TaskModel task;
  final Function(Offset tapPosition) onComplete;
  final VoidCallback? onEdit;
  final VoidCallback? onSetTime;
  final bool isGrid;
  final int index;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onLongPress;

  const TaskCard({
    super.key,
    required this.task,
    required this.onComplete,
    this.onEdit,
    this.onSetTime,
    this.isGrid = false,
    this.index = 0,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onLongPress,
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

  String _formatRelativeTime(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inMinutes < 1) {
      return 'just_now'.tr;
    } else if (difference.inHours < 1) {
      return 'minutes_ago'.trParams({'mins': difference.inMinutes.toString()});
    } else if (difference.inDays < 1) {
      return 'hours_ago'.trParams({'hours': difference.inHours.toString()});
    } else {
      return 'days_ago'.trParams({'days': difference.inDays.toString()});
    }
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


  void _showSetTimeGuidanceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Dialog(
          backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.access_time_rounded, size: 48, color: Colors.amber.shade700),
                const SizedBox(height: 16),
                Text(
                  'set_time_first_title'.tr,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'set_time_first_msg'.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'cancel'.tr,
                          style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: Colors.amber.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          widget.onSetTime?.call();
                        },
                        child: Text('set_now'.tr),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Color priorityColor = widget.task.levelColor;
    
    double width = MediaQuery.of(context).size.width - 32;
    double height = widget.isGrid ? (width / 2 - 4) : 84.0; // Strictly fixed height for list mode

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

      // Define Rarity Icon
      IconData rarityIcon = Icons.circle;
      switch (widget.task.levelIndex) {
        case 0:
          rarityIcon = Icons.radio_button_unchecked;
          break;
        case 1:
          rarityIcon = Icons.grade_rounded;
          break;
        case 2:
          rarityIcon = Icons.shield_rounded;
          break;
        case 3:
          rarityIcon = Icons.offline_bolt_rounded;
          break;
        case 4:
          rarityIcon = Icons.emoji_events_rounded;
          break;
      }

      final innerChild = ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (widget.isSelectionMode) ...[
                  Icon(
                    widget.isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                    color: widget.isSelected ? priorityColor : Colors.grey,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                ],
                
                // Left App-Icon Style Rarity Indicator (only in list mode)
                if (!widget.isGrid) ...[
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: priorityColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Icon(
                        rarityIcon,
                        color: priorityColor,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],

                // Middle Info Section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Row 1: Rarity Tag + Overdue Info + Spacer + Time/Deadline
                      Row(
                        children: [
                          Text(
                            settingsController.getLevelName(widget.task.levelIndex),
                            style: TextStyle(
                              color: priorityColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Inter',
                            ),
                          ),
                          if (isOverdue) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: isShieldActive ? Colors.blue.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isShieldActive ? 'buff_shield'.tr : 'overdue'.tr,
                                style: TextStyle(
                                  color: isShieldActive ? Colors.blue : Colors.red,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ),
                          ],
                          const Spacer(),
                          // Time display on the right
                          Obx(() {
                            final showCountdown = taskController.showAsCountdown.value;
                            String timeText = "";
                            if (widget.task.deadline != null) {
                              timeText = showCountdown
                                  ? _formatCountdown(widget.task.deadline!)
                                  : _formatDeadline(widget.task.deadline!);
                            } else {
                              timeText = _formatRelativeTime(widget.task.createdAt);
                            }
                            
                            return Text(
                              timeText,
                              style: TextStyle(
                                fontSize: 10,
                                color: isOverdue 
                                    ? (isShieldActive ? Colors.blue : Colors.red) 
                                    : (Theme.of(context).brightness == Brightness.dark ? Colors.white54 : Colors.black54),
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Inter',
                              ),
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 2),
                      // Row 2: Title
                      Text(
                        widget.task.title,
                        style: TextStyle(
                          fontSize: widget.isGrid ? 14 : 15,
                          fontWeight: FontWeight.bold,
                          color: widget.task.isCompleted 
                              ? Colors.grey 
                              : (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87),
                          decoration: widget.task.isCompleted ? TextDecoration.lineThrough : null,
                          fontFamily: 'Inter',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      // Row 3: Coins & Icons
                      Row(
                        children: [
                          Icon(
                            Icons.monetization_on, 
                            color: Theme.of(context).brightness == Brightness.light ? Colors.orange.shade800 : Colors.amber, 
                            size: 14,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            "+$finalDisplayReward",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).brightness == Brightness.light ? Colors.orange.shade800 : Colors.amber,
                              fontFamily: 'Inter',
                            ),
                          ),
                          if (doubleGoldMultiplier > 1) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0.5),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                "x2",
                                style: TextStyle(color: Colors.amber, fontSize: 8, fontWeight: FontWeight.w900),
                              ),
                            )
                          ],
                          
                          const Spacer(),
                          
                          // Alarm / Notification Indicators
                          if (widget.task.hasAlarm) ...[
                            GestureDetector(
                              onTap: () {
                                taskController.toggleAlarm(widget.task.id);
                              },
                              child: Icon(
                                Icons.alarm_on,
                                color: widget.task.isCompleted ? Colors.grey : priorityColor,
                                size: 14,
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          if (widget.task.hasReminder) ...[
                            GestureDetector(
                              onTap: () {
                                taskController.toggleReminder(widget.task.id);
                              },
                              child: Icon(
                                Icons.notifications_active,
                                color: widget.task.isCompleted ? Colors.grey : priorityColor,
                                size: 14,
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          
                          // Tiny edit/setting indicators if not active
                          if (!widget.task.hasAlarm && !widget.task.hasReminder) ...[
                            GestureDetector(
                              onTap: () {
                                if (widget.task.deadline == null) {
                                  _showSetTimeGuidanceDialog(context);
                                  return;
                                }
                                taskController.toggleAlarm(widget.task.id);
                              },
                              child: Icon(
                                Icons.alarm,
                                color: Colors.grey.withOpacity(0.4),
                                size: 14,
                              ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () {
                                if (widget.task.deadline == null) {
                                  _showSetTimeGuidanceDialog(context);
                                  return;
                                }
                                taskController.toggleReminder(widget.task.id);
                              },
                              child: Icon(
                                Icons.notifications_none,
                                color: Colors.grey.withOpacity(0.4),
                                size: 14,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Right side complete button
                GestureDetector(
                  onTapDown: (details) {
                    widget.onComplete(details.globalPosition);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4.0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.task.isCompleted 
                          ? Colors.grey.withOpacity(0.1) 
                          : priorityColor.withOpacity(0.1),
                    ),
                    child: Icon(
                      widget.task.isCompleted ? Icons.check_circle : Icons.check_circle_outline,
                      color: widget.task.isCompleted ? Colors.grey : priorityColor,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      return AnimatedBuilder(
        animation: _effectController,
        builder: (context, child) {
          double animValue = _effectController.value;
          
          double baseThickness = 0.0; // Borders are cancelled by user request
          double shadowOpacity = 0.06;
          double blurRadius = 8.0;
          double spreadRadius = 1.0;
          Gradient? borderGradient;

          if (effect == 1) { // Breathing (shadow glow pulses instead of border)
            double phaseOffset = (widget.index % 2 == 1) ? 0.5 : 0.0;
            double breathVal = (math.sin((animValue + phaseOffset) * 2 * math.pi) + 1) / 2;
            shadowOpacity = 0.04 + 0.12 * breathVal;
            blurRadius = 8.0 + 8.0 * breathVal;
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
            spreadRadius = 0.5 + 2.0 * pulse;
            shadowOpacity = 0.04 + 0.12 * pulse;
          }

          if (effect == 2 || effect == 3) {
            return Container(
              constraints: BoxConstraints(
                minHeight: height,
                maxHeight: height,
                minWidth: widget.isGrid ? height : 0.0,
                maxWidth: widget.isGrid ? height : double.infinity,
              ),
              margin: EdgeInsets.only(bottom: widget.isGrid ? 4 : 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: borderGradient,
                boxShadow: [
                  BoxShadow(
                    color: priorityColor.withOpacity(shadowOpacity),
                    blurRadius: blurRadius,
                    spreadRadius: spreadRadius,
                  )
                ]
              ),
              child: Padding(
                padding: EdgeInsets.all(baseThickness),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Theme.of(context).cardColor.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.4 : 0.7),
                  ),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: widget.isSelectionMode ? null : widget.onEdit,
                    onLongPress: widget.isSelectionMode ? null : widget.onLongPress,
                    child: innerChild,
                  ),
                ),
              ),
            );
          } else {
            return Container(
              constraints: BoxConstraints(
                minHeight: height,
                maxHeight: height,
                minWidth: widget.isGrid ? height : 0.0,
                maxWidth: widget.isGrid ? height : double.infinity,
              ),
              margin: EdgeInsets.only(bottom: widget.isGrid ? 4 : 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Theme.of(context).cardColor.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.4 : 0.7),
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
                onTap: widget.isSelectionMode ? null : widget.onEdit,
                onLongPress: widget.isSelectionMode ? null : widget.onLongPress,
                child: innerChild,
              ),
            );
          }
        },
      );
    });
  }
}
