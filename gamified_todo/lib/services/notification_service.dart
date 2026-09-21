import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_model.dart';
import '../models/check_in_model.dart';
import '../controllers/task_controller.dart';
import '../ui/widgets/alarm_trigger_dialog.dart';
import 'package:permission_handler/permission_handler.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) async {
  // Background action handler (runs in a separate isolate when app is killed)
  WidgetsFlutterBinding.ensureInitialized();
  final payload = notificationResponse.payload;
  if (payload == null || payload.isEmpty) return;

  try {
    final Map<String, dynamic> data = jsonDecode(payload);
    final String type = data['type'] ?? '';
    final String id = data['id'] ?? '';
    final String? actionId = notificationResponse.actionId;

    if (actionId == 'complete' || actionId == 'snooze') {
      final prefs = await SharedPreferences.getInstance();
      
      if (type == 'alarm' || type == 'reminder') {
        final String? tasksJson = prefs.getString('saved_tasks');
        if (tasksJson != null) {
          final List<dynamic> decoded = jsonDecode(tasksJson);
          final tasks = decoded.map((item) => TaskModel.fromMap(item as Map<String, dynamic>)).toList();
          final index = tasks.indexWhere((t) => t.id == id);
          if (index != -1) {
            if (actionId == 'complete') {
              tasks[index].isCompleted = true;
              tasks[index].completedAt = DateTime.now();
            } else if (actionId == 'snooze') {
              if (tasks[index].deadline != null) {
                tasks[index].deadline = tasks[index].deadline!.add(const Duration(minutes: 10));
              }
            }
            final listMap = tasks.map((t) => t.toMap()).toList();
            await prefs.setString('saved_tasks', jsonEncode(listMap));
          }
        }
      } else if (type == 'checkin') {
        if (actionId == 'complete') {
          final String? checkInsJson = prefs.getString('saved_check_ins');
          if (checkInsJson != null) {
            final List<dynamic> decoded = jsonDecode(checkInsJson);
            final checkIns = decoded.map((item) => CheckInModel.fromMap(item as Map<String, dynamic>)).toList();
            final index = checkIns.indexWhere((c) => c.id == id);
            if (index != -1) {
              final todayStr = DateTime.now().toString().split(' ')[0];
              if (!checkIns[index].history.contains(todayStr)) {
                checkIns[index].history.add(todayStr);
              }
              final listMap = checkIns.map((c) => c.toMap()).toList();
              await prefs.setString('saved_check_ins', jsonEncode(listMap));
            }
          }
        }
      }
    }
  } catch (e) {
    // Ignore errors in background isolate
  }
}

void handleNotificationAction(NotificationResponse response) {
  final payload = response.payload;
  if (payload == null || payload.isEmpty) return;

  try {
    final Map<String, dynamic> data = jsonDecode(payload);
    final String type = data['type'] ?? '';
    final String id = data['id'] ?? '';
    final String? actionId = response.actionId;

    if (!Get.isRegistered<TaskController>()) return;
    final taskController = Get.find<TaskController>();

    if (type == 'alarm' || type == 'reminder') {
      if (actionId == 'snooze') {
        taskController.snoozeAlarm(id);
      } else if (actionId == 'complete') {
        taskController.completeAlarmTask(id);
      } else {
        // Tapped notification body
        final task = taskController.tasks.firstWhereOrNull((t) => t.id == id);
        if (task != null && !task.isCompleted) {
          if (type == 'alarm') {
            taskController.activeAlarmTask.value = task;
            Get.dialog(
              AlarmTriggerDialog(task: task),
              barrierDismissible: false,
            );
          }
        }
      }
    } else if (type == 'checkin') {
      if (actionId == 'complete') {
        final todayStr = DateTime.now().toString().split(' ')[0];
        taskController.toggleCheckInStatus(id, todayStr);
      }
    }
  } catch (e) {
    // ignore
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  static const String channelRemindersId = 'bounty_reminders_channel';
  static const String channelAlarmsId = 'bounty_alarms_channel';

  Future<void> init() async {
    if (_isInitialized || TaskController.isTesting) return;

    // 1. Initialize timezone (fetch real local timezone from device)
    tz.initializeTimeZones();
    try {
      final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneInfo.identifier));
    } catch (e) {
      // Fallback
    }

    // 2. Initialize android notification settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (response) {
        handleNotificationAction(response);
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    // 3. Create Android notification channels
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      const reminderChannel = AndroidNotificationChannel(
        channelRemindersId,
        '待办与打卡提醒',
        description: '任务到期与每日习惯打卡通知',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      final alarmChannel = AndroidNotificationChannel(
        channelAlarmsId,
        '任务截止强闹钟',
        description: '任务截止时间高优先级强提醒闹钟',
        importance: Importance.max,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound('jackpot'),
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1000, 500, 1000]),
        audioAttributesUsage: AudioAttributesUsage.alarm,
      );

      await android.createNotificationChannel(reminderChannel);
      await android.createNotificationChannel(alarmChannel);
    }

    _isInitialized = true;
  }

  Future<bool> requestPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final notif = await android.requestNotificationsPermission();
      await android.requestExactAlarmsPermission();
      await android.requestFullScreenIntentPermission();
      
      // Request background execution and battery optimizations on Android 14+
      if (await Permission.ignoreBatteryOptimizations.isDenied) {
        await Permission.ignoreBatteryOptimizations.request();
      }
      if (await Permission.systemAlertWindow.isDenied) {
        await Permission.systemAlertWindow.request();
      }

      return notif ?? false;
    }
    return true;
  }

  Future<bool> areNotificationsEnabled() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.areNotificationsEnabled() ?? false;
    }
    return true;
  }

  int _getNotificationId(String id, {int offset = 0}) {
    return (id.hashCode + offset) & 0x7FFFFFFF;
  }

  Future<void> scheduleTaskAlarmOrReminder(TaskModel task) async {
    if (TaskController.isTesting) return;
    if (!_isInitialized) await init();

    final reminderId = _getNotificationId(task.id, offset: 0);
    final alarmId = _getNotificationId(task.id, offset: 1);

    await _plugin.cancel(id: reminderId);
    await _plugin.cancel(id: alarmId);

    if (task.isCompleted || task.deadline == null) return;

    final now = DateTime.now();
    if (task.deadline!.isBefore(now)) return;

    final scheduledDate = tz.TZDateTime.from(task.deadline!, tz.local);

    try {
      if (task.hasAlarm) {
        final payload = jsonEncode({
          'type': 'alarm',
          'id': task.id,
          'title': task.title,
        });

        final androidDetails = AndroidNotificationDetails(
          channelAlarmsId,
          '任务截止强闹钟',
          channelDescription: '任务截止时间高优先级强提醒闹钟',
          importance: Importance.max,
          priority: Priority.max,
          playSound: true,
          sound: const RawResourceAndroidNotificationSound('jackpot'),
          audioAttributesUsage: AudioAttributesUsage.alarm,
          fullScreenIntent: true,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1000, 500, 1000]),
          additionalFlags: Int32List.fromList([4]), // FLAG_INSISTENT: 持续发声
          category: AndroidNotificationCategory.alarm,
          actions: <AndroidNotificationAction>[
            const AndroidNotificationAction('snooze', '稍后 10 分钟', showsUserInterface: false),
            const AndroidNotificationAction('complete', '立即完成', showsUserInterface: false),
          ],
        );

        final notifDetails = NotificationDetails(
          android: androidDetails,
          iOS: const DarwinNotificationDetails(
            sound: 'jackpot.wav',
            presentAlert: true,
            presentSound: true,
            interruptionLevel: InterruptionLevel.timeSensitive,
          ),
        );

        await _plugin.zonedSchedule(
          id: alarmId,
          title: '⏰ 任务截止闹钟：${task.title}',
          body: task.description?.isNotEmpty == true
              ? task.description!
              : '截止时间已到，完成任务可获取 ${task.coinReward} 金币奖励！',
          scheduledDate: scheduledDate,
          notificationDetails: notifDetails,
          androidScheduleMode: AndroidScheduleMode.alarmClock, // 强制离线触发
          payload: payload,
        );
      } else if (task.hasReminder) {
        final payload = jsonEncode({
          'type': 'reminder',
          'id': task.id,
          'title': task.title,
        });

        const androidDetails = AndroidNotificationDetails(
          channelRemindersId,
          '待办与打卡提醒',
          channelDescription: '任务到期与每日习惯打卡通知',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          category: AndroidNotificationCategory.reminder,
          actions: <AndroidNotificationAction>[
            AndroidNotificationAction('complete', '标记完成', showsUserInterface: false),
          ],
        );

        const notifDetails = NotificationDetails(
          android: androidDetails,
          iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
        );

        await _plugin.zonedSchedule(
          id: reminderId,
          title: '📌 待办提醒：${task.title}',
          body: task.description?.isNotEmpty == true
              ? task.description!
              : '已到达计划完成时间，及时完成保持自律！',
          scheduledDate: scheduledDate,
          notificationDetails: notifDetails,
          androidScheduleMode: AndroidScheduleMode.alarmClock,
          payload: payload,
        );
      }
    } catch (e) {
      // 忽略因 Android 14+ 缺少精确闹钟权限导致的异常，防止重构崩溃
      debugPrint("Schedule task notification failed: $e");
    }
  }

  Future<void> cancelTaskNotification(String taskId) async {
    if (TaskController.isTesting) return;
    if (!_isInitialized) await init();
    await _plugin.cancel(id: _getNotificationId(taskId, offset: 0));
    await _plugin.cancel(id: _getNotificationId(taskId, offset: 1));
  }

  Future<void> scheduleCheckInReminder(CheckInModel checkIn) async {
    if (TaskController.isTesting) return;
    if (!_isInitialized) await init();

    final checkInId = _getNotificationId(checkIn.id, offset: 2);
    await _plugin.cancel(id: checkInId);

    if (checkIn.reminderTime == null || checkIn.reminderTime!.isEmpty) return;

    final parts = checkIn.reminderTime!.split(':');
    if (parts.length != 2) return;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return;

    final now = DateTime.now();
    var scheduled = DateTime(now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    final scheduledDate = tz.TZDateTime.from(scheduled, tz.local);

    final payload = jsonEncode({
      'type': 'checkin',
      'id': checkIn.id,
      'title': checkIn.title,
    });

    const androidDetails = AndroidNotificationDetails(
      channelRemindersId,
      '待办与打卡提醒',
      channelDescription: '任务到期与每日习惯打卡通知',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      category: AndroidNotificationCategory.reminder,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction('complete', '立即打卡', showsUserInterface: false),
      ],
    );

    const notifDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
    );

    try {
      await _plugin.zonedSchedule(
        id: checkInId,
        title: '🎯 习惯打卡提醒：${checkIn.title}',
        body: '到点打卡啦！坚持打卡可获得金币奖励哦！',
        scheduledDate: scheduledDate,
        notificationDetails: notifDetails,
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: payload,
      );
    } catch (e) {
      debugPrint("Schedule checkin notification failed: $e");
    }
  }

  Future<void> cancelCheckInNotification(String checkInId) async {
    if (TaskController.isTesting) return;
    if (!_isInitialized) await init();
    await _plugin.cancel(id: _getNotificationId(checkInId, offset: 2));
  }

  Future<void> rescheduleAll({
    required List<TaskModel> tasks,
    required List<CheckInModel> checkIns,
  }) async {
    if (TaskController.isTesting) return;
    if (!_isInitialized) await init();

    for (var task in tasks) {
      if (!task.isCompleted && (task.hasAlarm || task.hasReminder) && task.deadline != null) {
        await scheduleTaskAlarmOrReminder(task);
      }
    }

    for (var checkIn in checkIns) {
      if (checkIn.reminderTime != null && checkIn.reminderTime!.isNotEmpty) {
        await scheduleCheckInReminder(checkIn);
      }
    }
  }
}
