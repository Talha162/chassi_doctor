import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:motorsport/config/theme/theme_controller.dart';
import 'package:motorsport/constants/app_colors.dart';
import 'package:motorsport/utils/motion.dart';

/// Themed confirmation dialog (blue / black), used for important outcomes
/// such as "Check your email". Errors use snackbars instead.
Future<void> showAppDialog({
  required String title,
  required String message,
  IconData icon = Icons.check_circle_outline_rounded,
  String primaryLabel = 'OK',
  VoidCallback? onPrimary,
  String? secondaryLabel,
  VoidCallback? onSecondary,
  bool barrierDismissible = false,
}) {
  final isDark = ThemeController.instance.isDarkMode;
  final gold = kSecondaryColor;
  return Get.dialog<void>(
    PopIn(
      child: Dialog(
        backgroundColor: kQuaternaryColor,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: gold.withValues(alpha: 0.25)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: gold.withValues(alpha: 0.14),
                ),
                child: Icon(icon, color: gold, size: 30),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: kWhiteColor,
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: kTertiaryColor.withValues(alpha: 0.85),
                  fontSize: 14.5,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: gold,
                    foregroundColor: isDark ? Colors.black : kPrimaryColor,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  onPressed: () {
                    Get.back();
                    onPrimary?.call();
                  },
                  child: Text(
                    primaryLabel,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              if (secondaryLabel != null) ...[
                const SizedBox(height: 6),
                TextButton(
                  onPressed: () {
                    Get.back();
                    onSecondary?.call();
                  },
                  child: Text(
                    secondaryLabel,
                    style: TextStyle(
                      color: kTertiaryColor.withValues(alpha: 0.8),
                      fontSize: 14.5,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
    barrierDismissible: barrierDismissible,
  );
}
