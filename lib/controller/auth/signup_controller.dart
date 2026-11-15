import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:motorsport/config/routes/routes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/auth/auth_service.dart';
import '../../utils/app_error.dart';
import '../../utils/app_snackbar.dart';

class SignUpController extends GetxController {
  final AuthService _authService = AuthService();

  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  var isLoading = false.obs;
  var isPasswordVisible = false.obs;
  var isConfirmPasswordVisible = false.obs;

  void togglePasswordVisibility() =>
      isPasswordVisible.value = !isPasswordVisible.value;
  void toggleConfirmPasswordVisibility() =>
      isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;

  void _showError(Object error) {
    if (isUserCancelled(error)) return; // closed the Google/Apple sheet
    showErrorSnackbar(friendlyError(error), title: "Couldn't create account");
  }

  void _showAccountExists(String email) {
    showInfoSnackbar(
      '$email is already registered. Log in instead, or use '
      '"Forgot Password?" if you don\'t remember it.',
      title: 'Account already exists',
      action: SnackBarAction(
        label: 'Log in',
        textColor: const Color(0xffE8C670),
        onPressed: () => Get.offAllNamed(AppLinks.login),
      ),
    );
  }

  Future<void> signUp() async {
    // Field-level validation happens in the Sign Up form; this is a guard.
    if (emailController.text.trim().isEmpty ||
        passwordController.text.isEmpty ||
        fullNameController.text.trim().isEmpty ||
        passwordController.text != confirmPasswordController.text) {
      return;
    }

    final email = AuthService.normalizeEmail(emailController.text);

    try {
      isLoading.value = true;
      final response = await _authService.signUp(
        email: email,
        password: passwordController.text,
        fullName: fullNameController.text.trim(),
      );

      final user = response.user;
      if (user == null) return;

      // Email already registered: Supabase returns a placeholder user with
      // no identities (when confirmation is on) — treat as "account exists".
      if (user.identities != null && user.identities!.isEmpty) {
        _showAccountExists(email);
        return;
      }

      // Email confirmation is currently DISABLED in Supabase
      // (auth config `mailer_autoconfirm = true`), so sign-up returns a live
      // session and the user goes straight into onboarding — no OTP.
      if (response.session != null) {
        Get.offAllNamed(AppLinks.onboarding);
        return;
      }

      // Fallback if email confirmation is switched back on in Supabase:
      // the account needs the 6-digit code before it can sign in.
      Get.toNamed(AppLinks.emailVerification, arguments: email);
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      if (e.code == 'user_already_exists' ||
          msg.contains('already registered') ||
          msg.contains('already been registered') ||
          msg.contains('already exists')) {
        _showAccountExists(email);
      } else {
        _showError(e);
      }
    } catch (e) {
      _showError(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _socialAuth(Future<void> Function() method) async {
    try {
      isLoading.value = true;
      await method();
    } catch (e) {
      _showError(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signUpGoogle() =>
      _socialAuth(() => _authService.signInWithGoogle());
  Future<void> signUpApple() =>
      _socialAuth(() => _authService.signInWithApple());

  @override
  void onClose() {
    // GetX closes this controller as soon as the route is removed, but the
    // old page is still drawn while it animates out. Disposing the text
    // controllers immediately crashes that last frame, so wait it out.
    Future<void>.delayed(const Duration(milliseconds: 800), () {
      fullNameController.dispose();
      emailController.dispose();
      passwordController.dispose();
      confirmPasswordController.dispose();
    });
    super.onClose();
  }
}
