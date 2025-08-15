import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:motorsport/constants/app_colors.dart';
import 'package:motorsport/constants/app_images.dart';
import 'package:motorsport/constants/app_sizes.dart';
import 'package:motorsport/view/screens/auth/login.dart';
import 'package:motorsport/view/screens/auth/forgot_pass/otp_verification.dart';
import 'package:motorsport/view/widget/custom_app_bar_widget.dart';
import 'package:motorsport/view/widget/my_button_widget.dart';
import 'package:motorsport/view/widget/my_text_field_widget.dart';
import 'package:motorsport/view/widget/my_text_widget.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      Get.bottomSheet(
        _ForgotPassword(),
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
      appBar: simpleAppBar(
        title: 'Forget Password',
        onLeadingTap: () {
          Get.offAll(() => Login());
        },
      ),
      body: Container(
        height: Get.height,
        width: Get.width,
        decoration: BoxDecoration(
          color: kPrimaryColor,
          image: DecorationImage(
            image: AssetImage(Assets.imagesCar),
            alignment: Alignment(0, -0.65),
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

class _ForgotPassword extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 60),
      height: Get.height * 0.44,
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
            text: 'Forgot your password?',
            paddingTop: 12,
            size: 20,
            weight: FontWeight.w600,
            paddingBottom: 8,
          ),
          MyText(
            text:
                'Enter your email address below and we\'ll send you instructions to reset your password.',
            size: 14,
            color: kTertiaryColor.withValues(alpha: 0.8),
            lineHeight: 1.5,
            weight: FontWeight.w500,
            paddingBottom: 30,
          ),
          MyTextField(
            marginBottom: 30,
            labelText: 'Email Address',
            hintText: 'example@gmail.com',
            fillColor: kTertiaryColor.withValues(alpha: 0.1),
          ),
          MyButton(
            buttonText: 'Send Code',
            onTap: () {
              Get.to(() => OTPVerification());
            },
          ),

          SizedBox(height: 30),
          Center(
            child: Wrap(
              children: [
                MyText(text: 'Remember your password? ', size: 14),
                MyText(
                  onTap: () {
                    Get.back();
                  },
                  text: 'Login',
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
