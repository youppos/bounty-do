import 'package:flutter_test/flutter_test.dart';
import 'package:gamified_todo/models/task_model.dart';
import 'package:gamified_todo/models/check_in_model.dart';

void main() {
  group('TaskModel Persistence', () {
    test('toMap and fromMap should preserve all fields', () {
      final now = DateTime.now();
      final deadline = now.add(const Duration(hours: 3));
      final completedAt = now.add(const Duration(hours: 1));

      final task = TaskModel(
        id: 'test-id-123',
        title: 'Complete persistence feature',
        description: 'Ensure data is saved to SharedPreferences',
        isCompleted: true,
        hasAlarm: true,
        hasReminder: true,
        coinReward: 20,
        levelIndex: 3,
        createdAt: now,
        deadline: deadline,
        completedAt: completedAt,
        ringtoneType: 'custom',
        ringtoneName: 'Custom Audio',
        ringtonePath: '/path/to/custom.mp3',
        ringtoneBase64: 'dGVzdA==',
      );

      final map = task.toMap();
      final restored = TaskModel.fromMap(map);

      expect(restored.id, task.id);
      expect(restored.title, task.title);
      expect(restored.description, task.description);
      expect(restored.isCompleted, task.isCompleted);
      expect(restored.hasAlarm, task.hasAlarm);
      expect(restored.hasReminder, task.hasReminder);
      expect(restored.coinReward, task.coinReward);
      expect(restored.levelIndex, task.levelIndex);
      expect(restored.createdAt.millisecondsSinceEpoch, task.createdAt.millisecondsSinceEpoch);
      expect(restored.deadline?.millisecondsSinceEpoch, task.deadline?.millisecondsSinceEpoch);
      expect(restored.completedAt?.millisecondsSinceEpoch, task.completedAt?.millisecondsSinceEpoch);
      expect(restored.ringtoneType, task.ringtoneType);
      expect(restored.ringtoneName, task.ringtoneName);
      expect(restored.ringtonePath, task.ringtonePath);
      expect(restored.ringtoneBase64, task.ringtoneBase64);
    });

    test('toJson and fromJson should work with JSON string', () {
      final task = TaskModel(
        title: 'JSON Test',
        coinReward: 5,
        levelIndex: 2,
      );

      final jsonStr = task.toJson();
      final restored = TaskModel.fromJson(jsonStr);

      expect(restored.id, task.id);
      expect(restored.title, 'JSON Test');
      expect(restored.coinReward, 5);
      expect(restored.levelIndex, 2);
    });
  });

  group('CheckInModel Persistence', () {
    test('toMap and fromMap should preserve all fields', () {
      final checkIn = CheckInModel(
        id: 'checkin-456',
        title: 'Drink 2L Water',
        levelIndex: 1,
        reminderTime: '09:00',
        history: ['2026-09-20', '2026-09-21'],
        frequencyType: 'weekly',
        weeklyDays: [1, 3, 5],
        intervalDays: 3,
        startDate: '2026-09-01',
        monthlyDays: [1, 15],
      );

      final map = checkIn.toMap();
      final restored = CheckInModel.fromMap(map);

      expect(restored.id, checkIn.id);
      expect(restored.title, checkIn.title);
      expect(restored.levelIndex, checkIn.levelIndex);
      expect(restored.reminderTime, checkIn.reminderTime);
      expect(restored.history, ['2026-09-20', '2026-09-21']);
      expect(restored.frequencyType, 'weekly');
      expect(restored.weeklyDays, [1, 3, 5]);
      expect(restored.intervalDays, 3);
      expect(restored.startDate, '2026-09-01');
      expect(restored.monthlyDays, [1, 15]);
    });
  });
}
