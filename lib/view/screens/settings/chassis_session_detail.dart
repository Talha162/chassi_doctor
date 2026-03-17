import 'package:flutter/material.dart';
import 'package:motorsport/constants/app_colors.dart';
import 'package:motorsport/constants/app_sizes.dart';
import 'package:motorsport/models/history_entry.dart';
import 'package:motorsport/services/supabase/supabase_client_service.dart';
import 'package:motorsport/view/widget/custom_app_bar_widget.dart';
import 'package:motorsport/view/widget/my_text_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChassisSessionDetail extends StatefulWidget {
  const ChassisSessionDetail({
    super.key,
    required this.session,
  });

  final HistoryEntry session;

  @override
  State<ChassisSessionDetail> createState() => _ChassisSessionDetailState();
}

class _ChassisSessionDetailState extends State<ChassisSessionDetail> {
  final SupabaseService _service = SupabaseService.instance;
  String? _note;
  bool _isLoadingNote = false;

  String get _sourceType => widget.session.hasSessionData ? 'session' : 'track';
  String get _sourceId => widget.session.id;

  @override
  void initState() {
    super.initState();
    _loadNote();
  }

  Future<void> _loadNote() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    setState(() => _isLoadingNote = true);
    try {
      final note = await _service.getHistoryNote(
        userId: userId,
        sourceType: _sourceType,
        sourceId: _sourceId,
      );
      if (!mounted) return;
      setState(() {
        _note = note?.note;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingNote = false);
      }
    }
  }

  Future<void> _editNote() async {
    final controller = TextEditingController(text: _note ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: kQuaternaryColor,
          title: Text(
            'Session Note',
            style: TextStyle(color: kTertiaryColor),
          ),
          content: TextField(
            controller: controller,
            maxLines: 5,
            style: TextStyle(color: kTertiaryColor),
            cursorColor: kSecondaryColor,
            decoration: InputDecoration(
              hintText: 'Add your note...',
              hintStyle: TextStyle(color: kSecondaryColor),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (saved != true) return;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final nextNote = controller.text.trim();
    if (nextNote.isEmpty) {
      await _service.deleteHistoryNote(
        userId: userId,
        sourceType: _sourceType,
        sourceId: _sourceId,
      );
      setState(() => _note = null);
      return;
    }

    await _service.upsertHistoryNote(
      userId: userId,
      sourceType: _sourceType,
      sourceId: _sourceId,
      note: nextNote,
    );
    setState(() => _note = nextNote);
  }

  @override
  Widget build(BuildContext context) {
    final track = widget.session.trackSnapshot;
    final symptom = widget.session.symptomSnapshot;
    final issues = widget.session.issuesSnapshot;
    final recommendations = widget.session.recommendations;

    return Scaffold(
      appBar: simpleAppBar(
        title: 'Session Details',
        actions: [
          IconButton(
            onPressed: _isLoadingNote ? null : _editNote,
            icon: Icon(
              _note == null || _note!.isEmpty
                  ? Icons.note_add_outlined
                  : Icons.sticky_note_2_outlined,
              color: kTertiaryColor,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: AppSizes.DEFAULT,
        children: [
          _SectionTitle(title: 'Track Configuration'),
          _InfoRow(
            label: 'Track Type',
            value: track['track_type']?.toString() ?? 'Not set',
          ),
          _InfoRow(
            label: 'Surface Type',
            value: track['surface_type']?.toString() ?? 'Not set',
          ),
          _InfoRow(
            label: 'Weather',
            value: track['weather_condition']?.toString() ?? 'Not set',
          ),
          const SizedBox(height: 16),
          _SectionTitle(title: 'Selected Symptom'),
          if (!widget.session.hasSessionData)
            MyText(
              text: 'No symptom selected for this session.',
              size: 12,
              color: kSecondaryColor,
            )
          else
            _InfoRow(
              label: symptom['title']?.toString() ?? 'Unknown',
              value: symptom['description']?.toString() ?? '',
            ),
          const SizedBox(height: 16),
          _SectionTitle(title: 'Selected Issues'),
          if (!widget.session.hasSessionData || issues.isEmpty)
            MyText(
              text: 'No issues selected.',
              size: 12,
              color: kSecondaryColor,
            )
          else
            ...issues.map((issue) {
              final issueMap = issue as Map;
              return _BulletItem(
                title: issueMap['title']?.toString() ?? 'Issue',
                subtitle: issueMap['description']?.toString() ?? '',
              );
            }),
          const SizedBox(height: 16),
          _SectionTitle(title: 'AI Recommendations'),
          if (!widget.session.hasSessionData || recommendations.isEmpty)
            MyText(
              text: 'No recommendations generated.',
              size: 12,
              color: kSecondaryColor,
            )
          else
            ...recommendations.map((rec) {
              final recMap = rec as Map;
              final category = recMap['category']?.toString();
              return _BulletItem(
                title: recMap['title']?.toString() ?? 'Recommendation',
                subtitle: recMap['details']?.toString() ?? '',
                trailing: category,
              );
            }),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return MyText(
      text: title,
      size: 16,
      weight: FontWeight.bold,
      paddingBottom: 8,
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: kQuaternaryColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: MyText(
              text: label,
              size: 12,
              color: kSecondaryColor,
              maxLines: 2,
              textOverflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 4,
            child: MyText(
              text: value,
              size: 12,
              weight: FontWeight.w600,
              textAlign: TextAlign.end,
              maxLines: 3,
              textOverflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _BulletItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? trailing;

  const _BulletItem({
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: kQuaternaryColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: MyText(text: title, size: 13, weight: FontWeight.w600),
              ),
              if (trailing != null && trailing!.trim().isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xffE8618C).withAlpha(51),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: MyText(
                    text: trailing!,
                    size: 10,
                    color: const Color(0xffE8618C),
                  ),
                ),
            ],
          ),
          if (subtitle.trim().isNotEmpty)
            MyText(paddingTop: 6, text: subtitle, size: 12),
        ],
      ),
    );
  }
}
