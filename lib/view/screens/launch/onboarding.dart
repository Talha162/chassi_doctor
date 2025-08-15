import 'package:flutter/material.dart';
import 'package:motorsport/constants/app_colors.dart';
import 'package:motorsport/constants/app_images.dart';
import 'package:motorsport/constants/app_sizes.dart';
import 'package:motorsport/view/widget/custom_app_bar_widget.dart';
import 'package:motorsport/view/widget/my_text_widget.dart';
import 'package:motorsport/view/widget/my_button_widget.dart';

class Onboarding extends StatefulWidget {
  const Onboarding({super.key});

  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> {
  final List<Map<String, String>> onboardingData = [
    {
      'image': Assets.imagesOn1,
      'title': 'Take Control of Your Car’s Handling',
      'subtitle':
          'Discover the proven setup techniques used in competitive racing. This app simplifies car tuning with clear steps and expert logic.',
    },
    {
      'image': Assets.imagesOn2,
      'title': 'Master Your Car\'s Balance',
      'subtitle':
          'Calculate front and rear roll centres accurately using our step-by-step measurement tool. Understand roll axis, grip dynamics, and balance like a pro.',
    },
    {
      'image': Assets.imagesOn3,
      'title': 'Built-in Geometry Tools',
      'subtitle':
          'Learn how to measure and adjust your Panhard rod, A-frame, Leaf Springs, Watts Linkage, and more — all explained with diagrams.',
    },
  ];

  int currentPage = 0;
  final PageController _pageController = PageController();

  void _nextPage() {
    if (currentPage < onboardingData.length - 1) {
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    } else {
      // Handle finish onboarding (navigate to home or sign up)
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: simpleAppBar(title: 'Welcome to Motorsport ', haveLeading: false),
      body: PageView.builder(
        controller: _pageController,
        itemCount: onboardingData.length,
        onPageChanged: (index) {
          setState(() {
            currentPage = index;
          });
        },
        itemBuilder: (context, index) {
          final data = onboardingData[index];
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(data['image'] ?? '', height: 280),
              SizedBox(height: 40),
              MyText(
                text: data['title'] ?? '',
                size: 18,
                color: kSecondaryColor,
                weight: FontWeight.bold,
                textAlign: TextAlign.center,
                paddingBottom: 20,
                paddingLeft: 20,
                paddingRight: 20,
              ),
              MyText(
                paddingLeft: 20,
                paddingRight: 20,
                text: data['subtitle'] ?? '',
                size: 14,
                lineHeight: 1.5,
                color: Color(0xffF7CDB0),
                textAlign: TextAlign.center,
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: BottomAppBar(
        color: kPrimaryColor,
        elevation: 0,
        child: Padding(
          padding: AppSizes.DEFAULT,
          child: MyButton(
            buttonText: currentPage == onboardingData.length - 1
                ? 'Get Started'
                : 'Next',
            onTap: _nextPage,
          ),
        ),
      ),
    );
  }
}
