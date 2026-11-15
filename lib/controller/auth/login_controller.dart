import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:motorsport/config/routes/routes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/auth/auth_service.dart';
import '../../utils/app_error.dart';
import '../../utils/app_snackbar.dart';

class LoginController extends GetxController {
  final AuthService _authService = AuthService();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  var isLoading = false.obs;
  var isPasswordVisible = false.obs;
  var rememberMe = false.obs;

  void togglePasswordVisibility() =>
      isPasswordVisible.value = !isPasswordVisible.value;
  void toggleRememberMe() => rememberMe.value = !rememberMe.value;

  void _showError(Object error) {
    if (isUserCancelled(error)) return; // closed the Google/Apple sheet
    showErrorSnackbar(friendlyError(error), title: "Couldn't log in");
  }

  Future<void> _handleAuthAction(
    Future<AuthResponse> Function() authCall,
  ) async {
    try {
      isLoading.value = true;
      final response = await authCall();

      if (response.user != null) {
        // Use named route for navigation to preserve context
        Get.offAllNamed(AppLinks.bottomNavBar);
      }
    } catch (e) {
      _showError(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _handleOAuthAction(Future<void> Function() authCall) async {
    try {
      isLoading.value = true;
      await authCall();
    } catch (e) {
      _showError(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loginWithEmail() async {
    // Field-level validation happens in the Login form; this is a guard.
    if (emailController.text.trim().isEmpty ||
        passwordController.text.isEmpty) {
      return;
    }

    await _handleAuthAction(
      () => _authService.signInWithEmailPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      ),
    );
  }

  // --- SOCIAL LOGINS ---
  Future<void> loginGoogle() async =>
      await _handleOAuthAction(() => _authService.signInWithGoogle());
  Future<void> loginApple() async =>
      await _handleAuthAction(() => _authService.signInWithApple());

  @override
  void onClose() {
    // GetX closes this controller as soon as the route is removed, but the
    // old page is still drawn while it animates out. Disposing the text
    // controllers immediately crashes that last frame, so wait it out.
    Future<void>.delayed(const Duration(milliseconds: 800), () {
      emailController.dispose();
      passwordController.dispose();
    });
    super.onClose();
  }
}
