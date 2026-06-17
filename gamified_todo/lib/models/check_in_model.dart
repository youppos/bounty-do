import 'package:uuid/uuid.dart';

class CheckInModel {
  final String id;
  String title;
  int levelIndex; // 0: 一般, 1: 重要
  String? reminderTime; // "HH:mm" format, e.g. "08:30"
  List<String> history; // Completed date strings in "yyyy-MM-dd" format

  CheckInModel({
    String? id,
    required this.title,
    this.levelIndex = 0,
    this.reminderTime,
    List<String>? history,
  })  : id = id ?? const Uuid().v4(),
        history = history ?? [];

  CheckInModel copyWith({
    String? title,
    int? levelIndex,
    String? reminderTime,
    List<String>? history,
  }) {
    return CheckInModel(
      id: id,
      title: title ?? this.title,
      levelIndex: levelIndex ?? this.levelIndex,
      reminderTime: reminderTime ?? this.reminderTime,
      history: history ?? List.from(this.history),
    );
  }
}
