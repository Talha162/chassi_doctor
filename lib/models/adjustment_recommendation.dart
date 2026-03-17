class AdjustmentRecommendation {
  final String? id;
  final String title;
  final String details;
  final String? category;
  final int? priorityOrder;

  AdjustmentRecommendation({
    this.id,
    required this.title,
    required this.details,
    this.category,
    this.priorityOrder,
  });

  factory AdjustmentRecommendation.fromJson(Map<String, dynamic> json) {
    return AdjustmentRecommendation(
      id: json['id'] as String?,
      title: json['title'] as String? ?? '',
      details: json['details'] as String? ?? '',
      category: json['category'] as String?,
      priorityOrder: json['priority_order'] as int?,
    );
  }
}
