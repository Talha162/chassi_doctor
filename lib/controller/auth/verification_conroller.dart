import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:motorsport/view/screens/launch/onboarding.dart';

import '../../services/auth/auth_service.dart';

class VerificationController extends GetxController {
  final AuthService _authService = AuthService();
  final TextEditingController pinController = TextEditingController();

  // Arguments passed from Sign Up
  String email = '';

  var isLoading = false.obs;
  var pinStatus = 'default'.obs; // 'default', 'verified', 'invalid'
  var resendSeconds = 30.obs;
  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments != null && Get.arguments is String) {
      email = Get.arguments;
    }
    startResendTimer();
  }

  void startResendTimer() {
    resendSeconds.value = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (resendSeconds.value > 0) {
        resendSeconds.value--;
      } else {
        _timer?.cancel();
      }
    });
  }

  void onPinChanged(String value) {
    if (value.length < 6) {
      pinStatus.value = 'default';
    }
  }

  Future<void> verifyOtp() async {
    if (pinController.text.length != 6) return;

    try {
      isLoading.value = true;
      final response = await _authService.verifyOtp(
          email: email, token: pinController.text);

      if (response.session != null) {
        pinStatus.value = 'verified';
        // Give a slight delay for user to see the "verified" state
        await Future.delayed(const Duration(milliseconds: 500));
        Get.offAll(() => const Onboarding());
      } else {
        // This case can happen if the token is wrong but doesn't throw for some reason
        pinStatus.value = 'invalid';
        Get.snackbar("Verification Failed", "The code you entered is incorrect.",
            backgroundColor: Colors.redAccent, colorText: Colors.white);
      }
    } on AuthException catch (e) {
      pinStatus.value = 'invalid';
      Get.snackbar("Verification Failed", e.message,
          backgroundColor: Colors.redAccent, colorText: Colors.white);
    } catch (e) {
      Get.snackbar("Error", "An unexpected error occurred: $e",
          backgroundColor: Colors.redAccent, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resendCode() async {
    if (resendSeconds.value > 0) return;
    try {
      await _authService.resendOtp(email: email);
      Get.snackbar("Sent", "A new code has been sent to your email.",
          backgroundColor: Colors.green, colorText: Colors.white);
      startResendTimer();
    } catch (e) {
      Get.snackbar("Error", "Failed to resend code. Please try again later.",
          backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }

  @override
  void onClose() {
    _timer?.cancel();
    pinController.dispose();
    super.onClose();
  }
}
