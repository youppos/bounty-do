import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:get/get.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_model.dart';
import '../models/check_in_model.dart';
import 'skill_controller.dart';
import '../utils/snackbar_utils.dart';
import '../ui/widgets/alarm_trigger_dialog.dart';
import '../services/notification_service.dart';

class TaskController extends GetxController {
  // 观察状态的响应式列表
  var tasks = <TaskModel>[].obs;
  var checkIns = <CheckInModel>[].obs;
  
  // 用户的金币总数
  var totalCoins = 0.obs;

  // 闹钟控制与状态
  final AudioPlayer _alarmPlayer = AudioPlayer();
  final Rxn<TaskModel> activeAlarmTask = Rxn<TaskModel>();
  Timer? _alarmCheckTimer;
  final Set<String> _triggeredAlarmTaskIds = {};
  
  // 用户等级计算逻辑
  int get userLevel {
    int coins = totalCoins.value;
    if (coins < 100) return 1;
    if (coins < 500) return 2;
    if (coins < 1000) return 3;
    // 1000+ 后，每 2000 金币升一级
    return 3 + ((coins - 1000) ~/ 2000) + 1;
  }

  // 根据用户等级计算头衔
  String get userTitle {
    int lvl = userLevel;
    if (lvl < 5) return 'title_rookie'.tr;
    if (lvl < 10) return 'title_awakened'.tr;
    if (lvl < 15) return 'title_apprentice'.tr;
    if (lvl < 20) return 'title_expert'.tr;
    if (lvl < 30) return 'title_master'.tr;
    if (lvl < 50) return 'title_time_lord'.tr;
    return 'title_legend'.tr;
  }

  // 全局时间展示模式：true 为倒计时，false 为截止日期
  var showAsCountdown = true.obs;

  static bool isTesting = false;
  final List<AudioPlayer> _audioPlayers = [];
  int _currentPlayerIndex = 0;

  // 每日任务创建上限逻辑
  int get dailyTaskLimit {
    return (3 + (userLevel - 1)).clamp(3, 20);
  }

  int getTasksCreatedTodayCount() {
    final today = DateTime.now();
    return tasks.where((t) =>
      t.createdAt.year == today.year &&
      t.createdAt.month == today.month &&
      t.createdAt.day == today.day
    ).length;
  }

  bool canCreateTaskToday() {
    return getTasksCreatedTodayCount() < dailyTaskLimit;
  }

  final _prefs = SharedPreferences.getInstance();
  late final Future<void> initialization;

  @override
  void onInit() {
    super.onInit();
    initialization = _loadPersistedData();
    if (!isTesting) {
      _initAudio();
      _startAlarmCheckTimer();
    }
    
    // 监听闹钟触发
    ever(activeAlarmTask, (task) {
      if (task != null) {
        Get.dialog(
          AlarmTriggerDialog(task: task),
          barrierDismissible: false,
        );
      }
    });

    // 响应式自动保存金币与时间展示模式
    ever(totalCoins, (_) => _saveCoins());
    ever(showAsCountdown, (_) => _saveCountdownMode());
  }

  Future<void> _loadPersistedData() async {
    final prefs = await _prefs;

    // 1. 加载金币总数
    if (prefs.containsKey('total_coins')) {
      totalCoins.value = prefs.getInt('total_coins') ?? 0;
    } else {
      totalCoins.value = isTesting ? 0 : 3000;
      await prefs.setInt('total_coins', totalCoins.value);
    }

    // 2. 加载全局时间展示模式
    if (prefs.containsKey('show_as_countdown')) {
      showAsCountdown.value = prefs.getBool('show_as_countdown') ?? true;
    }

    // 3. 加载任务列表
    final String? tasksJson = prefs.getString('saved_tasks');
    if (tasksJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(tasksJson);
        final loadedTasks = decoded
            .map((item) => TaskModel.fromMap(item as Map<String, dynamic>))
            .toList();
        tasks.assignAll(loadedTasks);
      } catch (e) {
        print('Error loading tasks from preferences: $e');
        loadMockTasks();
        await _saveTasks();
      }
    } else {
      loadMockTasks();
      await _saveTasks();
    }

    // 4. 加载打卡项目列表
    final String? checkInsJson = prefs.getString('saved_check_ins');
    if (checkInsJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(checkInsJson);
        final loadedCheckIns = decoded
            .map((item) => CheckInModel.fromMap(item as Map<String, dynamic>))
            .toList();
        checkIns.assignAll(loadedCheckIns);
      } catch (e) {
        print('Error loading checkIns from preferences: $e');
        loadMockCheckIns();
        await _saveCheckIns();
      }
    } else {
      loadMockCheckIns();
      await _saveCheckIns();
    }

    // 同步离线系统通知与强闹钟
    NotificationService().rescheduleAll(tasks: tasks, checkIns: checkIns);
  }

  Future<void> _saveTasks() async {
    try {
      final prefs = await _prefs;
      final listMap = tasks.map((t) => t.toMap()).toList();
      await prefs.setString('saved_tasks', jsonEncode(listMap));
    } catch (e) {
      print('Error saving tasks: $e');
    }
  }

  void saveTasks() {
    _saveTasks();
  }

  Future<void> _saveCheckIns() async {
    try {
      final prefs = await _prefs;
      final listMap = checkIns.map((c) => c.toMap()).toList();
      await prefs.setString('saved_check_ins', jsonEncode(listMap));
    } catch (e) {
      print('Error saving checkIns: $e');
    }
  }

  void saveCheckIns() {
    _saveCheckIns();
  }

  Future<void> _saveCoins() async {
    try {
      final prefs = await _prefs;
      await prefs.setInt('total_coins', totalCoins.value);
    } catch (e) {
      print('Error saving coins: $e');
    }
  }

  void saveCoins() {
    _saveCoins();
  }

  Future<void> _saveCountdownMode() async {
    try {
      final prefs = await _prefs;
      await prefs.setBool('show_as_countdown', showAsCountdown.value);
    } catch (e) {
      print('Error saving countdown mode: $e');
    }
  }

  @override
  void onClose() {
    _alarmCheckTimer?.cancel();
    _alarmPlayer.dispose();
    super.onClose();
  }

  void _initAudio() {
    _audioPlayers.addAll(List.generate(5, (_) => AudioPlayer()));
    for (var player in _audioPlayers) {
      player.setReleaseMode(ReleaseMode.stop);
      player.setSource(AssetSource('audio/coin.wav'));
    }
  }

  void loadMockTasks() {
    final now = DateTime.now();
    tasks.assignAll([
      TaskModel(title: 'Test 2 Coins (No Time)', coinReward: 2, levelIndex: 1),
      TaskModel(title: 'Test 10 Coins (Overdue)', coinReward: 1, levelIndex: 1, deadline: now.subtract(const Duration(hours: 1))),
      TaskModel(title: 'Test 20 Coins (Due soon)', coinReward: 3, levelIndex: 1, deadline: now.add(const Duration(hours: 2, minutes: 30))),
      TaskModel(title: 'Test 40 Coins (Tomorrow)', coinReward: 3, levelIndex: 1, deadline: now.add(const Duration(days: 1, hours: 5))),
      TaskModel(title: 'Test 100 Coins', coinReward: 3, levelIndex: 2),
      TaskModel(title: 'Test 200 Coins', coinReward: 6, levelIndex: 3),
      TaskModel(title: 'Test 400 Coins', coinReward: 12, levelIndex: 4),
      TaskModel(title: 'Test 1000 Coins', coinReward: 20, levelIndex: 4),
      TaskModel(title: 'Test 2000 Coins', coinReward: 20, levelIndex: 4),
    ]);
  }

  // 切换全局时间展示模式
  void toggleTimeDisplayMode() {
    showAsCountdown.value = !showAsCountdown.value;
    _saveCountdownMode();
  }

  // 添加任务
  void addTask(TaskModel task) {
    tasks.add(task);
    _saveTasks();
    NotificationService().scheduleTaskAlarmOrReminder(task);
  }

  // 更新任务
  void updateTask(String id, TaskModel updatedTask) {
    var index = tasks.indexWhere((task) => task.id == id);
    if (index != -1) {
      tasks[index] = updatedTask;
      _saveTasks();
      NotificationService().scheduleTaskAlarmOrReminder(updatedTask);
    }
  }

  // 切换任务完成状态
  void toggleTaskCompletion(String id) {
    var index = tasks.indexWhere((task) => task.id == id);
    if (index != -1) {
      var task = tasks[index];
      bool isCompleted = !task.isCompleted;
      
      final now = DateTime.now();
      int finalReward = task.coinReward;
      
      if (isCompleted) {
        final isOverdue = task.deadline != null && task.deadline!.isBefore(now);
        final skillController = Get.find<SkillController>();
        
        int baseReward = task.calculateRewardAt(now);
        if (isOverdue && skillController.isShieldActive) {
          baseReward = TaskModel.getMinCoinsForLevel(task.levelIndex);
          SnackbarUtils.showSuccess(
            title: 'shield_protected'.tr,
            message: 'purchase_success'.tr,
          );
        } else if (isOverdue) {
          SnackbarUtils.showInfo(
            title: 'overdue_penalty_applied'.tr,
            message: 'purchase_success'.tr,
          );
        }
        
        finalReward = baseReward;
        if (skillController.useDoubleGoldCharge()) {
          finalReward = baseReward * 2;
        }
      }
      
      var updatedTask = task.copyWith(
        isCompleted: isCompleted,
        completedAt: isCompleted ? now : null,
        coinReward: finalReward, // Freeze the reward in the model
      );
      tasks[index] = updatedTask;
      _saveTasks();

      // 同步系统通知：完成则取消，重新未完成则重新规划
      if (isCompleted) {
        NotificationService().cancelTaskNotification(id);
      } else {
        NotificationService().scheduleTaskAlarmOrReminder(updatedTask);
      }
      
      // 更新金币
      if (isCompleted) {
        // 延迟900毫秒更新金币（等待飞行金币动画到达目标点再开始数字滚动）
        Future.delayed(const Duration(milliseconds: 900), () {
          totalCoins.value += finalReward;
          _saveCoins();
        });
      } else {
        totalCoins.value -= task.coinReward;
        if (totalCoins.value < 0) totalCoins.value = 0;
        _saveCoins();
      }
    }
  }

  // 切换任务闹钟状态
  void toggleAlarm(String id) {
    var index = tasks.indexWhere((task) => task.id == id);
    if (index != -1) {
      tasks[index] = tasks[index].copyWith(hasAlarm: !tasks[index].hasAlarm);
      _saveTasks();
      NotificationService().scheduleTaskAlarmOrReminder(tasks[index]);
    }
  }

  // 切换任务提醒状态
  void toggleReminder(String id) {
    var index = tasks.indexWhere((task) => task.id == id);
    if (index != -1) {
      tasks[index] = tasks[index].copyWith(hasReminder: !tasks[index].hasReminder);
      _saveTasks();
      NotificationService().scheduleTaskAlarmOrReminder(tasks[index]);
    }
  }

  void playSingleCoinSound() {
    try {
      final player = _audioPlayers[_currentPlayerIndex];
      _currentPlayerIndex = (_currentPlayerIndex + 1) % _audioPlayers.length;
      
      // Fire and forget, but use preloaded source
      player.seek(Duration.zero).then((_) {
        player.resume();
        Future.delayed(const Duration(milliseconds: 800), () {
          try {
            player.stop();
            player.setSource(AssetSource('audio/coin.wav'));
          } catch (_) {}
        });
      });
    } catch (e) {
      print('Error playing audio: $e');
    }
  }

  void stopAllCoinSounds() {
    for (var player in _audioPlayers) {
      try {
        player.stop();
        player.setSource(AssetSource('audio/coin.wav'));
      } catch (e) {
        print('Error stopping audio: $e');
      }
    }
  }

  // 删除任务
  void deleteTask(String id) {
    tasks.removeWhere((task) => task.id == id);
    _saveTasks();
    NotificationService().cancelTaskNotification(id);
  }

  // 添加打卡项目
  void addCheckIn(CheckInModel item) {
    checkIns.add(item);
    _saveCheckIns();
    NotificationService().scheduleCheckInReminder(item);
  }

  // 更新打卡项目
  void updateCheckIn(String id, CheckInModel updatedItem) {
    var index = checkIns.indexWhere((item) => item.id == id);
    if (index != -1) {
      checkIns[index] = updatedItem;
      _saveCheckIns();
      NotificationService().scheduleCheckInReminder(updatedItem);
    }
  }

  // 删除打卡项目
  void deleteCheckIn(String id) {
    checkIns.removeWhere((item) => item.id == id);
    _saveCheckIns();
    NotificationService().cancelCheckInNotification(id);
  }

  // 切换打卡完成状态
  void toggleCheckInStatus(String id, String dateStr) {
    var index = checkIns.indexWhere((item) => item.id == id);
    if (index != -1) {
      var item = checkIns[index];
      var history = List<String>.from(item.history);
      final isCompleted = history.contains(dateStr);
      if (isCompleted) {
        history.remove(dateStr);
      } else {
        history.add(dateStr);
      }
      checkIns[index] = item.copyWith(history: history);
      _saveCheckIns();

      if (!isCompleted) {
        final reward = item.levelIndex == 0 ? 1 : 3;
        Future.delayed(const Duration(milliseconds: 900), () {
          totalCoins.value += reward;
          _saveCoins();
        });
      } else {
        final reward = item.levelIndex == 0 ? 1 : 3;
        totalCoins.value -= reward;
        if (totalCoins.value < 0) totalCoins.value = 0;
        _saveCoins();
      }
    }
  }

  void loadMockCheckIns() {
    checkIns.assignAll([
      CheckInModel(title: '喝一杯水', levelIndex: 0, frequencyType: 'daily'),
      CheckInModel(
        title: '锻炼30分钟', 
        levelIndex: 1, 
        frequencyType: 'weekly', 
        weeklyDays: [1, 2, 3, 4, 5],
      ),
      CheckInModel(
        title: '阅读30分钟', 
        levelIndex: 0, 
        frequencyType: 'weekly', 
        weeklyDays: [6, 7],
      ),
    ]);
  }

  // 启动闹钟检测定时器
  void _startAlarmCheckTimer() {
    _alarmCheckTimer?.cancel();
    _alarmCheckTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _checkAlarms();
    });
  }

  // 轮询检测是否到达截止时间
  void _checkAlarms() {
    if (activeAlarmTask.value != null) return; // 已经有闹钟在响，先不触发新的

    final now = DateTime.now();
    for (var task in tasks) {
      if (task.hasAlarm && !task.isCompleted && task.deadline != null) {
        if (now.isAfter(task.deadline!) && !_triggeredAlarmTaskIds.contains(task.id)) {
          _triggeredAlarmTaskIds.add(task.id);
          _triggerAlarm(task);
          break; // 每次只触发一个闹钟
        }
      }
    }
  }

  // 触发闹钟
  void _triggerAlarm(TaskModel task) {
    activeAlarmTask.value = task;
    playAlarmSound(task);
  }

  // 播放闹钟铃声
  Future<void> playAlarmSound(TaskModel task) async {
    try {
      await _alarmPlayer.stop();
      _alarmPlayer.setReleaseMode(ReleaseMode.loop);

      if (task.ringtoneType == 'custom') {
        if (task.ringtoneBase64 != null) {
          final Uint8List bytes = base64Decode(task.ringtoneBase64!);
          await _alarmPlayer.play(BytesSource(bytes));
        } else if (task.ringtonePath != null) {
          await _alarmPlayer.play(DeviceFileSource(task.ringtonePath!));
        } else {
          // 备用播放默认铃声
          await _alarmPlayer.play(AssetSource('audio/jackpot.wav'));
        }
      } else {
        // 播放内置铃声
        final path = task.ringtonePath ?? 'audio/jackpot.wav';
        await _alarmPlayer.play(AssetSource(path));
      }
    } catch (e) {
      print('Error playing alarm audio: $e');
    }
  }

  // 停止播放闹钟铃声
  Future<void> stopAlarmSound() async {
    try {
      await _alarmPlayer.stop();
    } catch (e) {
      print('Error stopping alarm audio: $e');
    }
  }

  // 贪睡（延迟10分钟）
  void snoozeAlarm(String id) {
    var index = tasks.indexWhere((task) => task.id == id);
    if (index != -1) {
      stopAlarmSound();
      activeAlarmTask.value = null;
      // 顺延10分钟
      tasks[index] = tasks[index].copyWith(
        deadline: DateTime.now().add(const Duration(minutes: 10)),
      );
      // 移出已触发列表，使其到期时能再次触发
      _triggeredAlarmTaskIds.remove(id);
      _saveTasks();
      NotificationService().scheduleTaskAlarmOrReminder(tasks[index]);
      if (Get.isDialogOpen == true) {
        Get.back(); // 关闭闹钟弹窗
      }
      SnackbarUtils.showInfo(
        title: '闹钟已延迟',
        message: '任务截止时间已延时10分钟。',
      );
    }
  }

  // 关闭/忽略闹钟（仅关闭声音和弹窗，保持任务未完成）
  void dismissAlarm() {
    stopAlarmSound();
    activeAlarmTask.value = null;
    if (Get.isDialogOpen == true) {
      Get.back(); // 关闭闹钟弹窗
    }
  }

  // 立即完成任务（关闭闹钟并触发完成结算）
  void completeAlarmTask(String id) {
    stopAlarmSound();
    activeAlarmTask.value = null;
    if (Get.isDialogOpen == true) {
      Get.back(); // 关闭闹钟弹窗
    }
    toggleTaskCompletion(id);
  }
}
