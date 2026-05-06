import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:motorsport/constants/app_colors.dart';
import 'package:motorsport/constants/app_images.dart';
import 'package:motorsport/constants/app_sizes.dart';
import 'package:motorsport/services/auth/auth_service.dart';
import 'package:motorsport/view/screens/auth/login.dart';
import 'package:motorsport/view/widget/custom_app_bar_widget.dart';
import 'package:motorsport/view/widget/my_button_widget.dart';
import 'package:motorsport/view/widget/my_text_field_widget.dart';
import 'package:motorsport/view/widget/my_text_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  bool _isSending = false;

  Future<void> _sendResetLink() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      Get.snackbar(
        'Missing Email',
        'Enter your email address first.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() => _isSending = true);
    try {
      await _authService.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      Get.dialog(
        AlertDialog(
          title: const Text('Check Your Email'),
          content: Text(
            'We sent a password reset link to $email. Open it on this device to set a new password.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Get.back();
                Get.offAll(() => const Login());
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } on AuthException catch (e) {
      Get.snackbar(
        'Reset Failed',
        e.message,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Reset Failed',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: simpleAppBar(
        title: 'Forgot Password',
        onLeadingTap: () {
          Get.offAll(() => const Login());
        },
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
            child: Container(
              height: Get.height * 0.44,
              decoration:  BoxDecoration(
                color: kQuaternaryColor,
                borderRadius: BorderRadius.only(
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
                    text: 'Forgot your password?',
                    paddingTop: 12,
                    size: 20,
                    weight: FontWeight.w600,
                    paddingBottom: 8,
                  ),
                  MyText(
                    text:
                        'Enter your email address below and we\'ll send you a password reset link.',
                    size: 14,
                    color: kTertiaryColor.withValues(alpha: 0.8),
                    lineHeight: 1.5,
                    weight: FontWeight.w500,
                    paddingBottom: 30,
                  ),
                  MyTextField(
                    controller: _emailController,
                    marginBottom: 30,
                    labelText: 'Email Address',
                    hintText: 'example@gmail.com',
                    fillColor: kTertiaryColor.withValues(alpha: 0.1),
                  ),
                  _isSending
                      ? const Center(child: CircularProgressIndicator())
                      : MyButton(
                          buttonText: 'Send Reset Link',
                          onTap: _sendResetLink,
                        ),
                  const SizedBox(height: 30),
                  Center(
                    child: Wrap(
                      children: [
                        MyText(text: 'Remember your password? ', size: 14),
                        MyText(
                          onTap: () {
                            Get.offAll(() => const Login());
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
            ),
          ),
        ],
      ),
    );
  }
}
