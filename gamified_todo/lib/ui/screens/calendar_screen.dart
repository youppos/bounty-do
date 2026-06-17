import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/task_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../models/task_model.dart';
import '../widgets/task_card.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final TaskController taskController = Get.find();
  final SettingsController settingsController = Get.find();
  
  DateTime _selectedDate = DateTime.now();
  String _searchQuery = "";
  int _selectedFilterLevel = -1; // -1: All, 0-4: Level Index

  // Generate a list of 15 days (7 before, today, 7 after)
  List<DateTime> _getWeekDays() {
    final today = DateTime.now();
    return List.generate(15, (index) {
      return today.subtract(Duration(days: 7 - index));
    });
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    final primaryColor = Theme.of(context).primaryColor;

    return Column(
      children: [
        // 1. Search & Filter Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.black26 : Colors.white60,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: TextField(
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim().toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'search_tasks'.tr,
                hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black45),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
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

        const SizedBox(height: 12),

        // 2. Week Strip View
        Container(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: 15,
            itemBuilder: (context, index) {
              final days = _getWeekDays();
              final day = days[index];
              final isSelected = _isSameDay(day, _selectedDate);
              final weekdayName = _getWeekdayName(day.weekday);
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDate = day;
                  });
                },
                child: Container(
                  width: 60,
                  margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: [primaryColor, primaryColor.withOpacity(0.7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: !isSelected
                        ? (isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.7))
                        : null,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected 
                          ? Colors.white24 
                          : (isDark ? Colors.white12 : Colors.black.withOpacity(0.05)),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        weekdayName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.white70 : Colors.black54),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        day.day.toString(),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 12),

        // 3. Tasks List for Selected Date
        Expanded(
          child: Obx(() {
            final filteredTasks = taskController.tasks.where((t) {
              // Filter by selected date (checking deadline date, or createdAt date if no deadline)
              final targetDate = t.deadline ?? t.createdAt;
              final matchesDate = _isSameDay(targetDate, _selectedDate);
              if (!matchesDate) return false;

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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_today_outlined, 
                      size: 64, 
                      color: isDark ? Colors.white24 : Colors.black26
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'no_tasks_today'.tr,
                      style: TextStyle(
                        color: isDark ? Colors.white60 : Colors.black54,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
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
                  onComplete: (tapPosition) => _handleTaskToggle(task, tapPosition),
                );
              },
            );
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
    // Dispatch to HomeScreen state or trigger directly on controller
    taskController.toggleTaskCompletion(task.id);
  }

  void _showEditTaskBottomSheet(BuildContext context, TaskModel task) {
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
                      Text('edit_task'.tr, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 24),
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
                      Text('time_setting'.tr, style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
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
                            if (editTitleController.text.trim().isEmpty) {
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
                              title: editTitleController.text.trim(),
                              description: editDescController.text.trim().isEmpty ? null : editDescController.text.trim(),
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
