class HistoryEntry {
  final String id;
  final DateTime createdAt;
  final Map<String, dynamic> trackSnapshot;
  final Map<String, dynamic> symptomSnapshot;
  final List<dynamic> issuesSnapshot;
  final List<dynamic> recommendations;
  final bool hasSessionData;

  /// Set when the driver saved the session with a name ("Save to session").
  final String? sessionName;

  /// Race or test day chosen when saving; falls back to [createdAt] for display.
  final DateTime? eventDate;

  HistoryEntry({
    required this.id,
    required this.createdAt,
    required this.trackSnapshot,
    required this.symptomSnapshot,
    required this.issuesSnapshot,
    required this.recommendations,
    required this.hasSessionData,
    this.sessionName,
    this.eventDate,
  });

  /// The date to show: the race day if one was chosen, else when it was saved.
  DateTime get displayDate => eventDate ?? createdAt.toLocal();
}
