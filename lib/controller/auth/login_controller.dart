import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:motorsport/config/routes/routes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/auth/auth_service.dart';

class LoginController extends GetxController {
  final AuthService _authService = AuthService();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  var isLoading = false.obs;
  var isPasswordVisible = false.obs;
  var rememberMe = false.obs;

  void togglePasswordVisibility() => isPasswordVisible.value = !isPasswordVisible.value;
  void toggleRememberMe() => rememberMe.value = !rememberMe.value;

  // Helper for showing robust dialogs
  void _showErrorDialog(String message) {
    Get.dialog(
      AlertDialog(
        title: const Text("Login Failed"),
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

  Future<void> _handleAuthAction(Future<AuthResponse> Function() authCall) async {
    try {
      isLoading.value = true;
      final response = await authCall();

      if (response.user != null) {
        // Use named route for navigation to preserve context
        Get.offAllNamed(AppLinks.bottomNavBar);
      }
    } on AuthException catch (e) {
      _showErrorDialog(e.message);
    } catch (e) {
      _showErrorDialog("An unexpected error occurred: ${e.toString()}");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loginWithEmail() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      _showErrorDialog("Please fill in all fields.");
      return;
    }

    await _handleAuthAction(() => _authService.signInWithEmailPassword(
        email: emailController.text.trim(), password: passwordController.text));
  }

  // --- SOCIAL LOGINS ---
  Future<void> loginGoogle() async => await _handleAuthAction(() => _authService.signInWithGoogle());
  Future<void> loginFacebook() async => await _handleAuthAction(() => _authService.signInWithFacebook());

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
