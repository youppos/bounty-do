import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import '../../controllers/task_controller.dart';
import '../../controllers/theme_controller.dart';
import '../widgets/task_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final TaskController taskController = Get.find();
  final ThemeController themeController = Get.find();
  
  bool isGrid = false;
  bool showLottie = false;
  
  // Lottie 动画控制器
  late final AnimationController _lottieController;

  @override
  void initState() {
    super.initState();
    _lottieController = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _lottieController.dispose();
    super.dispose();
  }

  void _toggleView() {
    setState(() {
      isGrid = !isGrid;
    });
  }

  void _handleTaskComplete(String taskId) {
    taskController.completeTask(taskId);
    
    // 触发金币掉落动效
    setState(() {
      showLottie = true;
    });
    
    _lottieController.forward(from: 0).then((_) {
      setState(() {
        showLottie = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Bounty-Do', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(isGrid ? Icons.view_list : Icons.grid_view, color: Colors.white),
            onPressed: _toggleView,
          ),
          IconButton(
            icon: const Icon(Icons.color_lens, color: Colors.white),
            onPressed: () {
              int next = (themeController.currentThemeIndex.value + 1) % 5;
              themeController.changeTheme(next);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // 背景
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).primaryColor.withOpacity(0.8),
                  Theme.of(context).scaffoldBackgroundColor,
                ]
              )
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                _buildCoinDisplay(),
                const SizedBox(height: 10),
                Expanded(child: _buildTaskList()),
              ],
            ),
          ),

          // 金币爆出的 Lottie 动效层 (全屏遮罩)
          if (showLottie)
            Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: Lottie.network(
                    'https://assets3.lottiefiles.com/packages/lf20_touohxv0.json', // 这是一个免费的金币撒花 Lottie 动画占位
                    controller: _lottieController,
                    onLoaded: (composition) {
                      _lottieController.duration = composition.duration;
                      _lottieController.forward();
                    },
                    errorBuilder: (context, error, stackTrace) {
                      // 如果网络动画加载失败，显示文字占位
                      return const Center(child: Text("金币掉落中...", style: TextStyle(color: Colors.amber, fontSize: 24, fontWeight: FontWeight.bold)));
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.amber,
        onPressed: () {
          // TODO: 添加任务弹窗
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildCoinDisplay() {
    return Container(
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
          const Icon(Icons.monetization_on, color: Colors.amber, size: 32),
          const SizedBox(width: 12),
          Obx(() => Text(
            "${taskController.totalCoins.value}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              fontFamily: 'Inter',
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildTaskList() {
    return Obx(() {
      if (taskController.tasks.isEmpty) {
        return const Center(child: Text("暂无任务，开始赚金币吧！", style: TextStyle(color: Colors.white, fontSize: 18)));
      }

      if (isGrid) {
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: taskController.tasks.length,
          itemBuilder: (context, index) {
            var task = taskController.tasks[index];
            return TaskCard(
              task: task,
              isGrid: true,
              onComplete: () => _handleTaskComplete(task.id),
            );
          },
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: taskController.tasks.length,
        itemBuilder: (context, index) {
          var task = taskController.tasks[index];
          return TaskCard(
            task: task,
            isGrid: false,
            onComplete: () => _handleTaskComplete(task.id),
          );
        },
      );
    });
  }
}
