import 'package:flutter/material.dart';
import 'package:get/get.dart' show SnackPosition;

/// Root messenger wired into `GetMaterialApp.scaffoldMessengerKey`.
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

enum AppSnackType { error, success, info }

/// Red snackbar for something that went wrong.
void showErrorSnackbar(
  String message, {
  String? title,
  SnackBarAction? action,
}) => _show(AppSnackType.error, message, title: title, action: action);

/// Green snackbar confirming something worked.
void showSuccessSnackbar(
  String message, {
  String? title,
  SnackBarAction? action,
}) => _show(AppSnackType.success, message, title: title, action: action);

/// Neutral snackbar for hints ("Select at least one issue").
void showInfoSnackbar(
  String message, {
  String? title,
  SnackBarAction? action,
}) => _show(AppSnackType.info, message, title: title, action: action);

/// Drop-in replacement for `Get.snackbar` (kept for older call sites).
///
/// GetX 4.7.2's snackbar can't find the Overlay on current Flutter versions
/// and then blocks every later `Get.back()`, so the app uses Flutter's own
/// ScaffoldMessenger instead. A red-ish [backgroundColor] maps to an error,
/// green to success, anything else to info.
void showAppSnackbar(
  String title,
  String message, {
  Color? backgroundColor,
  Color? colorText,
  SnackPosition? snackPosition,
}) {
  var type = AppSnackType.info;
  if (backgroundColor != null) {
    final c = backgroundColor;
    if (c.r > c.g && c.r > c.b) type = AppSnackType.error;
    if (c.g > c.r && c.g > c.b) type = AppSnackType.success;
  }
  _show(type, message, title: title);
}

void _show(
  AppSnackType type,
  String message, {
  String? title,
  SnackBarAction? action,
}) {
  final messenger = rootScaffoldMessengerKey.currentState;
  if (messenger == null) {
    debugPrint('snackbar (no messenger yet): ${title ?? ''} $message');
    return;
  }

  final (Color bg, Color accent, IconData icon) = switch (type) {
    AppSnackType.error => (
      const Color(0xff3A1418),
      const Color(0xffFF6B6B),
      Icons.error_outline_rounded,
    ),
    AppSnackType.success => (
      const Color(0xff12301E),
      const Color(0xff4ADE80),
      Icons.check_circle_outline_rounded,
    ),
    AppSnackType.info => (
      const Color(0xff1C2A55),
      const Color(0xffE8C670),
      Icons.info_outline_rounded,
    ),
  };

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: bg,
        elevation: 6,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: Duration(seconds: type == AppSnackType.error ? 4 : 3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: accent.withValues(alpha: 0.45)),
        ),
        action: action,
        content: Row(
          children: [
            Icon(icon, color: accent, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null && title.isNotEmpty) ...[
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],
                  Text(
                    message,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 13.5,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
}
