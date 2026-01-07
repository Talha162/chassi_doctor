import 'package:flutter/material.dart';
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
  final LoginController controller = Get.put(LoginController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: simpleAppBar(title: 'Sign In', haveLeading: false),
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
              height: Get.height * 0.58,
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

                  // --- OPTIONS ---
                  Row(
                    children: [
                      Obx(() => CustomCheckBox(
                          isActive: controller.rememberMe.value,
                          onTap: controller.toggleRememberMe)),
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
                  Obx(() => controller.isLoading.value
                      ? Center(
                          child: CircularProgressIndicator(
                              color: kSecondaryColor))
                      : MyButton(
                          buttonText: 'Login',
                          onTap: controller.loginWithEmail,
                        )),

                  const SizedBox(height: 20),
                  Image.asset(
                    Assets.imagesOr,
                    color: kTertiaryColor.withValues(alpha: 0.5),
                  ),

                  // --- SOCIAL LOGIN SECTION ---
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _SocialButton(
                        icon: Get.isDarkMode
                            ? Assets.imagesDarkGoogle
                            : Assets.imagesGoogle,
                        onTap: controller.loginGoogle,
                      ),
                      _SocialButton(
                        icon: Get.isDarkMode
                            ? Assets.imagesDarkApple
                            : Assets.imagesApple,
                        onTap: controller.loginGoogle,
                      ),
                      _SocialButton(
                        icon: Get.isDarkMode
                            ? Assets.imagesDarkFacebooj
                            : Assets.imagesFacebook,
                        onTap: controller.loginFacebook,
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),
                  Center(
                    child: Wrap(
                      children: [
                        MyText(text: 'Don\'t have an account? ', size: 14),
                        MyText(
                          onTap: () => Get.offAllNamed(AppLinks.signUp), // Corrected this line
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
        ],
      ),
    );
  }
}

// Helper widget for cleaner code
class _SocialButton extends StatelessWidget {
  final String icon;
  final VoidCallback onTap;

  const _SocialButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Image.asset(
        icon,
        height: 48,
      ),
    );
  }
}
