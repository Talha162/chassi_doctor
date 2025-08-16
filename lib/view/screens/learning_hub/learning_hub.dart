import 'package:flutter/material.dart';
import 'package:motorsport/constants/app_colors.dart';
import 'package:motorsport/constants/app_images.dart';
import 'package:motorsport/constants/app_sizes.dart';
import 'package:motorsport/view/widget/custom_app_bar_widget.dart';
import 'package:motorsport/view/widget/my_button_widget.dart';
import 'package:motorsport/view/widget/my_text_widget.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

class LearningHub extends StatelessWidget {
  const LearningHub({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: simpleAppBar(
        title: 'Motorsport University - Learning Hub',
        haveLeading: false,
      ),
      body: ListView(
        shrinkWrap: true,
        padding: AppSizes.DEFAULT,
        physics: BouncingScrollPhysics(),
        children: [
          MyText(
            text: 'Learning Hub',
            size: 18,
            paddingBottom: 8,
            weight: FontWeight.bold,
          ),
          MyText(
            text:
                'Your one-stop destination for skill-building, expert resources, and self-paced learning — anytime, anywhere.',
            size: 12,
            paddingBottom: 25,
          ),
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(Assets.imagesRaceCraftBg),
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
                  text: 'Elevate Your Race Craft!',
                  size: 18,
                  weight: FontWeight.bold,
                  paddingBottom: 6,
                ),
                MyText(
                  text:
                      'Unlock advanced techniques and optimize your vehicle\'s performance with our premium courses.',
                  size: 12,
                  lineHeight: 1.5,
                  color: kTertiaryColor,
                  paddingBottom: 16,
                ),
                SizedBox(
                  width: 135,
                  child: MyButton(
                    buttonText: 'Explore Courses Now',
                    height: 30,
                    textSize: 12,
                    textColor: kTertiaryColor,
                    bgColor: Color(0xff636AE8),
                    radius: 8,
                    onTap: () {},
                  ),
                ),
              ],
            ),
          ),
          MyText(
            paddingTop: 16,
            text: 'My Learning Module',
            size: 18,
            paddingBottom: 12,
            weight: FontWeight.bold,
          ),
          ListView.builder(
            shrinkWrap: true,
            padding: AppSizes.ZERO,
            physics: BouncingScrollPhysics(),
            itemCount: 3,
            itemBuilder: (context, index) {
              final tiles = [
                {
                  'title': 'Advanced Aerodynamics',
                  'duration': '2hrs 30mins',
                  'imagePath': Assets.imagesAdvanced,
                  'percent': 0.75,
                  'completedText': '75% completed',
                },
                {
                  'title': 'Advanced Aerodynamics in Racing',
                  'duration': '2hrs 30mins',
                  'imagePath': Assets.imagesAdvanced1,
                  'percent': 0.75,
                  'completedText': '75% completed',
                },
                {
                  'title': 'Tire Science & Grip Management',
                  'duration': '2hrs 30mins',
                  'imagePath': Assets.imagesScience,
                  'percent': 0.75,
                  'completedText': '75% completed',
                },
              ];
              final tile = tiles[index];
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index < tiles.length - 1 ? 12 : 0,
                ),
                child: _LearningHubTile(
                  title: tile['title'] as String,
                  duration: tile['duration'] as String,
                  imagePath: tile['imagePath'] as String,
                  percent: tile['percent'] as double,
                  completedText: tile['completedText'] as String,
                ),
              );
            },
          ),
          MyText(
            paddingTop: 16,
            text: 'Module 1:  Chassis dynamic fundamentals',
            size: 18,
            lineHeight: 1.5,
            paddingBottom: 12,
            weight: FontWeight.bold,
          ),
          ListView.builder(
            shrinkWrap: true,
            padding: AppSizes.ZERO,
            physics: BouncingScrollPhysics(),
            itemCount: 3,
            itemBuilder: (context, index) {
              final tiles = [
                {
                  'title': 'Introduction to Vehicle Balance',
                  'duration': '15 min',
                },
                {
                  'title': 'Introduction to Vehicle Balance',
                  'duration': '15 min',
                },
                {
                  'title': 'Introduction to Vehicle Balance',
                  'duration': '15 min',
                },
              ];
              final tile = tiles[index];
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index < tiles.length - 1 ? 12 : 0,
                ),
                child: _LectureTile(
                  title: tile['title'] as String,
                  duration: tile['duration'] as String,
                  completed: index == 0,
                  percent: index == 0 ? 1.0 : 0.25,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _LearningHubTile extends StatelessWidget {
  final String title;
  final String duration;
  final String imagePath;
  final double percent;
  final String completedText;

  const _LearningHubTile({
    Key? key,
    required this.title,
    required this.duration,
    required this.imagePath,
    required this.percent,
    required this.completedText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: kQuaternaryColor,
        border: Border.all(color: Color(0xff634F91)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              imagePath,
              height: 70,
              width: 70,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MyText(
                  text: title,
                  size: 14,
                  paddingBottom: 4,
                  weight: FontWeight.bold,
                ),
                MyText(text: duration, size: 12, paddingBottom: 6),
                LinearPercentIndicator(
                  lineHeight: 6,
                  percent: percent,
                  padding: EdgeInsets.zero,
                  backgroundColor: kTertiaryColor,
                  progressColor: kGreenColor,
                  barRadius: Radius.circular(4),
                ),
                MyText(
                  paddingTop: 6,
                  textAlign: TextAlign.end,
                  text: completedText,
                  size: 12,
                  color: kTertiaryColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LectureTile extends StatelessWidget {
  final String title;
  final String duration;
  final double percent;
  final bool completed;

  const _LectureTile({
    Key? key,
    required this.title,
    required this.duration,
    required this.percent,
    this.completed = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: kQuaternaryColor,
        border: Border.all(color: Color(0xff634F91)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Column(
            children: [
              Image.asset(
                Assets.imagesSelected,
                height: 24,
                color: completed ? kGreenColor : kSecondaryColor,
              ),
              MyText(text: duration, size: 12, paddingTop: 5),
            ],
          ),
          SizedBox(width: 8),
          Expanded(
            child: MyText(
              text: title,
              size: 14,
              paddingRight: 8,
              weight: FontWeight.bold,
            ),
          ),
          SizedBox(
            width: 65,
            child: LinearPercentIndicator(
              lineHeight: 6,
              percent: percent,
              padding: EdgeInsets.zero,
              backgroundColor: kTertiaryColor,
              progressColor: completed ? kGreenColor : kSecondaryColor,
              barRadius: Radius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}
