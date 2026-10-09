class HabitModel {
  final String id;
  final String name;
  final String category;
  final String? emoji;
  final String? color;
  final List<bool> repeatDays;
  final String? reminderTime;
  final bool isInterval;
  final int? intervalMinutes;
  final String? windowStartTime;
  final String? windowEndTime;
  final double? targetValue;
  final String? unit;
  final bool rollingInterval;
  final double currentValueToday;
  final String? notes;
  final DateTime createdAt;
  List<String> completedDates;
  List<String> skippedDates;
  final int currentStreak;
  final int longestStreak;
  final int totalCompleted;

  HabitModel({
    required this.id,
    required this.name,
    required this.category,
    this.emoji,
    this.color,
    required this.repeatDays,
    this.reminderTime,
    this.isInterval = false,
    this.intervalMinutes,
    this.windowStartTime,
    this.windowEndTime,
    this.targetValue,
    this.unit,
    this.rollingInterval = false,
    this.currentValueToday = 0,
    this.notes,
    required this.createdAt,
    required this.completedDates,
    required this.skippedDates,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalCompleted = 0,
  });

  bool get isCompletedToday {
    final today = _todayStr;
    if (completedDates.contains(today)) return true;
    if (isInterval && targetValue != null && targetValue! > 0) {
      return currentValueToday >= targetValue!;
    }
    return false;
  }

  double get progressPercentage {
    if (targetValue == null || targetValue! <= 0) {
      return isCompletedToday ? 1.0 : 0.0;
    }
    return (currentValueToday / targetValue!).clamp(0.0, 1.0);
  }

  bool get isSkippedToday {
    final today = _todayStr;
    return skippedDates.contains(today);
  }

  /// Checks if this habit is scheduled to be performed on [date].
  /// Monday is 1, Sunday is 7 in Dart DateTime.
  /// Index in repeatDays: 0 = Mon, 6 = Sun.
  /// If no repeat days are selected, it defaults to daily.
  bool isScheduledOn(DateTime date) {
    final hasRepeatDay = repeatDays.any((d) => d);
    if (!hasRepeatDay) return true;
    final weekdayIndex = date.weekday - 1;
    return weekdayIndex >= 0 &&
        weekdayIndex < repeatDays.length &&
        repeatDays[weekdayIndex];
  }

  bool get isScheduledToday => isScheduledOn(DateTime.now());

  String get _todayStr {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  HabitModel copyWith({
    String? id,
    String? name,
    String? category,
    String? emoji,
    String? color,
    List<bool>? repeatDays,
    String? reminderTime,
    bool? isInterval,
    int? intervalMinutes,
    String? windowStartTime,
    String? windowEndTime,
    double? targetValue,
    String? unit,
    bool? rollingInterval,
    double? currentValueToday,
    String? notes,
    DateTime? createdAt,
    List<String>? completedDates,
    List<String>? skippedDates,
    int? currentStreak,
    int? longestStreak,
    int? totalCompleted,
  }) {
    return HabitModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      emoji: emoji ?? this.emoji,
      color: color ?? this.color,
      repeatDays: repeatDays ?? this.repeatDays,
      reminderTime: reminderTime ?? this.reminderTime,
      isInterval: isInterval ?? this.isInterval,
      intervalMinutes: intervalMinutes ?? this.intervalMinutes,
      windowStartTime: windowStartTime ?? this.windowStartTime,
      windowEndTime: windowEndTime ?? this.windowEndTime,
      targetValue: targetValue ?? this.targetValue,
      unit: unit ?? this.unit,
      rollingInterval: rollingInterval ?? this.rollingInterval,
      currentValueToday: currentValueToday ?? this.currentValueToday,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      completedDates: completedDates ?? this.completedDates,
      skippedDates: skippedDates ?? this.skippedDates,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      totalCompleted: totalCompleted ?? this.totalCompleted,
    );
  }

  factory HabitModel.fromJson(Map<String, dynamic> json) {
    final rawCategory = json['category'] as String? ?? 'Other';
    final parsedCategory = rawCategory.isNotEmpty
        ? rawCategory[0].toUpperCase() + rawCategory.substring(1).toLowerCase()
        : 'Other';

    return HabitModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String,
      category: parsedCategory,
      emoji: json['emoji'] as String?,
      color: json['color'] as String?,
      repeatDays: (json['repeatDays'] as List<dynamic>?)
              ?.map((e) => e as bool)
              .toList() ??
          List.filled(7, true),
      reminderTime: json['reminderTime'] as String?,
      isInterval: json['isInterval'] as bool? ?? false,
      intervalMinutes: json['intervalMinutes'] as int?,
      windowStartTime: json['windowStartTime'] as String?,
      windowEndTime: json['windowEndTime'] as String?,
      targetValue: (json['targetValue'] as num?)?.toDouble(),
      unit: json['unit'] as String?,
      rollingInterval: json['rollingInterval'] as bool? ?? false,
      currentValueToday:
          (json['currentValueToday'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedDates: (json['completedDates'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      skippedDates: (json['skippedDates'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      currentStreak: json['currentStreak'] as int? ?? 0,
      longestStreak: json['longestStreak'] as int? ?? 0,
      totalCompleted: json['totalCompleted'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': _safeCategory,
      'emoji': emoji,
      'color': color,
      'repeatDays': repeatDays,
      'reminderTime': reminderTime,
      'isInterval': isInterval,
      'intervalMinutes': intervalMinutes,
      'windowStartTime': windowStartTime,
      'windowEndTime': windowEndTime,
      'targetValue': targetValue,
      'unit': unit,
      'rollingInterval': rollingInterval,
      'currentValueToday': currentValueToday,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'completedDates': completedDates,
      'skippedDates': skippedDates,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'totalCompleted': totalCompleted,
    };
  }

  /// Payload for the backend `POST /habits` endpoint
  Map<String, dynamic> toCreateJson() {
    return {
      'name': name,
      'category': _safeCategory,
      'emoji': emoji,
      'color': color,
      'repeatDays': repeatDays,
      'reminderTime': reminderTime,
      'isInterval': isInterval,
      'intervalMinutes': intervalMinutes,
      'windowStartTime': windowStartTime,
      'windowEndTime': windowEndTime,
      'targetValue': targetValue,
      'unit': unit,
      'rollingInterval': rollingInterval,
      'notes': notes,
    };
  }

  String get _safeCategory {
    final catUpper = category.trim().toUpperCase();
    return catUpper.isEmpty ? 'OTHER' : catUpper;
  }
}
