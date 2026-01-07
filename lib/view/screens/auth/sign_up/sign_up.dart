import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:motorsport/config/routes/routes.dart';
import 'package:motorsport/constants/app_colors.dart';
import 'package:motorsport/constants/app_images.dart';
import 'package:motorsport/constants/app_sizes.dart';
import 'package:motorsport/view/widget/custom_app_bar_widget.dart';
import 'package:motorsport/view/widget/my_button_widget.dart';
import 'package:motorsport/view/widget/my_text_field_widget.dart';
import 'package:motorsport/view/widget/my_text_widget.dart';

import '../../../../controller/auth/signup_controller.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final SignUpController controller = Get.put(SignUpController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: simpleAppBar(title: 'Sign Up', haveLeading: false),
      body: Stack(
        children: [
          Container(
            height: Get.height,
            width: Get.width,
            decoration: BoxDecoration(
              color: kPrimaryColor,
              image: DecorationImage(
                image: AssetImage(Assets.imagesCar),
                alignment: const Alignment(0, -1),
                fit: BoxFit.contain,
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: Get.height * 0.7, // Increased height
              decoration: BoxDecoration(
                color: kQuaternaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: ListView(
                shrinkWrap: true,
                padding: AppSizes.DEFAULT,
                physics: const BouncingScrollPhysics(),
                children: [
                  MyText(
                    text: 'Create your account',
                    paddingTop: 12,
                    size: 20,
                    weight: FontWeight.w600,
                    paddingBottom: 8,
                  ),
                  MyText(
                    text:
                        'Join motorsport fans, create communities, and expand your network.',
                    size: 14,
                    color: kTertiaryColor.withValues(alpha: 0.8),
                    lineHeight: 1.5,
                    weight: FontWeight.w500,
                    paddingBottom: 30,
                  ),

                  // FIELDS
                  MyTextField(
                    controller: controller.fullNameController,
                    labelText: 'Full Name',
                    hintText: 'John Doe',
                    fillColor: kTertiaryColor.withValues(alpha: 0.1),
                  ),
                  MyTextField(
                    controller: controller.emailController,
                    labelText: 'Email Address',
                    hintText: 'example@gmail.com',
                    fillColor: kTertiaryColor.withValues(alpha: 0.1),
                  ),
                  Obx(() => MyTextField(
                        controller: controller.passwordController,
                        marginBottom: 16,
                        labelText: 'Password',
                        hintText: '********',
                        fillColor: kTertiaryColor.withValues(alpha: 0.1),
                        isObSecure: !controller.isPasswordVisible.value,
                        suffix: GestureDetector(
                          onTap: controller.togglePasswordVisibility,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                Assets.imagesVisibility,
                                height: 20,
                                color: controller.isPasswordVisible.value
                                    ? kSecondaryColor
                                    : kTertiaryColor.withValues(alpha: 0.4),
                              ),
                            ],
                          ),
                        ),
                      )),
                  Obx(() => MyTextField(
                        controller: controller.confirmPasswordController,
                        marginBottom: 0,
                        labelText: 'Confirm Password',
                        hintText: '********',
                        fillColor: kTertiaryColor.withValues(alpha: 0.1),
                        isObSecure:
                            !controller.isConfirmPasswordVisible.value,
                        suffix: GestureDetector(
                          onTap: controller.toggleConfirmPasswordVisibility,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                Assets.imagesVisibility,
                                height: 20,
                                color: controller.isConfirmPasswordVisible.value
                                    ? kSecondaryColor
                                    : kTertiaryColor.withValues(alpha: 0.4),
                              ),
                            ],
                          ),
                        ),
                      )),

                  const SizedBox(height: 30),
                  Obx(() => controller.isLoading.value
                      ? Center(
                          child: CircularProgressIndicator(
                              color: kSecondaryColor))
                      : MyButton(
                          buttonText: 'Sign Up',
                          onTap: controller.signUp,
                        )),

                  const SizedBox(height: 20),
                  Image.asset(
                    Assets.imagesOr,
                    color: kTertiaryColor.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 20),

                  // SOCIAL
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _SocialBtn(
                        icon: Get.isDarkMode
                            ? Assets.imagesDarkGoogle
                            : Assets.imagesGoogle,
                        onTap: controller.signUpGoogle,
                      ),
                      _SocialBtn(
                        icon: Get.isDarkMode
                            ? Assets.imagesDarkApple
                            : Assets.imagesApple,
                        onTap: controller.signUpGoogle,
                      ),
                      _SocialBtn(
                        icon: Get.isDarkMode
                            ? Assets.imagesDarkFacebooj
                            : Assets.imagesFacebook,
                        onTap: controller.signUpFacebook,
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),
                  Center(
                    child: Wrap(
                      children: [
                        MyText(text: 'Already have an account? ', size: 14),
                        MyText(
                          onTap: () => Get.offAllNamed(AppLinks.login), // Corrected this line
                          text: 'Sign In',
                          weight: FontWeight.w600,
                          color: kSecondaryColor,
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialBtn extends StatelessWidget {
  final String icon;
  final VoidCallback onTap;
  const _SocialBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Image.asset(icon, height: 48),
    );
  }
}
