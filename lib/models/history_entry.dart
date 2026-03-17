class HistoryEntry {
  final String id;
  final DateTime createdAt;
  final Map<String, dynamic> trackSnapshot;
  final Map<String, dynamic> symptomSnapshot;
  final List<dynamic> issuesSnapshot;
  final List<dynamic> recommendations;
  final bool hasSessionData;

  HistoryEntry({
    required this.id,
    required this.createdAt,
    required this.trackSnapshot,
    required this.symptomSnapshot,
    required this.issuesSnapshot,
    required this.recommendations,
    required this.hasSessionData,
  });
}
