class ModuleProgressSummary {
  final String moduleId;
  final String userId;
  final double progressPercentage;

  ModuleProgressSummary({
    required this.moduleId,
    required this.userId,
    required this.progressPercentage,
  });

  factory ModuleProgressSummary.fromJson(Map<String, dynamic> json) {
    return ModuleProgressSummary(
      moduleId: json['module_id'] as String,
      userId: json['user_id'] as String,
      progressPercentage: (json['progress_percentage'] as num).toDouble(),
    );
  }
}
