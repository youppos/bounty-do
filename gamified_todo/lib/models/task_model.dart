import 'package:uuid/uuid.dart';

enum TaskPriority { low, medium, high }

class TaskModel {
  final String id;
  String title;
  String? description;
  bool isCompleted;
  int coinReward;
  TaskPriority priority;
  DateTime createdAt;

  TaskModel({
    String? id,
    required this.title,
    this.description,
    this.isCompleted = false,
    required this.coinReward,
    this.priority = TaskPriority.medium,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  TaskModel copyWith({
    String? title,
    String? description,
    bool? isCompleted,
    int? coinReward,
    TaskPriority? priority,
  }) {
    return TaskModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      coinReward: coinReward ?? this.coinReward,
      priority: priority ?? this.priority,
      createdAt: createdAt,
    );
  }
}
