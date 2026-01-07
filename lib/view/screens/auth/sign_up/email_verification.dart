import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:motorsport/constants/app_colors.dart';
import 'package:motorsport/constants/app_fonts.dart';
import 'package:motorsport/constants/app_images.dart';
import 'package:motorsport/constants/app_sizes.dart';
import 'package:motorsport/view/screens/auth/sign_up/sign_up.dart';
import 'package:motorsport/view/widget/custom_app_bar_widget.dart';
import 'package:motorsport/view/widget/my_button_widget.dart';
import 'package:motorsport/view/widget/my_text_widget.dart';
import 'package:pinput/pinput.dart';

import '../../../../controller/auth/verification_conroller.dart';

class EmailVerification extends StatefulWidget {
  final String? email;
  const EmailVerification({super.key, this.email});

  @override
  State<EmailVerification> createState() => _EmailVerificationState();
}

class _EmailVerificationState extends State<EmailVerification> {
  late VerificationController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(VerificationController());
    if (widget.email != null) controller.email = widget.email!;
  }

  @override
  Widget build(BuildContext context) {
    // Helper to get color based on status
    Color getPinTextColor(String status) {
      return status == 'invalid' ? const Color(0xFFF73434) : kTertiaryColor;
    }

    final pinTheme = PinTheme(
      width: 56,
      height: 56,
      margin: EdgeInsets.zero,
      textStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        fontFamily: AppFonts.ROBOTO,
        color: getPinTextColor(controller.pinStatus.value),
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: kTertiaryColor.withValues(alpha: 0.1),
      ),
    );

    return Scaffold(
      appBar: simpleAppBar(
        title: 'Verification',
        onLeadingTap: () => Get.offAll(() => const SignUp()),
      ),
      body: Stack(
        children: [
          Container(
            height: Get.height,
            width: Get.width,
            decoration: BoxDecoration(
              color: kPrimaryColor,
              image: DecorationImage(
                image: AssetImage(Assets.imagesCar),
                alignment: const Alignment(0, -0.65),
                fit: BoxFit.contain,
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Obx(() => Container(
                  height: Get.height * 0.55,
                  decoration: BoxDecoration(
                    color: kQuaternaryColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: ListView(
                    shrinkWrap: true,
                    padding: AppSizes.DEFAULT,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      MyText(
                        text: 'Verify it\'s you',
                        paddingTop: 8,
                        size: 24,
                        weight: FontWeight.w600,
                        paddingBottom: 8,
                      ),
                      MyText(
                        text: 'Enter the 6-digit code we sent to ${controller.email}',
                        size: 16,
                        lineHeight: 1.5,
                        weight: FontWeight.w500,
                        color: kTertiaryColor.withValues(alpha: 0.8),
                        paddingBottom: 30,
                      ),
                      Pinput(
                        keyboardType: TextInputType.number,
                        length: 6, // Supabase default is usually 6 digits
                        controller: controller.pinController,
                        onChanged: controller.onPinChanged,
                        pinContentAlignment: Alignment.center,
                        defaultPinTheme: pinTheme,
                        focusedPinTheme: pinTheme,
                        submittedPinTheme: pinTheme,
                        mainAxisAlignment: MainAxisAlignment.center,
                        onCompleted: (val) => controller.verifyOtp(),
                      ),
                      if (controller.pinStatus.value == 'invalid')
                        MyText(
                          textAlign: TextAlign.end,
                          text: 'Wrong Code, Try Again',
                          color: const Color(0xFFF73434),
                          size: 16,
                          weight: FontWeight.w600,
                          paddingTop: 10,
                        ),
                      const SizedBox(height: 50),
                      controller.isLoading.value
                          ? Center(
                              child: CircularProgressIndicator(
                                  color: kSecondaryColor))
                          : MyButton(
                              buttonText: 'Verify & Continue',
                              onTap: controller.verifyOtp),
                      const SizedBox(height: 30),
                      Center(
                        child: Wrap(
                          children: [
                            MyText(
                              text: 'Didn’t receive the code? ',
                              size: 16,
                              weight: FontWeight.w500,
                            ),
                            MyText(
                              onTap: controller.resendSeconds.value > 0
                                  ? null
                                  : controller.resendCode,
                              text: controller.resendSeconds.value > 0
                                  ? 'Resend in ${controller.resendSeconds.value}s'
                                  : 'Resend',
                              weight: FontWeight.w600,
                              color: controller.resendSeconds.value > 0
                                  ? kTertiaryColor.withOpacity(0.5)
                                  : kSecondaryColor,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
          )
        ],
      ),
    );
  }
}
