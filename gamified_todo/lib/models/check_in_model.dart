import 'package:uuid/uuid.dart';

class CheckInModel {
  final String id;
  String title;
  int levelIndex; // 0: 一般, 1: 重要
  String? reminderTime; // "HH:mm" format, e.g. "08:30"
  List<String> history; // Completed date strings in "yyyy-MM-dd" format
  String frequencyType; // 'daily', 'weekly', 'interval', 'monthly'
  List<int> weeklyDays; // Mon=1, Sun=7
  int intervalDays; // e.g. 2 for every 2 days
  String startDate; // "yyyy-MM-dd" for interval anchoring
  List<int> monthlyDays; // 1-31

  CheckInModel({
    String? id,
    required this.title,
    this.levelIndex = 0,
    this.reminderTime,
    List<String>? history,
    this.frequencyType = 'daily',
    List<int>? weeklyDays,
    this.intervalDays = 2,
    String? startDate,
    List<int>? monthlyDays,
  })  : id = id ?? const Uuid().v4(),
        history = history ?? [],
        weeklyDays = weeklyDays ?? [1, 2, 3, 4, 5, 6, 7],
        startDate = startDate ?? DateTime.now().toString().split(' ')[0],
        monthlyDays = monthlyDays ?? [1];

  bool isDueOn(DateTime date) {
    final dateStr = DateTime(date.year, date.month, date.day).toString().split(' ')[0];
    if (history.contains(dateStr)) {
      return true;
    }

    switch (frequencyType) {
      case 'daily':
        return true;
      case 'weekly':
        return weeklyDays.contains(date.weekday);
      case 'interval':
        try {
          final start = DateTime.parse(startDate);
          final target = DateTime(date.year, date.month, date.day);
          final startMidnight = DateTime(start.year, start.month, start.day);
          if (target.isBefore(startMidnight)) return false;
          final difference = target.difference(startMidnight).inDays;
          return difference % intervalDays == 0;
        } catch (_) {
          return false;
        }
      case 'monthly':
        return monthlyDays.contains(date.day);
      default:
        return true;
    }
  }

  CheckInModel copyWith({
    String? title,
    int? levelIndex,
    String? reminderTime,
    List<String>? history,
    String? frequencyType,
    List<int>? weeklyDays,
    int? intervalDays,
    String? startDate,
    List<int>? monthlyDays,
  }) {
    return CheckInModel(
      id: id,
      title: title ?? this.title,
      levelIndex: levelIndex ?? this.levelIndex,
      reminderTime: reminderTime ?? this.reminderTime,
      history: history ?? List.from(this.history),
      frequencyType: frequencyType ?? this.frequencyType,
      weeklyDays: weeklyDays ?? (weeklyDays != null ? List.from(weeklyDays) : this.weeklyDays),
      intervalDays: intervalDays ?? this.intervalDays,
      startDate: startDate ?? this.startDate,
      monthlyDays: monthlyDays ?? (monthlyDays != null ? List.from(monthlyDays) : this.monthlyDays),
    );
  }
}

