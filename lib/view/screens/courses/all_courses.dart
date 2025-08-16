import 'package:flutter/material.dart';
import 'package:motorsport/constants/app_colors.dart';
import 'package:motorsport/constants/app_images.dart';
import 'package:motorsport/constants/app_sizes.dart';
import 'package:motorsport/view/widget/my_button_widget.dart';
import 'package:motorsport/view/widget/my_text_widget.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

class AllCourses extends StatelessWidget {
  const AllCourses({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      padding: AppSizes.VERTICAL,
      physics: BouncingScrollPhysics(),
      children: [
        MyText(
          paddingLeft: 20,
          text: 'All Available courses',
          size: 18,
          paddingBottom: 12,
          weight: FontWeight.bold,
        ),
        SizedBox(
          height: 30,
          child: ListView.separated(
            separatorBuilder: (context, index) {
              return SizedBox(width: 6);
            },
            shrinkWrap: true,
            scrollDirection: Axis.horizontal,
            itemCount: 4,
            physics: BouncingScrollPhysics(),
            padding: AppSizes.HORIZONTAL,
            itemBuilder: (context, index) {
              final filters = [
                'All',
                'Tire Management',
                'Advanced Braking',
                'Arts & Humanities',
              ];
              return Container(
                height: 30,
                padding: EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: index == 0 ? kSecondaryColor : kQuaternaryColor,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Center(
                  child: MyText(
                    text: filters[index],
                    size: 13,
                    color: index == 0 ? kPrimaryColor : kTertiaryColor,
                    weight: FontWeight.w500,
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          padding: AppSizes.HORIZONTAL,
          physics: BouncingScrollPhysics(),
          itemCount: 6,
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
      ],
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
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: kQuaternaryColor,
        border: Border.all(color: Color(0xff634F91)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(imagePath, height: 120, fit: BoxFit.cover),
          ),
          MyText(
            paddingTop: 6,
            text: title,
            size: 14,
            paddingBottom: 4,
            weight: FontWeight.bold,
          ),
          MyText(
            text: 'Camber refers to the vertical angle of the',
            size: 12,
            lineHeight: 1.5,
            color: kTertiaryColor.withValues(alpha: 0.8),
            paddingBottom: 6,
          ),
          Row(
            spacing: 6,
            children: [
              Image.asset(Assets.imagesStar, height: 14),
              MyText(text: '4.2', size: 12, weight: FontWeight.w500),
            ],
          ),
          SizedBox(height: 8),
          MyButton(
            height: 30,
            textSize: 12,
            radius: 50.0,
            buttonText: 'Get the course',
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
