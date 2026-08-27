import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:motorsport/constants/app_colors.dart';
import 'package:motorsport/constants/app_images.dart';
import 'package:motorsport/constants/app_sizes.dart';
import 'package:motorsport/services/subscription_service.dart';
import 'package:motorsport/view/screens/courses/all_courses.dart';
import 'package:motorsport/view/screens/courses/my_courses.dart';
import 'package:motorsport/view/screens/subscriptions/paywall_screen.dart';
import 'package:motorsport/view/widget/custom_app_bar_widget.dart';
import 'package:motorsport/view/widget/my_button_widget.dart';
import 'package:motorsport/view/widget/my_text_widget.dart';

class Courses extends StatelessWidget {
  const Courses({super.key, this.showBackButton = false});

  final bool showBackButton;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: simpleAppBar(
        title: 'Motorsport University',
        leadingWidth: showBackButton ? 96 : 72,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showBackButton)
                GestureDetector(
                  onTap: () => Get.back(),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Image.asset(
                      Assets.imagesArrowBack,
                      height: 14,
                      color: kTertiaryColor,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: kBorderColor2,
                  child: ClipOval(
                    child: Image.asset(Assets.mainlogo, fit: BoxFit.contain),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: ValueListenableBuilder(
        valueListenable: SubscriptionService.instance.state,
        builder: (context, state, _) => ListView(
          shrinkWrap: true,
          padding: AppSizes.ZERO,
          physics: BouncingScrollPhysics(),
          children: [
            Container(
              margin: AppSizes.HORIZONTAL,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(Assets.imagesCoursesBg),
                  fit: BoxFit.cover,
                ),
                borderRadius: BorderRadius.circular(12),
                color: kQuaternaryColor,
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MyText(
                    text: 'Motorsport University',
                    size: 18,
                    weight: FontWeight.bold,
                    paddingBottom: 6,
                  ),
                  MyText(
                    text: state.hasActiveSubscription
                        ? 'Your All Access subscription is active. Every published course is ready below.'
                        : 'Start a 3-day free trial, then unlock every current course with one monthly or yearly subscription.',
                    size: 12,
                    lineHeight: 1.5,
                    color: kTertiaryColor,
                    paddingBottom: 16,
                  ),
                  if (!state.hasActiveSubscription)
                    SizedBox(
                      width: 190,
                      child: MyButton(
                        buttonText: 'View All Access Plans',
                        height: 42,
                        textSize: 13,
                        bgColor: kSecondaryColor,
                        textColor: kPrimaryColor,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PaywallScreen(
                                sourceLabel: 'Courses Overview',
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            CustomTabBar(
              tabs: ['All Courses', 'My Learning'],
              tabContents: [AllCourses(), MyCourses()],
            ),
            const SizedBox(height: 16),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class CustomTabBar extends StatefulWidget {
  final List<String> tabs;
  final List<Widget> tabContents;
  final int initialIndex;

  const CustomTabBar({
    Key? key,
    required this.tabs,
    required this.tabContents,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  State<CustomTabBar> createState() => _CustomTabBarState();
}

class _CustomTabBarState extends State<CustomTabBar> {
  late int selectedIndex;

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 42,
          margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          decoration: BoxDecoration(
            color: kQuaternaryColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: List.generate(widget.tabs.length, (index) {
              final isSelected = selectedIndex == index;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedIndex = index;
                    });
                  },
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: isSelected ? kSecondaryColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        width: 2.0,
                        color: isSelected ? kTertiaryColor : Colors.transparent,
                      ),
                    ),
                    child: Center(
                      child: MyText(
                        text: widget.tabs[index],
                        size: 14,
                        weight: FontWeight.w600,
                        color: isSelected
                            ? kPrimaryColor
                            : kTertiaryColor.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        widget.tabContents[selectedIndex],
      ],
    );
  }
}
