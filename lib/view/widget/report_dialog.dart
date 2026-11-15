import 'package:flutter/material.dart';
import 'package:motorsport/config/theme/theme_controller.dart';
import 'package:motorsport/constants/app_colors.dart';
import 'package:motorsport/utils/app_error.dart';
import 'package:motorsport/utils/motion.dart';
import 'package:motorsport/utils/validators.dart';

/// Themed "report something missing" dialog with inline validation.
///
/// Returns `true` once [onSubmit] succeeds (the dialog closes itself), or
/// `false`/`null` if the user cancels. Errors from [onSubmit] are shown
/// inside the dialog, so the user doesn't lose what they typed.
Future<bool?> showReportDialog({
  required BuildContext context,
  required String heading,
  required String titleLabel,
  required String titleHint,
  required String descriptionHint,
  required Future<void> Function(String title, String description) onSubmit,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => PopIn(
      child: _ReportDialog(
        heading: heading,
        titleLabel: titleLabel,
        titleHint: titleHint,
        descriptionHint: descriptionHint,
        onSubmit: onSubmit,
      ),
    ),
  );
}

class _ReportDialog extends StatefulWidget {
  const _ReportDialog({
    required this.heading,
    required this.titleLabel,
    required this.titleHint,
    required this.descriptionHint,
    required this.onSubmit,
  });

  final String heading;
  final String titleLabel;
  final String titleHint;
  final String descriptionHint;
  final Future<void> Function(String title, String description) onSubmit;

  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  static const _titleMax = 60;
  static const _descMax = 200;
  static const _errorColor = Color(0xffFF6B6B);

  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _desc = TextEditingController();
  bool _submitted = false;
  bool _saving = false;
  String? _serverError;

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _submitted = true;
      _serverError = null;
    });
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);
    try {
      await widget.onSubmit(_title.text.trim(), _desc.text.trim());
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _serverError = friendlyError(
            e,
            fallback: "Couldn't send your report. Please try again.",
          );
        });
      }
    }
  }

  InputDecoration _decoration(String label, String hint) {
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
      counterStyle: TextStyle(color: kTertiaryColor.withValues(alpha: 0.55)),
      errorStyle: const TextStyle(color: _errorColor, fontSize: 12),
      errorMaxLines: 2,
      filled: true,
      fillColor: kPrimaryColor.withValues(alpha: 0.55),
      enabledBorder: border(kBorderColor2),
      border: border(kBorderColor2),
      focusedBorder: border(kSecondaryColor, 1.5),
      errorBorder: border(_errorColor.withValues(alpha: 0.85)),
      focusedErrorBorder: border(_errorColor, 1.5),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeController.instance.isDarkMode;
    final gold = kSecondaryColor;
    return Dialog(
      backgroundColor: kQuaternaryColor,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: gold.withValues(alpha: 0.22)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 14),
        child: Form(
          key: _formKey,
          autovalidateMode: _submitted
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.heading,
                style: TextStyle(
                  color: kWhiteColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Tell us what's missing. Our team reviews every report and "
                'adds it to the app.',
                style: TextStyle(
                  color: kTertiaryColor.withValues(alpha: 0.75),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _title,
                enabled: !_saving,
                maxLength: _titleMax,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                style: TextStyle(color: kWhiteColor),
                cursorColor: gold,
                decoration: _decoration(widget.titleLabel, widget.titleHint),
                validator: AppValidators.requiredText(
                  label: 'a title',
                  min: 3,
                  max: _titleMax,
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _desc,
                enabled: !_saving,
                maxLength: _descMax,
                maxLines: 4,
                minLines: 3,
                textCapitalization: TextCapitalization.sentences,
                style: TextStyle(color: kWhiteColor),
                cursorColor: gold,
                decoration: _decoration('Description', widget.descriptionHint),
                validator: AppValidators.requiredText(
                  label: 'a short description',
                  min: 10,
                  max: _descMax,
                ),
              ),
              if (_serverError != null) ...[
                const SizedBox(height: 8),
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
                        _serverError!,
                        style: const TextStyle(
                          color: _errorColor,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _saving
                          ? null
                          : () => Navigator.of(context).pop(false),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: kTertiaryColor.withValues(alpha: 0.85),
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: gold,
                          disabledBackgroundColor: gold.withValues(alpha: 0.5),
                          foregroundColor: isDark
                              ? Colors.black
                              : kPrimaryColor,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(23),
                          ),
                        ),
                        child: _saving
                            ? SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: isDark ? Colors.black : kPrimaryColor,
                                ),
                              )
                            : const Text(
                                'Submit',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
