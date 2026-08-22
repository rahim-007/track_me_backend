import 'package:flutter_test/flutter_test.dart';

import 'package:track_me/features/goals/data/models/goal_model.dart';

Map<String, dynamic> baseJson({
  int? durationDays,
  double? target,
  String? unit,
}) {
  return {
    'id': 'g1',
    'name': 'Save for a Trip',
    'category': 'FINANCE',
    'targetDate': '2026-12-31T00:00:00.000Z',
    'priority': 'HIGH',
    'status': 'IN_PROGRESS',
    'progress': 0.25,
    if (durationDays != null) 'durationDays': durationDays,
    if (target != null) 'target': target,
    if (unit != null) 'unit': unit,
    'notes': 'Saving 200 a month',
    'createdAt': '2026-01-01T00:00:00.000Z',
  };
}

void main() {
  test('parses the core fields and durationDays from the backend payload', () {
    final g = GoalModel.fromJson(baseJson(durationDays: 365));

    expect(g.id, 'g1');
    expect(g.name, 'Save for a Trip');
    expect(g.category, 'Finance');
    expect(g.priority, 'High');
    expect(g.status, 'in_progress');
    expect(g.progress, 0.25);
    expect(g.durationDays, 365);
  });

  test('defaults durationDays to 30 when the payload omits it', () {
    final g = GoalModel.fromJson(baseJson());
    expect(g.durationDays, 30);
  });

  test('a 365-day goal survives a JSON round trip', () {
    final g = GoalModel.fromJson(baseJson(durationDays: 365));
    final parsed = GoalModel.fromJson(g.toJson());
    expect(parsed.durationDays, 365);
  });

  test('toJson includes durationDays', () {
    final g = GoalModel.fromJson(baseJson(durationDays: 180));
    expect(g.toJson()['durationDays'], 180);
  });

  test('create and update payloads include durationDays but no server fields',
      () {
    final g = GoalModel.fromJson(baseJson(durationDays: 90));

    final create = g.toCreateJson();
    expect(create['durationDays'], 90);
    expect(create.containsKey('id'), isFalse);
    expect(create.containsKey('status'), isFalse);
    expect(create.containsKey('progress'), isFalse);
    expect(create.containsKey('createdAt'), isFalse);

    expect(g.toUpdateJson(), create);
  });

  test('copyWith overrides durationDays without touching other fields', () {
    final g = GoalModel.fromJson(baseJson(durationDays: 30));
    final changed = g.copyWith(durationDays: 365);
    expect(changed.durationDays, 365);
    expect(changed.id, g.id);
    expect(changed.name, g.name);
    expect(changed.progress, g.progress);
  });

  group('target / unit (type-aware numeric values)', () {
    test('parses target and unit from the backend payload', () {
      final g = GoalModel.fromJson(baseJson(target: 5, unit: 'kg'));
      expect(g.target, 5.0);
      expect(g.unit, 'kg');
      expect(g.hasTarget, isTrue);
      expect(g.allowsDecimalProgress, isTrue);
    });

    test('fractional targets survive for measurement units', () {
      final g = GoalModel.fromJson(baseJson(target: 0.5, unit: 'kg'));
      expect(g.target, 0.5);
    });

    test('count units are flagged as whole-number only', () {
      final g = GoalModel.fromJson(baseJson(target: 10, unit: 'books'));
      expect(g.allowsDecimalProgress, isFalse);

      final money = GoalModel.fromJson(baseJson(target: 50000, unit: '₹'));
      expect(money.allowsDecimalProgress, isFalse);
    });

    test('defaults target to 0 and unit to empty when omitted (legacy)', () {
      final g = GoalModel.fromJson(baseJson());
      expect(g.target, 0.0);
      expect(g.unit, '');
      expect(g.hasTarget, isFalse);
      // Legacy goals without a unit stay permissive (decimals allowed).
      expect(g.allowsDecimalProgress, isTrue);
    });

    test('target and unit survive a JSON round trip', () {
      final g = GoalModel.fromJson(baseJson(target: 2.5, unit: 'km'));
      final parsed = GoalModel.fromJson(g.toJson());
      expect(parsed.target, 2.5);
      expect(parsed.unit, 'km');
    });

    test('create payloads include target and unit, null unit when empty', () {
      final g = GoalModel.fromJson(baseJson(target: 5, unit: 'kg'));
      final create = g.toCreateJson();
      expect(create['target'], 5.0);
      expect(create['unit'], 'kg');
      expect(create.containsKey('id'), isFalse);
      expect(create.containsKey('progress'), isFalse);

      final noUnit = GoalModel.fromJson(baseJson(target: 5));
      expect(noUnit.toCreateJson()['unit'], isNull);
    });

    test('copyWith overrides target and unit', () {
      final g = GoalModel.fromJson(baseJson(target: 5, unit: 'kg'));
      final changed = g.copyWith(target: 2.5, unit: 'km');
      expect(changed.target, 2.5);
      expect(changed.unit, 'km');
      expect(changed.name, g.name);
    });
  });

  group('duration / target date linkage', () {
    test('dateOnly strips the time component', () {
      final d = GoalModel.dateOnly(DateTime(2026, 8, 15, 14, 30, 45));
      expect(d, DateTime(2026, 8, 15));
    });

    test('targetDateForDuration adds the duration to the start date', () {
      final start = DateTime(2026, 1, 1);
      expect(
        GoalModel.targetDateForDuration(start, 365),
        DateTime(2027, 1, 1),
      );
      expect(
        GoalModel.targetDateForDuration(start, 30),
        DateTime(2026, 1, 31),
      );
    });

    test('durationForTargetDate measures whole days and clamps to 1-365', () {
      final start = DateTime(2026, 1, 1);
      expect(
        GoalModel.durationForTargetDate(start, DateTime(2026, 4, 1)),
        90,
      );
      // Same-day target clamps to the 1-day minimum.
      expect(GoalModel.durationForTargetDate(start, start), 1);
      // Far-future targets clamp to the 365-day maximum.
      expect(
        GoalModel.durationForTargetDate(start, DateTime(2030, 1, 1)),
        365,
      );
      // A target before the start date also clamps to the minimum.
      expect(
        GoalModel.durationForTargetDate(
            DateTime(2026, 6, 1), DateTime(2026, 1, 1)),
        1,
      );
    });

    test('targetDateForDuration + durationForTargetDate round trip', () {
      final start = GoalModel.dateOnly(DateTime(2026, 8, 15));
      const days = 180;
      final target = GoalModel.targetDateForDuration(start, days);
      expect(GoalModel.durationForTargetDate(start, target), days);
    });
  });
}
