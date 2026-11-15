import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:motorsport/config/theme/theme_controller.dart';
import 'package:motorsport/constants/app_colors.dart';
import 'package:motorsport/constants/app_images.dart';

/// One tab of the [AppNavBar].
class AppNavItem {
  const AppNavItem(this.icon, this.label);

  final String icon;
  final String label;
}

/// The app's four main tabs, in order.
const List<AppNavItem> kAppNavItems = [
  AppNavItem(Assets.imagesHome, 'Home'),
  AppNavItem(Assets.imagesCourses, 'Learning'),
  AppNavItem(Assets.imagesSave, 'History'),
  AppNavItem(Assets.imagesProfile, 'Profile'),
];

/// Floating capsule navigation bar.
///
/// The active tab grows into a gold pill with its label; the others stay as
/// quiet icons. Widths, colours and the label animate together, so the pill
/// appears to glide between tabs. Follows the blue / black theme.
class AppNavBar extends StatelessWidget {
  const AppNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.items = kAppNavItems,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<AppNavItem> items;

  static const double _height = 64;
  static const Duration _duration = Duration(milliseconds: 380);
  static const Curve _curve = Curves.easeOutCubic;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDark = ThemeController.instance.isDarkMode;
      final gold = kSecondaryColor;
      final surfaceTop = isDark
          ? const Color(0xff1B1B1F)
          : const Color(0xff1E3170);
      final surfaceBottom = isDark
          ? const Color(0xff111114)
          : const Color(0xff15255A);

      return ColoredBox(
        color: kPrimaryColor,
        child: SafeArea(
          top: false,
          minimum: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
            child: Container(
              height: _height,
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(_height / 2),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [surfaceTop, surfaceBottom],
                ),
                border: Border.all(
                  color: gold.withValues(alpha: isDark ? 0.22 : 0.18),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: gold.withValues(alpha: 0.06),
                    blurRadius: 18,
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final total = constraints.maxWidth;
                  // Active tab takes ~38% so its label always fits.
                  final activeW = total * 0.38;
                  final idleW = (total - activeW) / (items.length - 1);
                  return Row(
                    children: [
                      for (var i = 0; i < items.length; i++)
                        _NavTab(
                          item: items[i],
                          active: i == currentIndex,
                          width: i == currentIndex ? activeW : idleW,
                          gold: gold,
                          activeText: isDark ? Colors.black : kPrimaryColor,
                          idleColor: kTertiaryColor.withValues(alpha: 0.62),
                          duration: _duration,
                          curve: _curve,
                          onTap: () {
                            if (i != currentIndex) {
                              HapticFeedback.selectionClick();
                            }
                            onTap(i);
                          },
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );
    });
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.item,
    required this.active,
    required this.width,
    required this.gold,
    required this.activeText,
    required this.idleColor,
    required this.duration,
    required this.curve,
    required this.onTap,
  });

  final AppNavItem item;
  final bool active;
  final double width;
  final Color gold;
  final Color activeText;
  final Color idleColor;
  final Duration duration;
  final Curve curve;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? activeText : idleColor;
    return Semantics(
      button: true,
      selected: active,
      label: item.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: duration,
          curve: curve,
          width: width,
          height: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            gradient: active
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color.lerp(gold, Colors.white, 0.18)!, gold],
                  )
                : null,
            boxShadow: active
                ? [
                    BoxShadow(
                      color: gold.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : const [],
          ),
          child: ClipRect(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  key: ValueKey(active),
                  tween: Tween(begin: active ? 0.82 : 1.0, end: 1.0),
                  duration: const Duration(milliseconds: 420),
                  curve: active ? Curves.elasticOut : Curves.easeOut,
                  builder: (context, s, child) =>
                      Transform.scale(scale: s, child: child),
                  child: TweenAnimationBuilder<Color?>(
                    tween: ColorTween(end: color),
                    duration: duration,
                    builder: (context, c, _) =>
                        ImageIcon(AssetImage(item.icon), size: 22, color: c),
                  ),
                ),
                // Label slides open on the active tab only.
                AnimatedSize(
                  duration: duration,
                  curve: curve,
                  child: active
                      ? Padding(
                          padding: const EdgeInsets.only(left: 7),
                          child: Text(
                            item.label,
                            maxLines: 1,
                            overflow: TextOverflow.fade,
                            softWrap: false,
                            style: TextStyle(
                              color: activeText,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
