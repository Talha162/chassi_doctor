import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

/// Handwritten font used for onboarding call-outs (bundled: assets/fonts).
const String kHandFont = 'Caveat';

/// One hand-drawn call-out on an onboarding slide.
///
/// [target] is in *screen-fraction* coordinates of the phone screenshot
/// (0..1 on both axes), so call-outs stay glued to the right UI element at
/// any device size. [label] is positioned on the slide canvas (see
/// [kOnboardingCanvas]) and may sit outside the phone.
@immutable
class OnboardingCallout {
  const OnboardingCallout({
    required this.target,
    required this.labelAt,
    required this.text,
    this.accent,
    this.step,
    this.shape = CalloutShape.ellipse,
    this.bend = 0.35,
    this.labelAlign = TextAlign.left,
    this.labelWidth = 92,
    this.spotlight = true,
  });

  /// Highlighted area on the phone screen, as fractions of the screenshot.
  final Rect target;

  /// Top-left of the label on the canvas.
  final Offset labelAt;

  /// Plain part of the label, e.g. "Car not right?".
  final String text;

  /// Gold, emphasised part shown after [text], e.g. "Start here!".
  final String? accent;

  /// Optional step number badge (1, 2, 3...).
  final int? step;
  final CalloutShape shape;

  /// How much the arrow curves (negative bends the other way).
  final double bend;
  final TextAlign labelAlign;
  final double labelWidth;

  /// Whether this target is cut out of the dimming spotlight.
  final bool spotlight;
}

enum CalloutShape { ellipse, pill, underline }

/// Fixed design canvas; the whole illustration scales with a FittedBox.
const Size kOnboardingCanvas = Size(390, 470);

/// Phone placement on the canvas and the screen inset inside the bezel.
// Screen inside the bezel matches the iPhone screenshot aspect (1206x2622)
// exactly, so call-out fractions land precisely and nothing is cropped.
const Rect kPhoneRect = Rect.fromLTWH(88.5, 6, 213, 448);
const double kBezel = 6;

Rect phoneScreenRect() => kPhoneRect.deflate(kBezel);

/// Maps a screen-fraction rect to canvas coordinates.
Rect screenToCanvas(Rect f) {
  final s = phoneScreenRect();
  return Rect.fromLTRB(
    s.left + f.left * s.width,
    s.top + f.top * s.height,
    s.left + f.right * s.width,
    s.top + f.bottom * s.height,
  );
}

/// Draws the circles/underlines and arrows for every call-out, each one
/// "inked" in sequence as [progress] runs 0→1. [pulse] (0→1 loop) drives a
/// soft glow on finished highlights.
class CalloutPainter extends CustomPainter {
  CalloutPainter({
    required this.callouts,
    required this.progress,
    required this.labelSizes,
    required this.color,
    required this.pulse,
  });

  final List<OnboardingCallout> callouts;
  final List<double> progress;
  final List<Size> labelSizes;
  final Color color;
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < callouts.length; i++) {
      final p = progress[i];
      if (p <= 0) continue;
      final c = callouts[i];
      final target = screenToCanvas(c.target);

      final stroke = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.1
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      // 1) Highlight shape — first 55% of this call-out's time.
      final shapeT = (p / 0.55).clamp(0.0, 1.0);
      final shapePath = _shapePath(c.shape, target, seed: i);
      _drawPartial(canvas, shapePath, shapeT, stroke);

      if (shapeT >= 1 && pulse > 0) {
        final glow = Paint()
          ..color = color.withValues(alpha: 0.28 * (1 - pulse))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2 + 6 * pulse
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawPath(shapePath, glow);
      }

      // 2) Arrow from the label to the highlight — remaining 45%.
      final arrowT = ((p - 0.45) / 0.55).clamp(0.0, 1.0);
      if (arrowT > 0) {
        final arrow = _arrowPath(c, target, labelSizes[i]);
        _drawPartial(canvas, arrow, arrowT, stroke);
        if (arrowT >= 0.98) {
          _drawArrowHead(canvas, arrow, stroke);
        }
      }
    }
  }

  /// Slightly irregular, overshooting outline — reads as drawn by hand.
  Path _shapePath(CalloutShape shape, Rect r, {required int seed}) {
    switch (shape) {
      case CalloutShape.underline:
        final y = r.bottom + 2;
        return Path()
          ..moveTo(r.left - 4, y + 1)
          ..cubicTo(
            r.left + r.width * 0.3,
            y - 2,
            r.left + r.width * 0.7,
            y + 3,
            r.right + 6,
            y - 1,
          );
      case CalloutShape.pill:
      case CalloutShape.ellipse:
        final rect = r.inflate(shape == CalloutShape.pill ? 3 : 6);
        final cx = rect.center.dx, cy = rect.center.dy;
        final rx = rect.width / 2, ry = rect.height / 2;
        final path = Path();
        const turns = 1.12; // overshoot past the start like a real pen
        const steps = 64;
        final start = -math.pi * 0.62 + seed * 0.7;
        for (var k = 0; k <= steps; k++) {
          final a = start + (k / steps) * turns * 2 * math.pi;
          final wobble = 1 + 0.035 * math.sin(a * 3 + seed) + 0.02 * k / steps;
          final x = cx + rx * wobble * math.cos(a);
          final y = cy + ry * wobble * math.sin(a);
          k == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
        }
        return path;
    }
  }

  Path _arrowPath(OnboardingCallout c, Rect target, Size label) {
    final labelRect = c.labelAt & label;
    // Leave from the label edge facing the target.
    final fromLeftSide = labelRect.center.dx > target.center.dx;
    final start = Offset(
      fromLeftSide ? labelRect.left - 2 : labelRect.right + 2,
      labelRect.center.dy + (labelRect.center.dy < target.center.dy ? 8 : -4),
    );
    // Aim at the point on the highlight edge nearest the label.
    final dir = (start - target.center);
    final ang = math.atan2(dir.dy, dir.dx);
    final rx = target.width / 2 + 9, ry = target.height / 2 + 9;
    final end = Offset(
      target.center.dx + rx * math.cos(ang),
      target.center.dy + ry * math.sin(ang),
    );
    final mid = Offset.lerp(start, end, 0.5)!;
    final normal = Offset(-(end.dy - start.dy), end.dx - start.dx);
    final ctrl = mid + normal * c.bend;
    return Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(ctrl.dx, ctrl.dy, end.dx, end.dy);
  }

  void _drawArrowHead(Canvas canvas, Path path, Paint paint) {
    final metric = path.computeMetrics().first;
    final tip = metric.getTangentForOffset(metric.length);
    final back = metric.getTangentForOffset(math.max(0, metric.length - 10));
    if (tip == null || back == null) return;
    final d = tip.position - back.position;
    final a = math.atan2(d.dy, d.dx);
    const len = 9.0, spread = 0.5;
    final p = tip.position;
    canvas.drawPath(
      Path()
        ..moveTo(
          p.dx - len * math.cos(a - spread),
          p.dy - len * math.sin(a - spread),
        )
        ..lineTo(p.dx, p.dy)
        ..lineTo(
          p.dx - len * math.cos(a + spread),
          p.dy - len * math.sin(a + spread),
        ),
      paint,
    );
  }

  void _drawPartial(Canvas canvas, Path path, double t, Paint paint) {
    if (t <= 0) return;
    if (t >= 1) {
      canvas.drawPath(path, paint);
      return;
    }
    final out = Path();
    for (final PathMetric m in path.computeMetrics()) {
      out.addPath(m.extractPath(0, m.length * t), Offset.zero);
    }
    canvas.drawPath(out, paint);
  }

  @override
  bool shouldRepaint(CalloutPainter old) =>
      old.pulse != pulse ||
      old.color != color ||
      !_listEq(old.progress, progress);

  static bool _listEq(List<double> a, List<double> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Dims the phone screen except for the call-out targets.
class SpotlightPainter extends CustomPainter {
  SpotlightPainter({
    required this.targets,
    required this.amount,
    required this.screen,
    required this.radius,
  });

  /// Targets in canvas coordinates.
  final List<Rect> targets;

  /// 0 = no dimming, 1 = full dimming.
  final double amount;
  final Rect screen;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    if (amount <= 0) return;
    final dim = Path()
      ..addRRect(RRect.fromRectAndRadius(screen, Radius.circular(radius)));
    var holes = Path();
    for (final t in targets) {
      holes = Path.combine(
        PathOperation.union,
        holes,
        Path()..addRRect(
          RRect.fromRectAndRadius(t.inflate(4), const Radius.circular(10)),
        ),
      );
    }
    canvas.drawPath(
      Path.combine(PathOperation.difference, dim, holes),
      Paint()..color = Colors.black.withValues(alpha: 0.42 * amount),
    );
  }

  @override
  bool shouldRepaint(SpotlightPainter old) =>
      old.amount != amount || old.targets != targets;
}

/// Faint racing "speed lines" drifting across the background.
class SpeedLinesPainter extends CustomPainter {
  SpeedLinesPainter({required this.t, required this.color});

  /// 0→1 loop.
  final double t;
  final Color color;

  static const _lines = [
    // y fraction, length, speed, phase, thickness
    (0.08, 120.0, 1.0, 0.10, 1.0),
    (0.17, 70.0, 1.6, 0.55, 1.0),
    (0.31, 160.0, 0.8, 0.30, 1.4),
    (0.46, 90.0, 1.3, 0.80, 1.0),
    (0.58, 140.0, 0.9, 0.05, 1.2),
    (0.71, 60.0, 1.8, 0.65, 1.0),
    (0.84, 110.0, 1.1, 0.40, 1.3),
    (0.93, 80.0, 1.4, 0.90, 1.0),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final (yf, len, speed, phase, w) in _lines) {
      final travel = size.width + len * 2;
      final x = ((t * speed + phase) % 1.0) * travel - len;
      final y = yf * size.height;
      final paint = Paint()
        ..strokeWidth = w
        ..strokeCap = StrokeCap.round
        ..shader = LinearGradient(
          colors: [color.withValues(alpha: 0), color.withValues(alpha: 0.10)],
        ).createShader(Rect.fromLTWH(x, y, len, 1));
      canvas.drawLine(Offset(x, y), Offset(x + len, y), paint);
    }
  }

  @override
  bool shouldRepaint(SpeedLinesPainter old) => old.t != t || old.color != color;
}
