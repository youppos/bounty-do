import 'package:get/get.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/task_model.dart';
import 'skill_controller.dart';
import '../utils/snackbar_utils.dart';

class TaskController extends GetxController {
  // 观察状态的响应式列表
  var tasks = <TaskModel>[].obs;
  
  // 用户的金币总数
  var totalCoins = 0.obs;
  
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

  @override
  void onInit() {
    super.onInit();
    if (isTesting) {
      totalCoins.value = 0;
    } else {
      totalCoins.value = 15000; // Start with 15000 coins for testing
    }
    if (!isTesting) {
      _initAudio();
    }
    // 模拟从数据库加载数据
    loadMockTasks();
  }

  void _initAudio() {
    _audioPlayers.addAll(List.generate(5, (_) => AudioPlayer()));
    for (var player in _audioPlayers) {
      player.setReleaseMode(ReleaseMode.stop);
      player.setSource(AssetSource('audio/jackpot.wav'));
    }
  }

  void loadMockTasks() {
    final now = DateTime.now();
    tasks.assignAll([
      TaskModel(title: 'Test 10 Coins (No Time)', coinReward: 10, levelIndex: 1),
      TaskModel(title: 'Test 50 Coins (Overdue)', coinReward: 5, levelIndex: 1, deadline: now.subtract(const Duration(hours: 1))),
      TaskModel(title: 'Test 100 Coins (Due soon)', coinReward: 15, levelIndex: 1, deadline: now.add(const Duration(hours: 2, minutes: 30))),
      TaskModel(title: 'Test 200 Coins (Tomorrow)', coinReward: 15, levelIndex: 1, deadline: now.add(const Duration(days: 1, hours: 5))),
      TaskModel(title: 'Test 500 Coins', coinReward: 15, levelIndex: 2),
      TaskModel(title: 'Test 1000 Coins', coinReward: 30, levelIndex: 3),
      TaskModel(title: 'Test 2000 Coins', coinReward: 60, levelIndex: 4),
      TaskModel(title: 'Test 5000 Coins', coinReward: 100, levelIndex: 4),
      TaskModel(title: 'Test 10000 Coins', coinReward: 100, levelIndex: 4),
    ]);
  }

  // 切换全局时间展示模式
  void toggleTimeDisplayMode() {
    showAsCountdown.value = !showAsCountdown.value;
  }

  // 添加任务
  void addTask(TaskModel task) {
    tasks.add(task);
  }

  // 更新任务
  void updateTask(String id, TaskModel updatedTask) {
    var index = tasks.indexWhere((task) => task.id == id);
    if (index != -1) {
      tasks[index] = updatedTask;
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
      
      // 更新金币
      if (isCompleted) {
        // 延迟900毫秒更新金币（等待飞行金币动画到达目标点再开始数字滚动）
        Future.delayed(const Duration(milliseconds: 900), () {
          totalCoins.value += finalReward;
        });
      } else {
        totalCoins.value -= task.coinReward;
        if (totalCoins.value < 0) totalCoins.value = 0;
      }
    }
  }

  // 切换任务闹钟状态
  void toggleAlarm(String id) {
    var index = tasks.indexWhere((task) => task.id == id);
    if (index != -1) {
      tasks[index] = tasks[index].copyWith(hasAlarm: !tasks[index].hasAlarm);
    }
  }

  // 切换任务提醒状态
  void toggleReminder(String id) {
    var index = tasks.indexWhere((task) => task.id == id);
    if (index != -1) {
      tasks[index] = tasks[index].copyWith(hasReminder: !tasks[index].hasReminder);
    }
  }

  void playSingleCoinSound() {
    try {
      final player = _audioPlayers[_currentPlayerIndex];
      _currentPlayerIndex = (_currentPlayerIndex + 1) % _audioPlayers.length;
      
      // Fire and forget, but use preloaded source
      player.seek(Duration.zero).then((_) {
        player.resume();
      });
    } catch (e) {
      print('Error playing audio: $e');
    }
  }

  // 删除任务
  void deleteTask(String id) {
    tasks.removeWhere((task) => task.id == id);
  }
}
