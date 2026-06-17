import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/task_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../models/task_model.dart';
import '../../controllers/settings_controller.dart';
import '../../controllers/skill_controller.dart';
import '../widgets/task_card.dart';
import '../widgets/flying_coin_widget.dart';
import '../widgets/swipe_to_reveal.dart';
import '../widgets/animated_coin_counter.dart';
import 'settings_screen.dart';
import 'skills_screen.dart';
import 'adventure_screen.dart';
import 'calendar_screen.dart';
import 'check_in_screen.dart';
import '../../models/check_in_model.dart';
import '../widgets/voice_assistant_overlay.dart';
import '../theme/app_theme.dart';
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}
class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final TaskController taskController = Get.find();
  final ThemeController themeController = Get.find();
  final SettingsController settingsController = Get.find();
  final SkillController skillController = Get.put(SkillController());
  
  bool isGrid = false;
  int _currentIndex = 0;
  final List<Map<String, dynamic>> _flyingCoins = [];
  bool _coinSoundPlayed = false;
  
  late final AnimationController _coinBarController;
  late final Animation<double> _coinBarScale;
  @override
  void initState() {
    super.initState();
    
    _coinBarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    
    _coinBarScale = Tween<double>(begin: 1.0, end: 2.0).animate(
      CurvedAnimation(parent: _coinBarController, curve: Curves.easeOutCubic),
    );
    
    _coinBarController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _coinBarController.reverse();
      }
    });
  }
  @override
  void dispose() {
    _coinBarController.dispose();
    super.dispose();
  }
  void _toggleView() {
    setState(() {
      isGrid = !isGrid;
    });
  }
  void _spawnCoins(Offset startPosition, int reward) async {
    final targetPosition = Offset(
      80.0,
      MediaQuery.of(context).padding.top + 40
    );
    
    _coinSoundPlayed = false; // Reset for new batch
    int coinCount = (reward / 10).ceil().clamp(1, 15).toInt();
    int delayMs = coinCount > 1 ? 80 : 0;
    
    final random = Random();
    
    for (int i = 0; i < coinCount; i++) {
      if (!mounted) break;
      
      final id = "coin_${DateTime.now().microsecondsSinceEpoch}_${i}_${random.nextInt(1000)}";
      setState(() {
        _flyingCoins.add({
          'id': id,
          'start': startPosition,
          'target': targetPosition,
        });
      });
      
      if (i < coinCount - 1) {
        await Future.delayed(Duration(milliseconds: delayMs));
      }
    }
  }
  void _handleTaskToggle(TaskModel task, Offset tapPosition) {
    bool isBecomingCompleted = !task.isCompleted;
    
    if (isBecomingCompleted) {
      final multiplier = skillController.doubleGoldCharges.value > 0 ? 2 : 1;
      _spawnCoins(tapPosition, task.coinReward * multiplier);
    }
    
    taskController.toggleTaskCompletion(task.id);
  }
  void _handleCheckInToggle(CheckInModel item, Offset tapPosition) {
    final todayStr = DateTime.now().toString().split(' ')[0];
    final isBecomingCompleted = !item.history.contains(todayStr);
    if (isBecomingCompleted) {
      final reward = item.levelIndex == 0 ? 5 : 15;
      _spawnCoins(tapPosition, reward);
    }
    taskController.toggleCheckInStatus(item.id, todayStr);
  }
  void _showProfileBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                spreadRadius: 2,
              )
            ],
          ),
          child: Stack(
            children: [
              const ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                child: AdventureScreen(),
              ),
              Positioned(
                right: 16,
                top: 16,
                child: CircleAvatar(
                  backgroundColor: isDark ? Colors.white12 : Colors.black12,
                  child: IconButton(
                     icon: Icon(Icons.close, color: isDark ? Colors.white : Colors.black87),
                     onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  void _showAddTaskBottomSheet(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    
    final daysController = TextEditingController(text: "0");
    final hoursController = TextEditingController(text: "1");
    final minutesController = TextEditingController(text: "0");
    
    String timeOption = "none";
    DateTime? selectedDeadline;
    bool titleError = false;
    int selectedLevel = 1; // Default to Level 2 (Index 1)
    
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Dialog(
          alignment: Alignment.topCenter,
          insetPadding: const EdgeInsets.only(top: 60, left: 16, right: 16, bottom: 16),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              final minCoins = TaskModel.getMinCoinsForLevel(selectedLevel);
              final maxCoins = TaskModel.getMaxCoinsForLevel(selectedLevel);
              return Padding(
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'add_new_task'.tr,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Inter'),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: titleController,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontFamily: 'Inter'),
                        onChanged: (value) {
                          if (titleError && value.trim().isNotEmpty) {
                            setModalState(() => titleError = false);
                          }
                        },
                        decoration: InputDecoration(
                          labelText: 'task_title'.tr,
                          errorText: titleError ? 'title_required'.tr : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: titleError ? Colors.red : Theme.of(context).primaryColor, width: 2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: titleError ? Colors.red : Colors.grey[400]!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: descController,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontFamily: 'Inter'),
                        decoration: InputDecoration(
                          labelText: 'task_desc'.tr,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text('priority'.tr, style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87, fontFamily: 'Inter')),
                      const SizedBox(height: 8),
                      
                      // Level Selector Row
                      Row(
                        children: List.generate(5, (idx) {
                          final isSelected = selectedLevel == idx;
                          final name = settingsController.getLevelName(idx);
                          final color = TaskModel(title: '', coinReward: 0, levelIndex: idx).levelColor;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => setModalState(() => selectedLevel = idx),
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? color : color.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: color, width: 1.5),
                                ),
                                child: Center(
                                  child: Text(
                                    name,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? Colors.white : color,
                                      fontFamily: 'Inter',
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 12),
                      
                      // Coin rewards indicator
                      Text(
                        timeOption == "none"
                            ? "奖励金币: $minCoins 个金币 (无时间默认分配最小值)"
                            : "奖励金币: 达到全额可得 $maxCoins 个金币 (逾期最低得 $minCoins)",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.amber : Colors.amber.shade800,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text('time_setting'.tr, style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87, fontFamily: 'Inter')),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4.0),
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: timeOption == "none" ? Theme.of(context).primaryColor.withOpacity(0.1) : Colors.transparent,
                                  side: BorderSide(color: timeOption == "none" ? Theme.of(context).primaryColor : Theme.of(context).dividerColor),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () => setModalState(() => timeOption = "none"),
                                child: Text('time_none'.tr, style: TextStyle(color: timeOption == "none" ? Theme.of(context).primaryColor : Theme.of(context).textTheme.bodyLarge?.color)),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4.0),
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: timeOption == "countdown" ? Theme.of(context).primaryColor.withOpacity(0.1) : Colors.transparent,
                                  side: BorderSide(color: timeOption == "countdown" ? Theme.of(context).primaryColor : Theme.of(context).dividerColor),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () => setModalState(() => timeOption = "countdown"),
                                child: Text('time_countdown'.tr, style: TextStyle(color: timeOption == "countdown" ? Theme.of(context).primaryColor : Theme.of(context).textTheme.bodyLarge?.color)),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4.0),
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: timeOption == "deadline" ? Theme.of(context).primaryColor.withOpacity(0.1) : Colors.transparent,
                                  side: BorderSide(color: timeOption == "deadline" ? Theme.of(context).primaryColor : Theme.of(context).dividerColor),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () => setModalState(() => timeOption = "deadline"),
                                child: Text('time_deadline'.tr, style: TextStyle(color: timeOption == "deadline" ? Theme.of(context).primaryColor : Theme.of(context).textTheme.bodyLarge?.color)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (timeOption == "countdown") ...[
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: daysController,
                                style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontFamily: 'Inter'),
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'days'.tr,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: hoursController,
                                style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontFamily: 'Inter'),
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'hours'.tr,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: minutesController,
                                style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontFamily: 'Inter'),
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'mins'.tr,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ),
                          ],
                        )
                      ] else if (timeOption == "deadline") ...[
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
                                    initialDate: DateTime.now(),
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(const Duration(days: 365)),
                                  );
                                  if (date != null) {
                                    TimeOfDay? time = await showTimePicker(
                                      context: context,
                                      initialTime: TimeOfDay.now(),
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
                                      });
                                    }
                                  }
                                },
                              ),
                            ),
                          ],
                        )
                      ],
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
                            if (titleController.text.trim().isEmpty) {
                              setModalState(() => titleError = true);
                              return;
                            }
                            // Check daily task limits before creation
                            if (!taskController.canCreateTaskToday()) {
                              Navigator.pop(context);
                              showDialog(
                                context: context,
                                builder: (context) {
                                  final isDarkDialog = Theme.of(context).brightness == Brightness.dark;
                                  return AlertDialog(
                                    backgroundColor: isDarkDialog ? Colors.grey[900] : Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    title: Text('daily_limit_reached'.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    content: Text('daily_limit_msg'.tr
                                        .replaceAll('@current', taskController.getTasksCreatedTodayCount().toString())
                                        .replaceAll('@max', taskController.dailyTaskLimit.toString())),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('OK'),
                                      ),
                                    ],
                                  );
                                },
                              );
                              return;
                            }
                            
                            DateTime? finalDeadline;
                            if (timeOption == "countdown") {
                              int days = int.tryParse(daysController.text) ?? 0;
                              int hours = int.tryParse(hoursController.text) ?? 0;
                              int minutes = int.tryParse(minutesController.text) ?? 0;
                              finalDeadline = DateTime.now().add(Duration(
                                days: days,
                                hours: hours,
                                minutes: minutes,
                              ));
                            } else if (timeOption == "deadline") {
                              finalDeadline = selectedDeadline;
                            }
                            
                            // If deadline exists, reward starts at maxCoins
                            final coinReward = finalDeadline == null ? minCoins : maxCoins;
                            
                            final newTask = TaskModel(
                              title: titleController.text.trim(),
                              description: descController.text.trim().isEmpty ? null : descController.text.trim(),
                              coinReward: coinReward,
                              levelIndex: selectedLevel,
                              deadline: finalDeadline,
                            );
                            
                            taskController.addTask(newTask);
                            Navigator.pop(context);
                          },
                          child: Text('create_task'.tr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
  void _showEditTaskBottomSheet(BuildContext context, TaskModel task, {bool onlyTime = false}) {
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
        final isDark = Theme.of(context).brightness == Brightness.dark;
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
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Inter'),
                      ),
                      const SizedBox(height: 24),
                      if (!onlyTime) ...[
                        TextField(
                          controller: editTitleController,
                          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                          decoration: InputDecoration(
                            labelText: 'task_title'.tr,
                            errorText: titleError ? 'required_field'.tr : null,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: const Icon(Icons.title),
                          ),
                          onChanged: (val) {
                            if (titleError) setModalState(() => titleError = false);
                          },
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: editDescController,
                          maxLines: 3,
                          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                          decoration: InputDecoration(
                            labelText: 'task_desc'.tr,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: const Icon(Icons.description),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'priority'.tr,
                          style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87, fontFamily: 'Inter'),
                        ),
                        const SizedBox(height: 8),
                        
                        // Level Selector Row
                        Row(
                          children: List.generate(5, (idx) {
                            final isSelected = selectedLevel == idx;
                            final name = settingsController.getLevelName(idx);
                            final color = TaskModel(title: '', coinReward: 0, levelIndex: idx).levelColor;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => setModalState(() => selectedLevel = idx),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 2),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? color : color.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: color, width: 1.5),
                                  ),
                                  child: Center(
                                    child: Text(
                                      name,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? Colors.white : color,
                                        fontFamily: 'Inter',
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
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
  Widget _buildLiquidGlassBackground() {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
    );
  }
  Widget _buildCurrentPage() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (_currentIndex) {
      case 0:
        return DefaultTabController(
          length: 3,
          child: Stack(
            children: [
              TabBarView(
                children: [
                  _buildTaskList(filter: 'in_progress', topPadding: 50.0),
                  _buildTaskList(filter: 'overdue', topPadding: 50.0),
                  _buildTaskList(filter: 'completed', topPadding: 50.0),
                ],
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 35, sigmaY: 35),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? Colors.black.withOpacity(0.05) : Colors.white.withOpacity(0.1),
                        border: Border(
                          bottom: BorderSide(
                            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                            width: 0.5,
                          ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                            spreadRadius: 0,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: TabBar(
                        tabs: [
                          Tab(text: 'tab_in_progress'.tr),
                          Tab(text: 'tab_overdue'.tr),
                          Tab(text: 'tab_completed'.tr),
                        ],
                        indicatorColor: Colors.amber,
                        labelColor: Colors.amber,
                        unselectedLabelColor: isDark ? Colors.white70 : Colors.black54,
                        dividerColor: Colors.transparent,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      case 1:
        return CheckInScreen(
          onCheckIn: _handleCheckInToggle,
        );
      case 2:
        return CalendarScreen(
          onCompleteTask: _handleTaskToggle,
        );
      case 3:
        return const SkillsScreen();
      default:
        return const SizedBox.shrink();
    }
  }
  void _showVoiceAssistantOverlay(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "voice",
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return const VoiceAssistantOverlay();
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        toolbarHeight: 60,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 220,
        leading: Obx(() {
          final coins = taskController.totalCoins.value;
          final level = taskController.userLevel;
          final title = taskController.userTitle;
          return GestureDetector(
            onTap: () => _showProfileBottomSheet(context),
            child: Padding(
              padding: const EdgeInsets.only(left: 16, top: 2, bottom: 2),
              child: Row(
                children: [
                  // Avatar with gold border
                  Container(
                    width: 42,
                    height: 42,
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
                          blurRadius: 6,
                          spreadRadius: 1,
                        )
                      ],
                      border: Border.all(
                        color: Colors.white.withOpacity(0.8),
                        width: 1.5,
                      ),
                    ),
                    child: const Center(
                      child: Icon(Icons.person, color: Colors.white, size: 24),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 3-line status
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.amberAccent : Colors.orange.shade800,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade800,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            "Lv.$level",
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        ScaleTransition(
                          scale: _coinBarScale,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 14,
                                height: 14,
                                decoration: const BoxDecoration(
                                  color: Colors.amber,
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: Text(
                                    "\$",
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      height: 1.0,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                "$coins",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.amberAccent : Colors.amber.shade800,
                                  fontFamily: 'Inter',
                                  height: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        actions: [
          if (_currentIndex == 0)
            IconButton(
              icon: Icon(isGrid ? Icons.view_list : Icons.grid_view, color: isDark ? Colors.white : Colors.black87),
              onPressed: _toggleView,
            ),
          Obx(() {
            IconData icon;
            switch (settingsController.soundMode.value) {
              case 0:
                icon = Icons.volume_up;
                break;
              case 1:
                icon = Icons.volume_down;
                break;
              case 2:
              default:
                icon = Icons.volume_off;
                break;
            }
            return IconButton(
              icon: Icon(icon, color: isDark ? Colors.white : Colors.black87),
              onPressed: () {
                settingsController.toggleMute();
                Get.closeAllSnackbars();
                Get.rawSnackbar(
                  message: '${'sound'.tr}: ${settingsController.getSoundModeString()}',
                  duration: const Duration(seconds: 1),
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: isDark ? Colors.grey.shade900 : Colors.white,
                  messageText: Text(
                    '${'sound'.tr}: ${settingsController.getSoundModeString()}',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Inter',
                    ),
                  ),
                  margin: const EdgeInsets.all(16),
                  borderRadius: 12,
                );
              },
            );
          }),
          IconButton(
            icon: Icon(Icons.settings, color: isDark ? Colors.white : Colors.black87),
            onPressed: () {
              Get.to(() => const SettingsScreen(), transition: Transition.cupertino);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildLiquidGlassBackground(),
          
          SafeArea(
            bottom: false,
            child: _buildCurrentPage(),
          ),
          // Flying coins layer
          ..._flyingCoins.map((coin) {
            return FlyingCoinWidget(
              key: ValueKey(coin['id']),
              start: coin['start'],
              target: coin['target'],
              onFinished: () {
                setState(() {
                  _flyingCoins.removeWhere((c) => c['id'] == coin['id']);
                });
                if (_coinBarController.status != AnimationStatus.forward) {
                  _coinBarController.forward(from: 0);
                }
                // Play sound only on the first coin arrival
                if (!_coinSoundPlayed && !settingsController.isMuted.value) {
                  _coinSoundPlayed = true;
                  taskController.playSingleCoinSound();
                }
                // Stop all sounds when the last coin finishes
                if (_flyingCoins.isEmpty) {
                  taskController.stopAllCoinSounds();
                }
              },
            );
          }).toList(),
        ],
      ),
      floatingActionButton: (_currentIndex == 0 || _currentIndex == 1)
          ? Obx(() {
              final themeIndex = themeController.currentThemeIndex.value;
              final fabColors = AppTheme.getFabGradientColors(themeIndex);
              return GestureDetector(
                onTap: () {
                  if (_currentIndex == 0) {
                    _showAddTaskBottomSheet(context);
                  } else if (_currentIndex == 1) {
                    showAddOrEditCheckInDialog(context, null);
                  }
                },
                child: Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: fabColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: fabColors.first.withOpacity(0.4),
                        blurRadius: 12,
                        spreadRadius: 1,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 28),
                ),
              );
            })
          : null,
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 35, sigmaY: 35),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.black.withOpacity(0.05) : Colors.white.withOpacity(0.1),
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                  width: 0.5,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(5, (index) {
                      // index 2 is the center mic button
                      if (index == 2) {
                        return GestureDetector(
                          onTap: () => _showVoiceAssistantOverlay(context),
                          child: Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Colors.purple, Colors.blue],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.mic, color: Colors.white, size: 24),
                          ),
                        );
                      }
                      // Map dock index to page index (skip center mic slot)
                      final int tabIndex = index < 2 ? index : index - 1;
                      final isSelected = _currentIndex == tabIndex;
                      
                      IconData icon;
                      IconData activeIcon;
                      String label;
                      
                      switch (tabIndex) {
                        case 0:
                          icon = Icons.assignment_turned_in_outlined;
                          activeIcon = Icons.assignment_turned_in;
                          label = '待办';
                          break;
                        case 1:
                          icon = Icons.alarm_on_outlined;
                          activeIcon = Icons.alarm_on;
                          label = '打卡';
                          break;
                        case 2:
                          icon = Icons.calendar_month_outlined;
                          activeIcon = Icons.calendar_month;
                          label = '日程';
                          break;
                        case 3:
                          icon = Icons.storefront_outlined;
                          activeIcon = Icons.storefront;
                          label = '商店';
                          break;
                        default:
                          icon = Icons.help_outline;
                          activeIcon = Icons.help;
                          label = '';
                      }
                      
                      final activeColor = Theme.of(context).primaryColor;
                      
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _currentIndex = tabIndex;
                          });
                        },
                        child: Container(
                          color: Colors.transparent,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 1.0, end: isSelected ? 1.25 : 1.0),
                                    duration: const Duration(milliseconds: 200),
                                    curve: Curves.easeOutBack,
                                    builder: (context, scale, child) {
                                      return Transform.scale(
                                        scale: scale,
                                        child: Icon(
                                          isSelected ? activeIcon : icon,
                                          color: isSelected
                                              ? activeColor
                                              : (isDark ? Colors.white54 : Colors.black45),
                                          size: 24,
                                        ),
                                      );
                                    },
                                  ),
                                  if (tabIndex == 0 || tabIndex == 1)
                                    Positioned(
                                      right: -8,
                                      top: -6,
                                      child: Obx(() {
                                        int count = 0;
                                        if (tabIndex == 0) {
                                          count = taskController.tasks.where((t) => !t.isCompleted).length;
                                        } else {
                                          final todayStr = DateTime.now().toString().split(' ')[0];
                                          count = taskController.checkIns.where((c) => !c.history.contains(todayStr)).length;
                                        }
                                        if (count <= 0) return const SizedBox.shrink();
                                        return Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          constraints: const BoxConstraints(
                                            minWidth: 16,
                                            minHeight: 16,
                                          ),
                                          child: Center(
                                            child: Text(
                                              count.toString(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                height: 1.0,
                                              ),
                                            ),
                                          ),
                                        );
                                      }),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                label,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected
                                      ? activeColor
                                      : (isDark ? Colors.white54 : Colors.black45),
                                  fontFamily: 'Inter',
                                ),
                              ),
                              const SizedBox(height: 3),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOutCubic,
                                width: isSelected ? 16 : 0,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: activeColor,
                                  borderRadius: BorderRadius.circular(1.5),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: activeColor.withOpacity(0.5),
                                            blurRadius: 4,
                                            spreadRadius: 0.5,
                                          )
                                        ]
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        ),
    );
  }
  Widget _buildTaskList({required String filter, double topPadding = 0}) {
    return Obx(() {
      final now = DateTime.now();
      final filteredTasks = taskController.tasks.where((t) {
        if (filter == 'completed') {
          return t.isCompleted;
        } else if (filter == 'overdue') {
          return !t.isCompleted && t.deadline != null && t.deadline!.isBefore(now);
        } else {
          return !t.isCompleted && (t.deadline == null || !t.deadline!.isBefore(now));
        }
      }).toList();
      if (filteredTasks.isEmpty) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Center(
          child: Text(
            'no_tasks'.tr, 
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54, 
              fontSize: 16, 
              fontWeight: FontWeight.w500
            )
          )
        );
      }
      if (isGrid) {
        return GridView.builder(
          padding: EdgeInsets.fromLTRB(16, 16 + topPadding, 16, 100),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.0,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: filteredTasks.length,
          itemBuilder: (context, index) {
            var task = filteredTasks[index];
            return SwipeToReveal(
              key: ValueKey(task.id),
              actionWidth: 140,
              actionButton: GestureDetector(
                onTap: () => taskController.deleteTask(task.id),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8, left: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.shade600,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: Icon(Icons.delete, color: Colors.white, size: 48),
                  ),
                ),
              ),
              child: TaskCard(
                task: task,
                isGrid: true,
                index: index,
                onEdit: () => _showEditTaskBottomSheet(context, task),
                onSetTime: () => _showEditTaskBottomSheet(context, task, onlyTime: true),
                onComplete: (tapPosition) => _handleTaskToggle(task, tapPosition),
              ),
            );
          },
        );
      }
      return ListView.builder(
        padding: EdgeInsets.fromLTRB(16, 8 + topPadding, 16, 100),
        itemCount: filteredTasks.length,
        itemBuilder: (context, index) {
          var task = filteredTasks[index];
          return SwipeToReveal(
            key: ValueKey(task.id),
            actionWidth: 140,
            actionButton: GestureDetector(
              onTap: () => taskController.deleteTask(task.id),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8, left: 6),
                decoration: BoxDecoration(
                  color: Colors.red.shade600,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                  child: Icon(Icons.delete, color: Colors.white, size: 48),
                ),
              ),
            ),
            child: TaskCard(
              task: task,
              isGrid: false,
              index: index,
              onEdit: () => _showEditTaskBottomSheet(context, task),
              onSetTime: () => _showEditTaskBottomSheet(context, task, onlyTime: true),
              onComplete: (tapPosition) => _handleTaskToggle(task, tapPosition),
            ),
          );
        },
      );
    });
  }
}
