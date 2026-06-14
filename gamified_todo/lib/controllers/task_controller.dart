import 'package:get/get.dart';
import '../models/task_model.dart';

class TaskController extends GetxController {
  // 观察状态的响应式列表
  var tasks = <TaskModel>[].obs;
  
  // 用户的金币总数
  var totalCoins = 0.obs;

  @override
  void onInit() {
    super.onInit();
    // 模拟从数据库加载数据
    loadMockTasks();
  }

  void loadMockTasks() {
    tasks.assignAll([
      TaskModel(title: "喝一杯水", coinReward: 10, priority: TaskPriority.low),
      TaskModel(title: "完成待办APP需求文档", coinReward: 100, priority: TaskPriority.high),
      TaskModel(title: "去健身房锻炼一小时", coinReward: 50, priority: TaskPriority.medium),
    ]);
  }

  // 添加任务
  void addTask(TaskModel task) {
    tasks.add(task);
  }

  // 完成任务
  void completeTask(String id) {
    var index = tasks.indexWhere((task) => task.id == id);
    if (index != -1) {
      var task = tasks[index];
      if (!task.isCompleted) {
        var updatedTask = task.copyWith(isCompleted: true);
        tasks[index] = updatedTask;
        // 增加金币
        totalCoins.value += task.coinReward;
        
        // TODO: 触发金币掉落动画和音效
      }
    }
  }

  // 删除任务
  void deleteTask(String id) {
    tasks.removeWhere((task) => task.id == id);
  }
}
