class ChassisSymptom {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;

  ChassisSymptom({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
  });

  factory ChassisSymptom.fromJson(Map<String, dynamic> json) {
    final rawImage = json['image_url'] as String?;
    final image = rawImage?.trim();
    return ChassisSymptom(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      imageUrl: image == null || image.isEmpty ? null : image,
    );
  }
}
