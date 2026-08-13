class GoalModel {
  final String id;
  final String name;
  final String category;
  final DateTime targetDate;
  final String priority;
  final String status;
  final double progress; // 0.0 - 1.0
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
    this.notes,
    required this.createdAt,
  });

  GoalModel copyWith({
    String? id,
    String? name,
    String? category,
    DateTime? targetDate,
    String? priority,
    String? status,
    double? progress,
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
      'notes': notes,
    };
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
