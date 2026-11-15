import 'package:flutter/material.dart';
import 'package:motorsport/constants/app_colors.dart';
import 'package:motorsport/view/widget/my_text_widget.dart';

// ignore: must_be_immutable
class MyTextField extends StatefulWidget {
  MyTextField({
    Key? key,
    this.controller,
    this.hintText,
    this.labelText,
    this.onChanged,
    this.isObSecure = false,
    this.marginBottom = 16.0,
    this.maxLines = 1,
    this.labelSize,
    this.prefix,
    this.suffix,
    this.isReadOnly,
    this.onTap,
    this.fillColor,
    this.keyboardType,
    this.validator,
    this.textInputAction,
    this.onFieldSubmitted,
    this.autofillHints,
    this.maxLength,
  }) : super(key: key);

  /// Returns an error message (shown in red under the field) or null.
  /// Runs when the enclosing [Form] validates.
  final FormFieldValidator<String>? validator;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final Iterable<String>? autofillHints;
  final int? maxLength;

  /// When [TextInputType.emailAddress], the field also turns off
  /// autocorrect, suggestions and auto-capitalisation so iOS doesn't
  /// change what the user types (e.g. "talha" -> "Talha").
  final TextInputType? keyboardType;

  String? labelText, hintText;
  TextEditingController? controller;
  ValueChanged<String>? onChanged;
  bool? isObSecure, isReadOnly;
  double? marginBottom;
  int? maxLines;
  double? labelSize;
  Color? fillColor;
  Widget? prefix, suffix;
  final VoidCallback? onTap;

  @override
  State<MyTextField> createState() => _MyTextFieldState();
}

class _MyTextFieldState extends State<MyTextField> {
  static const Color _errorColor = Color(0xffFF6B6B);

  static OutlineInputBorder _border(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: color == Colors.transparent
        ? BorderSide.none
        : BorderSide(color: color, width: 1.2),
  );

  @override
  Widget build(BuildContext context) {
    final isEmail = widget.keyboardType == TextInputType.emailAddress;
    return Padding(
      padding: EdgeInsets.only(bottom: widget.marginBottom!),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.labelText != null)
            MyText(
              text: widget.labelText ?? '',
              paddingBottom: 6,
              size: 12,
              color: kBorderColor,
              weight: FontWeight.w600,
            ),
          TextFormField(
            onTap: widget.onTap,
            textAlignVertical: widget.prefix != null || widget.suffix != null
                ? TextAlignVertical.center
                : null,
            cursorColor: kTertiaryColor,
            maxLines: widget.maxLines,
            maxLength: widget.maxLength,
            readOnly: widget.isReadOnly ?? false,
            controller: widget.controller,
            onChanged: widget.onChanged,
            validator: widget.validator,
            onFieldSubmitted: widget.onFieldSubmitted,
            textInputAction:
                widget.textInputAction ??
                (widget.maxLines! > 1
                    ? TextInputAction.newline
                    : TextInputAction.next),
            keyboardType: widget.keyboardType,
            textCapitalization: TextCapitalization.none,
            autocorrect: !isEmail && !widget.isObSecure!,
            enableSuggestions: !isEmail && !widget.isObSecure!,
            autofillHints:
                widget.autofillHints ??
                (isEmail ? const [AutofillHints.email] : null),
            obscureText: widget.isObSecure!,
            obscuringCharacter: '*',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: kTertiaryColor,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: widget.fillColor ?? kQuaternaryColor,
              prefixIcon: widget.prefix,
              suffixIcon: widget.suffix,
              counterText: '',
              contentPadding: EdgeInsets.symmetric(
                horizontal: 15,
                vertical: widget.maxLines! > 1 ? 15 : 14,
              ),
              hintText: widget.hintText,
              hintStyle: TextStyle(
                fontSize: 14,
                color: kTertiaryColor.withValues(alpha: 0.6),
                fontWeight: FontWeight.w500,
              ),
              errorMaxLines: 2,
              errorStyle: const TextStyle(
                color: _errorColor,
                fontSize: 12,
                height: 1.3,
                fontWeight: FontWeight.w500,
              ),
              border: _border(Colors.transparent),
              enabledBorder: _border(Colors.transparent),
              disabledBorder: _border(Colors.transparent),
              focusedBorder: _border(kSecondaryColor.withValues(alpha: 0.7)),
              errorBorder: _border(_errorColor.withValues(alpha: 0.85)),
              focusedErrorBorder: _border(_errorColor),
            ),
          ),
        ],
      ),
    );
  }
}
