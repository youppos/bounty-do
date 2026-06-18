import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/task_controller.dart';
import '../../models/check_in_model.dart';
import '../widgets/swipe_to_reveal.dart';
import '../widgets/check_in_history_dialog.dart';

class CheckInScreen extends StatefulWidget {
  final Function(CheckInModel item, Offset tapPosition)? onCheckIn;
  final Function(bool isSelectionMode)? onSelectionModeChanged;
  const CheckInScreen({super.key, this.onCheckIn, this.onSelectionModeChanged});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  final TaskController taskController = Get.find();
  bool _isSelectionMode = false;
  final Set<String> _selectedCheckInIds = {};
  bool _showTodayOnly = true;

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

  String _getFrequencyDescription(CheckInModel item) {
    switch (item.frequencyType) {
      case 'daily':
        return 'freq_daily'.tr;
      case 'weekly':
        if (item.weeklyDays.length == 7) {
          return 'freq_daily'.tr;
        }
        if (item.weeklyDays.length == 5 &&
            item.weeklyDays.contains(1) &&
            item.weeklyDays.contains(2) &&
            item.weeklyDays.contains(3) &&
            item.weeklyDays.contains(4) &&
            item.weeklyDays.contains(5)) {
          return 'freq_weekdays'.tr;
        }
        if (item.weeklyDays.length == 2 &&
            item.weeklyDays.contains(6) &&
            item.weeklyDays.contains(7)) {
          return 'freq_weekends'.tr;
        }
        final days = List<int>.from(item.weeklyDays)..sort();
        final names = days.map((d) {
          if (d == 1) return '一';
          if (d == 2) return '二';
          if (d == 3) return '三';
          if (d == 4) return '四';
          if (d == 5) return '五';
          if (d == 6) return '六';
          return '日';
        }).join('、');
        return '每周$names';
      case 'interval':
        return '每隔${item.intervalDays}天';
      case 'monthly':
        final days = List<int>.from(item.monthlyDays)..sort();
        return '每月${days.join('、')}号';
      default:
        return 'freq_daily'.tr;
    }
  }

  Widget _buildTabButton(String label, bool isSelected, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withOpacity(0.15)
              : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primaryColor.withOpacity(0.4) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? primaryColor : (isDark ? Colors.white70 : Colors.black87),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTabButton('show_today_only'.tr, _showTodayOnly, () => setState(() => _showTodayOnly = true)),
                const SizedBox(width: 12),
                _buildTabButton('show_all_checkins'.tr, !_showTodayOnly, () => setState(() => _showTodayOnly = false)),
              ],
            ),
          ),
          Expanded(
            child: Obx(() {
              final today = DateTime.now();
              final list = taskController.checkIns.where((item) {
                if (_showTodayOnly) {
                  return item.isDueOn(today);
                }
                return true;
              }).toList();

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
                          _showTodayOnly ? '今天没有需要打卡的项目哦！' : '暂无打卡项目，快去添加吧！',
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

              final listWidget = ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final item = list[index];
                  final todayStr = today.toString().split(' ')[0];
                  final isCompletedToday = item.history.contains(todayStr);
                  final icon = _getIconForTitle(item.title);
                  final iconColor = _getIconColor(item.title, isCompletedToday);
                  final isSelected = _selectedCheckInIds.contains(item.id);

                  Widget card = GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _isSelectionMode
                        ? () {
                            setState(() {
                              if (isSelected) {
                                _selectedCheckInIds.remove(item.id);
                                if (_selectedCheckInIds.isEmpty) {
                                  _isSelectionMode = false;
                                  widget.onSelectionModeChanged?.call(false);
                                }
                              } else {
                                _selectedCheckInIds.add(item.id);
                              }
                            });
                          }
                        : () => showAddOrEditCheckInDialog(context, item),
                    onLongPress: _isSelectionMode
                        ? null
                        : () {
                            setState(() {
                              _isSelectionMode = true;
                              _selectedCheckInIds.add(item.id);
                            });
                            widget.onSelectionModeChanged?.call(true);
                          },
                    child: Container(
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
                              if (_isSelectionMode) ...[
                                Icon(
                                  isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                                  color: isSelected ? primaryColor : Colors.grey,
                                  size: 22,
                                ),
                                const SizedBox(width: 12),
                              ],
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
                                    Wrap(
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      spacing: 8,
                                      runSpacing: 4,
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
                                        // Frequency Badge
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: primaryColor.withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            _getFrequencyDescription(item),
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: primaryColor,
                                            ),
                                          ),
                                        ),
                                        // Gold Coin Reward
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.monetization_on,
                                              color: isDark ? Colors.amber : Colors.orange.shade800,
                                              size: 13,
                                            ),
                                            const SizedBox(width: 2),
                                            Text(
                                              item.levelIndex == 0 ? '+1' : '+3',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: isDark ? Colors.amber : Colors.orange.shade800,
                                              ),
                                            ),
                                          ],
                                        ),
                                        // Reminder Time
                                        if (item.reminderTime != null)
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.access_time, size: 12, color: isDark ? Colors.white60 : Colors.black54),
                                              const SizedBox(width: 2),
                                              Text(
                                                item.reminderTime!,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: isDark ? Colors.white60 : Colors.black54,
                                                ),
                                              ),
                                            ],
                                          ),
                                        // History count
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
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
                                  ],
                                ),
                              ),
                              // Check-in History Button
                              if (!_isSelectionMode) ...[
                                GestureDetector(
                                  onTap: () {
                                    showCheckInHistoryDialog(context, item);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.calendar_month_outlined,
                                      color: isDark ? Colors.white70 : Colors.black54,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],
                              // Check-in Button
                              GestureDetector(
                                onTapDown: _isSelectionMode
                                    ? null
                                    : (details) {
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
                            ],
                          ),
                        ),
                      ),
                    ),
                  );

                  if (_isSelectionMode) {
                    return card;
                  }

                  return SwipeToReveal(
                    key: ValueKey(item.id),
                    actionWidth: 84,
                    actionButton: GestureDetector(
                      onTap: () => taskController.deleteCheckIn(item.id),
                      child: Container(
                        margin: const EdgeInsets.only(top: 8, bottom: 8, left: 6),
                        decoration: BoxDecoration(
                          color: Colors.red.shade600,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Center(
                          child: Icon(Icons.delete, color: Colors.white, size: 26),
                        ),
                      ),
                    ),
                    child: card,
                  );
                },
              );

              return Stack(
                children: [
                  listWidget,
                  if (_isSelectionMode)
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 80,
                      child: _buildBatchSelectBar(
                        allVisibleIds: list.map((c) => c.id).toList(),
                        onDelete: () {
                          _showDeleteCheckInsConfirmationDialog();
                        },
                      ),
                    ),
                ],
              );
            }),
          ),
        ],
      ),
      // floatingActionButton removed to match HomeScreen's global FAB
    );
  }

  void _showDeleteCheckInsConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            '确定删除所选打卡项目吗？',
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          ),
          content: Text(
            '删除后将无法恢复，确定要继续吗？',
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                for (var id in _selectedCheckInIds) {
                  taskController.deleteCheckIn(id);
                }
                setState(() {
                  _selectedCheckInIds.clear();
                  _isSelectionMode = false;
                });
                widget.onSelectionModeChanged?.call(false);
                Navigator.pop(context);
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBatchSelectBar({required List<String> allVisibleIds, required VoidCallback onDelete}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final isAllSelected = allVisibleIds.isNotEmpty &&
        allVisibleIds.every((id) => _selectedCheckInIds.contains(id));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 60,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xE61E1E2E) : const Color(0xE6FFFFFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black12,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          TextButton(
            onPressed: () {
              setState(() {
                _isSelectionMode = false;
                _selectedCheckInIds.clear();
              });
              widget.onSelectionModeChanged?.call(false);
            },
            child: Text(
              'cancel'.tr,
              style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
            ),
          ),
          const Spacer(),
          Text(
            '已选择 ${_selectedCheckInIds.length} 项',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          TextButton(
            onPressed: () {
              setState(() {
                if (isAllSelected) {
                  for (var id in allVisibleIds) {
                    _selectedCheckInIds.remove(id);
                  }
                } else {
                  _selectedCheckInIds.addAll(allVisibleIds);
                }
              });
            },
            child: Text(
              isAllSelected ? '取消全选' : '全选',
              style: TextStyle(color: primaryColor),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: _selectedCheckInIds.isEmpty ? null : onDelete,
          ),
        ],
      ),
    );
  }
}

void showAddOrEditCheckInDialog(BuildContext context, CheckInModel? existingItem) {
  final taskController = Get.find<TaskController>();
  final titleController = TextEditingController(text: existingItem?.title ?? '');
  int selectedLevel = existingItem?.levelIndex ?? 0;
  String? selectedTime = existingItem?.reminderTime;
  bool titleError = false;

  String selectedFreqType = existingItem?.frequencyType ?? 'daily';
  List<int> selectedWeeklyDays = List<int>.from(existingItem?.weeklyDays ?? [1, 2, 3, 4, 5, 6, 7]);
  int selectedIntervalDays = existingItem?.intervalDays ?? 2;
  String selectedStartDate = existingItem?.startDate ?? DateTime.now().toString().split(' ')[0];
  List<int> selectedMonthlyDays = List<int>.from(existingItem?.monthlyDays ?? [1]);

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
                      onChanged: (value) {
                        if (titleError && value.trim().isNotEmpty) {
                          setModalState(() => titleError = false);
                        }
                      },
                      decoration: InputDecoration(
                        labelText: '打卡名称 (如: 喝水、早起)',
                        errorText: titleError ? 'checkin_title_required'.tr : null,
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
                            label: const Center(child: Text('一般 (奖励 1金币)')),
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
                            label: const Center(child: Text('重要 (奖励 3金币)')),
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
                    Text('freq_type'.tr, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 8),
                    Row(
                      children: ['daily', 'weekly', 'interval', 'monthly'].map((type) {
                        String label = '';
                        if (type == 'daily') label = 'freq_daily'.tr;
                        if (type == 'weekly') label = 'freq_weekly'.tr;
                        if (type == 'interval') label = 'freq_interval'.tr;
                        if (type == 'monthly') label = 'freq_monthly'.tr;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: ChoiceChip(
                              label: Center(child: Text(label, style: const TextStyle(fontSize: 12))),
                              selected: selectedFreqType == type,
                              selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                              labelStyle: TextStyle(
                                color: selectedFreqType == type
                                    ? Theme.of(context).primaryColor
                                    : (isDarkDialog ? Colors.white70 : Colors.black87),
                                fontWeight: selectedFreqType == type ? FontWeight.bold : FontWeight.normal,
                              ),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              onSelected: (val) {
                                if (val) setModalState(() => selectedFreqType = type);
                              },
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    if (selectedFreqType == 'weekly') ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () {
                              setModalState(() {
                                selectedWeeklyDays = [1, 2, 3, 4, 5];
                              });
                            },
                            child: Text('freq_weekdays'.tr, style: TextStyle(color: Theme.of(context).primaryColor)),
                          ),
                          TextButton(
                            onPressed: () {
                              setModalState(() {
                                selectedWeeklyDays = [6, 7];
                              });
                            },
                            child: Text('freq_weekends'.tr, style: TextStyle(color: Theme.of(context).primaryColor)),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(7, (index) {
                          final day = index + 1;
                          final isSelected = selectedWeeklyDays.contains(day);
                          String label = '';
                          if (day == 1) label = '一';
                          if (day == 2) label = '二';
                          if (day == 3) label = '三';
                          if (day == 4) label = '四';
                          if (day == 5) label = '五';
                          if (day == 6) label = '六';
                          if (day == 7) label = '日';
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2),
                              child: GestureDetector(
                                onTap: () {
                                  setModalState(() {
                                    if (isSelected) {
                                      if (selectedWeeklyDays.length > 1) {
                                        selectedWeeklyDays.remove(day);
                                      }
                                    } else {
                                      selectedWeeklyDays.add(day);
                                    }
                                  });
                                },
                                child: Container(
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Theme.of(context).primaryColor
                                        : (isDarkDialog ? Colors.white12 : Colors.grey.shade100),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      label,
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : (isDarkDialog ? Colors.white70 : Colors.black87),
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      )
                    ],
                    if (selectedFreqType == 'interval') ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text('每隔', style: TextStyle(color: isDarkDialog ? Colors.white70 : Colors.black87)),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(Icons.remove_circle_outline, color: Theme.of(context).primaryColor),
                            onPressed: selectedIntervalDays > 2
                                ? () => setModalState(() => selectedIntervalDays--)
                                : null,
                          ),
                          Text(
                            '$selectedIntervalDays',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDarkDialog ? Colors.white : Colors.black87,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.add_circle_outline, color: Theme.of(context).primaryColor),
                            onPressed: () => setModalState(() => selectedIntervalDays++),
                          ),
                          const SizedBox(width: 8),
                          Text('天打卡', style: TextStyle(color: isDarkDialog ? Colors.white70 : Colors.black87)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text('${'freq_start_date'.tr}: ', style: TextStyle(color: isDarkDialog ? Colors.white70 : Colors.black87, fontSize: 13)),
                          OutlinedButton.icon(
                            icon: Icon(Icons.calendar_today, size: 14, color: Theme.of(context).primaryColor),
                            label: Text(
                              selectedStartDate,
                              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 13),
                            ),
                            onPressed: () async {
                              final initial = DateTime.tryParse(selectedStartDate) ?? DateTime.now();
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: initial,
                                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (picked != null) {
                                setModalState(() {
                                  selectedStartDate = picked.toString().split(' ')[0];
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                    if (selectedFreqType == 'monthly') ...[
                      const SizedBox(height: 12),
                      const Text('选择每月打卡日期', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          mainAxisSpacing: 4,
                          crossAxisSpacing: 4,
                          childAspectRatio: 1.1,
                        ),
                        itemCount: 31,
                        itemBuilder: (context, index) {
                          final day = index + 1;
                          final isSelected = selectedMonthlyDays.contains(day);
                          return GestureDetector(
                            onTap: () {
                              setModalState(() {
                                if (isSelected) {
                                  if (selectedMonthlyDays.length > 1) {
                                    selectedMonthlyDays.remove(day);
                                  }
                                } else {
                                  selectedMonthlyDays.add(day);
                                }
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Theme.of(context).primaryColor
                                    : (isDarkDialog ? Colors.white12 : Colors.grey.shade100),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Center(
                                child: Text(
                                  '$day',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isSelected ? Colors.white : (isDarkDialog ? Colors.white70 : Colors.black87),
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      )
                    ],
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
                            if (titleController.text.trim().isEmpty) {
                              setModalState(() => titleError = true);
                              return;
                            }

                            if (existingItem == null) {
                              // Create
                              final newCheckIn = CheckInModel(
                                title: titleController.text.trim(),
                                levelIndex: selectedLevel,
                                reminderTime: selectedTime,
                                frequencyType: selectedFreqType,
                                weeklyDays: selectedWeeklyDays,
                                intervalDays: selectedIntervalDays,
                                startDate: selectedStartDate,
                                monthlyDays: selectedMonthlyDays,
                              );
                              taskController.addCheckIn(newCheckIn);
                            } else {
                              // Update
                              final updated = existingItem.copyWith(
                                title: titleController.text.trim(),
                                levelIndex: selectedLevel,
                                reminderTime: selectedTime,
                                frequencyType: selectedFreqType,
                                weeklyDays: selectedWeeklyDays,
                                intervalDays: selectedIntervalDays,
                                startDate: selectedStartDate,
                                monthlyDays: selectedMonthlyDays,
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
