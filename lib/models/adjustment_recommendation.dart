class AdjustmentRecommendation {
  final String title;
  final String details;
  final String? category;

  AdjustmentRecommendation({
    required this.title,
    required this.details,
    this.category,
  });

  factory AdjustmentRecommendation.fromJson(Map<String, dynamic> json) {
    return AdjustmentRecommendation(
      title: json['title'] as String? ?? '',
      details: json['details'] as String? ?? '',
      category: json['category'] as String?,
    );
  }
}
