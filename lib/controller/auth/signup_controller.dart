import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:motorsport/config/routes/routes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/auth/auth_service.dart';

class SignUpController extends GetxController {
  final AuthService _authService = AuthService();

  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  var isLoading = false.obs;
  var isPasswordVisible = false.obs;
  var isConfirmPasswordVisible = false.obs;

  void togglePasswordVisibility() => isPasswordVisible.value = !isPasswordVisible.value;
  void toggleConfirmPasswordVisibility() =>
      isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;

  void _showErrorDialog(String message) {
    Get.dialog(
      AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<void> signUp() async {
    if (emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        fullNameController.text.isEmpty) {
      _showErrorDialog("Please fill in all fields");
      return;
    }
    if (passwordController.text != confirmPasswordController.text) {
      _showErrorDialog("Passwords do not match");
      return;
    }

    try {
      isLoading.value = true;
      final response = await _authService.signUp(
        email: emailController.text.trim(),
        password: passwordController.text,
        fullName: fullNameController.text.trim(),
      );

      if (response.user != null) {
        // CORRECTED NAVIGATION: Use a named route with arguments.
        Get.toNamed(AppLinks.emailVerification, arguments: emailController.text.trim());
      }
    } on AuthException catch (e) {
      _showErrorDialog(e.message);
    } catch (e) {
      _showErrorDialog("An unexpected error occurred: ${e.toString()}");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _socialAuth(Future<AuthResponse> Function() method) async {
    try {
      isLoading.value = true;
      final response = await method();
      if (response.user != null) Get.offAllNamed(AppLinks.bottomNavBar);
    } on AuthException catch (e) {
      _showErrorDialog(e.message);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signUpGoogle() => _socialAuth(() => _authService.signInWithGoogle());
  Future<void> signUpFacebook() => _socialAuth(() => _authService.signInWithFacebook());

  @override
  void onClose() {
    fullNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}
