import 'dart:math';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'task_controller.dart';

class SkillController extends GetxController {
  final _prefs = SharedPreferences.getInstance();

  // Buff states
  var doubleGoldCharges = 0.obs;
  var shieldExpiry = Rx<DateTime?>(null);

  // Unlocked themes/skins indices (0-5 are free by default, 6-9 are locked)
  var unlockedSkins = <int>[0, 1, 2, 3, 4, 5].obs;

  // Skill cost configurations
  static const int costMidasTouch = 150;
  static const int costShieldDiscipline = 100;
  static const int costTimeSandglass = 200;
  static const int costJackpotWheel = 50;
  static const int costSkinUnlock = 800;

  // Check if Shield of Discipline is currently active
  bool get isShieldActive {
    if (shieldExpiry.value == null) return false;
    return shieldExpiry.value!.isAfter(DateTime.now());
  }

  @override
  void onInit() {
    super.onInit();
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await _prefs;
    
    // Load double gold charges
    doubleGoldCharges.value = prefs.getInt('doubleGoldCharges') ?? 0;
    
    // Load shield expiry
    String? expiryStr = prefs.getString('shieldExpiry');
    if (expiryStr != null) {
      shieldExpiry.value = DateTime.tryParse(expiryStr);
    }

    // Load unlocked skins
    List<String>? skinsStrList = prefs.getStringList('unlockedSkins');
    if (skinsStrList != null) {
      unlockedSkins.assignAll(skinsStrList.map((s) => int.tryParse(s) ?? 0).toList());
    } else {
      unlockedSkins.assignAll([0, 1, 2, 3, 4, 5]);
    }
  }

  Future<void> _saveState() async {
    final prefs = await _prefs;
    await prefs.setInt('doubleGoldCharges', doubleGoldCharges.value);
    
    if (shieldExpiry.value != null) {
      await prefs.setString('shieldExpiry', shieldExpiry.value!.toIso8601String());
    } else {
      await prefs.remove('shieldExpiry');
    }

    await prefs.setStringList(
      'unlockedSkins',
      unlockedSkins.map((idx) => idx.toString()).toList(),
    );
  }

  // Purchases Midas Touch (charges double gold)
  bool buyMidasTouch() {
    final taskController = Get.find<TaskController>();
    if (taskController.totalCoins.value >= costMidasTouch) {
      taskController.totalCoins.value -= costMidasTouch;
      doubleGoldCharges.value += 1;
      _saveState();
      return true;
    }
    return false;
  }

  // Purchases Shield of Discipline (extends active protection by 24h)
  bool buyShieldDiscipline() {
    final taskController = Get.find<TaskController>();
    if (taskController.totalCoins.value >= costShieldDiscipline) {
      taskController.totalCoins.value -= costShieldDiscipline;
      
      DateTime baseTime = isShieldActive ? shieldExpiry.value! : DateTime.now();
      shieldExpiry.value = baseTime.add(const Duration(hours: 24));
      
      _saveState();
      return true;
    }
    return false;
  }

  // Purchases Time Sandglass (extends all in-progress deadlines by 12 hours)
  bool buyTimeSandglass() {
    final taskController = Get.find<TaskController>();
    if (taskController.totalCoins.value >= costTimeSandglass) {
      taskController.totalCoins.value -= costTimeSandglass;
      
      // Extend all current in-progress task deadlines by 12 hours
      for (int i = 0; i < taskController.tasks.length; i++) {
        var t = taskController.tasks[i];
        if (!t.isCompleted && t.deadline != null) {
          taskController.tasks[i] = t.copyWith(
            deadline: t.deadline!.add(const Duration(hours: 12)),
          );
        }
      }
      return true;
    }
    return false;
  }

  // Purchases Skin Unlock
  bool unlockSkin(int index) {
    final taskController = Get.find<TaskController>();
    if (unlockedSkins.contains(index)) return true;
    
    if (taskController.totalCoins.value >= costSkinUnlock) {
      taskController.totalCoins.value -= costSkinUnlock;
      unlockedSkins.add(index);
      _saveState();
      return true;
    }
    return false;
  }

  // Spins the Jackpot Wheel. Returns won coins amount, or -1 if insufficient coins.
  int spinJackpot() {
    final taskController = Get.find<TaskController>();
    if (taskController.totalCoins.value < costJackpotWheel) {
      return -1;
    }
    taskController.totalCoins.value -= costJackpotWheel;
    
    // Outcome probabilities:
    // 0 coins: 40%
    // 10 coins: 20%
    // 50 coins: 20%
    // 100 coins: 12%
    // 200 coins: 6%
    // 300 coins (Jackpot): 2%
    
    final rand = Random().nextInt(100);
    int wonCoins = 0;
    if (rand < 40) {
      wonCoins = 0;
    } else if (rand < 60) {
      wonCoins = 10;
    } else if (rand < 80) {
      wonCoins = 50;
    } else if (rand < 92) {
      wonCoins = 100;
    } else if (rand < 98) {
      wonCoins = 200;
    } else {
      wonCoins = 300;
    }
    
    taskController.totalCoins.value += wonCoins;
    return wonCoins;
  }

  // Uses a Midas Touch charge if available.
  bool useDoubleGoldCharge() {
    if (doubleGoldCharges.value > 0) {
      doubleGoldCharges.value -= 1;
      _saveState();
      return true;
    }
    return false;
  }
}
