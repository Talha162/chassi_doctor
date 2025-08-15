import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:motorsport/constants/app_colors.dart';
import 'package:motorsport/constants/app_fonts.dart';
import 'package:motorsport/constants/app_images.dart';
import 'package:motorsport/constants/app_sizes.dart';
import 'package:motorsport/view/screens/auth/forgot_pass/create_new_pass.dart';
import 'package:motorsport/view/screens/auth/forgot_pass/forgot_pass.dart';
import 'package:motorsport/view/screens/auth/sign_up/sign_up.dart';
import 'package:motorsport/view/screens/launch/onboarding.dart';
import 'package:motorsport/view/widget/custom_app_bar_widget.dart';
import 'package:motorsport/view/widget/my_button_widget.dart';
import 'package:motorsport/view/widget/my_text_widget.dart';
import 'package:pinput/pinput.dart';

class EmailVerification extends StatefulWidget {
  const EmailVerification({super.key});

  @override
  State<EmailVerification> createState() => _EmailVerificationState();
}

class _EmailVerificationState extends State<EmailVerification> {
  String pinStatus = 'default'; // 'default', 'verified', 'invalid'
  String pinValue = '';
  int resendSeconds = 28;
  final TextEditingController _pinController = TextEditingController();

  Color getPinTextColor() {
    switch (pinStatus) {
      case 'invalid':
        return Color(0xFFF73434);
      default:
        return kTertiaryColor;
    }
  }

  void _onPinChanged(String value) {
    setState(() {
      pinValue = value;
      if (value.length == 5) {
        if (value == '12345') {
          pinStatus = 'verified';
        } else {
          pinStatus = 'invalid';
        }
      } else {
        pinStatus = 'default';
      }
    });
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      Get.bottomSheet(
        _OTPBottomSheet(
          pinStatus: pinStatus,
          pinValue: pinValue,
          pinController: _pinController,
          onPinChanged: _onPinChanged,
          onVerify: () {
            Get.to(() => Onboarding());
          },
        ),
        backgroundColor: Colors.transparent,
        barrierColor: Colors.transparent,
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
        title: 'Verification',
        onLeadingTap: () {
          Get.offAll(() => SignUp());
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

class _OTPBottomSheet extends StatelessWidget {
  final String pinStatus;
  final String pinValue;
  final TextEditingController pinController;
  final ValueChanged<String> onPinChanged;
  final VoidCallback onVerify;

  const _OTPBottomSheet({
    required this.pinStatus,
    required this.pinValue,
    required this.pinController,
    required this.onPinChanged,
    required this.onVerify,
  });

  Color getPinTextColor() {
    switch (pinStatus) {
      case 'invalid':
        return Color(0xFFF73434);
      default:
        return kTertiaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final PinTheme pinTheme = PinTheme(
      width: 56,
      height: 56,
      margin: EdgeInsets.zero,
      textStyle: TextStyle(
        fontSize: 20,
        height: 0.0,
        fontWeight: FontWeight.w600,
        fontFamily: AppFonts.ROBOTO,
        color: getPinTextColor(),
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: kTertiaryColor.withValues(alpha: 0.1),
      ),
    );

    return Container(
      height: 340,
      margin: EdgeInsets.only(top: 60),
      decoration: BoxDecoration(
        color: kQuaternaryColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: ListView(
        shrinkWrap: true,
        padding: AppSizes.DEFAULT,
        physics: BouncingScrollPhysics(),
        children: [
          MyText(
            text: 'Verify it\'s you',
            paddingTop: 8,
            size: 24,
            weight: FontWeight.w600,
            paddingBottom: 8,
          ),
          MyText(
            text: 'Enter the 4-digit code we sent to your email.',
            size: 16,
            lineHeight: 1.5,
            weight: FontWeight.w500,
            color: kTertiaryColor.withValues(alpha: 0.8),
            paddingBottom: 30,
          ),
          Pinput(
            keyboardType: TextInputType.number,
            length: 4,
            controller: pinController,
            onChanged: onPinChanged,
            pinContentAlignment: Alignment.center,
            defaultPinTheme: pinTheme,
            focusedPinTheme: pinTheme,
            submittedPinTheme: pinTheme,
            mainAxisAlignment: MainAxisAlignment.center,
            onCompleted: onPinChanged,
          ),
          if (pinStatus == 'invalid')
            MyText(
              textAlign: TextAlign.end,
              text: 'Wrong Code, Try Again',
              color: Color(0xFFF73434),
              size: 16,
              weight: FontWeight.w600,
              paddingTop: 10,
            ),
          SizedBox(height: 50),
          MyButton(buttonText: 'Verify & Continue', onTap: onVerify),
          SizedBox(height: 30),
          Center(
            child: Wrap(
              children: [
                MyText(
                  text: 'Didn’t receive the code? ',
                  size: 16,
                  weight: FontWeight.w500,
                ),
                MyText(
                  onTap: () {},
                  text: 'Resend',
                  weight: FontWeight.w600,
                  color: kSecondaryColor,
                  size: 16,
                ),
              ],
            ),
          ),
          SizedBox(height: 120),
        ],
      ),
    );
  }
}
