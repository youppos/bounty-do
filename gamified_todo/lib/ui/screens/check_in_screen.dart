import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/task_controller.dart';
import '../../models/check_in_model.dart';

class CheckInScreen extends StatefulWidget {
  final Function(CheckInModel item, Offset tapPosition)? onCheckIn;
  const CheckInScreen({super.key, this.onCheckIn});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  final TaskController taskController = Get.find();

  IconData _getIconForTitle(String title) {
    final t = title.toLowerCase();
    if (t.contains('水') || t.contains('water') || t.contains('喝')) {
      return Icons.local_drink;
    } else if (t.contains('跑') || t.contains('运') || t.contains('锻炼') || t.contains('健身') || t.contains('gym') || t.contains('workout')) {
      return Icons.directions_run;
    } else if (t.contains('起') || t.contains('早') || t.contains('wake') || t.contains('morning')) {
      return Icons.wb_sunny;
    } else if (t.contains('书') || t.contains('读') || t.contains('read') || t.contains('学')) {
      return Icons.menu_book;
    } else if (t.contains('睡') || t.contains('晚') || t.contains('sleep') || t.contains('night')) {
      return Icons.nights_stay;
    } else if (t.contains('吃') || t.contains('餐') || t.contains('eat') || t.contains('food')) {
      return Icons.restaurant;
    }
    return Icons.task_alt;
  }

  Color _getIconColor(String title, bool isSelected) {
    if (isSelected) return Colors.white;
    final t = title.toLowerCase();
    if (t.contains('水') || t.contains('water') || t.contains('喝')) {
      return Colors.blueAccent;
    } else if (t.contains('跑') || t.contains('运') || t.contains('锻炼') || t.contains('健身') || t.contains('gym') || t.contains('workout')) {
      return Colors.orangeAccent;
    } else if (t.contains('起') || t.contains('早') || t.contains('wake') || t.contains('morning')) {
      return Colors.amber;
    } else if (t.contains('书') || t.contains('读') || t.contains('read') || t.contains('学')) {
      return Colors.purpleAccent;
    } else if (t.contains('睡') || t.contains('晚') || t.contains('sleep') || t.contains('night')) {
      return Colors.indigoAccent;
    }
    return Colors.tealAccent;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Obx(() {
        final list = taskController.checkIns;
        final todayStr = DateTime.now().toString().split(' ')[0];

        if (list.isEmpty) {
          return Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.alarm_on_outlined,
                    size: 64,
                    color: isDark ? Colors.white24 : Colors.black26,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '暂无打卡项目，快去添加吧！',
                    style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.black54,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final item = list[index];
            final isCompletedToday = item.history.contains(todayStr);
            final icon = _getIconForTitle(item.title);
            final iconColor = _getIconColor(item.title, isCompletedToday);

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isCompletedToday
                    ? (isDark ? Colors.green.withOpacity(0.15) : Colors.green.withOpacity(0.08))
                    : (isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.6)),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isCompletedToday
                      ? Colors.green.withOpacity(0.4)
                      : (isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05)),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isCompletedToday
                        ? Colors.green.withOpacity(0.05)
                        : Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  child: Row(
                    children: [
                      // Icon Container
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: isCompletedToday
                              ? Colors.green
                              : (isDark ? Colors.white12 : Colors.grey.shade100),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          icon,
                          color: iconColor,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Text Column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                                decoration: isCompletedToday ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                // Level Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: item.levelIndex == 0
                                        ? Colors.blue.withOpacity(0.15)
                                        : Colors.red.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    item.levelIndex == 0 ? '一般' : '重要',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: item.levelIndex == 0 ? Colors.blue : Colors.redAccent,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Reminder Time
                                if (item.reminderTime != null) ...[
                                  Icon(Icons.access_time, size: 12, color: isDark ? Colors.white60 : Colors.black54),
                                  const SizedBox(width: 2),
                                  Text(
                                    item.reminderTime!,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? Colors.white60 : Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                // History count
                                Icon(Icons.calendar_today, size: 11, color: isDark ? Colors.white60 : Colors.black54),
                                const SizedBox(width: 2),
                                Text(
                                  '已打卡 ${item.history.length} 天',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? Colors.white60 : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Check-in Button or Popup Menu
                      GestureDetector(
                        onTapDown: (details) {
                          if (isCompletedToday) {
                            // If completed, let's just toggle check-in back to uncompleted
                            taskController.toggleCheckInStatus(item.id, todayStr);
                          } else {
                            // Complete! Trigger flying coin animation using tap position
                            if (widget.onCheckIn != null) {
                              widget.onCheckIn!(item, details.globalPosition);
                            } else {
                              taskController.toggleCheckInStatus(item.id, todayStr);
                            }
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: isCompletedToday
                                ? null
                                : LinearGradient(
                                    colors: [primaryColor, primaryColor.withOpacity(0.8)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                            color: isCompletedToday
                                ? (isDark ? Colors.white12 : Colors.grey.shade200)
                                : null,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: isCompletedToday
                                ? null
                                : [
                                    BoxShadow(
                                      color: primaryColor.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isCompletedToday ? Icons.check : Icons.check_circle_outline,
                                color: isCompletedToday
                                    ? (isDark ? Colors.greenAccent : Colors.green.shade700)
                                    : Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isCompletedToday ? '已打卡' : '打卡',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isCompletedToday
                                      ? (isDark ? Colors.greenAccent : Colors.green.shade700)
                                      : Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      // More popup menu for edit/delete
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert, color: isDark ? Colors.white60 : Colors.black45),
                        color: Theme.of(context).scaffoldBackgroundColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        onSelected: (action) {
                          if (action == 'edit') {
                            showAddOrEditCheckInDialog(context, item);
                          } else if (action == 'delete') {
                            taskController.deleteCheckIn(item.id);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 18),
                                SizedBox(width: 8),
                                Text('编辑'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red, size: 18),
                                SizedBox(width: 8),
                                Text('删除', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }),
      // floatingActionButton removed to match HomeScreen's global FAB
    );
  }
}

void showAddOrEditCheckInDialog(BuildContext context, CheckInModel? existingItem) {
  final taskController = Get.find<TaskController>();
  final titleController = TextEditingController(text: existingItem?.title ?? '');
    int selectedLevel = existingItem?.levelIndex ?? 0;
    String? selectedTime = existingItem?.reminderTime;

    showDialog(
      context: context,
      builder: (context) {
        final isDarkDialog = Theme.of(context).brightness == Brightness.dark;
        return Dialog(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        existingItem == null ? '添加每日打卡' : '修改打卡项目',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: titleController,
                        style: TextStyle(color: isDarkDialog ? Colors.white : Colors.black87),
                        decoration: InputDecoration(
                          labelText: '打卡名称 (如: 喝水、早起)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('打卡等级', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Center(child: Text('一般 (奖励 5金币)')),
                              selected: selectedLevel == 0,
                              selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                              labelStyle: TextStyle(
                                color: selectedLevel == 0
                                    ? Theme.of(context).primaryColor
                                    : (isDarkDialog ? Colors.white70 : Colors.black87),
                                fontWeight: selectedLevel == 0 ? FontWeight.bold : FontWeight.normal,
                              ),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              onSelected: (val) {
                                if (val) setModalState(() => selectedLevel = 0);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ChoiceChip(
                              label: const Center(child: Text('重要 (奖励 15金币)')),
                              selected: selectedLevel == 1,
                              selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                              labelStyle: TextStyle(
                                color: selectedLevel == 1
                                    ? Theme.of(context).primaryColor
                                    : (isDarkDialog ? Colors.white70 : Colors.black87),
                                fontWeight: selectedLevel == 1 ? FontWeight.bold : FontWeight.normal,
                              ),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              onSelected: (val) {
                                if (val) setModalState(() => selectedLevel = 1);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text('每日提醒时间', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: Icon(Icons.access_time, color: Theme.of(context).primaryColor),
                              label: Text(
                                selectedTime == null ? '未设置提醒' : selectedTime!,
                                style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                              ),
                              onPressed: () async {
                                final initialTime = selectedTime != null
                                    ? TimeOfDay(
                                        hour: int.parse(selectedTime!.split(':')[0]),
                                        minute: int.parse(selectedTime!.split(':')[1]),
                                      )
                                    : TimeOfDay.now();
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: initialTime,
                                );
                                if (time != null) {
                                  setModalState(() {
                                    selectedTime = "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
                                  });
                                }
                              },
                            ),
                          ),
                          if (selectedTime != null) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.clear, color: Colors.red),
                              onPressed: () {
                                setModalState(() {
                                  selectedTime = null;
                                });
                              },
                            )
                          ]
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('取消'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              if (titleController.text.trim().isEmpty) return;

                              if (existingItem == null) {
                                // Create
                                final newCheckIn = CheckInModel(
                                  title: titleController.text.trim(),
                                  levelIndex: selectedLevel,
                                  reminderTime: selectedTime,
                                );
                                taskController.addCheckIn(newCheckIn);
                              } else {
                                // Update
                                final updated = existingItem.copyWith(
                                  title: titleController.text.trim(),
                                  levelIndex: selectedLevel,
                                  reminderTime: selectedTime,
                                );
                                taskController.updateCheckIn(existingItem.id, updated);
                              }
                              Navigator.pop(context);
                            },
                            child: const Text('确定'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
