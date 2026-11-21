import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Whether decorative motion should run. Honours the OS "reduce motion"
/// setting; when off, animated widgets render their final (design) state.
bool motionEnabled(BuildContext context) =>
    !(MediaQuery.maybeDisableAnimationsOf(context) ?? false);

/// Plays a one-shot entrance for a screen and exposes it to [Reveal]s below.
class EntranceScope extends StatefulWidget {
  const EntranceScope({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 900),
    this.delay = Duration.zero,
  });

  final Widget child;
  final Duration duration;
  final Duration delay;

  static Animation<double> of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<EntranceProvider>()
          ?.animation ??
      kAlwaysCompleteAnimation;

  @override
  State<EntranceScope> createState() => _EntranceScopeState();
}

class _EntranceScopeState extends State<EntranceScope>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!motionEnabled(context)) {
      _controller.value = 1;
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      EntranceProvider(animation: _controller, child: widget.child);
}

/// Supplies an entrance animation to descendant [Reveal]s.
class EntranceProvider extends InheritedWidget {
  const EntranceProvider({
    super.key,
    required this.animation,
    required super.child,
  });

  final Animation<double> animation;

  static Animation<double>? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<EntranceProvider>()?.animation;

  @override
  bool updateShouldNotify(EntranceProvider old) => old.animation != animation;
}

/// Fades, slides and optionally scales [child] in during the [start]–[end]
/// slice of the nearest entrance animation ([EntranceScope] or a tour
/// illustration). At rest the child is exactly where the layout puts it.
class Reveal extends StatelessWidget {
  const Reveal({
    super.key,
    required this.child,
    this.start = 0,
    this.end = 0.6,
    this.offset = const Offset(0, 14),
    this.scaleFrom = 1,
    this.curve = Curves.easeOutCubic,
    this.animation,
  });

  final Widget child;
  final double start;
  final double end;
  final Offset offset;
  final double scaleFrom;
  final Curve curve;

  /// Defaults to the enclosing [EntranceScope].
  final Animation<double>? animation;

  @override
  Widget build(BuildContext context) {
    final parent = animation ?? EntranceScope.of(context);
    final t = CurvedAnimation(
      parent: parent,
      curve: Interval(start, end, curve: curve),
    );
    final fade = CurvedAnimation(
      parent: parent,
      curve: Interval(start, end, curve: Curves.easeOut),
    );
    return AnimatedBuilder(
      animation: t,
      child: child,
      builder: (context, child) {
        final v = t.value;
        return Opacity(
          opacity: fade.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: offset * (1 - v),
            child: scaleFrom == 1
                ? child
                : Transform.scale(
                    scale: scaleFrom + (1 - scaleFrom) * v,
                    child: child,
                  ),
          ),
        );
      },
    );
  }
}

/// Shrinks slightly while pressed — tactile feedback for custom buttons.
class PressScale extends StatefulWidget {
  const PressScale({super.key, required this.child, this.enabled = true});

  final Widget child;
  final bool enabled;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;
  Offset? _downAt;

  void _set(bool down) {
    if (_down != down && mounted) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: widget.enabled
          ? (e) {
              _downAt = e.position;
              _set(true);
            }
          : null,
      onPointerUp: (e) {
        // A light tick for a real tap, not for the start of a scroll.
        final start = _downAt;
        if (widget.enabled &&
            start != null &&
            (e.position - start).distance < 12) {
          HapticFeedback.selectionClick();
        }
        _downAt = null;
        _set(false);
      },
      onPointerCancel: (_) {
        _downAt = null;
        _set(false);
      },
      child: AnimatedScale(
        scale: _down ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// A repeating 0→1 animation for ambient motion (e.g. the scan line).
/// `null` when motion is disabled, so widgets fall back to their design pose.
class LoopProvider extends InheritedWidget {
  const LoopProvider({
    super.key,
    required this.animation,
    required super.child,
  });

  final Animation<double>? animation;

  static Animation<double>? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LoopProvider>()?.animation;

  @override
  bool updateShouldNotify(LoopProvider old) => old.animation != animation;
}

/// Runs a repeating 0→1 animation for ambient motion and exposes it through
/// [LoopProvider]. Stays idle (null) when motion is disabled.
class AmbientLoop extends StatefulWidget {
  const AmbientLoop({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 2600),
  });

  final Widget child;
  final Duration duration;

  @override
  State<AmbientLoop> createState() => _AmbientLoopState();
}

class _AmbientLoopState extends State<AmbientLoop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  bool _motion = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _motion = motionEnabled(context);
    if (_motion) {
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
  Widget build(BuildContext context) => LoopProvider(
    animation: _motion ? _controller : null,
    child: widget.child,
  );
}

/// Pops [child] in (scale + fade) when it first appears, after [delay].
/// Used for items added at runtime, such as new pages.
class PopIn extends StatefulWidget {
  const PopIn({super.key, required this.child, this.delay = Duration.zero});

  final Widget child;
  final Duration delay;

  @override
  State<PopIn> createState() => _PopInState();
}

class _PopInState extends State<PopIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!motionEnabled(context)) {
      _controller.value = 1;
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    return FadeTransition(
      opacity: _controller,
      child: ScaleTransition(
        scale: Tween(begin: 0.7, end: 1.0).animate(scale),
        child: widget.child,
      ),
    );
  }
}

/// Gentle vertical float driven by the nearest [AmbientLoop].
class Bob extends StatelessWidget {
  const Bob({super.key, required this.child, this.amplitude = 1.6});

  final Widget child;
  final double amplitude;

  @override
  Widget build(BuildContext context) {
    final loop = LoopProvider.of(context);
    if (loop == null) return child;
    return AnimatedBuilder(
      animation: loop,
      child: child,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, math.sin(loop.value * 2 * math.pi) * amplitude),
        child: child,
      ),
    );
  }
}

/// A column whose children cascade in (fade + rise) one after another.
class StaggeredColumn extends StatelessWidget {
  const StaggeredColumn({
    super.key,
    required this.children,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.step = 0.06,
  });

  final List<Widget> children;
  final CrossAxisAlignment crossAxisAlignment;
  final double step;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (i, c) in children.indexed)
          Reveal(
            start: (i * step).clamp(0.0, 0.6),
            end: (i * step + 0.4).clamp(0.4, 1.0),
            child: c,
          ),
      ],
    );
  }
}

/// Fades + rises [child] in the first time it is built, after [delay].
/// Self-timed, so it works for content that arrives later (network lists):
/// pass `delay: staggerDelay(index)` for a cascading list.
class FadeInUp extends StatefulWidget {
  const FadeInUp({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 460),
    this.offset = 18,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;

  /// Starting distance below the final position, in logical pixels.
  final double offset;

  @override
  State<FadeInUp> createState() => _FadeInUpState();
}

class _FadeInUpState extends State<FadeInUp>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _c,
    curve: Curves.easeOutCubic,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!motionEnabled(context)) {
      _c.value = 1;
    } else if (widget.delay == Duration.zero) {
      _c.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: _curve.value,
        child: Transform.translate(
          offset: Offset(0, widget.offset * (1 - _curve.value)),
          child: child,
        ),
      ),
    );
  }
}

/// Cascade delay for the [index]-th item of a list (capped so long lists
/// don't keep the user waiting).
Duration staggerDelay(int index, {int stepMs = 55, int maxMs = 420}) =>
    Duration(milliseconds: math.min(index * stepMs, maxMs));
