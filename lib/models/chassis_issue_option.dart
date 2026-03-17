class ChassisIssueOption {
  final String id;
  final String symptomId;
  final String title;
  final String description;

  ChassisIssueOption({
    required this.id,
    required this.symptomId,
    required this.title,
    required this.description,
  });

  factory ChassisIssueOption.fromJson(Map<String, dynamic> json) {
    return ChassisIssueOption(
      id: json['id'] as String,
      symptomId: json['symptom_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }
}
