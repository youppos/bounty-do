import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/task_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../models/task_model.dart';
import '../widgets/task_card.dart';

class CalendarScreen extends StatefulWidget {
  final Function(TaskModel task, Offset tapPosition)? onCompleteTask;
  const CalendarScreen({super.key, this.onCompleteTask});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> with SingleTickerProviderStateMixin {
  final TaskController taskController = Get.find();
  final SettingsController settingsController = Get.find();
  final ThemeController themeController = Get.find();
  
  late AnimationController _waveAnimationController;
  
  DateTime? _selectedDate = DateTime.now();
  DateTime _focusedDate = DateTime.now();
  bool _isMonthView = false;
  String _searchQuery = "";
  int _selectedFilterLevel = -1; // -1: All, 0-4: Level Index
  int _selectedCalendarTab = 0; // 0: 待办日程, 1: 打卡日程
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _waveAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _searchFocusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _waveAnimationController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // Generate a list of 7 days of the week containing _focusedDate (Monday to Sunday)
  List<DateTime> _getWeekDays() {
    final monday = _focusedDate.subtract(Duration(days: _focusedDate.weekday - 1));
    return List.generate(7, (index) {
      return DateTime(monday.year, monday.month, monday.day).add(Duration(days: index));
    });
  }

  // Generate all grid cells for the month (including padded days from adjacent months)
  List<DateTime> _getDaysInMonthGrid(DateTime date) {
    final firstDay = DateTime(date.year, date.month, 1);
    final weekdayOfFirst = firstDay.weekday; // 1 = Monday, 7 = Sunday
    final prefixEmptyDays = weekdayOfFirst - 1;
    
    final daysInMonth = DateTime(date.year, date.month + 1, 0).day;
    final gridDays = <DateTime>[];
    
    // Previous month's trailing days
    final prevMonth = DateTime(date.year, date.month - 1, 1);
    final prevMonthDays = DateTime(date.year, date.month, 0).day;
    for (int i = prefixEmptyDays - 1; i >= 0; i--) {
      gridDays.add(DateTime(prevMonth.year, prevMonth.month, prevMonthDays - i));
    }
    
    // Current month days
    for (int i = 1; i <= daysInMonth; i++) {
      gridDays.add(DateTime(date.year, date.month, i));
    }
    
    // Next month's leading days to make a multiple of 7
    final totalCells = gridDays.length;
    int nextMonthDaysNeeded = 0;
    if (totalCells % 7 != 0) {
      nextMonthDaysNeeded = 7 - (totalCells % 7);
    }
    final nextMonth = DateTime(date.year, date.month + 1, 1);
    for (int i = 1; i <= nextMonthDaysNeeded; i++) {
      gridDays.add(DateTime(nextMonth.year, nextMonth.month, i));
    }
    
    return gridDays;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  int _getTaskCountForDay(DateTime day) {
    return taskController.tasks.where((t) {
      final targetDate = t.deadline ?? t.createdAt;
      return _isSameDay(targetDate, day);
    }).length;
  }

  String _getFormatMonthYear(DateTime date) {
    final isZh = Get.locale?.languageCode == 'zh';
    if (isZh) {
      return "${date.year}年${date.month}月";
    } else {
      const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
      return "${months[date.month - 1]} ${date.year}";
    }
  }

  Color _getWaveColor(int taskCount, bool isDark) {
    if (taskCount <= 4) {
      return isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32); // Green
    } else if (taskCount <= 8) {
      return isDark ? const Color(0xFFFFD54F) : const Color(0xFFE65100); // Yellow/Amber
    } else {
      return isDark ? const Color(0xFFE57373) : const Color(0xFFC62828); // Red
    }
  }

  Color _getActiveBorderColor(int themeIndex, bool isDark) {
    switch (themeIndex) {
      case 0: // Liquid Glass (Light)
        return const Color(0xFF3B82F6); // Vibrant Royal Blue
      case 1: // Polar Night (Dark)
        return const Color(0xFF00F0FF); // Neon Cyan
      case 2: // Sakura Pink (Light)
        return const Color(0xFFEC4899); // Vibrant Hot Pink
      case 3: // Forest Green (Light)
        return const Color(0xFF2E7D32); // Deep Forest Green
      case 4: // Ocean Blue (Light)
        return const Color(0xFFFF9100); // Complementary Sunset Orange (Highly visible!)
      case 5: // Pure White (Light)
        return const Color(0xFF111827); // Dark Charcoal/Black
      case 6: // Premium Dark Purple (Dark)
        return const Color(0xFFD946EF); // Neon Magenta
      case 7: // Sunset Gold (Light)
        return const Color(0xFFE65100); // Warm Orange-Yellow
      case 8: // Cyberpunk (Dark)
        return const Color(0xFFFF007F); // Cyber Hot Pink
      case 9: // Mint Breeze (Light)
        return const Color(0xFF0F9690); // Deep Mint/Teal
      default:
        return const Color(0xFF3B82F6);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    final primaryColor = Theme.of(context).primaryColor;
    final themeIndex = themeController.currentThemeIndex.value;
    final activeBorderColor = _getActiveBorderColor(themeIndex, isDark);

    return Column(
      children: [
        // Sliding Tab Selector for "待办日程" and "打卡日程"
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
          child: Container(
            height: 40,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.02),
                width: 1.0,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedCalendarTab = 0),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: _selectedCalendarTab == 0
                            ? (isDark ? Colors.white10 : Colors.white)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: _selectedCalendarTab == 0 && !isDark
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '待办日程',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: _selectedCalendarTab == 0 ? FontWeight.bold : FontWeight.normal,
                          color: _selectedCalendarTab == 0
                              ? (isDark ? Colors.white : Colors.black87)
                              : (isDark ? Colors.white60 : Colors.black54),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedCalendarTab = 1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: _selectedCalendarTab == 1
                            ? (isDark ? Colors.white10 : Colors.white)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: _selectedCalendarTab == 1 && !isDark
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '打卡日程',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: _selectedCalendarTab == 1 ? FontWeight.bold : FontWeight.normal,
                          color: _selectedCalendarTab == 1
                              ? (isDark ? Colors.white : Colors.black87)
                              : (isDark ? Colors.white60 : Colors.black54),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // 1. Search & Filter Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            height: (_searchFocusNode.hasFocus || _searchQuery.isNotEmpty) ? 46 : 36,
            margin: EdgeInsets.symmetric(
              horizontal: (_searchFocusNode.hasFocus || _searchQuery.isNotEmpty) ? 0 : 32,
            ),
            decoration: BoxDecoration(
              color: isDark ? Colors.black26 : Colors.white60,
              borderRadius: BorderRadius.circular((_searchFocusNode.hasFocus || _searchQuery.isNotEmpty) ? 16 : 18),
              border: Border.all(color: Colors.white10),
            ),
            child: TextField(
              focusNode: _searchFocusNode,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: (_searchFocusNode.hasFocus || _searchQuery.isNotEmpty) ? 14 : 13,
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim().toLowerCase();
                });
              },
              textAlignVertical: TextAlignVertical.center,
              decoration: InputDecoration(
                hintText: 'search_tasks'.tr,
                hintStyle: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black45,
                  fontSize: (_searchFocusNode.hasFocus || _searchQuery.isNotEmpty) ? 14 : 13,
                ),
                prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              ),
            ),
          ),
        ),

        // Level Filter chip row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              _buildFilterChip(
                label: 'view_all'.tr,
                isSelected: _selectedFilterLevel == -1,
                onTap: () => setState(() => _selectedFilterLevel = -1),
                color: primaryColor,
              ),
              ...List.generate(5, (idx) {
                final name = settingsController.getLevelName(idx);
                final color = TaskModel(title: '', coinReward: 0, levelIndex: idx).levelColor;
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: _buildFilterChip(
                    label: name,
                    isSelected: _selectedFilterLevel == idx,
                    onTap: () => setState(() => _selectedFilterLevel = idx),
                    color: color,
                  ),
                );
              }),
            ],
          ),
        ),

        AnimatedBuilder(
          animation: _waveAnimationController,
          builder: (context, child) {
            final wavePhase = _waveAnimationController.value * 2 * math.pi;
            return Column(
              children: [
                // Month/Week Navigation & View Switcher Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Date Text (Month Year) with Navigation arrows
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.chevron_left, color: isDark ? Colors.white70 : Colors.black87),
                            onPressed: () {
                              setState(() {
                                if (_isMonthView) {
                                  _focusedDate = DateTime(_focusedDate.year, _focusedDate.month - 1, 1);
                                } else {
                                  _focusedDate = _focusedDate.subtract(const Duration(days: 7));
                                }
                              });
                            },
                          ),
                          Text(
                            _getFormatMonthYear(_focusedDate),
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.chevron_right, color: isDark ? Colors.white70 : Colors.black87),
                            onPressed: () {
                              setState(() {
                                if (_isMonthView) {
                                  _focusedDate = DateTime(_focusedDate.year, _focusedDate.month + 1, 1);
                                } else {
                                  _focusedDate = _focusedDate.add(const Duration(days: 7));
                                }
                              });
                            },
                          ),
                        ],
                      ),
                      // View Toggle Button
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: primaryColor.withOpacity(0.3)),
                          ),
                        ),
                        icon: Icon(_isMonthView ? Icons.calendar_view_week : Icons.calendar_view_month, size: 18),
                        label: Text(_isMonthView ? 'week_view'.tr : 'month_view'.tr),
                        onPressed: () {
                          setState(() {
                            _isMonthView = !_isMonthView;
                          });
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // 2. Calendar view: Month grid or Week strip
                if (!_isMonthView)
                  Container(
                    height: 90,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: 7,
                      itemBuilder: (context, index) {
                        final days = _getWeekDays();
                        final day = days[index];
                        final isSelected = _selectedDate != null && _isSameDay(day, _selectedDate!);
                        final isToday = _isSameDay(day, DateTime.now());
                        final weekdayName = _getWeekdayName(day.weekday);
                        final taskCount = _getTaskCountForDay(day);
                        
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (_selectedDate != null && _isSameDay(day, _selectedDate!)) {
                                _selectedDate = null;
                              } else {
                                _selectedDate = day;
                                _focusedDate = day;
                              }
                            });
                          },
                          child: Container(
                            width: 60,
                            margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            decoration: BoxDecoration(
                              color: isToday
                                  ? primaryColor.withOpacity(0.15)
                                  : (isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.7)),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected 
                                    ? activeBorderColor 
                                    : (isToday 
                                        ? primaryColor.withOpacity(0.5) 
                                        : (isDark ? Colors.white12 : Colors.black.withOpacity(0.05))),
                                width: isSelected ? 3.0 : 1.0,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: activeBorderColor.withOpacity(0.4),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      )
                                    ]
                                  : null,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Positioned.fill(
                                    child: CustomPaint(
                                      painter: LiquidWavePainter(
                                        fill: (taskCount / 10.0).clamp(0.0, 1.0),
                                        phase: wavePhase + index * 0.5,
                                        color: _getWaveColor(taskCount, isDark),
                                        isSelected: isSelected,
                                      ),
                                    ),
                                  ),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        weekdayName,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                          color: isDark ? Colors.white70 : Colors.black54,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        day.day.toString(),
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.white : Colors.black87,
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
                    ),
                  )
                else ...[
                  // Weekday headers for Month grid
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(7, (index) {
                        // weekday starts at Monday = 1
                        final weekdayName = _getWeekdayName(index + 1);
                        return SizedBox(
                          width: 32,
                          child: Text(
                            weekdayName,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white54 : Colors.black45,
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 1.1,
                      ),
                      itemCount: _getDaysInMonthGrid(_focusedDate).length,
                      itemBuilder: (context, index) {
                        final gridDays = _getDaysInMonthGrid(_focusedDate);
                        final day = gridDays[index];
                        final isCurrentMonth = day.month == _focusedDate.month;
                        final isSelected = _selectedDate != null && _isSameDay(day, _selectedDate!);
                        final isToday = _isSameDay(day, DateTime.now());
                        final taskCount = _getTaskCountForDay(day);

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (_selectedDate != null && _isSameDay(day, _selectedDate!)) {
                                _selectedDate = null;
                              } else {
                                _selectedDate = day;
                                _focusedDate = day;
                              }
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: isToday
                                  ? primaryColor.withOpacity(0.15)
                                  : (isDark ? Colors.white.withOpacity(0.03) : Colors.white.withOpacity(0.6)),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? activeBorderColor
                                    : (isToday
                                        ? primaryColor.withOpacity(0.5)
                                        : (isDark ? Colors.white10 : Colors.black.withOpacity(0.03))),
                                width: isSelected ? 3.0 : 1.0,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: activeBorderColor.withOpacity(0.4),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      )
                                    ]
                                  : null,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Positioned.fill(
                                    child: CustomPaint(
                                      painter: LiquidWavePainter(
                                        fill: (taskCount / 10.0).clamp(0.0, 1.0),
                                        phase: wavePhase + index * 0.5,
                                        color: _getWaveColor(taskCount, isDark),
                                        isSelected: isSelected,
                                      ),
                                    ),
                                  ),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        day.day.toString(),
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.normal,
                                          color: isCurrentMonth
                                              ? (isDark ? Colors.white : Colors.black87)
                                              : (isDark ? Colors.white24 : Colors.black26),
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
                    ),
                  ),
                ],
              ],
            );
          },
        ),

        const SizedBox(height: 4),

        // 3. Lists Area (Todo / Check-in)
        Expanded(
          child: Obx(() {
            if (_selectedCalendarTab == 0) {
              final filteredTasks = taskController.tasks.where((t) {
                // Filter by selected date (checking deadline date, or createdAt date if no deadline)
                if (_selectedDate != null) {
                  final targetDate = t.deadline ?? t.createdAt;
                  final matchesDate = _isSameDay(targetDate, _selectedDate!);
                  if (!matchesDate) return false;
                }

                // Filter by keyword search
                if (_searchQuery.isNotEmpty) {
                  final matchTitle = t.title.toLowerCase().contains(_searchQuery);
                  final matchDesc = t.description?.toLowerCase().contains(_searchQuery) ?? false;
                  if (!matchTitle && !matchDesc) return false;
                }

                // Filter by level
                if (_selectedFilterLevel != -1 && t.levelIndex != _selectedFilterLevel) {
                  return false;
                }

                return true;
              }).toList();

              if (filteredTasks.isEmpty) {
                return Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_today_outlined, 
                          size: 48, 
                          color: isDark ? Colors.white24 : Colors.black26
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _selectedDate == null ? 'no_tasks'.tr : 'no_tasks_today'.tr,
                          style: TextStyle(
                            color: isDark ? Colors.white60 : Colors.black54,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: filteredTasks.length,
                itemBuilder: (context, index) {
                  final task = filteredTasks[index];
                  return TaskCard(
                    task: task,
                    isGrid: false,
                    index: index,
                    onEdit: () => _showEditTaskBottomSheet(context, task),
                    onSetTime: () => _showEditTaskBottomSheet(context, task, onlyTime: true),
                    onComplete: (tapPosition) => _handleTaskToggle(task, tapPosition),
                  );
                },
              );
            } else {
              // Check-in Schedule Tab
              final dateStr = _selectedDate != null ? _selectedDate!.toString().split(' ')[0] : '';
              final todayStr = DateTime.now().toString().split(' ')[0];
              final isToday = dateStr == todayStr;
              
              // Define whether the selected date is in the future
              bool isFuture = false;
              if (_selectedDate != null) {
                final todayMidnight = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
                final selectedMidnight = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day);
                isFuture = selectedMidnight.isAfter(todayMidnight);
              }

              final list = taskController.checkIns;

              if (list.isEmpty) {
                return Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.alarm_on_outlined, 
                          size: 48, 
                          color: isDark ? Colors.white24 : Colors.black26
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '暂无打卡项目',
                          style: TextStyle(
                            color: isDark ? Colors.white60 : Colors.black54,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final item = list[index];
                  final isCompleted = item.history.contains(dateStr);

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? (isDark ? Colors.green.withOpacity(0.12) : Colors.green.withOpacity(0.06))
                          : (isDark ? Colors.white.withOpacity(0.04) : Colors.white.withOpacity(0.5)),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isCompleted
                            ? Colors.green.withOpacity(0.3)
                            : (isDark ? Colors.white10 : Colors.black.withOpacity(0.04)),
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                          color: isCompleted ? Colors.green : (isDark ? Colors.white38 : Colors.black38),
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.levelIndex == 0 ? '一般打卡 (5金币)' : '重要打卡 (15金币)',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: item.levelIndex == 0 ? Colors.blue : Colors.redAccent,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTapDown: (details) {
                            if (isFuture) {
                              Get.snackbar('打卡失败', '不可提前对未来的日期打卡哦！', snackPosition: SnackPosition.BOTTOM);
                              return;
                            }
                            
                            if (isCompleted) {
                              taskController.toggleCheckInStatus(item.id, dateStr);
                            } else {
                              // Play coin drop animations only if completed for today
                              if (isToday && widget.onCompleteTask != null) {
                                final reward = item.levelIndex == 0 ? 5 : 15;
                                final tempTask = TaskModel(
                                  title: item.title,
                                  coinReward: reward,
                                  levelIndex: item.levelIndex,
                                );
                                widget.onCompleteTask!(tempTask, details.globalPosition);
                              } else {
                                taskController.toggleCheckInStatus(item.id, dateStr);
                              }
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isCompleted
                                  ? Colors.transparent
                                  : (isFuture
                                      ? Colors.grey.withOpacity(0.2)
                                      : primaryColor),
                              borderRadius: BorderRadius.circular(12),
                              border: isCompleted
                                  ? Border.all(color: Colors.green.withOpacity(0.5))
                                  : null,
                            ),
                            child: Text(
                              isCompleted
                                  ? '已完成'
                                  : (isFuture ? '未开启' : (isToday ? '立即打卡' : '补签')),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isCompleted
                                    ? Colors.green
                                    : (isFuture ? Colors.white30 : Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            }
          }),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.25) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.grey.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? color : (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87),
          ),
        ),
      ),
    );
  }

  String _getWeekdayName(int weekday) {
    final isZh = Get.locale?.languageCode == 'zh';
    if (isZh) {
      switch (weekday) {
        case 1: return '一';
        case 2: return '二';
        case 3: return '三';
        case 4: return '四';
        case 5: return '五';
        case 6: return '六';
        case 7: return '日';
        default: return '';
      }
    } else {
      switch (weekday) {
        case 1: return 'Mon';
        case 2: return 'Tue';
        case 3: return 'Wed';
        case 4: return 'Thu';
        case 5: return 'Fri';
        case 6: return 'Sat';
        case 7: return 'Sun';
        default: return '';
      }
    }
  }

  void _handleTaskToggle(TaskModel task, Offset tapPosition) {
    if (widget.onCompleteTask != null) {
      widget.onCompleteTask!(task, tapPosition);
    } else {
      taskController.toggleTaskCompletion(task.id);
    }
  }

  void _showEditTaskBottomSheet(BuildContext context, TaskModel task, {bool onlyTime = false}) {
    // Find the state of HomeScreen to trigger edit dialog, or show directly.
    // For simplicity, we can reuse the edit dialog from task card or write a global helper.
    // Let's implement editing inline here since we want full compatibility!
    String title = task.title;
    String desc = task.description ?? "";
    String timeOption = task.deadline == null ? "none" : "deadline";
    DateTime? selectedDeadline = task.deadline;
    int selectedLevel = task.levelIndex;

    TextEditingController editTitleController = TextEditingController(text: title);
    TextEditingController editDescController = TextEditingController(text: desc);
    
    bool titleError = false;

    showDialog(
      context: context,
      builder: (context) {
        final isDarkDialog = Theme.of(context).brightness == Brightness.dark;
        return Dialog(
          alignment: Alignment.topCenter,
          insetPadding: const EdgeInsets.only(top: 60, left: 16, right: 16, bottom: 16),
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
                        onlyTime ? 'set_time_first_title'.tr : 'edit_task'.tr,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 24),
                      if (!onlyTime) ...[
                        TextField(
                          controller: editTitleController,
                          style: TextStyle(color: isDarkDialog ? Colors.white : Colors.black87),
                          decoration: InputDecoration(
                            labelText: 'task_title'.tr,
                            errorText: titleError ? 'title_required'.tr : null,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onChanged: (val) {
                            if (titleError) setModalState(() => titleError = false);
                          },
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: editDescController,
                          style: TextStyle(color: isDarkDialog ? Colors.white : Colors.black87),
                          decoration: InputDecoration(
                            labelText: 'task_desc'.tr,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text('priority'.tr, style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        // Dropdown or button row for Level selection (0 to 4)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: selectedLevel,
                              isExpanded: true,
                              dropdownColor: Theme.of(context).scaffoldBackgroundColor,
                              items: List.generate(5, (idx) {
                                return DropdownMenuItem<int>(
                                  value: idx,
                                  child: Text(settingsController.getLevelName(idx)),
                                );
                              }),
                              onChanged: (val) {
                                if (val != null) {
                                  setModalState(() => selectedLevel = val);
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: Icon(Icons.calendar_month, color: Theme.of(context).primaryColor),
                              label: Text(
                                selectedDeadline == null 
                                  ? 'select_date_time'.tr 
                                  : "${selectedDeadline!.year}-${selectedDeadline!.month.toString().padLeft(2, '0')}-${selectedDeadline!.day.toString().padLeft(2, '0')} ${selectedDeadline!.hour.toString().padLeft(2, '0')}:${selectedDeadline!.minute.toString().padLeft(2, '0')}",
                                style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                              ),
                              onPressed: () async {
                                DateTime? date = await showDatePicker(
                                  context: context,
                                  initialDate: selectedDeadline ?? DateTime.now(),
                                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                );
                                if (date != null) {
                                  TimeOfDay? time = await showTimePicker(
                                    context: context,
                                    initialTime: selectedDeadline != null ? TimeOfDay(hour: selectedDeadline!.hour, minute: selectedDeadline!.minute) : TimeOfDay.now(),
                                  );
                                  if (time != null) {
                                    setModalState(() {
                                      selectedDeadline = DateTime(
                                        date.year,
                                        date.month,
                                        date.day,
                                        time.hour,
                                        time.minute,
                                      );
                                      timeOption = "deadline";
                                    });
                                  }
                                }
                              },
                            ),
                          ),
                          if (selectedDeadline != null) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.clear, color: Colors.red),
                              onPressed: () {
                                setModalState(() {
                                  selectedDeadline = null;
                                  timeOption = "none";
                                });
                              },
                            )
                          ]
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).primaryColor,
                              Theme.of(context).primaryColor.withOpacity(0.7),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).primaryColor.withOpacity(0.4),
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
                            if (!onlyTime && editTitleController.text.trim().isEmpty) {
                              setModalState(() => titleError = true);
                              return;
                            }
                            
                            // For default coins, if no deadline: min values, otherwise dynamic starting with max
                            int defaultCoins = TaskModel.getMinCoinsForLevel(selectedLevel);
                            if (timeOption == "deadline" && selectedDeadline != null) {
                              defaultCoins = TaskModel.getMaxCoinsForLevel(selectedLevel);
                            }

                            final reallyUpdatedTask = TaskModel(
                              id: task.id,
                              title: onlyTime ? task.title : editTitleController.text.trim(),
                              description: onlyTime ? task.description : (editDescController.text.trim().isEmpty ? null : editDescController.text.trim()),
                              isCompleted: task.isCompleted,
                              coinReward: defaultCoins,
                              levelIndex: selectedLevel,
                              createdAt: task.createdAt,
                              deadline: timeOption == "none" ? null : selectedDeadline,
                            );

                            taskController.updateTask(task.id, reallyUpdatedTask);
                            Navigator.pop(context);
                          },
                          child: Text('save'.tr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 8),
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
}

class LiquidWavePainter extends CustomPainter {
  final double fill; // 0.0 to 1.0
  final double phase; // 0.0 to 2*pi
  final Color color;
  final bool isSelected;

  LiquidWavePainter({
    required this.fill,
    required this.phase,
    required this.color,
    required this.isSelected,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (fill <= 0.0) return;

    final Paint paint = Paint()..style = PaintingStyle.fill;

    double targetY = size.height * (1.0 - fill);
    double waveTop = (targetY - 3).clamp(0.0, size.height);
    
    double topOpacity = isSelected ? 0.8 : 0.7;
    double bottomOpacity = isSelected ? 0.5 : 0.4;

    paint.shader = LinearGradient(
      colors: [color.withOpacity(topOpacity), color.withOpacity(bottomOpacity)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(Rect.fromLTWH(0, waveTop, size.width, size.height - waveTop));

    final path = Path();
    if (fill >= 0.95) {
      path.addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    } else {
      path.moveTo(0, size.height);
      path.lineTo(0, targetY);

      double amplitude = 1.0; 
      double waveLength = size.width;

      for (double x = 0; x <= size.width; x++) {
        double y = targetY + amplitude * math.sin((2 * math.pi * x / waveLength) + phase);
        path.lineTo(x, y);
      }

      path.lineTo(size.width, size.height);
      path.close();
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant LiquidWavePainter oldDelegate) {
    return oldDelegate.fill != fill || 
        oldDelegate.phase != phase || 
        oldDelegate.color != color || 
        oldDelegate.isSelected != isSelected;
  }
}
