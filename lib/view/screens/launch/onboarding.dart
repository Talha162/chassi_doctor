import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
import 'package:motorsport/config/routes/routes.dart';
import 'package:motorsport/constants/app_colors.dart';
import 'package:motorsport/constants/app_images.dart';
import 'package:motorsport/view/widget/my_button_widget.dart';
import 'package:motorsport/view/widget/my_text_widget.dart';

/// Metrics taken from the onboarding design (414 x 896 logical / 828 x 1792 @2x).
class _Spec {
  static const horizontalPadding = 26.0;

  static const skipTopOffset = 28.0;
  static const skipSize = 16.0;
  static const skipColor = Color(0xffCDD0D9);

  static const imageAspectRatio = 1264 / 848;
  static const imageTopGap = 52.0;

  static const titleTopGap = 104.75;
  static const titleSize = 28.0;
  static const titleHeight = 1.2;
  static const letterSpacing = -0.25;

  static const subtitleTopGap = 11.0;
  static const subtitleSize = 16.0;
  static const subtitleHeight = 1.375;
  static const subtitleColor = Color(0xffF7CDB0);

  static const dotSize = 10.0;
  static const dotSpacing = 12.0;
  static const dotInactiveColor = Color(0xff3F4356);

  static const buttonTopGap = 38.5;
  static const buttonHeight = 56.0;
  static const buttonRadius = 10.0;
  static const buttonMargin = 44.0;
  static const buttonTextSize = 18.0;
  static const buttonTextColor = Color(0xff373737);
  static const buttonBottomGap = 4.0;
}

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.image,
    required this.title,
    required this.subtitle,
  });

  final String image;
  final String title;
  final String subtitle;
}

class Onboarding extends StatefulWidget {
  const Onboarding({super.key});

  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> {
  static const List<_OnboardingPageData> _pages = [
    _OnboardingPageData(
      image: Assets.imagesOnboardingWelcome,
      title: 'Welcome to Chassis Doctor',
      subtitle:
          'Diagnose handling issues, dial in your setup, and understand the '
          'engineering behind every adjustment, all in one app.',
    ),
    _OnboardingPageData(
      image: Assets.imagesOnboardingSetupAdvice,
      title: 'Setup Advice, Made for Your Car',
      subtitle:
          'Search proven setup recommendations filtered by your vehicle, '
          'track, surface, and weather, so you always know where to start.',
    ),
    _OnboardingPageData(
      image: Assets.imagesOnboardingCalculate,
      title: 'Calculate With Confidence',
      subtitle:
          'Diagnose handling issues, dial in your setup, and understand the '
          'engineering behind every adjustment, all in one app.',
    ),
    _OnboardingPageData(
      image: Assets.imagesOnboardingUniversity,
      title: 'Go Deeper With Motorsport University',
      subtitle:
          'Learn the theory behind the setup with video courses on '
          'aerodynamics, tire management, braking, and more.',
    ),
    _OnboardingPageData(
      image: Assets.imagesOnboardingFreeStart,
      title: 'Free to Start, More When You\'re Ready',
      subtitle:
          'Setup advice and calculators are free forever. Subscribe anytime '
          'to unlock full video courses and advanced tools.',
    ),
  ];

  final PageController _pageController = PageController();
  int _currentPage = 0;

  bool get _isLastPage => _currentPage == _pages.length - 1;

  void _next() {
    if (_isLastPage) {
      _finish();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    }
  }

  void _finish() => Get.offAllNamed(AppLinks.trackConfiguration);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimaryColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildSkip(),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                itemCount: _pages.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) => _buildPage(_pages[index]),
              ),
            ),
            _buildDots(),
            const SizedBox(height: _Spec.buttonTopGap),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: _Spec.buttonMargin,
              ),
              child: MyButton(
                buttonText: _isLastPage ? 'Get Started' : 'Next',
                onTap: _next,
                height: _Spec.buttonHeight,
                radius: _Spec.buttonRadius,
                textSize: _Spec.buttonTextSize,
                textColor: _Spec.buttonTextColor,
              ),
            ),
            const SizedBox(height: _Spec.buttonBottomGap),
          ],
        ),
      ),
    );
  }

  Widget _buildSkip() {
    return Padding(
      padding: const EdgeInsets.only(
        top: _Spec.skipTopOffset,
        right: _Spec.horizontalPadding,
      ),
      child: Align(
        alignment: Alignment.centerRight,
        child: Opacity(
          // Keeps the row height stable so the artwork never shifts between
          // pages, while the last page hides Skip as per the design.
          opacity: _isLastPage ? 0 : 1,
          child: MyText(
            text: 'Skip',
            size: _Spec.skipSize,
            color: _Spec.skipColor,
            onTap: _isLastPage ? null : _finish,
          ),
        ),
      ),
    );
  }

  Widget _buildPage(_OnboardingPageData data) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: _Spec.imageTopGap),
          AspectRatio(
            aspectRatio: _Spec.imageAspectRatio,
            child: Image.asset(data.image, fit: BoxFit.fitWidth),
          ),
          const SizedBox(height: _Spec.titleTopGap),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: _Spec.horizontalPadding,
            ),
            child: Column(
              children: [
                MyText(
                  text: data.title,
                  size: _Spec.titleSize,
                  lineHeight: _Spec.titleHeight,
                  letterSpacing: _Spec.letterSpacing,
                  weight: FontWeight.w700,
                  color: kSecondaryColor,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: _Spec.subtitleTopGap),
                MyText(
                  text: data.subtitle,
                  size: _Spec.subtitleSize,
                  lineHeight: _Spec.subtitleHeight,
                  letterSpacing: _Spec.letterSpacing,
                  color: _Spec.subtitleColor,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pages.length, (index) {
        return Container(
          width: _Spec.dotSize,
          height: _Spec.dotSize,
          margin: EdgeInsets.only(
            right: index == _pages.length - 1 ? 0 : _Spec.dotSpacing,
          ),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index == _currentPage
                ? kSecondaryColor
                : _Spec.dotInactiveColor,
          ),
        );
      }),
    );
  }
}
