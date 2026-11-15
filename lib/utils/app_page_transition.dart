import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// App-wide page transition (same feel as Filean): the new page fades in
/// while sliding a short distance from the right; the page underneath drifts
/// slightly left and dims. Keeps an iOS-style swipe-from-left-edge to go back.
class AppPageTransition extends CustomTransition {
  @override
  Widget buildTransition(
    BuildContext context,
    Curve? curve,
    Alignment? alignment,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      return _EdgeSwipeBack(child: child);
    }
    final inCurve = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final outCurve = CurvedAnimation(
      parent: secondaryAnimation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return SlideTransition(
      position: Tween(
        begin: Offset.zero,
        end: const Offset(-0.06, 0),
      ).animate(outCurve),
      child: FadeTransition(
        opacity: Tween(begin: 1.0, end: 0.6).animate(outCurve),
        child: FadeTransition(
          opacity: inCurve,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0.09, 0),
              end: Offset.zero,
            ).animate(inCurve),
            child: _EdgeSwipeBack(child: child),
          ),
        ),
      ),
    );
  }
}

/// Swipe right from the left edge to pop the page (like iOS).
class _EdgeSwipeBack extends StatefulWidget {
  const _EdgeSwipeBack({required this.child});

  final Widget child;

  @override
  State<_EdgeSwipeBack> createState() => _EdgeSwipeBackState();
}

class _EdgeSwipeBackState extends State<_EdgeSwipeBack> {
  double _dx = 0;

  @override
  Widget build(BuildContext context) {
    final canPop = ModalRoute.of(context)?.canPop ?? false;
    if (!canPop) return widget.child;
    return Stack(
      children: [
        Transform.translate(offset: Offset(_dx, 0), child: widget.child),
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: 20,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragUpdate: (d) => setState(
              () => _dx = (_dx + d.delta.dx).clamp(0.0, double.infinity),
            ),
            onHorizontalDragEnd: (d) {
              final width = MediaQuery.sizeOf(context).width;
              final shouldPop =
                  _dx > width * 0.3 || (d.primaryVelocity ?? 0) > 600;
              setState(() => _dx = 0);
              if (shouldPop) Navigator.of(context).maybePop();
            },
            onHorizontalDragCancel: () => setState(() => _dx = 0),
          ),
        ),
      ],
    );
  }
}
