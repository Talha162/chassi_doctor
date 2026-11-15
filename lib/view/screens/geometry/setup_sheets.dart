import 'package:flutter/material.dart';
import 'package:motorsport/config/theme/theme_controller.dart';
import 'package:motorsport/constants/app_colors.dart';
import 'package:motorsport/models/geometry_tool.dart';
import 'package:motorsport/models/saved_setup.dart';
import 'package:motorsport/services/supabase/supabase_client_service.dart';
import 'package:motorsport/utils/app_error.dart';
import 'package:motorsport/utils/app_snackbar.dart';
import 'package:motorsport/utils/motion.dart';
import 'package:motorsport/utils/validators.dart';

const _errorColor = Color(0xffFF6B6B);

String formatSetupDate(DateTime d) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}

/// "Brands Hatch · 14 Nov 2026", or null when neither is set.
String? setupSubtitle(SavedSetup s) {
  final parts = [
    if ((s.trackName ?? '').isNotEmpty) s.trackName!,
    if (s.eventDate != null) formatSetupDate(s.eventDate!),
  ];
  return parts.isEmpty ? null : parts.join(' · ');
}

Widget appSheetFrame(BuildContext context, {required Widget child}) {
  return Container(
    decoration: BoxDecoration(
      color: kQuaternaryColor,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      border: Border(
        top: BorderSide(color: kSecondaryColor.withValues(alpha: 0.25)),
      ),
    ),
    child: SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 42,
            height: 4.5,
            decoration: BoxDecoration(
              color: kTertiaryColor.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Flexible(child: child),
        ],
      ),
    ),
  );
}

InputDecoration appSheetDecoration(String label, {String? hint}) {
  OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c, width: w),
      );
  return InputDecoration(
    labelText: label,
    hintText: hint,
    alignLabelWithHint: true,
    labelStyle: TextStyle(color: kTertiaryColor.withValues(alpha: 0.75)),
    floatingLabelStyle: TextStyle(color: kSecondaryColor),
    hintStyle: TextStyle(color: kTertiaryColor.withValues(alpha: 0.4)),
    counterStyle: TextStyle(color: kTertiaryColor.withValues(alpha: 0.5)),
    errorStyle: const TextStyle(color: _errorColor, fontSize: 12),
    filled: true,
    fillColor: kPrimaryColor.withValues(alpha: 0.55),
    enabledBorder: border(kBorderColor2),
    border: border(kBorderColor2),
    focusedBorder: border(kSecondaryColor, 1.5),
    errorBorder: border(_errorColor.withValues(alpha: 0.85)),
    focusedErrorBorder: border(_errorColor, 1.5),
  );
}

// ───────────────────────────── Save / edit ─────────────────────────────

/// Save the calculator's current [data] as a new setup, or edit an
/// existing setup's details when [existing] is given. Returns the saved row.
Future<SavedSetup?> showSaveSetupSheet(
  BuildContext context, {
  required GeometryTool tool,
  Map<String, dynamic>? data,
  SavedSetup? existing,
}) {
  return showModalBottomSheet<SavedSetup>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: appSheetFrame(
        ctx,
        child: _SaveSetupForm(tool: tool, data: data, existing: existing),
      ),
    ),
  );
}

class _SaveSetupForm extends StatefulWidget {
  const _SaveSetupForm({required this.tool, this.data, this.existing});

  final GeometryTool tool;
  final Map<String, dynamic>? data;
  final SavedSetup? existing;

  @override
  State<_SaveSetupForm> createState() => _SaveSetupFormState();
}

class _SaveSetupFormState extends State<_SaveSetupForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.existing?.name);
  late final _track = TextEditingController(text: widget.existing?.trackName);
  late final _notes = TextEditingController(text: widget.existing?.notes);
  late DateTime? _date = widget.existing?.eventDate ??
      (widget.existing == null ? DateTime.now() : null);
  bool _submitted = false;
  bool _saving = false;
  String? _error;

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
      initialDate: _date ?? now,
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
      final service = SupabaseService.instance;
      final existing = widget.existing;
      final saved = existing == null
          ? await service.createSavedSetup(
              tool: widget.tool.key,
              stateKey: widget.tool.stateKey,
              data: widget.data!,
              name: _name.text,
              trackName: _track.text,
              eventDate: _date,
              notes: _notes.text,
            )
          : await service.updateSavedSetupDetails(
              id: existing.id,
              name: _name.text,
              trackName: _track.text,
              eventDate: _date,
              notes: _notes.text,
            );
      if (mounted) Navigator.of(context).pop(saved);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = friendlyError(
            e,
            fallback: "Couldn't save this setup. Please try again.",
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeController.instance.isDarkMode;
    final gold = kSecondaryColor;
    final editing = widget.existing != null;
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
              editing ? 'Edit setup details' : 'Save this setup',
              style: TextStyle(
                color: kWhiteColor,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              editing
                  ? 'Change the name, track, date or notes.'
                  : 'Saved to your account. Open it again here or on the '
                      'Chassis Doctor website before your next race.',
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
              autofocus: !editing,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              style: TextStyle(color: kWhiteColor),
              cursorColor: gold,
              decoration: appSheetDecoration('Setup name', hint: 'e.g. Qualifying, softer front'),
              validator: AppValidators.requiredText(label: 'a name', max: 80),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _track,
              enabled: !_saving,
              maxLength: 80,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              style: TextStyle(color: kWhiteColor),
              cursorColor: gold,
              decoration: appSheetDecoration('Track (optional)', hint: 'e.g. Brands Hatch'),
              validator: AppValidators.optionalMax(80, label: 'Track'),
            ),
            const SizedBox(height: 8),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _saving ? null : _pickDate,
              child: InputDecorator(
                decoration: appSheetDecoration('Race date (optional)').copyWith(
                  suffixIcon: _date == null
                      ? Icon(Icons.calendar_today_rounded,
                          color: kTertiaryColor.withValues(alpha: 0.6), size: 20)
                      : IconButton(
                          tooltip: 'Clear date',
                          icon: Icon(Icons.close_rounded,
                              color: kTertiaryColor.withValues(alpha: 0.7)),
                          onPressed: () => setState(() => _date = null),
                        ),
                ),
                child: Text(
                  _date == null ? 'No date' : formatSetupDate(_date!),
                  style: TextStyle(
                    color: _date == null
                        ? kTertiaryColor.withValues(alpha: 0.5)
                        : kWhiteColor,
                    fontSize: 16,
                  ),
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
                hint: 'Weather, tyres, how the car felt…',
              ),
              validator: AppValidators.optionalMax(1000, label: 'Notes'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: _errorColor, size: 18),
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
                    : Text(
                        editing ? 'Save details' : 'Save setup',
                        style: const TextStyle(
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

// ───────────────────────────── List ─────────────────────────────

/// The member's setups for [tool]. Returns the setup to load, if one is picked.
Future<SavedSetup?> showSetupListSheet(
  BuildContext context, {
  required GeometryTool tool,
  required Future<Map<String, dynamic>?> Function() readCurrentState,
}) {
  return showModalBottomSheet<SavedSetup>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(ctx).height * 0.82,
      ),
      child: appSheetFrame(
        ctx,
        child: _SetupList(tool: tool, readCurrentState: readCurrentState),
      ),
    ),
  );
}

class _SetupList extends StatefulWidget {
  const _SetupList({required this.tool, required this.readCurrentState});

  final GeometryTool tool;
  final Future<Map<String, dynamic>?> Function() readCurrentState;

  @override
  State<_SetupList> createState() => _SetupListState();
}

class _SetupListState extends State<_SetupList> {
  List<SavedSetup>? _setups;
  String? _error;
  String? _confirmDelete;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list =
          await SupabaseService.instance.getSavedSetups(tool: widget.tool.key);
      if (mounted) setState(() => _setups = list);
    } catch (e) {
      if (mounted) {
        setState(() => _error = friendlyError(
              e,
              fallback: "Couldn't load your setups. Please try again.",
            ));
      }
    }
  }

  Future<void> _updateFigures(SavedSetup s) async {
    final state = await widget.readCurrentState();
    if (state == null) {
      showErrorSnackbar("Couldn't read the calculator's figures.");
      return;
    }
    try {
      final updated = await SupabaseService.instance.updateSavedSetupFigures(
        id: s.id,
        stateKey: widget.tool.stateKey,
        data: state,
      );
      if (!mounted) return;
      setState(() {
        _setups = [updated, ..._setups!.where((x) => x.id != s.id)];
      });
      showSuccessSnackbar('Updated “${s.name}” with the current figures.');
    } catch (e) {
      showErrorSnackbar(friendlyError(e), title: "Couldn't update the setup");
    }
  }

  Future<void> _edit(SavedSetup s) async {
    final updated = await showSaveSetupSheet(context, tool: widget.tool, existing: s);
    if (updated != null && mounted) {
      setState(() {
        _setups = _setups!.map((x) => x.id == updated.id ? updated : x).toList();
      });
    }
  }

  Future<void> _delete(SavedSetup s) async {
    try {
      await SupabaseService.instance.deleteSavedSetup(s.id);
      if (!mounted) return;
      setState(() {
        _setups = _setups!.where((x) => x.id != s.id).toList();
        _confirmDelete = null;
      });
      showSuccessSnackbar('Deleted “${s.name}”.');
    } catch (e) {
      showErrorSnackbar(friendlyError(e), title: "Couldn't delete the setup");
    }
  }

  @override
  Widget build(BuildContext context) {
    final setups = _setups;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My setups',
                style: TextStyle(
                  color: kWhiteColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${widget.tool.title} · saved on the app and website',
                style: TextStyle(
                  color: kTertiaryColor.withValues(alpha: 0.7),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        Flexible(
          child: _error != null
              ? _Message(icon: Icons.cloud_off_rounded, text: _error!)
              : setups == null
                  ? const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : setups.isEmpty
                      ? const _Message(
                          icon: Icons.bookmark_add_outlined,
                          text:
                              'No saved setups yet. Set up your figures, then tap “Save setup”.',
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                          itemCount: setups.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, i) => FadeInUp(
                            delay: staggerDelay(i),
                            child: _SetupCard(
                              setup: setups[i],
                              confirmingDelete: _confirmDelete == setups[i].id,
                              onLoad: () => Navigator.of(context).pop(setups[i]),
                              onUpdate: () => _updateFigures(setups[i]),
                              onEdit: () => _edit(setups[i]),
                              onAskDelete: () =>
                                  setState(() => _confirmDelete = setups[i].id),
                              onCancelDelete: () =>
                                  setState(() => _confirmDelete = null),
                              onDelete: () => _delete(setups[i]),
                            ),
                          ),
                        ),
        ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: kSecondaryColor, size: 40),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: kTertiaryColor.withValues(alpha: 0.85),
              fontSize: 14.5,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _SetupCard extends StatelessWidget {
  const _SetupCard({
    required this.setup,
    required this.confirmingDelete,
    required this.onLoad,
    required this.onUpdate,
    required this.onEdit,
    required this.onAskDelete,
    required this.onCancelDelete,
    required this.onDelete,
  });

  final SavedSetup setup;
  final bool confirmingDelete;
  final VoidCallback onLoad;
  final VoidCallback onUpdate;
  final VoidCallback onEdit;
  final VoidCallback onAskDelete;
  final VoidCallback onCancelDelete;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeController.instance.isDarkMode;
    final gold = kSecondaryColor;
    final subtitle = setupSubtitle(setup);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      decoration: BoxDecoration(
        color: kPrimaryColor.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorderColor2.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      setup.name,
                      style: TextStyle(
                        color: kWhiteColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(color: gold, fontSize: 13),
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'More',
                color: kQuaternaryColor,
                icon: Icon(Icons.more_vert_rounded,
                    color: kTertiaryColor.withValues(alpha: 0.8)),
                onSelected: (v) {
                  if (v == 'update') onUpdate();
                  if (v == 'edit') onEdit();
                  if (v == 'delete') onAskDelete();
                },
                itemBuilder: (_) => [
                  _menuItem('update', Icons.sync_rounded, 'Update with current figures'),
                  _menuItem('edit', Icons.edit_outlined, 'Edit details'),
                  _menuItem('delete', Icons.delete_outline_rounded, 'Delete',
                      color: _errorColor),
                ],
              ),
            ],
          ),
          if ((setup.notes ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                setup.notes!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: kTertiaryColor.withValues(alpha: 0.85),
                  fontSize: 13.5,
                  height: 1.35,
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: confirmingDelete
                ? Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Delete this setup?',
                          style: TextStyle(
                            color: _errorColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: onCancelDelete,
                        child: Text('Keep',
                            style: TextStyle(color: kTertiaryColor)),
                      ),
                      TextButton(
                        onPressed: onDelete,
                        child: const Text('Delete',
                            style: TextStyle(
                                color: _errorColor,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Icon(
                        setup.source == 'app'
                            ? Icons.phone_iphone_rounded
                            : Icons.language_rounded,
                        size: 14,
                        color: kTertiaryColor.withValues(alpha: 0.55),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          'Updated ${formatSetupDate(setup.updatedAt)} · '
                          '${setup.source == 'app' ? 'app' : 'website'}',
                          style: TextStyle(
                            color: kTertiaryColor.withValues(alpha: 0.55),
                            fontSize: 12,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 36,
                        child: ElevatedButton(
                          onPressed: onLoad,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: gold,
                            foregroundColor:
                                isDark ? Colors.black : kPrimaryColor,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: const Text(
                            'Load',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _menuItem(String v, IconData icon, String label,
      {Color? color}) {
    return PopupMenuItem<String>(
      value: v,
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? kTertiaryColor),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(color: color ?? kWhiteColor)),
        ],
      ),
    );
  }
}
