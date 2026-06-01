class ChassisIssueOption {
  final String id;
  final String symptomId;
  final String title;
  final String description;
  final String? imageUrl;

  ChassisIssueOption({
    required this.id,
    required this.symptomId,
    required this.title,
    required this.description,
    this.imageUrl,
  });

  factory ChassisIssueOption.fromJson(Map<String, dynamic> json) {
    final rawImage = json['image_url'] as String?;
    final image = rawImage?.trim();
    return ChassisIssueOption(
      id: json['id'] as String,
      symptomId: json['symptom_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      imageUrl: image == null || image.isEmpty ? null : image,
    );
  }
}
