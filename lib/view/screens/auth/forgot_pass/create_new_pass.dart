import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:motorsport/constants/app_colors.dart';
import 'package:motorsport/constants/app_images.dart';
import 'package:motorsport/constants/app_sizes.dart';
import 'package:motorsport/view/screens/auth/forgot_pass/forgot_pass.dart';
import 'package:motorsport/view/screens/auth/login.dart';
import 'package:motorsport/view/widget/custom_app_bar_widget.dart';
import 'package:motorsport/view/widget/my_button_widget.dart';
import 'package:motorsport/view/widget/my_text_field_widget.dart';
import 'package:motorsport/view/widget/my_text_widget.dart';

class CreateNewPass extends StatefulWidget {
  const CreateNewPass({super.key});

  @override
  State<CreateNewPass> createState() => _CreateNewPassState();
}

class _CreateNewPassState extends State<CreateNewPass> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      Get.bottomSheet(
        _NewPassword(),
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
        title: 'New Password',
        onLeadingTap: () {
          Get.offAll(() => ForgotPassword());
        },
      ),
      body: Container(
        height: Get.height,
        width: Get.width,
        decoration: BoxDecoration(
          color: kPrimaryColor,
          image: DecorationImage(
            image: AssetImage(Assets.imagesCar),
            alignment: Alignment(0, -0.75),
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

class _NewPassword extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 60),
      height: Get.height * 0.48,
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
            text: 'Create New Password',
            paddingTop: 12,
            size: 20,
            weight: FontWeight.w600,
            paddingBottom: 8,
          ),
          MyText(
            text:
                'Set a new password for your account. Make sure it\'s strong and secure.',
            size: 14,
            color: kTertiaryColor.withValues(alpha: 0.8),
            lineHeight: 1.5,
            weight: FontWeight.w500,
            paddingBottom: 30,
          ),
          MyTextField(
            labelText: 'Enter Password',
            hintText: '*********',
            fillColor: kTertiaryColor.withValues(alpha: 0.1),
          ),
          MyTextField(
            marginBottom: 30,
            labelText: 'Confirm your Password',
            hintText: '*********',
            fillColor: kTertiaryColor.withValues(alpha: 0.1),
          ),
          MyButton(
            buttonText: 'Submit',
            onTap: () {
              Get.offAll(() => Login());
            },
          ),
        ],
      ),
    );
  }
}
