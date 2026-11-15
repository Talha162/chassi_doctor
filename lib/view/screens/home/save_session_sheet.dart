import 'package:flutter/material.dart';
import 'package:motorsport/config/theme/theme_controller.dart';
import 'package:motorsport/constants/app_colors.dart';
import 'package:motorsport/models/chassis_session.dart';
import 'package:motorsport/utils/app_error.dart';
import 'package:motorsport/utils/validators.dart';
import 'package:motorsport/view/screens/geometry/setup_sheets.dart';

const _errorColor = Color(0xffFF6B6B);

/// What the driver typed in the "Save to session" sheet.
class SessionDetails {
  const SessionDetails({
    required this.name,
    required this.trackName,
    required this.eventDate,
    required this.notes,
  });

  final String name;
  final String trackName;
  final DateTime eventDate;
  final String notes;
}

/// Asks for a session name, track, date and notes, then calls [onSave].
/// Returns the saved session, or null if the driver closed the sheet.
Future<ChassisSession?> showSaveSessionSheet(
  BuildContext context, {
  required String? initialTrack,
  required String summary,
  required Future<ChassisSession> Function(SessionDetails details) onSave,
}) {
  return showModalBottomSheet<ChassisSession>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: appSheetFrame(
        ctx,
        child: _SaveSessionForm(
          initialTrack: initialTrack,
          summary: summary,
          onSave: onSave,
        ),
      ),
    ),
  );
}

class _SaveSessionForm extends StatefulWidget {
  const _SaveSessionForm({
    required this.initialTrack,
    required this.summary,
    required this.onSave,
  });

  final String? initialTrack;
  final String summary;
  final Future<ChassisSession> Function(SessionDetails details) onSave;

  @override
  State<_SaveSessionForm> createState() => _SaveSessionFormState();
}

class _SaveSessionFormState extends State<_SaveSessionForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  late final _track = TextEditingController(text: widget.initialTrack ?? '');
  final _notes = TextEditingController();
  DateTime _date = DateTime.now();
  bool _submitted = false;
  bool _saving = false;
  String? _error;

  static const _suggestions = [
    'Practice',
    'Qualifying',
    'Race 1',
    'Race 2',
    'Test day',
  ];

  @override
  void dispose() {
    _name.dispose();
    _track.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 2, 12, 31),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.dark(
            primary: kSecondaryColor,
            surface: kPrimaryColor,
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _submitted = true;
      _error = null;
    });
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final saved = await widget.onSave(
        SessionDetails(
          name: _name.text.trim(),
          trackName: _track.text.trim(),
          eventDate: _date,
          notes: _notes.text.trim(),
        ),
      );
      if (mounted) Navigator.of(context).pop(saved);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = friendlyError(
            e,
            fallback: "Couldn't save this session. Please try again.",
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeController.instance.isDarkMode;
    final gold = kSecondaryColor;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Form(
        key: _formKey,
        autovalidateMode: _submitted
            ? AutovalidateMode.onUserInteraction
            : AutovalidateMode.disabled,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Save to session',
              style: TextStyle(
                color: kWhiteColor,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.summary}. Saved to your History so you can look '
              'back at what you changed at each event.',
              style: TextStyle(
                color: kTertiaryColor.withValues(alpha: 0.75),
                fontSize: 13.5,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _name,
              enabled: !_saving,
              maxLength: 80,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              style: TextStyle(color: kWhiteColor),
              cursorColor: gold,
              decoration: appSheetDecoration(
                'Session name',
                hint: 'e.g. Qualifying',
              ),
              validator: AppValidators.requiredText(label: 'a name', max: 80),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in _suggestions)
                  _SuggestionChip(
                    label: s,
                    gold: gold,
                    onTap: _saving
                        ? null
                        : () => setState(() {
                              _name.text = s;
                              _name.selection = TextSelection.collapsed(
                                offset: s.length,
                              );
                            }),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _track,
              enabled: !_saving,
              maxLength: 80,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              style: TextStyle(color: kWhiteColor),
              cursorColor: gold,
              decoration: appSheetDecoration(
                'Track (optional)',
                hint: 'e.g. Brands Hatch',
              ),
              validator: AppValidators.optionalMax(80, label: 'Track'),
            ),
            const SizedBox(height: 8),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _saving ? null : _pickDate,
              child: InputDecorator(
                decoration: appSheetDecoration('Date').copyWith(
                  suffixIcon: Icon(
                    Icons.calendar_today_rounded,
                    color: kTertiaryColor.withValues(alpha: 0.6),
                    size: 20,
                  ),
                ),
                child: Text(
                  formatSetupDate(_date),
                  style: TextStyle(color: kWhiteColor, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notes,
              enabled: !_saving,
              maxLength: 1000,
              minLines: 3,
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
              style: TextStyle(color: kWhiteColor),
              cursorColor: gold,
              decoration: appSheetDecoration(
                'Notes (optional)',
                hint: 'Tyres, pressures, what you changed, how it felt…',
              ),
              validator: AppValidators.optionalMax(1000, label: 'Notes'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: _errorColor,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: _errorColor, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: gold,
                  disabledBackgroundColor: gold.withValues(alpha: 0.5),
                  foregroundColor: isDark ? Colors.black : kPrimaryColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                ),
                child: _saving
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: isDark ? Colors.black : kPrimaryColor,
                        ),
                      )
                    : const Text(
                        'Save session',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({
    required this.label,
    required this.gold,
    required this.onTap,
  });

  final String label;
  final Color gold;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: gold.withValues(alpha: 0.55)),
          color: gold.withValues(alpha: 0.08),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: gold,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
