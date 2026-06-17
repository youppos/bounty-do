import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/task_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../models/task_model.dart';
import '../../utils/snackbar_utils.dart';

class VoiceAssistantOverlay extends StatefulWidget {
  const VoiceAssistantOverlay({super.key});

  @override
  State<VoiceAssistantOverlay> createState() => _VoiceAssistantOverlayState();
}

class _VoiceAssistantOverlayState extends State<VoiceAssistantOverlay> with TickerProviderStateMixin {
  final TaskController taskController = Get.find();
  final SettingsController settingsController = Get.find();
  final TextEditingController _textController = TextEditingController();

  late AnimationController _pulseController;
  late AnimationController _waveController;
  
  bool _isListening = true;
  String _statusText = "";
  
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    
    _statusText = 'voice_listening'.tr;
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _startListening() {
    setState(() {
      _isListening = true;
      _statusText = 'voice_listening'.tr;
    });
  }

  void _stopListeningAndParse(String text) {
    setState(() {
      _isListening = false;
      _statusText = 'voice_mic_tap'.tr;
      _textController.clear();
    });
    
    if (text.trim().isEmpty) return;

    _parseCommand(text.trim());
  }

  // NLP Command Parser (Speech-to-JSON NLP parser)
  void _parseCommand(String text) {
    final lowerText = text.toLowerCase();
    
    // 1. Check if it's a Complete/Check-in command
    // e.g. "我要去打卡喝水任务", "打卡喝水", "完成健身任务", "我要打卡喝水"
    if (lowerText.contains("打卡") || lowerText.contains("完成") || lowerText.contains("check") || lowerText.contains("complete")) {
      // Extract task title. E.g. strip "我要去打卡", "任务", "完成"
      String targetTitle = text
          .replaceAll(RegExp(r'(我要去|我要|去|打卡|完成|任务|check|complete|done)'), '')
          .trim();
          
      if (targetTitle.isEmpty) {
        SnackbarUtils.showError(title: 'error'.tr, message: 'Could not detect task title.');
        return;
      }

      // Find task matching this title
      final matchingTask = taskController.tasks.firstWhereOrNull(
        (t) => t.title.toLowerCase().contains(targetTitle.toLowerCase()) && !t.isCompleted
      );

      if (matchingTask != null) {
        taskController.toggleTaskCompletion(matchingTask.id);
        SnackbarUtils.showSuccess(
          title: 'success'.tr,
          message: 'Task "${matchingTask.title}" marked completed!',
        );
        Navigator.pop(context);
      } else {
        SnackbarUtils.showInfo(
          title: 'info'.tr,
          message: 'Active task matching "$targetTitle" not found. Creating it first.',
        );
        // Fallback to creating a task and completing it
        _createTaskFromVoice(targetTitle, isImmediateComplete: true);
      }
      return;
    }

    // 2. Check if it's a Create command
    // e.g. "新建健身任务，等级是紧急，截止日期是明天", "新建喝水任务"
    String taskTitle = text
        .replaceAll(RegExp(r'(新建|创建|添加|添加一个|new|create|add)'), '')
        .replaceAll(RegExp(r'(任务)'), '')
        .trim();

    // Parse out parameters if they exist
    int? levelIndex;
    DateTime? deadline;

    // Check level index keywords
    for (int i = 0; i < 5; i++) {
      final name = settingsController.getLevelName(i);
      if (text.contains(name)) {
        levelIndex = i;
        break;
      }
    }
    
    // Extra keyword checks for levels
    if (levelIndex == null) {
      if (text.contains("一般") || text.contains("普通") || text.contains("normal") || text.contains("common")) levelIndex = 0;
      else if (text.contains("重要") || text.contains("优秀") || text.contains("important") || text.contains("uncommon")) levelIndex = 1;
      else if (text.contains("紧急") || text.contains("稀有") || text.contains("urgent") || text.contains("rare")) levelIndex = 2;
      else if (text.contains("重要且紧急") || text.contains("史诗") || text.contains("epic")) levelIndex = 3;
      else if (text.contains("极其重要紧急") || text.contains("传说") || text.contains("legendary")) levelIndex = 4;
    }

    // Check deadline keywords
    if (text.contains("今天") || text.contains("today")) {
      deadline = DateTime.now().add(const Duration(hours: 4)); // Today, say 4 hours from now
    } else if (text.contains("明天") || text.contains("tomorrow")) {
      deadline = DateTime.now().add(const Duration(days: 1)); // Tomorrow
    } else if (text.contains("后天") || text.contains("day after tomorrow")) {
      deadline = DateTime.now().add(const Duration(days: 2));
    }

    // Clean up title by removing Level/Deadline keywords
    taskTitle = taskTitle
        .split(RegExp(r'(等级是|等级为|截止|截止日期是|时间是|级别是|level|deadline)'))[0]
        .trim();

    if (taskTitle.isEmpty) {
      SnackbarUtils.showError(title: 'error'.tr, message: 'Could not detect task title.');
      return;
    }

    _createTaskFromVoice(taskTitle, levelIndex: levelIndex, deadline: deadline);
  }

  void _createTaskFromVoice(String title, {int? levelIndex, DateTime? deadline, bool isImmediateComplete = false}) {
    // Check daily limits
    if (!taskController.canCreateTaskToday()) {
      showDialog(
        context: context,
        builder: (context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return AlertDialog(
            backgroundColor: isDark ? Colors.grey[900] : Colors.white,
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

    // If levelIndex or deadline are null, apply historical habit fallback
    int finalLevel = levelIndex ?? 0;
    DateTime? finalDeadline = deadline;
    bool foundHabit = false;

    // Look for previous task with similar title
    final similarTask = taskController.tasks.firstWhereOrNull(
      (t) => t.title.toLowerCase().contains(title.toLowerCase())
    );

    if (similarTask != null) {
      foundHabit = true;
      if (levelIndex == null) {
        finalLevel = similarTask.levelIndex;
      }
      if (deadline == null && similarTask.deadline != null) {
        // Apply relative deadline duration
        final originalDuration = similarTask.deadline!.difference(similarTask.createdAt);
        finalDeadline = DateTime.now().add(originalDuration);
      }
    }

    int defaultReward = TaskModel.getMinCoinsForLevel(finalLevel);
    if (finalDeadline != null) {
      // Dynamic rewards starting value is max coins
      defaultReward = TaskModel.getMaxCoinsForLevel(finalLevel);
    }

    final newTask = TaskModel(
      title: title,
      levelIndex: finalLevel,
      coinReward: defaultReward,
      deadline: finalDeadline,
    );

    taskController.addTask(newTask);

    if (isImmediateComplete) {
      taskController.toggleTaskCompletion(newTask.id);
    }

    SnackbarUtils.showSuccess(
      title: 'create_task'.tr,
      message: 'Added task "$title" (Level ${finalLevel + 1})' + 
          (foundHabit ? " [Applied habit fallback]" : ""),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          color: isDark ? Colors.black.withOpacity(0.65) : Colors.white.withOpacity(0.65),
          padding: const EdgeInsets.all(24),
          child: SafeArea(
            child: Stack(
              children: [
                // Top close button
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: Icon(Icons.close, color: isDark ? Colors.white : Colors.black87, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),

                // Centered Mic and Status Text
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Status text indicator
                      Text(
                        _statusText,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white70 : Colors.black87,
                          fontFamily: 'Inter',
                        ),
                      ),
                      
                      const SizedBox(height: 40),

                      // Pulsing Mic wave representation
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          if (_isListening)
                            AnimatedBuilder(
                              animation: _waveController,
                              builder: (context, child) {
                                return Container(
                                  width: 140 + (_waveController.value * 100),
                                  height: 140 + (_waveController.value * 100),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: primaryColor.withOpacity(0.15 * (1.0 - _waveController.value)),
                                  ),
                                );
                              },
                            ),
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Container(
                                width: 120 + (_pulseController.value * 15),
                                height: 120 + (_pulseController.value * 15),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [Colors.purple, Colors.blue],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blue.withOpacity(0.4),
                                      blurRadius: 15,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      if (_isListening) {
                                        _stopListeningAndParse(_textController.text);
                                      } else {
                                        _startListening();
                                      }
                                    },
                                    customBorder: const CircleBorder(),
                                    child: const Icon(
                                      Icons.mic,
                                      color: Colors.white,
                                      size: 48,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      // A fixed offset to raise the center of weight slightly upwards
                      const SizedBox(height: 80),
                    ],
                  ),
                ),

                // Bottom content (Input bar & Templates)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Text Simulation Input box
                      AnimatedOpacity(
                        opacity: _isListening ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: _isListening ? 50.0 : 0.0,
                          curve: Curves.easeInOut,
                          child: IgnorePointer(
                            ignoring: !_isListening,
                            child: SingleChildScrollView(
                              physics: const NeverScrollableScrollPhysics(),
                              child: Container(
                                height: 50.0,
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _textController,
                                        style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontFamily: 'Inter'),
                                        decoration: InputDecoration(
                                          hintText: 'Type voice simulation here...',
                                          hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
                                          border: InputBorder.none,
                                        ),
                                        onSubmitted: _stopListeningAndParse,
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.send, color: primaryColor),
                                      onPressed: () => _stopListeningAndParse(_textController.text),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Helper templates
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'voice_suggestions'.tr,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                                fontSize: 14,
                                fontFamily: 'Inter',
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildSuggestionItem("“新建 去健身房，等级是 紧急，截止日期是 明天”"),
                            const SizedBox(height: 4),
                            _buildSuggestionItem("“我要打卡 喝一杯水”"),
                            const SizedBox(height: 4),
                            _buildSuggestionItem("“新建 读书” (将自动应用历史习惯设置)"),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionItem(String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        // Strip quotes and paste into simulation bar
        final cleanText = text.replaceAll("“", "").replaceAll("”", "").split(" (")[0];
        _textController.text = cleanText;
        if (!_isListening) {
          _startListening();
        }
        setState(() {});
      },
      child: Text(
        text,
        style: TextStyle(
          color: isDark ? Colors.white70 : Colors.black87,
          fontSize: 13,
          fontFamily: 'Inter',
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}
