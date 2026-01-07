import 'package:flutter/material.dart';
import 'package:motorsport/constants/app_colors.dart';
import 'package:motorsport/constants/app_images.dart';
import 'package:motorsport/constants/app_sizes.dart';
import 'package:motorsport/view/screens/courses/all_courses.dart';
import 'package:motorsport/view/screens/courses/my_courses.dart';
import 'package:motorsport/view/widget/custom_app_bar_widget.dart';
import 'package:motorsport/view/widget/my_button_widget.dart';
import 'package:motorsport/view/widget/my_text_widget.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

class Courses extends StatelessWidget {
  const Courses({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: simpleAppBar(title: 'Courses', haveLeading: false),
      body: ListView(
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
                  text: 'Boost Your Racing Career!',
                  size: 18,
                  weight: FontWeight.bold,
                  paddingBottom: 6,
                ),
                MyText(
                  text:
                      'Discover advanced setup strategies and master truck dynamics',
                  size: 12,
                  lineHeight: 1.5,
                  color: kTertiaryColor,
                  paddingBottom: 16,
                ),

              ],
            ),
          ),
          CustomTabBar(
            tabs: ['All Courses', 'My Courses'],
            tabContents: [AllCourses(), MyCourses()],
          ),
        ],
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
                            : kTertiaryColor.withOpacity(0.6),
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
