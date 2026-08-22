import 'goal_units.dart';

class GoalModel {
  final String id;
  final String name;
  final String category;
  final DateTime targetDate;
  final String priority;
  final String status;
  final double progress; // 0.0 - 1.0
  final int durationDays;
  final double target; // target amount in [unit] (0 = not set → parsed from name)
  final String unit; // e.g. 'kg', 'km', 'L', 'hours', '₹', 'books', 'tasks'
  final String? notes;
  final DateTime createdAt;

  GoalModel({
    required this.id,
    required this.name,
    required this.category,
    required this.targetDate,
    required this.priority,
    required this.status,
    required this.progress,
    this.durationDays = 30,
    this.target = 0,
    this.unit = '',
    this.notes,
    required this.createdAt,
  });

  /// Whether a numeric target has been stored (legacy goals have none and fall
  /// back to parsing the target out of the goal name).
  bool get hasTarget => target > 0;

  /// Whether the goal's unit allows fractional values (kg, km, L, hours …).
  /// Goals without a unit default to allowing decimals (permissive legacy).
  bool get allowsDecimalProgress => unitAllowsDecimals(unit);

  GoalModel copyWith({
    String? id,
    String? name,
    String? category,
    DateTime? targetDate,
    String? priority,
    String? status,
    double? progress,
    int? durationDays,
    double? target,
    String? unit,
    String? notes,
    DateTime? createdAt,
  }) {
    return GoalModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      targetDate: targetDate ?? this.targetDate,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      durationDays: durationDays ?? this.durationDays,
      target: target ?? this.target,
      unit: unit ?? this.unit,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory GoalModel.fromJson(Map<String, dynamic> json) {
    final rawCategory = json['category'] as String? ?? 'Personal';
    final parsedCategory = rawCategory.isNotEmpty
        ? rawCategory[0].toUpperCase() + rawCategory.substring(1).toLowerCase()
        : 'Personal';

    final rawPriority = json['priority'] as String? ?? 'Medium';
    final parsedPriority = rawPriority.isNotEmpty
        ? rawPriority[0].toUpperCase() + rawPriority.substring(1).toLowerCase()
        : 'Medium';

    final rawStatus = json['status'] as String? ?? 'in_progress';
    final parsedStatus = rawStatus.toLowerCase();

    return GoalModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? 'Untitled Goal',
      category: parsedCategory,
      targetDate: json['targetDate'] != null ? DateTime.parse(json['targetDate'] as String) : DateTime.now(),
      priority: parsedPriority,
      status: parsedStatus,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      durationDays: (json['durationDays'] as num?)?.toInt() ?? 30,
      target: (json['target'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] as String? ?? '',
      notes: json['notes'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': _safeCategory,
      'targetDate': targetDate.toUtc().toIso8601String(),
      'priority': _safePriority,
      'status': _safeStatus,
      'progress': progress,
      'durationDays': durationDays,
      'target': target,
      'unit': unit,
      'notes': notes,
      'createdAt': createdAt.toUtc().toIso8601String(),
    };
  }

  /// Payload for the backend `POST /goals` endpoint — only fields the API
  /// accepts (server-managed fields like id/status/progress/createdAt must be
  /// omitted or the strict validation pipe rejects the request with 400).
  Map<String, dynamic> toCreateJson() {
    return {
      'name': name,
      'category': _safeCategory,
      'targetDate': targetDate.toUtc().toIso8601String(),
      'priority': _safePriority,
      'durationDays': durationDays,
      'target': target,
      // The backend only accepts units from its whitelist, so an empty unit is
      // sent as null (absent) instead of a rejected empty string.
      'unit': unit.isEmpty ? null : unit,
      'notes': notes,
    };
  }

  /// Payload for the backend `PATCH /goals/:id` endpoint — same editable
  /// fields as creation; server-managed fields (id, status, progress,
  /// createdAt) are intentionally omitted so they are never overwritten.
  Map<String, dynamic> toUpdateJson() {
    return toCreateJson();
  }

  /// Date-only form of [date] (midnight, no time component) so day arithmetic
  /// in the goal form is exact.
  static DateTime dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// Target date for a goal of [durationDays] starting on [startDate].
  static DateTime targetDateForDuration(
          DateTime startDate, int durationDays) =>
      dateOnly(startDate).add(Duration(days: durationDays));

  /// Effective duration (clamped to 1 – 365 days) implied by a manually chosen
  /// [targetDate], measured from [startDate]. Used when the user overrides the
  /// target date so Duration and Target Date stay in sync.
  static int durationForTargetDate(DateTime startDate, DateTime targetDate) {
    final days =
        dateOnly(targetDate).difference(dateOnly(startDate)).inDays;
    return days.clamp(1, 365);
  }

  String get _safeCategory {
    const validCategories = {
      'PERSONAL', 'CAREER', 'FITNESS', 'EDUCATION', 'FINANCE', 'HEALTH', 'RELATIONSHIPS', 'OTHER'
    };
    final catUpper = category.toUpperCase();
    return validCategories.contains(catUpper) ? catUpper : 'PERSONAL';
  }

  String get _safePriority {
    const validPriorities = {'LOW', 'MEDIUM', 'HIGH'};
    final prioUpper = priority.toUpperCase();
    return validPriorities.contains(prioUpper) ? prioUpper : 'MEDIUM';
  }

  String get _safeStatus {
    const validStatuses = {'IN_PROGRESS', 'COMPLETED', 'ARCHIVED', 'CANCELLED'};
    final statusUpper = status.toUpperCase();
    return validStatuses.contains(statusUpper) ? statusUpper : 'IN_PROGRESS';
  }
}
