import 'dart:convert';
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

  // Alarm Ringtone Configurations
  String ringtoneType; // "preset" or "custom"
  String ringtoneName; // Display name e.g., "宝藏金币 (默认)"
  String? ringtonePath; // Asset path (for preset) or file path (for custom)
  String? ringtoneBase64; // Base64 encoded string for Web custom audio persistence

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
    this.ringtoneType = 'preset',
    this.ringtoneName = '宝藏金币 (默认)',
    this.ringtonePath = 'audio/jackpot.wav',
    this.ringtoneBase64,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  static int getMinCoinsForLevel(int level) {
    switch (level) {
      case 0: return 1;
      case 1: return 1;
      case 2: return 3;
      case 3: return 6;
      case 4: return 12;
      default: return 1;
    }
  }

  static int getMaxCoinsForLevel(int level) {
    switch (level) {
      case 0: return 1;
      case 1: return 3;
      case 2: return 6;
      case 3: return 12;
      case 4: return 20;
      default: return 1;
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
    String? ringtoneType,
    String? ringtoneName,
    String? ringtonePath,
    String? ringtoneBase64,
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
      ringtoneType: ringtoneType ?? this.ringtoneType,
      ringtoneName: ringtoneName ?? this.ringtoneName,
      ringtonePath: ringtonePath ?? this.ringtonePath,
      ringtoneBase64: ringtoneBase64 ?? this.ringtoneBase64,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
      'hasAlarm': hasAlarm,
      'hasReminder': hasReminder,
      'coinReward': coinReward,
      'levelIndex': levelIndex,
      'createdAt': createdAt.toIso8601String(),
      'deadline': deadline?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'ringtoneType': ringtoneType,
      'ringtoneName': ringtoneName,
      'ringtonePath': ringtonePath,
      'ringtoneBase64': ringtoneBase64,
    };
  }

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id'] as String?,
      title: map['title'] as String? ?? '',
      description: map['description'] as String?,
      isCompleted: map['isCompleted'] as bool? ?? false,
      hasAlarm: map['hasAlarm'] as bool? ?? false,
      hasReminder: map['hasReminder'] as bool? ?? false,
      coinReward: map['coinReward'] as int? ?? 1,
      levelIndex: map['levelIndex'] as int? ?? 1,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      deadline: map['deadline'] != null
          ? DateTime.tryParse(map['deadline'] as String)
          : null,
      completedAt: map['completedAt'] != null
          ? DateTime.tryParse(map['completedAt'] as String)
          : null,
      ringtoneType: map['ringtoneType'] as String? ?? 'preset',
      ringtoneName: map['ringtoneName'] as String? ?? '宝藏金币 (默认)',
      ringtonePath: map['ringtonePath'] as String? ?? 'audio/jackpot.wav',
      ringtoneBase64: map['ringtoneBase64'] as String?,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory TaskModel.fromJson(String source) =>
      TaskModel.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
