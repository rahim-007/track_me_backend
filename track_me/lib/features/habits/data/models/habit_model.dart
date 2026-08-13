class HabitModel {
  final String id;
  final String name;
  final String category;
  final String? emoji;
  final String? color;
  final List<bool> repeatDays;
  final String? reminderTime;
  final String? notes;
  final DateTime createdAt;
  List<String> completedDates;
  List<String> skippedDates;

  HabitModel({
    required this.id,
    required this.name,
    required this.category,
    this.emoji,
    this.color,
    required this.repeatDays,
    this.reminderTime,
    this.notes,
    required this.createdAt,
    required this.completedDates,
    required this.skippedDates,
  });

  bool get isCompletedToday {
    final today = _todayStr;
    return completedDates.contains(today);
  }

  bool get isSkippedToday {
    final today = _todayStr;
    return skippedDates.contains(today);
  }

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
    String? notes,
    DateTime? createdAt,
    List<String>? completedDates,
    List<String>? skippedDates,
  }) {
    return HabitModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      emoji: emoji ?? this.emoji,
      color: color ?? this.color,
      repeatDays: repeatDays ?? this.repeatDays,
      reminderTime: reminderTime ?? this.reminderTime,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      completedDates: completedDates ?? this.completedDates,
      skippedDates: skippedDates ?? this.skippedDates,
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
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'completedDates': completedDates,
      'skippedDates': skippedDates,
    };
  }

  /// Payload for the backend `POST /habits` endpoint — only fields the API
  /// accepts (server-managed fields like id/createdAt/logs must be omitted or
  /// the strict validation pipe rejects the request with 400).
  Map<String, dynamic> toCreateJson() {
    return {
      'name': name,
      'category': _safeCategory,
      'emoji': emoji,
      'color': color,
      'repeatDays': repeatDays,
      'reminderTime': reminderTime,
      'notes': notes,
    };
  }

  String get _safeCategory {
    const validCategories = {
      'HEALTH', 'FITNESS', 'LEARNING', 'MINDFULNESS',
      'PRODUCTIVITY', 'SOCIAL', 'FINANCE', 'OTHER'
    };
    final catUpper = category.toUpperCase();
    return validCategories.contains(catUpper) ? catUpper : 'OTHER';
  }
}
