// Small shared pieces for a modern feel, in the same style as the floating
// nav bar: loading skeletons, empty states, pull-to-refresh, large title
// bars, an option sheet and haptic taps.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants/app_colors.dart';
import '../../utils/motion.dart';
import 'custom_app_bar_widget.dart';
import 'my_button_widget.dart';
import 'my_text_widget.dart';

// ───────────────────────────── Haptics ─────────────────────────────

/// Light vibration for taps on buttons, chips, tiles and switches.
abstract final class AppHaptics {
  static void tap() => HapticFeedback.selectionClick();

  /// A slightly firmer bump for confirming actions (save, select).
  static void confirm() => HapticFeedback.lightImpact();
}

// ───────────────────────────── Skeletons ─────────────────────────────

/// Sweeps a soft highlight across its [child]'s grey shapes while loading.
class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child});

  final Widget child;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (motionEnabled(context)) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = kTertiaryColor.withValues(alpha: 0.10);
    final shine = kTertiaryColor.withValues(alpha: 0.22);
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final t = _controller.value * 3 - 1; // -1 → 2 across the box
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (rect) => LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [base, shine, base],
            stops: [
              (t - 0.35).clamp(0.0, 1.0),
              t.clamp(0.0, 1.0),
              (t + 0.35).clamp(0.0, 1.0),
            ],
          ).createShader(rect),
          child: child,
        );
      },
    );
  }
}

/// One grey placeholder shape. Wrap a group of these in a [Shimmer].
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.radius = 8,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}

/// Placeholder for a list of cards with a thumbnail and two lines of text
/// (courses, notifications).
class SkeletonCardList extends StatelessWidget {
  const SkeletonCardList({
    super.key,
    this.count = 4,
    this.thumbSize = 72,
    this.padding = const EdgeInsets.fromLTRB(20, 16, 20, 16),
    this.header = false,
  });

  final int count;
  final double thumbSize;
  final EdgeInsets padding;

  /// Adds a large banner placeholder above the cards.
  final bool header;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading',
      child: Shimmer(
        child: ListView(
          padding: padding,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            if (header) ...[
              const SkeletonBox(height: 150, radius: 14),
              const SizedBox(height: 22),
              const SkeletonBox(width: 140, height: 16),
              const SizedBox(height: 14),
            ],
            for (var i = 0; i < count; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _SkeletonCard(thumbSize: thumbSize),
              ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({required this.thumbSize});

  final double thumbSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: Row(
        children: [
          SkeletonBox(width: thumbSize, height: thumbSize, radius: 10),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(height: 14),
                SizedBox(height: 10),
                FractionallySizedBox(
                  widthFactor: 0.6,
                  child: SkeletonBox(height: 12),
                ),
                SizedBox(height: 14),
                SkeletonBox(height: 6, radius: 3),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Placeholder for a two-column grid of tiles (saved sessions history).
class SkeletonGrid extends StatelessWidget {
  const SkeletonGrid({
    super.key,
    this.count = 6,
    this.tileHeight = 196,
    this.padding = const EdgeInsets.fromLTRB(20, 4, 20, 20),
  });

  final int count;
  final double tileHeight;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading',
      child: Shimmer(
        child: GridView.builder(
          padding: padding,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: count,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: tileHeight,
          ),
          itemBuilder: (_, _) => Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 36, height: 36, radius: 18),
                SizedBox(height: 14),
                SkeletonBox(height: 14),
                SizedBox(height: 8),
                FractionallySizedBox(
                  widthFactor: 0.55,
                  child: SkeletonBox(height: 12),
                ),
                Spacer(),
                SkeletonBox(height: 28, radius: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────────── Empty states ─────────────────────────────

/// A friendly "nothing here yet" panel: icon, title, a line of text and an
/// optional button.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionText,
    this.onAction,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionText;
  final VoidCallback? onAction;

  /// Smaller version to sit inside a scrolling page rather than fill a screen.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final badge = compact ? 64.0 : 88.0;
    return PopIn(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 32,
          vertical: compact ? 12 : 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: badge,
              height: badge,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kSecondaryColor.withValues(alpha: 0.12),
                border: Border.all(
                  color: kSecondaryColor.withValues(alpha: 0.35),
                ),
              ),
              child: Icon(icon, size: badge * 0.45, color: kSecondaryColor),
            ),
            SizedBox(height: compact ? 14 : 20),
            MyText(
              text: title,
              size: compact ? 16 : 18,
              weight: FontWeight.w700,
              textAlign: TextAlign.center,
              color: kTertiaryColor,
            ),
            if (message != null)
              MyText(
                paddingTop: 8,
                text: message!,
                size: 13,
                lineHeight: 1.5,
                textAlign: TextAlign.center,
                color: kTertiaryColor.withValues(alpha: 0.7),
              ),
            if (actionText != null && onAction != null) ...[
              SizedBox(height: compact ? 16 : 22),
              SizedBox(
                width: 220,
                child: MyButton(
                  buttonText: actionText!,
                  height: 44,
                  textSize: 14,
                  radius: 50,
                  onTap: onAction,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// [EmptyState] centred in a scrollable box, so pull-to-refresh still works
/// on an empty list.
class ScrollableEmptyState extends StatelessWidget {
  const ScrollableEmptyState({super.key, required this.child});

  final EmptyState child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(child: child),
        ),
      ),
    );
  }
}

// ───────────────────────────── Pull to refresh ─────────────────────────────

/// Pull-to-refresh in the app's colours, with a light bump when it triggers.
class AppRefresh extends StatelessWidget {
  const AppRefresh({super.key, required this.onRefresh, required this.child});

  final Future<void> Function() onRefresh;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: kSecondaryColor,
      backgroundColor: kQuaternaryColor,
      onRefresh: () {
        AppHaptics.confirm();
        return onRefresh();
      },
      child: child,
    );
  }
}

// ───────────────────────────── Page scaffold ─────────────────────────────

/// A page with the app's standard top bar ([simpleAppBar]).
class AppPageScaffold extends StatelessWidget {
  const AppPageScaffold({
    super.key,
    required this.title,
    required this.body,
    this.showBack = true,
    this.leading,
    this.leadingWidth,
    this.actions,
    this.bottomNavigationBar,
  });

  final String title;
  final Widget body;
  final bool showBack;
  final Widget? leading;
  final double? leadingWidth;
  final List<Widget>? actions;
  final Widget? bottomNavigationBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: simpleAppBar(
        title: title,
        haveLeading: showBack || leading != null,
        leading: leading,
        leadingWidth: leadingWidth,
        actions: actions,
      ),
      bottomNavigationBar: bottomNavigationBar,
      body: body,
    );
  }
}

// ───────────────────────────── Option sheet ─────────────────────────────

/// A rounded bottom sheet listing [options] as large rows with a tick on the
/// selected one. Returns the picked option, or null if dismissed.
Future<T?> showOptionSheet<T>(
  BuildContext context, {
  required String title,
  required List<T> options,
  required String Function(T) labelOf,
  T? selected,
  String? Function(T)? subtitleOf,
}) {
  AppHaptics.tap();
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(ctx).height * 0.7,
      ),
      child: Container(
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 42,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: kTertiaryColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              MyText(
                paddingTop: 16,
                paddingLeft: 22,
                paddingRight: 22,
                paddingBottom: 8,
                text: title,
                size: 18,
                weight: FontWeight.w700,
                color: kTertiaryColor,
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                  itemCount: options.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (ctx, i) {
                    final option = options[i];
                    final isSelected = option == selected;
                    final subtitle = subtitleOf?.call(option);
                    return Material(
                      color: isSelected
                          ? kSecondaryColor.withValues(alpha: 0.14)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          AppHaptics.confirm();
                          Navigator.of(ctx).pop(option);
                        },
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 56),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? kSecondaryColor.withValues(alpha: 0.6)
                                  : kBorderColor2.withValues(alpha: 0.6),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    MyText(
                                      text: labelOf(option),
                                      size: 15,
                                      weight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? kSecondaryColor
                                          : kTertiaryColor,
                                    ),
                                    if (subtitle != null)
                                      MyText(
                                        paddingTop: 3,
                                        text: subtitle,
                                        size: 12,
                                        color: kTertiaryColor.withValues(
                                          alpha: 0.6,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 180),
                                child: isSelected
                                    ? Icon(
                                        Icons.check_circle_rounded,
                                        key: const ValueKey('on'),
                                        color: kSecondaryColor,
                                      )
                                    : Icon(
                                        Icons.circle_outlined,
                                        key: const ValueKey('off'),
                                        color: kTertiaryColor.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
