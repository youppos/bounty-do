import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';

class TaskModel {
  final String id;
  String title;
  String? description;
  bool isCompleted;
  bool hasAlarm;
  bool hasReminder;
  int coinReward; // Frozen final coin reward if completed, or base reward
  int levelIndex; // 0 to 4 (Level 1 to Level 5)
  DateTime createdAt;
  DateTime? deadline;
  DateTime? completedAt;

  TaskModel({
    String? id,
    required this.title,
    this.description,
    this.isCompleted = false,
    this.hasAlarm = false,
    this.hasReminder = false,
    required this.coinReward,
    this.levelIndex = 1, // Default to Level 2 (Index 1)
    DateTime? createdAt,
    this.deadline,
    this.completedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  static int getMinCoinsForLevel(int level) {
    switch (level) {
      case 0: return 1;
      case 1: return 5;
      case 2: return 15;
      case 3: return 30;
      case 4: return 60;
      default: return 1;
    }
  }

  static int getMaxCoinsForLevel(int level) {
    switch (level) {
      case 0: return 5;
      case 1: return 15;
      case 2: return 30;
      case 3: return 60;
      case 4: return 100;
      default: return 5;
    }
  }

  Color get levelColor {
    switch (levelIndex) {
      case 0: return Colors.green;
      case 1: return Colors.blue;
      case 2: return Colors.orange;
      case 3: return Colors.purple;
      case 4: return Colors.red;
      default: return Colors.green;
    }
  }

  int calculateRewardAt(DateTime time) {
    if (deadline == null) {
      return coinReward;
    }
    final minCoins = getMinCoinsForLevel(levelIndex);
    final maxCoins = getMaxCoinsForLevel(levelIndex);
    
    // Overdue penalty
    if (time.isAfter(deadline!)) {
      return (minCoins * 0.5).round();
    }
    
    final totalDurationMs = deadline!.difference(createdAt).inMilliseconds;
    if (totalDurationMs <= 0) {
      return maxCoins;
    }
    
    final elapsedMs = time.difference(createdAt).inMilliseconds;
    if (elapsedMs <= 0) {
      return maxCoins;
    }
    
    final ratio = elapsedMs / totalDurationMs;
    if (ratio <= 0.25) {
      return maxCoins;
    }
    
    // Linear decay from 0.25 to 1.0
    final decayRatio = (ratio - 0.25) / 0.75;
    final calculated = maxCoins - (decayRatio * (maxCoins - minCoins));
    return calculated.round().clamp(minCoins, maxCoins);
  }

  TaskModel copyWith({
    String? title,
    String? description,
    bool? isCompleted,
    bool? hasAlarm,
    bool? hasReminder,
    int? coinReward,
    int? levelIndex,
    DateTime? deadline,
    DateTime? completedAt,
  }) {
    return TaskModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      hasAlarm: hasAlarm ?? this.hasAlarm,
      hasReminder: hasReminder ?? this.hasReminder,
      coinReward: coinReward ?? this.coinReward,
      levelIndex: levelIndex ?? this.levelIndex,
      createdAt: createdAt,
      deadline: deadline ?? this.deadline,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
