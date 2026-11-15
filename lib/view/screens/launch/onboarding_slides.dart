import 'package:flutter/material.dart';
import 'package:motorsport/constants/app_colors.dart';
import 'package:motorsport/constants/app_images.dart';
import 'package:motorsport/view/screens/launch/onboarding_annotations.dart';

/// Builds an extra floating widget over the phone (e.g. the All Access card).
typedef SlideOverlayBuilder =
    Widget Function(BuildContext context, Color gold, bool isDark);

@immutable
class OnboardingSlide {
  const OnboardingSlide({
    required this.screen,
    required this.title,
    required this.body,
    required this.callouts,
    this.overlay,
  });

  /// Screenshot name in assets/images/onboarding/{blue|black}/<screen>.jpg.
  final String screen;
  final String title;
  final String body;
  final List<OnboardingCallout> callouts;
  final SlideOverlayBuilder? overlay;
}

// Call-out targets are fractions of the screenshot (x, y, right, bottom),
// measured from the real app screens captured by
// integration_test/screenshot_tour_test.dart.
final List<OnboardingSlide> onboardingSlides = [
  // 1 ─ What the app is
  OnboardingSlide(
    screen: 'home',
    title: 'Your pit crew, in your pocket',
    body:
        'Car not behaving? Get setup help in seconds, or dive into the '
        'learning hub and understand the engineering.',
    callouts: const [
      OnboardingCallout(
        target: Rect.fromLTRB(0.05, 0.425, 0.485, 0.548),
        labelAt: Offset(0, 138),
        text: 'Car not right?',
        accent: 'Start here!',
        labelWidth: 86,
      ),
      OnboardingCallout(
        target: Rect.fromLTRB(0.515, 0.425, 0.95, 0.548),
        labelAt: Offset(298, 126),
        text: 'Learn the',
        accent: 'why behind it',
        labelWidth: 92,
        labelAlign: TextAlign.right,
        bend: -0.35,
      ),
      OnboardingCallout(
        target: Rect.fromLTRB(0.74, 0.592, 0.925, 0.632),
        labelAt: Offset(306, 300),
        text: 'Set car & track',
        accent: 'once',
        labelWidth: 84,
        labelAlign: TextAlign.right,
        shape: CalloutShape.pill,
        bend: 0.3,
      ),
      OnboardingCallout(
        target: Rect.fromLTRB(0.615, 0.89, 0.715, 0.95),
        labelAt: Offset(2, 392),
        text: 'Every session',
        accent: 'saved',
        labelWidth: 86,
        bend: 0.25,
      ),
    ],
  ),

  // 2 ─ Car profile (missing from the client's set)
  OnboardingSlide(
    screen: 'track_configuration',
    title: 'Set up your car once',
    body:
        'Track, surface, weather, engine, aero and drive. Every '
        'recommendation is matched to your exact car and conditions.',
    callouts: const [
      OnboardingCallout(
        target: Rect.fromLTRB(0.05, 0.155, 0.95, 0.275),
        labelAt: Offset(0, 22),
        text: 'Name your',
        accent: 'track',
        labelWidth: 84,
        bend: -0.3,
      ),
      OnboardingCallout(
        target: Rect.fromLTRB(0.05, 0.50, 0.95, 0.695),
        labelAt: Offset(304, 170),
        text: 'Oval or',
        accent: 'circuit?',
        labelWidth: 84,
        labelAlign: TextAlign.right,
        bend: -0.3,
      ),
      OnboardingCallout(
        target: Rect.fromLTRB(0.05, 0.72, 0.95, 0.87),
        labelAt: Offset(0, 408),
        text: 'Tarmac or',
        accent: 'dirt?',
        labelWidth: 84,
        bend: 0.3,
      ),
    ],
  ),

  // 3 ─ Symptom
  OnboardingSlide(
    screen: 'symptoms',
    title: "Tell it what the car's doing",
    body:
        'Pick the symptom you feel from the seat. Not listed? Report it '
        "and we'll add it.",
    callouts: const [
      OnboardingCallout(
        target: Rect.fromLTRB(0.05, 0.245, 0.485, 0.47),
        labelAt: Offset(0, 36),
        text: 'Rear end',
        accent: 'stepping out?',
        labelWidth: 86,
        bend: -0.3,
      ),
      OnboardingCallout(
        target: Rect.fromLTRB(0.515, 0.245, 0.95, 0.47),
        labelAt: Offset(304, 36),
        text: 'Pushing',
        accent: 'wide?',
        labelWidth: 84,
        labelAlign: TextAlign.right,
        bend: 0.3,
      ),
      OnboardingCallout(
        target: Rect.fromLTRB(0.05, 0.52, 0.95, 0.745),
        labelAt: Offset(0, 372),
        text: 'Something else?',
        accent: 'Tell us!',
        labelWidth: 86,
        bend: 0.3,
      ),
    ],
  ),

  // 4 ─ Corner phase
  OnboardingSlide(
    screen: 'corner_phase_selected',
    title: 'Pinpoint where it happens',
    body:
        'Corner entry, mid corner or exit. Select every phase you feel it, '
        'then tap Recommend Adjustments.',
    callouts: const [
      OnboardingCallout(
        target: Rect.fromLTRB(0.05, 0.36, 0.485, 0.505),
        labelAt: Offset(0, 96),
        step: 1,
        text: 'Where does it',
        accent: 'bite?',
        labelWidth: 86,
        bend: -0.3,
      ),
      OnboardingCallout(
        target: Rect.fromLTRB(0.515, 0.36, 0.95, 0.505),
        labelAt: Offset(304, 96),
        step: 2,
        text: 'Tick all that',
        accent: 'apply',
        labelWidth: 84,
        labelAlign: TextAlign.right,
        bend: 0.3,
      ),
      OnboardingCallout(
        target: Rect.fromLTRB(0.05, 0.765, 0.95, 0.82),
        labelAt: Offset(304, 392),
        step: 3,
        text: 'Then hit',
        accent: 'GO!',
        labelWidth: 84,
        labelAlign: TextAlign.right,
        shape: CalloutShape.pill,
        bend: -0.3,
      ),
    ],
  ),

  // 5 ─ Recommendations
  OnboardingSlide(
    screen: 'recommendations',
    title: 'The fix, and the reason why',
    body:
        'Every adjustment comes with the engineering behind it, filtered '
        'to your car and track.',
    callouts: const [
      OnboardingCallout(
        target: Rect.fromLTRB(0.07, 0.178, 0.55, 0.212),
        labelAt: Offset(0, 30),
        text: "Here's",
        accent: 'the fix',
        labelWidth: 84,
        shape: CalloutShape.pill,
        bend: -0.3,
      ),
      OnboardingCallout(
        target: Rect.fromLTRB(0.675, 0.178, 0.925, 0.212),
        labelAt: Offset(304, 24),
        text: 'Quick tweak or',
        accent: 'big change',
        labelWidth: 86,
        labelAlign: TextAlign.right,
        shape: CalloutShape.pill,
        bend: 0.3,
      ),
      OnboardingCallout(
        target: Rect.fromLTRB(0.07, 0.218, 0.90, 0.253),
        labelAt: Offset(0, 236),
        text: '...and',
        accent: 'WHY it works',
        labelWidth: 84,
        shape: CalloutShape.underline,
        bend: 0.3,
      ),
    ],
  ),

  // 6 ─ History (missing from the client's set)
  OnboardingSlide(
    screen: 'tab_history',
    title: 'Every session, saved',
    body:
        'Look back at what you changed, add notes from the track and share '
        'any session as a PDF.',
    callouts: const [
      OnboardingCallout(
        target: Rect.fromLTRB(0.05, 0.165, 0.488, 0.37),
        labelAt: Offset(0, 26),
        text: 'Every run,',
        accent: 'on record',
        labelWidth: 84,
        bend: -0.3,
      ),
      OnboardingCallout(
        target: Rect.fromLTRB(0.28, 0.323, 0.457, 0.357),
        labelAt: Offset(304, 120),
        text: 'Share it as a',
        accent: 'PDF',
        labelWidth: 84,
        labelAlign: TextAlign.right,
        shape: CalloutShape.pill,
        bend: 0.35,
      ),
      OnboardingCallout(
        target: Rect.fromLTRB(0.42, 0.89, 0.76, 0.955),
        labelAt: Offset(304, 380),
        text: 'Always one',
        accent: 'tap away',
        labelWidth: 84,
        labelAlign: TextAlign.right,
        bend: -0.3,
      ),
    ],
  ),

  // 7 ─ All Access (and what stays free)
  OnboardingSlide(
    screen: 'courses',
    title: 'Go deeper with All Access',
    body:
        'Setup Help is free. Unlock every Motorsport University course '
        'with one subscription, on all your devices.',
    callouts: const [
      OnboardingCallout(
        target: Rect.fromLTRB(0.05, 0.135, 0.95, 0.31),
        labelAt: Offset(0, 40),
        text: 'Pro courses,',
        accent: 'right in the app',
        labelWidth: 86,
        spotlight: false,
      ),
    ],
    overlay: (context, gold, isDark) => const _AllAccessCard(),
  ),
];

/// Floating "All Access" card for the last slide, styled like the paywall.
class _AllAccessCard extends StatelessWidget {
  const _AllAccessCard();

  @override
  Widget build(BuildContext context) {
    final gold = kSecondaryColor;
    final text = kTertiaryColor;
    Widget row(String s) => Padding(
      padding: const EdgeInsets.only(top: 7),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, size: 15, color: gold),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              s,
              style: TextStyle(color: text, fontSize: 11.5, height: 1.2),
            ),
          ),
        ],
      ),
    );
    return Stack(
      children: [
        Positioned(
          left: 54,
          right: 54,
          top: 250,
          child: Transform.rotate(
            angle: -0.035,
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              decoration: BoxDecoration(
                color: kQuaternaryColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: gold.withValues(alpha: 0.55)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 26,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      ClipOval(
                        child: Image.asset(
                          Assets.mainlogo,
                          width: 34,
                          height: 34,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'All Access',
                              style: TextStyle(
                                color: gold,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'Every course. One subscription.',
                              style: TextStyle(
                                color: text.withValues(alpha: 0.8),
                                fontSize: 10.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  row('Every Motorsport University course'),
                  row('Monthly or yearly, cancel anytime'),
                  row('Restore on all your devices'),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: gold.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Setup Help stays free',
                      style: TextStyle(
                        color: gold,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
