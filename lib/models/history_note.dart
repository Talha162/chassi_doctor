class HistoryNote {
  final String id;
  final String userId;
  final String sourceType;
  final String sourceId;
  final String note;
  final DateTime updatedAt;

  HistoryNote({
    required this.id,
    required this.userId,
    required this.sourceType,
    required this.sourceId,
    required this.note,
    required this.updatedAt,
  });

  factory HistoryNote.fromJson(Map<String, dynamic> json) {
    return HistoryNote(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      sourceType: json['source_type'] as String? ?? '',
      sourceId: json['source_id'] as String? ?? '',
      note: json['note'] as String? ?? '',
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
