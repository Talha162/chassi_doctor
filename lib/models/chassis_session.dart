class ChassisSession {
  final String id;
  final String userId;
  final Map<String, dynamic> trackSnapshot;
  final Map<String, dynamic> symptomSnapshot;
  final List<dynamic> issuesSnapshot;
  final List<dynamic> recommendations;
  final DateTime createdAt;

  /// Name the driver gave the session, e.g. "Qualifying" (null on older rows).
  final String? sessionName;

  /// Race or test day the session belongs to (null on older rows).
  final DateTime? eventDate;

  ChassisSession({
    required this.id,
    required this.userId,
    required this.trackSnapshot,
    required this.symptomSnapshot,
    required this.issuesSnapshot,
    required this.recommendations,
    required this.createdAt,
    this.sessionName,
    this.eventDate,
  });

  factory ChassisSession.fromJson(Map<String, dynamic> json) {
    final name = (json['session_name'] as String?)?.trim();
    final date = json['event_date'] as String?;
    return ChassisSession(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      trackSnapshot: (json['track_snapshot'] as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{},
      symptomSnapshot:
          (json['symptom_snapshot'] as Map?)?.cast<String, dynamic>() ??
              <String, dynamic>{},
      issuesSnapshot: (json['issues_snapshot'] as List?) ?? <dynamic>[],
      recommendations: (json['recommendations'] as List?) ?? <dynamic>[],
      createdAt: DateTime.parse(json['created_at'] as String),
      sessionName: (name == null || name.isEmpty) ? null : name,
      eventDate: date == null ? null : DateTime.tryParse(date),
    );
  }
}
