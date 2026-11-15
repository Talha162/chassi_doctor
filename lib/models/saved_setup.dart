/// A geometry calculator setup saved to the member's account.
///
/// Shared with the Chassis Doctor website: [data] is the calculator's state in
/// exactly the JSON the website keeps under [stateKey] in localStorage, so the
/// same setup opens on either side.
class SavedSetup {
  SavedSetup({
    required this.id,
    required this.tool,
    required this.stateKey,
    required this.name,
    required this.data,
    required this.source,
    required this.createdAt,
    required this.updatedAt,
    this.trackName,
    this.eventDate,
    this.notes,
  });

  final String id;
  final String tool;
  final String stateKey;
  final String name;
  final String? trackName;
  final DateTime? eventDate;
  final String? notes;
  final Map<String, dynamic> data;
  final String source; // 'app' | 'web'
  final DateTime createdAt;
  final DateTime updatedAt;

  factory SavedSetup.fromJson(Map<String, dynamic> json) => SavedSetup(
        id: json['id'] as String,
        tool: json['tool'] as String,
        stateKey: json['state_key'] as String,
        name: json['name'] as String,
        trackName: json['track_name'] as String?,
        eventDate: json['event_date'] == null
            ? null
            : DateTime.tryParse(json['event_date'] as String),
        notes: json['notes'] as String?,
        data: Map<String, dynamic>.from(json['data'] as Map),
        source: (json['source'] as String?) ?? 'app',
        createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
        updatedAt: DateTime.parse(json['updated_at'] as String).toLocal(),
      );
}
