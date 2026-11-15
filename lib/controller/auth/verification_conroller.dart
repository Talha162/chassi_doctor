import 'package:motorsport/utils/app_snackbar.dart';
import 'package:motorsport/utils/app_error.dart';
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
        email: email,
        token: pinController.text,
      );

      if (response.session != null) {
        pinStatus.value = 'verified';
        // Give a slight delay for user to see the "verified" state
        await Future.delayed(const Duration(milliseconds: 500));
        Get.offAll(() => const Onboarding());
      } else {
        // This case can happen if the token is wrong but doesn't throw for some reason
        pinStatus.value = 'invalid';
        showErrorSnackbar(
          "That code isn't right. Please check it and try again.",
          title: 'Verification failed',
        );
      }
    } on AuthException catch (e) {
      pinStatus.value = 'invalid';
      showErrorSnackbar(friendlyError(e), title: 'Verification failed');
    } catch (e) {
      showErrorSnackbar(friendlyError(e), title: 'Verification failed');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resendCode() async {
    if (resendSeconds.value > 0) return;
    try {
      await _authService.resendOtp(email: email);
      showSuccessSnackbar('A new code has been sent to your email.');
      startResendTimer();
    } catch (e) {
      showErrorSnackbar(friendlyError(e), title: "Couldn't resend the code");
    }
  }

  @override
  void onClose() {
    // GetX closes this controller as soon as the route is removed, but the
    // old page is still drawn while it animates out. Disposing the text
    // controllers immediately crashes that last frame, so wait it out.
    Future<void>.delayed(const Duration(milliseconds: 800), () {
      pinController.dispose();
    });
    _timer?.cancel();
    super.onClose();
  }
}
