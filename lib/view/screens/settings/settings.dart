import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/utils.dart';
import 'package:motorsport/constants/app_colors.dart';
import 'package:motorsport/main.dart';
import 'package:motorsport/view/screens/settings/privacy_policy.dart';
import 'package:motorsport/view/widget/common_image_view_widget.dart';
import 'package:motorsport/view/widget/my_text_widget.dart';
import 'package:motorsport/view/widget/custom_tile_widget.dart';
import 'package:motorsport/constants/app_images.dart';
import 'package:motorsport/constants/app_sizes.dart';
import 'package:motorsport/view/widget/custom_app_bar_widget.dart';

class Settings extends StatelessWidget {
  const Settings({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: simpleAppBar(title: 'Settings'),
      body: ListView(
        shrinkWrap: true,
        padding: AppSizes.DEFAULT,
        physics: BouncingScrollPhysics(),
        children: [
          SizedBox(height: 16),
          Center(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: kSecondaryColor, // Change color as needed
                  width: 4,
                ),
                shape: BoxShape.circle,
              ),
              child: CommonImageView(
                height: 120,
                width: 120,
                radius: 100,
                url: dummyImg,
              ),
            ),
          ),
          SizedBox(height: 12),
          MyText(
            text: 'Rayan Ali',
            size: 18,
            weight: FontWeight.bold,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          MyText(
            text: 'Rayan.Ali@gmail.com',
            size: 14,
            textAlign: TextAlign.center,
            color: kTertiaryColor.withValues(alpha: 0.8),
            paddingBottom: 30,
          ),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kQuaternaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SettingsTile(
                  imagePath: Assets.imagesProfile,
                  title: 'Profile information',
                  onTap: () {},
                ),
                _Divider(),
                _SettingsTile(
                  imagePath: Assets.imagesNotifications,
                  title: 'Push notification',
                  trailing: Transform.scale(
                    scale: 0.65,
                    alignment: Alignment.centerRight,
                    child: Container(
                      margin: EdgeInsets.only(right: 10),
                      height: 20 / 0.65,
                      width: 20 / 0.65,
                      child: CupertinoSwitch(
                        value: true,
                        thumbColor: kPrimaryColor,
                        activeTrackColor: kSecondaryColor,
                        onChanged: (bool value) {},
                      ),
                    ),
                  ),
                  onTap: () {},
                ),
                _Divider(),

                _SettingsTile(
                  imagePath: Assets.imagesSave,
                  title: 'Save setup history',
                  onTap: () {},
                ),
                _Divider(),

                _SettingsTile(
                  imagePath: Assets.imagesData,
                  title: 'Data and Privacy Setting',
                  onTap: () {
                    Get.to(() => PrivacyPolicy());
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kQuaternaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SettingsTile(
                  imagePath: Assets.imagesLogout,
                  title: 'Logout',
                  onTap: () {
                    showCupertinoModalPopup(
                      context: context,
                      builder: (context) => Theme(
                        data: Theme.of(context).copyWith(
                          cupertinoOverrideTheme: const CupertinoThemeData(
                            scaffoldBackgroundColor: kPrimaryColor,
                          ),
                        ),

                        child: CupertinoAlertDialog(
                          title: Column(
                            children: [
                              Image.asset(Assets.imagesLogoutIcon, height: 38),
                              SizedBox(height: 8),
                              MyText(
                                text: 'Logout',
                                size: 16,
                                color: Colors.black,
                                weight: FontWeight.w700,
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 6),
                              MyText(
                                text: 'Do you really want to logout?',
                                size: 12,
                                color: Colors.black,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                          content: Container(),
                          actions: [
                            CupertinoDialogAction(
                              child: MyText(
                                text: 'Cancel',
                                size: 14,
                                color: Colors.black,
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                            CupertinoDialogAction(
                              child: MyText(
                                text: 'Logout',
                                size: 14,
                                color: CupertinoColors.destructiveRed,
                              ),
                              isDestructiveAction: true,
                              onPressed: () {
                                // Add your logout logic here
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                _Divider(),

                _SettingsTile(
                  imagePath: Assets.imagesDelete,
                  title: 'Delete Account',
                  onTap: () {
                    showCupertinoModalPopup(
                      context: context,
                      builder: (context) => Theme(
                        data: Theme.of(context).copyWith(
                          cupertinoOverrideTheme: const CupertinoThemeData(
                            scaffoldBackgroundColor: kPrimaryColor,
                          ),
                        ),

                        child: CupertinoAlertDialog(
                          title: Column(
                            children: [
                              Image.asset(
                                Assets.imagesDeleteProfile,
                                height: 38,
                              ),
                              SizedBox(height: 8),
                              MyText(
                                text: 'Delete Account',
                                size: 16,
                                color: Colors.black,
                                weight: FontWeight.w700,
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 6),
                              MyText(
                                text:
                                    'Are you sure you want to delete your account? This will permanently erase your account.',
                                size: 12,
                                color: Colors.black,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                          content: Container(),
                          actions: [
                            CupertinoDialogAction(
                              child: MyText(
                                text: 'Cancel',
                                size: 14,
                                color: Colors.black,
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                            CupertinoDialogAction(
                              child: MyText(
                                text: 'Delete',
                                size: 14,
                                color: CupertinoColors.destructiveRed,
                              ),
                              isDestructiveAction: true,
                              onPressed: () {
                                // Add your logout logic here
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String imagePath;
  final String title;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _SettingsTile({
    Key? key,
    required this.imagePath,
    required this.title,
    this.onTap,
    this.trailing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Image.asset(imagePath, height: 24),
          SizedBox(width: 12),
          Expanded(
            child: MyText(text: title, size: 16, weight: FontWeight.w500),
          ),
          trailing ?? SizedBox(),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      color: Color(0xff4B3B73),
      margin: EdgeInsets.symmetric(vertical: 12),
    );
  }
}
