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
  
  late final AnimationController _coinBarController;
  late final Animation<double> _coinBarScale;

  @override
  void initState() {
    super.initState();
    
    _coinBarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    
    _coinBarScale = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _coinBarController, curve: Curves.easeOut),
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
      MediaQuery.of(context).size.width / 2,
      MediaQuery.of(context).padding.top + 26
    );
    
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

  void _showEditTaskBottomSheet(BuildContext context, TaskModel task) {
    String title = task.title;
    String desc = task.description ?? "";
    String coinStr = task.coinReward.toString();
    String timeOption = task.deadline == null ? "none" : "deadline";
    DateTime? selectedDeadline = task.deadline;
    
    TextEditingController editTitleController = TextEditingController(text: title);
    TextEditingController editDescController = TextEditingController(text: desc);
    TextEditingController editCoinController = TextEditingController(text: coinStr);
    
    bool titleError = false;
    bool coinError = false;

    showDialog(
      context: context,
      builder: (context) {
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
                      Text('edit_task'.tr, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Inter')),
                      const SizedBox(height: 24),
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
                      TextField(
                        controller: editCoinController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                        decoration: InputDecoration(
                          labelText: 'coin_reward'.tr,
                          errorText: coinError ? 'max_10000'.tr : null,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: Icon(Icons.monetization_on, color: Theme.of(context).primaryColor),
                        ),
                        onChanged: (val) {
                          if (coinError) setModalState(() => coinError = false);
                        },
                      ),
                      const SizedBox(height: 20),
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
                            
                            int parsedCoin = int.tryParse(editCoinController.text) ?? 10;
                            if (parsedCoin > 10000) {
                              setModalState(() => coinError = true);
                              return;
                            }
                            if (parsedCoin < 0) parsedCoin = 0;
                            
                            final reallyUpdatedTask = TaskModel(
                              id: task.id,
                              title: editTitleController.text.trim(),
                              description: editDescController.text.trim().isEmpty ? null : editDescController.text.trim(),
                              isCompleted: task.isCompleted,
                              coinReward: parsedCoin,
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
    return Obx(() {
      final themeIndex = themeController.currentThemeIndex.value;
      final colors = AppTheme.getThemeBackgroundColors(themeIndex);
      final isDark = Theme.of(context).brightness == Brightness.dark;
      
      return Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark 
                    ? [colors[0].withOpacity(0.4), const Color(0xFF0C0910)]
                    : [colors[0].withOpacity(0.2), const Color(0xFFF1F5F9)],
              )
            ),
          ),
          
          Positioned(
            top: -100,
            left: -50,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors[1].withOpacity(isDark ? 0.35 : 0.45),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
                child: const SizedBox.shrink(),
              ),
            ),
          ),
          
          Positioned(
            bottom: -80,
            right: -80,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors[2].withOpacity(isDark ? 0.3 : 0.4),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                child: const SizedBox.shrink(),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildCurrentPage() {
    switch (_currentIndex) {
      case 0:
        return DefaultTabController(
          length: 3,
          child: Column(
            children: [
              _buildCoinDisplay(),
              const SizedBox(height: 10),
              TabBar(
                tabs: [
                  Tab(text: 'tab_in_progress'.tr),
                  Tab(text: 'tab_overdue'.tr),
                  Tab(text: 'tab_completed'.tr),
                ],
                indicatorColor: Colors.amber,
                labelColor: Colors.amber,
                unselectedLabelColor: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54,
                dividerColor: Colors.transparent,
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildTaskList(filter: 'in_progress'),
                    _buildTaskList(filter: 'overdue'),
                    _buildTaskList(filter: 'completed'),
                  ],
                ),
              ),
            ],
          ),
        );
      case 1:
        return const CalendarScreen();
      case 2:
        return const SkillsScreen();
      case 3:
        return const AdventureScreen();
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
      appBar: AppBar(
        title: Text(
          _currentIndex == 0
              ? 'app_title'.tr
              : (_currentIndex == 1 
                  ? 'calendar_title'.tr
                  : (_currentIndex == 2 ? 'nav_skills'.tr : 'nav_adventure'.tr)),
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_currentIndex == 0)
            IconButton(
              icon: Icon(isGrid ? Icons.view_list : Icons.grid_view, color: Colors.white),
              onPressed: _toggleView,
            ),
          Obx(() => IconButton(
            icon: Icon(
              settingsController.isMuted.value ? Icons.volume_off : Icons.volume_up,
              color: Colors.white,
            ),
            onPressed: () => settingsController.toggleMute(),
          )),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
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
                if (!settingsController.isMuted.value) {
                  taskController.playSingleCoinSound();
                }
              },
            );
          }).toList(),
        ],
      ),
      floatingActionButton: _currentIndex == 0 
          ? Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () => _showVoiceAssistantOverlay(context),
                  child: Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.purple, Colors.blue],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.mic, color: Colors.white, size: 28),
                  ),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () => _showAddTaskBottomSheet(context),
                  child: Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).primaryColor,
                          Theme.of(context).primaryColor.withOpacity(0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).primaryColor.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 28),
                  ),
                ),
              ],
            )
          : null,
      bottomNavigationBar: Obx(() {
        final themeIndex = themeController.currentThemeIndex.value;
        final colors = AppTheme.getThemeBackgroundColors(themeIndex);
        
        return ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.black.withOpacity(0.3) : Colors.white.withOpacity(0.55),
                border: Border(
                  top: BorderSide(color: Colors.white.withOpacity(0.15), width: 1.5),
                ),
              ),
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.transparent,
                elevation: 0,
                selectedItemColor: Colors.amber.shade700,
                unselectedItemColor: isDark ? Colors.white54 : Colors.black45,
                selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
                items: [
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.assignment),
                    label: 'nav_tasks'.tr,
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.calendar_month),
                    label: 'calendar_title'.tr,
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.auto_awesome),
                    label: 'nav_skills'.tr,
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.person),
                    label: 'nav_adventure'.tr,
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildCoinDisplay() {
    return ScaleTransition(
      scale: _coinBarScale,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Obx(() => Text(
              taskController.userTitle,
              style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 16, fontStyle: FontStyle.italic),
            )),
            const SizedBox(width: 8),
            Obx(() => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.shade800,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "Lv.${taskController.userLevel}",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Inter'),
              ),
            )),
            const SizedBox(width: 8),
            const Icon(Icons.monetization_on, color: Colors.amber, size: 32),
            const SizedBox(width: 12),
            Obx(() => AnimatedCoinCounter(
              value: taskController.totalCoins.value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskList({required String filter}) {
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
          padding: const EdgeInsets.all(16),
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
                  margin: const EdgeInsets.only(bottom: 16, left: 6),
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
                onComplete: (tapPosition) => _handleTaskToggle(task, tapPosition),
              ),
            );
          },
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filteredTasks.length,
        itemBuilder: (context, index) {
          var task = filteredTasks[index];
          return SwipeToReveal(
            key: ValueKey(task.id),
            actionWidth: 140,
            actionButton: GestureDetector(
              onTap: () => taskController.deleteTask(task.id),
              child: Container(
                margin: const EdgeInsets.only(bottom: 16, left: 6),
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
              onComplete: (tapPosition) => _handleTaskToggle(task, tapPosition),
            ),
          );
        },
      );
    });
  }
}