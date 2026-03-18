import 'package:flutter/material.dart';
import 'package:motorsport/constants/app_colors.dart';
import 'package:motorsport/constants/app_images.dart';
import 'package:motorsport/constants/app_sizes.dart';
import 'package:motorsport/view/screens/courses/all_courses.dart';
import 'package:motorsport/view/screens/courses/my_courses.dart';
import 'package:motorsport/view/widget/custom_app_bar_widget.dart';
import 'package:motorsport/view/widget/my_text_widget.dart';

class Courses extends StatelessWidget {
  const Courses({super.key, this.showBackButton = false});

  final bool showBackButton;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: simpleAppBar(
        title: 'Courses',
        // haveLeading: showBackButton,
        leading: GestureDetector(
          // onTap: () async {
          //   final _ = await Get.to(() => const Settings(showBackButton: true));
          //   _loadUser(); // refresh after returning
          // },
          child: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: kBorderColor2,
                  child: ClipOval(
                    child: Image.asset(Assets.mainlogo, fit: BoxFit.contain),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
                      'Grow your race car knowledge! Discover why race cars do what they do and master the technical knowledge with these easy to understand bitesize modules.',
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
          const SizedBox(height: 16),
          // Center(child: Image.asset(Assets.imagesChassisDoc, height: 36)),
          const SizedBox(height: 16),
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
