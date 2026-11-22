import 'package:motorsport/utils/motion.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:motorsport/view/widget/auth_hero.dart';
import 'package:motorsport/utils/validators.dart';
import 'package:get/get.dart';
import 'package:motorsport/config/routes/routes.dart';
import 'package:motorsport/constants/app_colors.dart';
import 'package:motorsport/constants/app_images.dart';
import 'package:motorsport/constants/app_sizes.dart';
import 'package:motorsport/controller/auth/login_controller.dart';
import 'package:motorsport/view/screens/auth/forgot_pass/forgot_pass.dart';
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
  // One controller per screen instance. A shared Get.put() would hand a
  // new Login screen the controller owned by an older one, which GetX
  // then deletes with the old route, leaving dead text fields behind.
  late final String _tag = 'login-${identityHashCode(this)}';
  late final LoginController controller = Get.put(LoginController(), tag: _tag);
  final _formKey = GlobalKey<FormState>();

  /// Errors appear only after the first submit, then update live as the
  /// user fixes them.
  bool _submitted = false;

  void _submit() {
    FocusScope.of(context).unfocus();
    setState(() => _submitted = true);
    if (_formKey.currentState?.validate() ?? false) {
      controller.loginWithEmail();
    }
  }

  @override
  void dispose() {
    Get.delete<LoginController>(tag: _tag);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: simpleAppBar(
        bgColor: Colors.transparent,title: 'Sign In', haveLeading: false),
      body: Stack(
        children: [
          const AuthHero(),
          Container(
            height: Get.height,
            width: Get.width,
            decoration: BoxDecoration(
            ),
          ),
          FadeInUp(
            delay: const Duration(milliseconds: 120),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: Get.height * 0.58,
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

                      // --- FIELDS ---
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
                          validator: AppValidators.loginPassword,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          onFieldSubmitted: (_) => _submit(),
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

                      // --- OPTIONS ---
                      Row(
                        children: [
                          Obx(
                            () => CustomCheckBox(
                              isActive: controller.rememberMe.value,
                              onTap: controller.toggleRememberMe,
                            ),
                          ),
                          Expanded(
                            child: MyText(
                              paddingLeft: 10,
                              text: 'Remember me',
                              size: 14,
                              color: kTertiaryColor,
                            ),
                          ),
                          MyText(
                            onTap: () => Get.to(() => const ForgotPassword()),
                            textAlign: TextAlign.end,
                            text: 'Forgot Password?',
                            weight: FontWeight.w600,
                            color: kSecondaryColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),

                      // --- LOGIN BTN ---
                      Obx(
                        () => controller.isLoading.value
                            ? Center(
                                child: CircularProgressIndicator(
                                  color: kSecondaryColor,
                                ),
                              )
                            : MyButton(buttonText: 'Login', onTap: _submit),
                      ),

                      const SizedBox(height: 20),
                      Image.asset(
                        Assets.imagesOr,
                        color: kTertiaryColor.withValues(alpha: 0.5),
                      ),

                      // --- SOCIAL LOGIN SECTION ---
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _SocialButton(
                            icon: Get.isDarkMode
                                ? Assets.imagesDarkGoogle
                                : Assets.imagesGoogle,
                            onTap: controller.loginGoogle,
                          ),
                          // Sign in with Apple — required by App Store on iOS
                          if (Platform.isIOS) ...[
                            const SizedBox(width: 20),
                            _SocialButton(
                              iconData: Icons.apple,
                              onTap: controller.loginApple,
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 30),
                      Center(
                        child: Wrap(
                          children: [
                            MyText(text: 'Don\'t have an account? ', size: 14),
                            MyText(
                              onTap: () => Get.offAllNamed(
                                AppLinks.signUp,
                              ), // Corrected this line
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
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper widget for cleaner code
class _SocialButton extends StatelessWidget {
  final String? icon;
  final IconData? iconData;
  final VoidCallback onTap;

  const _SocialButton({this.icon, this.iconData, required this.onTap});

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
