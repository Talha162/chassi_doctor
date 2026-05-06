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

class CreateNewPass extends StatefulWidget {
  const CreateNewPass({super.key});

  @override
  State<CreateNewPass> createState() => _CreateNewPassState();
}

class _CreateNewPassState extends State<CreateNewPass> {
  final AuthService _authService = AuthService();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isSubmitting = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  Future<void> _submit() async {
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (password.isEmpty || confirmPassword.isEmpty) {
      Get.snackbar(
        'Missing Password',
        'Enter and confirm your new password.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (password != confirmPassword) {
      Get.snackbar(
        'Password Mismatch',
        'Both password fields must match.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (password.length < 6) {
      Get.snackbar(
        'Weak Password',
        'Use at least 6 characters.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _authService.updatePassword(newPassword: password);
      await _authService.signOut();
      if (!mounted) return;
      Get.dialog(
        AlertDialog(
          title: const Text('Password Updated'),
          content: const Text(
            'Your password has been changed successfully. Please sign in again.',
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
        'Update Failed',
        e.message,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Update Failed',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: simpleAppBar(
        title: 'New Password',
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
                alignment: const Alignment(0, -0.75),
                fit: BoxFit.contain,
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.only(top: 60),
              height: Get.height * 0.5,
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
                    text: 'Create New Password',
                    paddingTop: 12,
                    size: 20,
                    weight: FontWeight.w600,
                    paddingBottom: 8,
                  ),
                  MyText(
                    text:
                        'Set a new password for your account. Make sure it is strong and secure.',
                    size: 14,
                    color: kTertiaryColor.withValues(alpha: 0.8),
                    lineHeight: 1.5,
                    weight: FontWeight.w500,
                    paddingBottom: 30,
                  ),
                  MyTextField(
                    controller: _passwordController,
                    labelText: 'Enter Password',
                    hintText: '*********',
                    fillColor: kTertiaryColor.withValues(alpha: 0.1),
                    isObSecure: !_showPassword,
                    suffix: GestureDetector(
                      onTap: () {
                        setState(() => _showPassword = !_showPassword);
                      },
                      child: Icon(
                        _showPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: kTertiaryColor.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  MyTextField(
                    controller: _confirmPasswordController,
                    marginBottom: 30,
                    labelText: 'Confirm your Password',
                    hintText: '*********',
                    fillColor: kTertiaryColor.withValues(alpha: 0.1),
                    isObSecure: !_showConfirmPassword,
                    suffix: GestureDetector(
                      onTap: () {
                        setState(
                          () => _showConfirmPassword = !_showConfirmPassword,
                        );
                      },
                      child: Icon(
                        _showConfirmPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: kTertiaryColor.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  _isSubmitting
                      ? const Center(child: CircularProgressIndicator())
                      : MyButton(
                          buttonText: 'Submit',
                          onTap: _submit,
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
