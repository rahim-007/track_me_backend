import 'package:flutter_test/flutter_test.dart';
import 'package:track_me/features/habits/data/models/habit_model.dart';
import 'package:track_me/core/notifications/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Interval Habit Model & Logic Tests', () {
    test('HabitModel properly parses and serializes interval fields', () {
      final habit = HabitModel(
        id: 'water_1',
        name: 'Drink 4L Water',
        category: 'HEALTH',
        emoji: '💧',
        color: '#06B6D4',
        repeatDays: List.filled(7, true),
        isInterval: true,
        intervalMinutes: 60,
        windowStartTime: '08:00',
        windowEndTime: '22:00',
        targetValue: 4000,
        unit: 'ml',
        rollingInterval: false,
        currentValueToday: 1500,
        createdAt: DateTime.now(),
        completedDates: [],
        skippedDates: [],
      );

      expect(habit.isInterval, true);
      expect(habit.intervalMinutes, 60);
      expect(habit.windowStartTime, '08:00');
      expect(habit.windowEndTime, '22:00');
      expect(habit.targetValue, 4000);
      expect(habit.unit, 'ml');
      expect(habit.currentValueToday, 1500);
      expect(habit.progressPercentage, 1500 / 4000);
      expect(habit.isCompletedToday, false);

      final json = habit.toJson();
      expect(json['isInterval'], true);
      expect(json['intervalMinutes'], 60);
      expect(json['targetValue'], 4000);
      expect(json['unit'], 'ml');

      final deserialized = HabitModel.fromJson(json);
      expect(deserialized.name, 'Drink 4L Water');
      expect(deserialized.isInterval, true);
      expect(deserialized.intervalMinutes, 60);
      expect(deserialized.targetValue, 4000);
      expect(deserialized.unit, 'ml');
      expect(deserialized.currentValueToday, 1500);
    });

    test('isCompletedToday is true when currentValueToday >= targetValue', () {
      final habit = HabitModel(
        id: 'water_2',
        name: 'Drink 4L Water',
        category: 'HEALTH',
        repeatDays: List.filled(7, true),
        isInterval: true,
        intervalMinutes: 60,
        windowStartTime: '08:00',
        windowEndTime: '22:00',
        targetValue: 4000,
        unit: 'ml',
        currentValueToday: 4000,
        createdAt: DateTime.now(),
        completedDates: [],
        skippedDates: [],
      );

      expect(habit.progressPercentage, 1.0);
      expect(habit.isCompletedToday, true);
    });

    test('Medicine 2-hour rolling gap habit model configuration', () {
      final medicine = HabitModel(
        id: 'med_1',
        name: 'Take Antibiotics',
        category: 'HEALTH',
        emoji: '💊',
        repeatDays: List.filled(7, true),
        isInterval: true,
        intervalMinutes: 120,
        windowStartTime: '08:00',
        windowEndTime: '20:00',
        targetValue: 4,
        unit: 'doses',
        rollingInterval: true,
        currentValueToday: 2,
        createdAt: DateTime.now(),
        completedDates: [],
        skippedDates: [],
      );

      expect(medicine.isInterval, true);
      expect(medicine.rollingInterval, true);
      expect(medicine.intervalMinutes, 120);
      expect(medicine.progressPercentage, 0.5);
      expect(medicine.isCompletedToday, false);
    });

    test('NotificationService scheduleIntervalHabitReminder completes safely without crashing', () async {
      await expectLater(
        NotificationService.scheduleIntervalHabitReminder(
          habitId: 'water_test',
          habitName: 'Drink Water',
          windowStartTime: '08:00',
          windowEndTime: '22:00',
          intervalMinutes: 60,
        ),
        completes,
      );

      await expectLater(
        NotificationService.cancelHabitReminder('water_test'),
        completes,
      );
    });

    test('NotificationService scheduleRollingReminder completes safely without crashing', () async {
      await expectLater(
        NotificationService.scheduleRollingReminder(
          habitId: 'med_test',
          habitName: 'Take Medicine',
          gapMinutes: 120,
        ),
        completes,
      );
    });
  });
}
