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
    return GoalModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String,
      category: json['category'] as String? ?? 'Other',
      targetDate: DateTime.parse(json['targetDate'] as String),
      priority: json['priority'] as String? ?? 'Medium',
      status: json['status'] as String? ?? 'in_progress',
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'targetDate': targetDate.toIso8601String(),
      'priority': priority,
      'status': status,
      'progress': progress,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
