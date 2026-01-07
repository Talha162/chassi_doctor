class ChassisSymptom {
  final String id;
  final String title;
  final String description;

  ChassisSymptom({
    required this.id,
    required this.title,
    required this.description,
  });

  factory ChassisSymptom.fromJson(Map<String, dynamic> json) {
    return ChassisSymptom(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }
}
