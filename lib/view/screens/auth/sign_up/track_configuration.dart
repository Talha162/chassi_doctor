import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/utils.dart';
import 'package:motorsport/constants/app_sizes.dart';
import 'package:motorsport/view/screens/bottom_nav_bar/bottom_nav_bar.dart';
import 'package:motorsport/view/widget/custom_app_bar_widget.dart';
import 'package:motorsport/view/widget/my_button_widget.dart';
import 'package:motorsport/view/widget/my_text_widget.dart';
import 'package:motorsport/view/widget/custom_check_box_widget.dart';

class TrackConfiguration extends StatelessWidget {
  const TrackConfiguration({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: simpleAppBar(title: 'Track Configuration', haveLeading: false),
      body: ListView(
        shrinkWrap: true,
        padding: AppSizes.DEFAULT,
        physics: BouncingScrollPhysics(),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyText(text: 'Track Type', size: 16, weight: FontWeight.w600),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          CustomCheckBox(
                            isActive: false,
                            onTap: () {},
                            isRadio: true,
                          ),
                          SizedBox(width: 8),
                          MyText(text: 'Oval', size: 14),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          CustomCheckBox(
                            isActive: false,
                            onTap: () {},
                            isRadio: true,
                          ),
                          SizedBox(width: 8),
                          MyText(text: 'Circuit/Road Course', size: 14),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyText(text: 'Surface Type', size: 16, weight: FontWeight.w600),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          CustomCheckBox(
                            isActive: false,
                            onTap: () {},
                            isRadio: true,
                          ),
                          SizedBox(width: 8),
                          MyText(text: 'Tarmac/Paved', size: 14),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          CustomCheckBox(
                            isActive: false,
                            onTap: () {},
                            isRadio: true,
                          ),
                          SizedBox(width: 8),
                          MyText(text: 'Shale/Dirt/Grass', size: 14),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyText(
                  text: 'Weather Condition',
                  size: 16,
                  weight: FontWeight.w600,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          CustomCheckBox(
                            isActive: false,
                            onTap: () {},
                            isRadio: true,
                          ),
                          SizedBox(width: 8),
                          MyText(text: 'Dry', size: 14),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          CustomCheckBox(
                            isActive: false,
                            onTap: () {},
                            isRadio: true,
                          ),
                          SizedBox(width: 8),
                          MyText(text: 'Wet', size: 14),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: AppSizes.DEFAULT,
          child: MyButton(
            buttonText: 'Save Configuration',
            onTap: () {
              Get.offAll(() => BottomNavBar());
            },
          ),
        ),
      ),
    );
  }
}
