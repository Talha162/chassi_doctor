import 'package:motorsport/utils/motion.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:motorsport/utils/validators.dart';
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
  // One controller per screen instance. A shared Get.put() would hand a
  // new SignUp screen the controller owned by an older one, which GetX
  // then deletes with the old route, leaving dead text fields behind.
  late final String _tag = 'signup-${identityHashCode(this)}';
  late final SignUpController controller = Get.put(SignUpController(), tag: _tag);
  final _formKey = GlobalKey<FormState>();
  bool _submitted = false;

  void _submit() {
    FocusScope.of(context).unfocus();
    setState(() => _submitted = true);
    if (_formKey.currentState?.validate() ?? false) {
      controller.signUp();
    }
  }

  @override
  void dispose() {
    Get.delete<SignUpController>(tag: _tag);
    super.dispose();
  }

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
          FadeInUp(
            delay: const Duration(milliseconds: 120),
            child: Align(
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
                child: Form(
                  key: _formKey,
                  autovalidateMode: _submitted
                      ? AutovalidateMode.onUserInteraction
                      : AutovalidateMode.disabled,
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
                        validator: AppValidators.fullName,
                        autofillHints: const [AutofillHints.name],
                        maxLength: 60,
                        hintText: 'John Doe',
                        fillColor: kTertiaryColor.withValues(alpha: 0.1),
                      ),
                      MyTextField(
                        controller: controller.emailController,
                        labelText: 'Email Address',
                        keyboardType: TextInputType.emailAddress,
                        validator: AppValidators.email,
                        hintText: 'example@gmail.com',
                        fillColor: kTertiaryColor.withValues(alpha: 0.1),
                      ),
                      Obx(
                        () => MyTextField(
                          controller: controller.passwordController,
                          marginBottom: 16,
                          labelText: 'Password',
                          validator: AppValidators.newPassword,
                          autofillHints: const [AutofillHints.newPassword],
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
                        ),
                      ),
                      Obx(
                        () => MyTextField(
                          controller: controller.confirmPasswordController,
                          marginBottom: 0,
                          labelText: 'Confirm Password',
                          validator: AppValidators.confirmPassword(
                            () => controller.passwordController.text,
                          ),
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
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
                                  color:
                                      controller.isConfirmPasswordVisible.value
                                      ? kSecondaryColor
                                      : kTertiaryColor.withValues(alpha: 0.4),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),
                      Obx(
                        () => controller.isLoading.value
                            ? Center(
                                child: CircularProgressIndicator(
                                  color: kSecondaryColor,
                                ),
                              )
                            : MyButton(buttonText: 'Sign Up', onTap: _submit),
                      ),

                      const SizedBox(height: 20),
                      Image.asset(
                        Assets.imagesOr,
                        color: kTertiaryColor.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 20),

                      // SOCIAL
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _SocialBtn(
                            icon: Get.isDarkMode
                                ? Assets.imagesDarkGoogle
                                : Assets.imagesGoogle,
                            onTap: controller.signUpGoogle,
                          ),
                          // Sign up with Apple — required by App Store on iOS
                          if (Platform.isIOS) ...[
                            const SizedBox(width: 20),
                            _SocialBtn(
                              iconData: Icons.apple,
                              onTap: controller.signUpApple,
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 30),
                      Center(
                        child: Wrap(
                          children: [
                            MyText(text: 'Already have an account? ', size: 14),
                            MyText(
                              onTap: () => Get.offAllNamed(
                                AppLinks.login,
                              ), // Corrected this line
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
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialBtn extends StatelessWidget {
  final String? icon;
  final IconData? iconData;
  final VoidCallback onTap;
  const _SocialBtn({this.icon, this.iconData, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 60,
        width: 60,
        decoration: BoxDecoration(
          color: kBorderColor2,
          shape: BoxShape.circle,
          border: Border.all(
            color: kWhiteColor.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
        child: Center(
          child: iconData != null
              ? Icon(iconData, size: 32, color: kWhiteColor)
              : Image.asset(icon!, height: 30, width: 30, fit: BoxFit.contain),
        ),
      ),
    );
  }
}
