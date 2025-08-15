import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:motorsport/constants/app_colors.dart';
import 'package:motorsport/constants/app_images.dart';
import 'package:motorsport/constants/app_sizes.dart';
import 'package:motorsport/view/screens/auth/forgot_pass/forgot_pass.dart';
import 'package:motorsport/view/screens/auth/sign_up/sign_up.dart';
import 'package:motorsport/view/screens/bottom_nav_bar/bottom_nav_bar.dart';
import 'package:motorsport/view/widget/custom_app_bar_widget.dart';
import 'package:motorsport/view/widget/custom_check_box_widget.dart';
import 'package:motorsport/view/widget/my_button_widget.dart';
import 'package:motorsport/view/widget/my_text_field_widget.dart';
import 'package:motorsport/view/widget/my_text_widget.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      Get.bottomSheet(
        _LoginBottomSheet(),
        barrierColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        isDismissible: false,
        enableDrag: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        clipBehavior: Clip.antiAlias,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: simpleAppBar(title: 'Sign In', haveLeading: false),
      body: Container(
        height: Get.height,
        width: Get.width,
        decoration: BoxDecoration(
          color: kPrimaryColor,
          image: DecorationImage(
            image: AssetImage(Assets.imagesCar),
            alignment: Alignment(0, -1),
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

class _LoginBottomSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 60),
      height: Get.height * 0.58,
      decoration: BoxDecoration(
        color: kQuaternaryColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: ListView(
        shrinkWrap: true,
        padding: AppSizes.DEFAULT,
        physics: BouncingScrollPhysics(),
        children: [
          MyText(
            text: 'Kindly enter your credentials',
            paddingTop: 12,
            size: 20,
            weight: FontWeight.w600,
            paddingBottom: 8,
          ),
          MyText(
            text:
                'Connect with motorsport fans, join communities, and grow your circle.',
            size: 14,
            color: kTertiaryColor.withValues(alpha: 0.8),
            lineHeight: 1.5,
            weight: FontWeight.w500,
            paddingBottom: 30,
          ),
          MyTextField(
            labelText: 'Email Address',
            hintText: 'example@gmail.com',
            fillColor: kTertiaryColor.withValues(alpha: 0.1),
          ),
          MyTextField(
            marginBottom: 16,
            labelText: 'Password',
            hintText: '********',
            fillColor: kTertiaryColor.withValues(alpha: 0.1),
            suffix: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  Assets.imagesVisibility,
                  height: 20,
                  color: kTertiaryColor.withValues(alpha: 0.4),
                ),
              ],
            ),
          ),
          Row(
            children: [
              CustomCheckBox(isActive: true, onTap: () {}),
              Expanded(
                child: MyText(
                  paddingLeft: 10,
                  text: 'Remember me',
                  size: 14,
                  color: kTertiaryColor,
                ),
              ),
              MyText(
                onTap: () {
                  Get.to(() => ForgotPassword());
                },
                textAlign: TextAlign.end,
                text: 'Forgot Password?',
                weight: FontWeight.w600,
                color: kSecondaryColor,
              ),
            ],
          ),
          SizedBox(height: 30),
          MyButton(
            buttonText: 'Login',
            onTap: () {
              Get.offAll(() => BottomNavBar());
            },
          ),
          SizedBox(height: 20),
          Image.asset(
            Assets.imagesOr,
            color: kTertiaryColor.withValues(alpha: 0.5),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(3, (index) {
              return Image.asset(
                [
                  Assets.imagesGoogle,
                  Assets.imagesApple,
                  Assets.imagesFacebook,
                ][index],
                height: 48,
              );
            }),
          ),

          SizedBox(height: 30),
          Center(
            child: Wrap(
              children: [
                MyText(text: 'Don\'t have an account? ', size: 14),
                MyText(
                  onTap: () {
                    Get.offAll(() => SignUp());
                  },
                  text: 'Sign Up',
                  weight: FontWeight.w600,
                  color: kSecondaryColor,
                  size: 14,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
