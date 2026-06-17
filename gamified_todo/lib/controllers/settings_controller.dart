import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsController extends GetxController {
  final _prefs = SharedPreferences.getInstance();
  
  // 'system', 'en_US', 'zh_CN'
  var selectedLanguage = 'system'.obs;

  // 静音模式
  var isMuted = false.obs;

  // 动态光效模式 (0: 静态, 1: 呼吸, 2: 跑马灯, 3: 流光, 4: 脉冲)
  var taskLightEffect = 0.obs;

  // 边框粗细 (0: 细, 1: 中, 2: 粗)
  var taskBorderThickness = 1.obs;

  // 预设方案索引 (0: 艾森豪威尔, 1: RPG稀有度, 2: 专注能耗, 3: 生活支柱, 4: 星级, 5: 自定义)
  var selectedPresetIndex = 1.obs;

  // 自定义等级名称
  var customLevelNames = <String>['Level 1', 'Level 2', 'Level 3', 'Level 4', 'Level 5'].obs;

  // 避免输入框重复创建导致的焦点丢失
  final customNameControllers = List.generate(5, (_) => TextEditingController());

  @override
  void onInit() {
    super.onInit();
    _loadSettings().then((_) {
      for (int i = 0; i < 5; i++) {
        customNameControllers[i].text = customLevelNames[i];
        customNameControllers[i].addListener(() {
          updateCustomLevelName(i, customNameControllers[i].text);
        });
      }
    });
  }

  @override
  void onClose() {
    for (var ctrl in customNameControllers) {
      ctrl.dispose();
    }
    super.onClose();
  }

  Future<void> _loadSettings() async {
    final prefs = await _prefs;
    String? lang = prefs.getString('language');
    if (lang != null) {
      selectedLanguage.value = lang;
      _applyLanguage(lang);
    }
    isMuted.value = prefs.getBool('isMuted') ?? false;
    soundMode.value = prefs.getInt('soundMode') ?? 0;
    taskLightEffect.value = prefs.getInt('taskLightEffect') ?? 0;
    taskBorderThickness.value = prefs.getInt('taskBorderThickness') ?? 1;
    selectedPresetIndex.value = prefs.getInt('selectedPresetIndex') ?? 1;
    
    List<String>? savedCustoms = prefs.getStringList('customLevelNames');
    if (savedCustoms != null && savedCustoms.length == 5) {
      customLevelNames.assignAll(savedCustoms);
    }
  }

  // 0: 开启, 1: 跟随系统, 2: 静音
  var soundMode = 0.obs;

  Future<void> toggleMute() async {
    soundMode.value = (soundMode.value + 1) % 3;
    isMuted.value = (soundMode.value == 2);
    final prefs = await _prefs;
    await prefs.setInt('soundMode', soundMode.value);
    await prefs.setBool('isMuted', isMuted.value);
  }

  String getSoundModeString() {
    switch (soundMode.value) {
      case 0: return 'sound_on'.tr;
      case 1: return 'system_default'.tr;
      case 2: return 'sound_off'.tr;
      default: return 'sound_on'.tr;
    }
  }

  Future<void> changeTaskLightEffect(int effectIndex) async {
    taskLightEffect.value = effectIndex;
    final prefs = await _prefs;
    await prefs.setInt('taskLightEffect', effectIndex);
  }

  Future<void> changeTaskBorderThickness(int thicknessIndex) async {
    taskBorderThickness.value = thicknessIndex;
    final prefs = await _prefs;
    await prefs.setInt('taskBorderThickness', thicknessIndex);
  }

  Future<void> changeLanguage(String lang) async {
    selectedLanguage.value = lang;
    final prefs = await _prefs;
    await prefs.setString('language', lang);
    _applyLanguage(lang);
  }

  void _applyLanguage(String lang) {
    if (lang == 'system') {
      Get.updateLocale(Get.deviceLocale ?? const Locale('en', 'US'));
    } else if (lang == 'en_US') {
      Get.updateLocale(const Locale('en', 'US'));
    } else if (lang == 'zh_CN') {
      Get.updateLocale(const Locale('zh', 'CN'));
    }
  }

  // 修改等级预设方案
  Future<void> changePresetIndex(int index) async {
    selectedPresetIndex.value = index;
    final prefs = await _prefs;
    await prefs.setInt('selectedPresetIndex', index);
  }

  // 修改自定义等级名称
  Future<void> updateCustomLevelName(int levelIndex, String name) async {
    if (levelIndex >= 0 && levelIndex < 5) {
      // 避免不必要的触发更新
      if (customLevelNames[levelIndex] != name) {
        customLevelNames[levelIndex] = name;
        final prefs = await _prefs;
        await prefs.setStringList('customLevelNames', customLevelNames);
      }
    }
  }

  // 获取当前生效的5个等级名称
  List<String> get activeLevelNames {
    if (selectedPresetIndex.value == 5) {
      return customLevelNames;
    }
    
    final isZh = Get.locale?.languageCode == 'zh';
    
    switch (selectedPresetIndex.value) {
      case 0: // 艾森豪威尔
        return isZh
            ? ['一般', '重要', '紧急', '重要且紧急', '极其重要紧急']
            : ['Normal', 'Important', 'Urgent', 'Urgent & Important', 'Critical'];
      case 1: // RPG稀有度
        return isZh
            ? ['普通', '优秀', '稀有', '史诗', '传说']
            : ['Common', 'Uncommon', 'Rare', 'Epic', 'Legendary'];
      case 2: // 专注能耗
        return isZh
            ? ['微耗能', '轻度专注', '深度专注', '核心挑战', '极限突破']
            : ['Micro Focus', 'Light Focus', 'Deep Focus', 'Core Challenge', 'Limit Break'];
      case 3: // 生活支柱
        return isZh
            ? ['日常琐事', '自我提升', '工作学习', '关键里程碑', '终极挑战']
            : ['Daily Chore', 'Self Growth', 'Work/Study', 'Key Milestone', 'Ultimate Challenge'];
      case 4: // 星级星等
        return ['★☆☆☆☆', '★★☆☆☆', '★★★☆☆', '★★★★☆', '★★★★★'];
      default:
        return isZh
            ? ['普通', '优秀', '稀有', '史诗', '传说']
            : ['Common', 'Uncommon', 'Rare', 'Epic', 'Legendary'];
    }
  }

  String getLevelName(int levelIndex) {
    final names = activeLevelNames;
    if (levelIndex >= 0 && levelIndex < names.length) {
      return names[levelIndex];
    }
    return 'L${levelIndex + 1}';
  }
}
