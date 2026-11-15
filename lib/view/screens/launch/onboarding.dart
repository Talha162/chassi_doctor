import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:motorsport/config/routes/routes.dart';
import 'package:motorsport/config/theme/theme_controller.dart';
import 'package:motorsport/constants/app_colors.dart';
import 'package:motorsport/utils/motion.dart';
import 'package:motorsport/view/screens/launch/onboarding_annotations.dart';
import 'package:motorsport/view/screens/launch/onboarding_slides.dart';

/// First-run tour shown after sign-up. Each slide shows a real screen of the
/// app (in the user's current theme) with hand-drawn call-outs that ink
/// themselves in, so it's loud and clear what you get inside the app.
class Onboarding extends StatefulWidget {
  const Onboarding({super.key});

  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> {
  final _pages = PageController();
  int _index = 0;

  bool get _isLast => _index == onboardingSlides.length - 1;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _goTo(int page) => _pages.animateToPage(
    page,
    duration: const Duration(milliseconds: 420),
    curve: Curves.easeOutCubic,
  );

  void _finish() => Get.offAllNamed(AppLinks.trackConfiguration);

  @override
  Widget build(BuildContext context) {
    // Rebuild when the user's theme (blue / black) changes.
    return Obx(() {
      final isDark = ThemeController.instance.isDarkMode;
      final bg = kPrimaryColor;
      final gold = kSecondaryColor;
      // No AppBar here, so set the status bar explicitly: light icons on
      // both the blue and the black background.
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
        ),
        child: Scaffold(
          backgroundColor: bg,
          body: AmbientLoop(
            duration: const Duration(seconds: 9),
            child: Stack(
              children: [
                const Positioned.fill(child: _SpeedLines()),
                SafeArea(
                  child: Column(
                    children: [
                      _TopBar(
                        index: _index,
                        count: onboardingSlides.length,
                        onSkip: _finish,
                      ),
                      Expanded(
                        child: PageView.builder(
                          controller: _pages,
                          itemCount: onboardingSlides.length,
                          onPageChanged: (i) => setState(() => _index = i),
                          itemBuilder: (context, i) => AnimatedBuilder(
                            animation: _pages,
                            builder: (context, _) {
                              final page =
                                  _pages.hasClients &&
                                      _pages.position.haveDimensions
                                  ? _pages.page!
                                  : _index.toDouble();
                              return _SlideView(
                                slide: onboardingSlides[i],
                                active: i == _index,
                                offset: page - i,
                                isDark: isDark,
                                gold: gold,
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _Dots(
                        count: onboardingSlides.length,
                        index: _index,
                        color: gold,
                        onTap: _goTo,
                      ),
                      const SizedBox(height: 18),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: _PrimaryButton(
                          label: _isLast ? 'Set up my car' : 'Next',
                          color: gold,
                          textColor: isDark ? Colors.black : bg,
                          onTap: _isLast ? _finish : () => _goTo(_index + 1),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.index,
    required this.count,
    required this.onSkip,
  });

  final int index;
  final int count;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final isLast = index == count - 1;
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          const SizedBox(width: 20),
          Text(
            '${index + 1} / $count',
            style: TextStyle(
              color: kTertiaryColor.withValues(alpha: 0.55),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
          const Spacer(),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 220),
            opacity: isLast ? 0 : 1,
            child: TextButton(
              onPressed: isLast ? null : onSkip,
              child: Text(
                'Skip',
                style: TextStyle(
                  color: kTertiaryColor.withValues(alpha: 0.85),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({
    required this.slide,
    required this.active,
    required this.offset,
    required this.isDark,
    required this.gold,
  });

  final OnboardingSlide slide;
  final bool active;

  /// Signed distance from the settled page; drives parallax + fading.
  final double offset;
  final bool isDark;
  final Color gold;

  @override
  Widget build(BuildContext context) {
    final fade = (1 - offset.abs() * 0.9).clamp(0.0, 1.0);
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            Expanded(
              child: Transform.translate(
                offset: Offset(offset * 70, 0),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: SizedBox.fromSize(
                      size: kOnboardingCanvas,
                      child: SlideIllustration(
                        slide: slide,
                        active: active,
                        isDark: isDark,
                        gold: gold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Opacity(
              opacity: fade,
              child: _SlideText(slide: slide, active: active, gold: gold),
            ),
          ],
        );
      },
    );
  }
}

class _SlideText extends StatefulWidget {
  const _SlideText({
    required this.slide,
    required this.active,
    required this.gold,
  });

  final OnboardingSlide slide;
  final bool active;
  final Color gold;

  @override
  State<_SlideText> createState() => _SlideTextState();
}

class _SlideTextState extends State<_SlideText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(_SlideText old) {
    super.didUpdateWidget(old);
    if (old.active != widget.active) _sync();
  }

  void _sync() {
    if (!motionEnabled(context)) {
      _c.value = 1;
    } else if (widget.active && _c.isDismissed) {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 6, 28, 0),
      child: Column(
        children: [
          Reveal(
            animation: _c,
            end: 0.7,
            offset: const Offset(0, 16),
            child: Text(
              widget.slide.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: widget.gold,
                fontSize: 26,
                height: 1.15,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Reveal(
            animation: _c,
            start: 0.18,
            end: 0.95,
            offset: const Offset(0, 12),
            child: Text(
              widget.slide.body,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: kTertiaryColor.withValues(alpha: 0.9),
                fontSize: 15,
                height: 1.45,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The phone + call-outs for one slide, on the fixed design canvas.
class SlideIllustration extends StatefulWidget {
  const SlideIllustration({
    super.key,
    required this.slide,
    required this.active,
    required this.isDark,
    required this.gold,
  });

  final OnboardingSlide slide;
  final bool active;
  final bool isDark;
  final Color gold;

  @override
  State<SlideIllustration> createState() => _SlideIllustrationState();
}

class _SlideIllustrationState extends State<SlideIllustration>
    with TickerProviderStateMixin {
  // Phone entrance, then each call-out inks in turn.
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: 700 + 650 * widget.slide.callouts.length),
  );
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );
  bool _motion = true;
  final List<GlobalKey> _labelKeys = [];
  List<Size> _labelSizes = const [];

  static const _phoneShare = 0.32; // part of the timeline for the phone

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < widget.slide.callouts.length; i++) {
      _labelKeys.add(GlobalKey());
    }
    _labelSizes = List.filled(widget.slide.callouts.length, const Size(80, 40));
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureLabels());
  }

  void _measureLabels() {
    if (!mounted) return;
    final sizes = [
      for (final k in _labelKeys)
        (k.currentContext?.findRenderObject() as RenderBox?)?.size ??
            const Size(80, 40),
    ];
    setState(() => _labelSizes = sizes);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _motion = motionEnabled(context);
    _sync();
  }

  @override
  void didUpdateWidget(SlideIllustration old) {
    super.didUpdateWidget(old);
    if (old.active != widget.active) _sync();
  }

  void _sync() {
    if (!_motion) {
      _intro.value = 1;
      _pulse.stop();
      return;
    }
    if (widget.active) {
      if (_intro.isDismissed) _intro.forward();
      if (!_pulse.isAnimating) _pulse.repeat();
    } else {
      _pulse.stop();
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    _pulse.dispose();
    super.dispose();
  }

  /// Progress (0..1) of call-out [i] within the intro timeline.
  double _calloutT(int i, double t) {
    final n = widget.slide.callouts.length;
    if (n == 0) return 0;
    final slot = (1 - _phoneShare) / n;
    final start = _phoneShare + i * slot;
    return ((t - start) / (slot * 1.15)).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final slide = widget.slide;
    final theme = widget.isDark ? 'black' : 'blue';
    final screenshot = 'assets/images/onboarding/$theme/${slide.screen}.jpg';

    return AnimatedBuilder(
      animation: Listenable.merge([_intro, _pulse]),
      builder: (context, _) {
        final t = _intro.value;
        final phoneT = Curves.easeOutCubic.transform(
          (t / _phoneShare).clamp(0.0, 1.0),
        );
        final progress = [
          for (var i = 0; i < slide.callouts.length; i++) _calloutT(i, t),
        ];
        final spotlight = slide.callouts
            .where((c) => c.spotlight)
            .map((c) => screenToCanvas(c.target))
            .toList();
        final spotAmount = spotlight.isEmpty
            ? 0.0
            : Curves.easeOut.transform(
                ((t - _phoneShare * 0.8) / 0.25).clamp(0.0, 1.0),
              );

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // ── Phone ───────────────────────────────────────────────
            Positioned.fromRect(
              rect: kPhoneRect,
              child: Opacity(
                opacity: phoneT,
                child: Transform.translate(
                  offset: Offset(0, 40 * (1 - phoneT)),
                  child: Transform.scale(
                    scale: 0.94 + 0.06 * phoneT,
                    child: Bob(
                      amplitude: 2.2,
                      child: _PhoneFrame(
                        screenshot: screenshot,
                        isDark: widget.isDark,
                        gold: widget.gold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // ── Spotlight ──────────────────────────────────────────
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: SpotlightPainter(
                    targets: spotlight,
                    amount: spotAmount,
                    screen: phoneScreenRect(),
                    radius: 22,
                  ),
                ),
              ),
            ),
            // ── Extra floating card (e.g. All Access) ─────────────
            if (slide.overlay != null)
              Positioned.fill(
                child: _OverlayReveal(
                  t: ((t - _phoneShare) / 0.3).clamp(0.0, 1.0),
                  child: slide.overlay!(context, widget.gold, widget.isDark),
                ),
              ),
            // ── Ink: circles + arrows ──────────────────────────────
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: CalloutPainter(
                    callouts: slide.callouts,
                    progress: progress,
                    labelSizes: _labelSizes,
                    color: widget.gold,
                    pulse: _motion ? _pulse.value : 0,
                  ),
                ),
              ),
            ),
            // ── Handwritten labels ─────────────────────────────────
            for (var i = 0; i < slide.callouts.length; i++)
              Positioned(
                left: slide.callouts[i].labelAt.dx,
                top: slide.callouts[i].labelAt.dy,
                child: _CalloutLabel(
                  key: _labelKeys[i],
                  callout: slide.callouts[i],
                  t: ((progress[i] - 0.05) / 0.35).clamp(0.0, 1.0),
                  gold: widget.gold,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _OverlayReveal extends StatelessWidget {
  const _OverlayReveal({required this.t, required this.child});

  final double t;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final v = Curves.easeOutBack.transform(t);
    return Opacity(
      opacity: t,
      child: Transform.translate(
        offset: Offset(0, 30 * (1 - v)),
        child: Transform.scale(scale: 0.9 + 0.1 * v, child: child),
      ),
    );
  }
}

class _CalloutLabel extends StatelessWidget {
  const _CalloutLabel({
    super.key,
    required this.callout,
    required this.t,
    required this.gold,
  });

  final OnboardingCallout callout;
  final double t;
  final Color gold;

  @override
  Widget build(BuildContext context) {
    final base = TextStyle(
      fontFamily: kHandFont,
      fontSize: 20,
      height: 1.0,
      fontWeight: FontWeight.w700,
      color: Colors.white,
      shadows: const [
        Shadow(color: Color(0x88000000), blurRadius: 6, offset: Offset(0, 1)),
      ],
    );
    final label = SizedBox(
      width: callout.labelWidth,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: callout.text),
            if (callout.accent != null)
              TextSpan(
                text: ' ${callout.accent}',
                style: TextStyle(color: gold),
              ),
          ],
        ),
        textAlign: callout.labelAlign,
        style: base,
      ),
    );
    return Opacity(
      opacity: t,
      child: Transform.translate(
        offset: Offset(0, 8 * (1 - t)),
        child: callout.step == null
            ? label
            : Column(
                crossAxisAlignment: callout.labelAlign == TextAlign.right
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: gold,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${callout.step}',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  label,
                ],
              ),
      ),
    );
  }
}

class _PhoneFrame extends StatelessWidget {
  const _PhoneFrame({
    required this.screenshot,
    required this.isDark,
    required this.gold,
  });

  final String screenshot;
  final bool isDark;
  final Color gold;

  @override
  Widget build(BuildContext context) {
    final bezel = isDark ? const Color(0xff2A2A2E) : const Color(0xff2C3E73);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: bezel,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isDark ? const Color(0xff4A4A50) : const Color(0xff4D63A3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: gold.withValues(alpha: 0.08),
            blurRadius: 40,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(kBezel),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Image.asset(
            screenshot,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            filterQuality: FilterQuality.medium,
            errorBuilder: (_, __, ___) => ColoredBox(color: kQuaternaryColor),
          ),
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({
    required this.count,
    required this.index,
    required this.color,
    required this.onTap,
  });

  final int count;
  final int index;
  final Color color;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: kTertiaryColor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.14)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < count; i++)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onTap(i),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 3,
                    vertical: 8,
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutCubic,
                    width: i == index ? 26 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: i == index
                          ? color
                          : kTertiaryColor.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(4),
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

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.color,
    required this.textColor,
    required this.onTap,
  });

  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 54,
          alignment: Alignment.center,
          // Same gold pill + glow as the active tab in the app's nav bar.
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color.lerp(color, Colors.white, 0.18)!, color],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.25),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (child, a) => FadeTransition(
              opacity: a,
              child: SlideTransition(
                position: Tween(
                  begin: const Offset(0, 0.4),
                  end: Offset.zero,
                ).animate(a),
                child: child,
              ),
            ),
            child: Text(
              label,
              key: ValueKey(label),
              style: TextStyle(
                color: textColor,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SpeedLines extends StatelessWidget {
  const _SpeedLines();

  @override
  Widget build(BuildContext context) {
    final loop = LoopProvider.of(context);
    final color = kTertiaryColor;
    if (loop == null) {
      return CustomPaint(painter: SpeedLinesPainter(t: 0.3, color: color));
    }
    return AnimatedBuilder(
      animation: loop,
      builder: (context, _) => CustomPaint(
        painter: SpeedLinesPainter(t: loop.value, color: color),
      ),
    );
  }
}
