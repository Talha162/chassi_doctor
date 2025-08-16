import 'package:flutter/material.dart';
import 'package:motorsport/constants/app_colors.dart';
import 'package:motorsport/constants/app_images.dart';
import 'package:motorsport/constants/app_sizes.dart';
import 'package:motorsport/main.dart';
import 'package:motorsport/view/widget/common_image_view_widget.dart';
import 'package:motorsport/view/widget/custom_app_bar_widget.dart';
import 'package:motorsport/view/widget/my_button_widget.dart';
import 'package:motorsport/view/widget/my_text_widget.dart';

class SavedSetupHistory extends StatelessWidget {
  const SavedSetupHistory({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: simpleAppBar(title: 'Saved Setup History'),
      body: ListView(
        shrinkWrap: true,
        padding: AppSizes.DEFAULT,
        physics: BouncingScrollPhysics(),
        children: [
          MyText(
            text: 'History',
            size: 18,
            paddingBottom: 8,
            weight: FontWeight.bold,
          ),
          MyText(
            text: 'Review and manage your past vehicle configurations.',
            size: 12,
            paddingBottom: 25,
          ),
          GridView.builder(
            shrinkWrap: true,
            padding: AppSizes.ZERO,
            physics: BouncingScrollPhysics(),
            itemCount: 10,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisExtent: 180,
              crossAxisSpacing: 10,
              mainAxisSpacing: 16,
            ),
            itemBuilder: (context, index) {
              return SetupHistoryTile(
                title: 'Track Day',
                location: 'Silverstone Circuit',
                car: 'BMW M3 E30',
                date: '2023-10-01',
                onView: () {},
                onShare: () {},
              );
            },
          ),
        ],
      ),
    );
  }
}

class SetupHistoryTile extends StatelessWidget {
  final String title;
  final String location;
  final String car;
  final String date;
  final VoidCallback? onView;
  final VoidCallback? onShare;

  const SetupHistoryTile({
    Key? key,
    required this.title,
    required this.location,
    required this.car,
    required this.date,
    this.onView,
    this.onShare,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kQuaternaryColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MyText(
            text: title,
            size: 16,
            weight: FontWeight.bold,
            paddingBottom: 16,
          ),
          Row(
            children: [
              Image.asset(Assets.imagesLocPin, height: 16),
              Expanded(
                child: MyText(
                  paddingLeft: 6,
                  text: location,
                  size: 12,
                  color: kTertiaryColor,
                  maxLines: 1,
                  textOverflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Image.asset(Assets.imagesModel, height: 16),
              Expanded(
                child: MyText(
                  paddingLeft: 6,
                  text: car,
                  size: 12,
                  color: kTertiaryColor,
                  maxLines: 1,
                  textOverflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Image.asset(Assets.imagesDate, height: 16),
              Expanded(
                child: MyText(
                  paddingLeft: 6,
                  text: date,
                  size: 12,
                  color: kTertiaryColor,
                  maxLines: 1,
                  textOverflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: MyButton(
                  buttonText: 'View',
                  height: 30,
                  textSize: 12,
                  radius: 8,
                  onTap: () {},
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: MyBorderButton(
                  buttonText: 'Share',
                  height: 30,
                  textSize: 12,
                  buttonColor: kSecondaryColor,
                  textColor: kSecondaryColor,
                  radius: 8,
                  onTap: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
