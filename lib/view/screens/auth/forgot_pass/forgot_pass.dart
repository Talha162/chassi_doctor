import 'package:motorsport/utils/motion.dart';
import 'package:motorsport/utils/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:motorsport/view/widget/auth_hero.dart';
import 'package:get/get.dart';
import 'package:motorsport/constants/app_colors.dart';
import 'package:motorsport/constants/app_sizes.dart';
import 'package:motorsport/services/auth/auth_service.dart';
import 'package:motorsport/view/screens/auth/login.dart';
import 'package:motorsport/view/widget/custom_app_bar_widget.dart';
import 'package:motorsport/view/widget/my_button_widget.dart';
import 'package:motorsport/view/widget/my_text_field_widget.dart';
import 'package:motorsport/view/widget/my_text_widget.dart';
import 'package:motorsport/utils/app_error.dart';
import 'package:motorsport/utils/validators.dart';
import 'package:motorsport/view/widget/app_dialog.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  bool _isSending = false;

  final _formKey = GlobalKey<FormState>();
  bool _submitted = false;

  Future<void> _sendResetLink() async {
    FocusScope.of(context).unfocus();
    setState(() => _submitted = true);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final email = AuthService.normalizeEmail(_emailController.text);

    setState(() => _isSending = true);
    try {
      await _authService.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      showAppDialog(
        title: 'Check your email',
        icon: Icons.mark_email_read_outlined,
        message:
            'If an account exists for $email, we\'ve sent a link to reset '
            'your password. Open it on this device.',
        primaryLabel: 'Back to Login',
        onPrimary: () => Get.offAll(() => const Login()),
      );
    } catch (e) {
      showErrorSnackbar(
        friendlyError(e),
        title: "Couldn't send the reset link",
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
      extendBodyBehindAppBar: true,
      appBar: simpleAppBar(
        bgColor: Colors.transparent,
        title: 'Forgot Password',
        onLeadingTap: () {
          Get.offAll(() => const Login());
        },
      ),
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
                height: Get.height * 0.44,
                decoration: BoxDecoration(
                  color: kQuaternaryColor,
                  borderRadius: BorderRadius.only(
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
                        keyboardType: TextInputType.emailAddress,
                        validator: AppValidators.email,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _sendResetLink(),
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
            ),
          ),
        ],
      ),
    );
  }
}
